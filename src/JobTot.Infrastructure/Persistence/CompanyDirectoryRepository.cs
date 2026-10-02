using JobTot.Application;
using JobTot.Application.Companies;
using JobTot.Domain.Entities;
using JobTot.Domain.Enums;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace JobTot.Infrastructure.Persistence;

public sealed class CompanyDirectoryRepository(RecruitmentDbContext db) : ICompanyDirectoryRepository
{
    private IQueryable<Company> Companies => db.Companies.AsNoTracking().Where(x => x.Status == EntityStatus.Active);
    private IQueryable<JobPost> OpenJobs => db.Jobs.AsNoTracking().Where(x => !x.IsClosed && x.ExpiresAt > DateTimeOffset.UtcNow);

    public async Task<PageResult<CompanyListingDto>> SearchAsync(CompanySearch search, CancellationToken ct)
    {
        var query = Companies;
        if (!string.IsNullOrWhiteSpace(search.Keyword))
        {
            var keyword = search.Keyword.Trim();
            query = query.Where(x => x.Name.Contains(keyword) || x.Description.Contains(keyword));
        }
        if (search.ProvinceId is { } province) query = query.Where(x => x.HeadOfficeProvinceId == province);
        if (search.IndustryId is { } industry)
            query = query.Where(x => x.IndustryId == industry || x.CompanyIndustrys.Any(y => y.IndustryId == industry && y.Status == EntityStatus.Active));
        if (search.VerifiedOnly) query = query.Where(x => x.VerificationStatus == "Verified");
        if (search.HiringOnly) query = query.Where(x => OpenJobs.Any(job => job.CompanyId == x.Id));
        if (search.CompanySizeMin is { } min)
            query = query.Where(x => (x.CompanySizeMax ?? x.CompanySizeMin) >= min);
        if (search.CompanySizeMax is { } max)
            query = query.Where(x => (x.CompanySizeMin ?? x.CompanySizeMax) <= max);
        var total = await query.CountAsync(ct);
        var ranked = query.Select(x => new
        {
            Company = x, OpenJobCount = OpenJobs.Count(job => job.CompanyId == x.Id)
        });
        var ordered = search.Sort switch
        {
            "name" => ranked.OrderBy(x => x.Company.Name).ThenBy(x => x.Company.Id),
            "jobs" => ranked.OrderByDescending(x => x.OpenJobCount).ThenBy(x => x.Company.Name).ThenBy(x => x.Company.Id),
            _ => ranked.OrderByDescending(x => x.Company.VerificationStatus == "Verified")
                .ThenByDescending(x => x.OpenJobCount).ThenBy(x => x.Company.Name).ThenBy(x => x.Company.Id)
        };
        var items = await ordered.Skip((search.Page - 1) * search.PageSize).Take(search.PageSize)
            .Select(x => new CompanyListingDto(x.Company.Id, x.Company.Name, x.Company.Description,
                x.Company.Industry != null ? x.Company.Industry.IndustryName : null,
                x.Company.HeadOfficeProvince != null ? x.Company.HeadOfficeProvince.ProvinceName : null,
                x.Company.AddressLine, x.Company.CompanySizeMin, x.Company.CompanySizeMax,
                x.Company.LogoFile != null ? x.Company.LogoFile.Url : null,
                x.Company.CoverFile != null ? x.Company.CoverFile.Url : null,
                x.Company.VerificationStatus == "Verified", x.OpenJobCount, new List<string>())).ToListAsync(ct);
        var ids = items.Select(x => x.Id).ToArray();
        var titles = await OpenJobs.Where(x => ids.Contains(x.CompanyId)).OrderByDescending(x => x.CreatedAt).ThenBy(x => x.Id)
            .Select(x => new { x.CompanyId, x.Title }).ToListAsync(ct);
        var byCompany = titles.GroupBy(x => x.CompanyId).ToDictionary(x => x.Key, x => (IReadOnlyList<string>)x.Select(y => y.Title).Distinct().Take(3).ToArray());
        return new(items.Select(x => x with { HiringTitles = byCompany.GetValueOrDefault(x.Id, []) }).ToArray(), total, search.Page, search.PageSize);
    }

    public async Task<CompanyDirectoryMetadata> MetadataAsync(CancellationToken ct)
    {
        var stats = new CompanyDirectoryStats(await Companies.CountAsync(ct),
            await Companies.CountAsync(x => x.VerificationStatus == "Verified", ct),
            await Companies.CountAsync(x => OpenJobs.Any(job => job.CompanyId == x.Id), ct),
            await OpenJobs.CountAsync(x => Companies.Any(company => company.Id == x.CompanyId), ct));
        var provinces = await db.ProvinceRecords.AsNoTracking().Where(x => x.Status == EntityStatus.Active)
            .Select(x => new { x.Id, Name = x.ProvinceName, Count = Companies.Count(c => c.HeadOfficeProvinceId == x.Id) })
            .OrderBy(x => x.Name)
            .Select(x => new CompanyFilterOption(x.Id, x.Name, x.Count)).ToListAsync(ct);
        var industries = await db.IndustryRecords.AsNoTracking().Where(x => x.Status == EntityStatus.Active)
            .Select(x => new { x.Id, Name = x.IndustryName,
                Count = Companies.Count(c => c.IndustryId == x.Id || c.CompanyIndustrys.Any(y => y.IndustryId == x.Id && y.Status == EntityStatus.Active)) })
            .Where(x => x.Count > 0).OrderBy(x => x.Name)
            .Select(x => new CompanyFilterOption(x.Id, x.Name, x.Count)).ToListAsync(ct);
        return new(stats, provinces, industries);
    }

    public async Task<IReadOnlyList<Guid>> FollowedAsync(Guid accountId, CancellationToken ct)
        => await db.FollowedCompanyRecords.AsNoTracking().Where(x => x.Candidate.AccountId == accountId
            && x.Status == EntityStatus.Active && x.Company.Status == EntityStatus.Active).Select(x => x.CompanyId).ToListAsync(ct);

    public async Task SetFollowedAsync(Guid accountId, Guid companyId, bool followed, CancellationToken ct)
    {
        if (!await Companies.AnyAsync(x => x.Id == companyId, ct)) throw new NotFoundException("Company not found.");
        var candidateId = await db.CandidateProfileRecords.Where(x => x.AccountId == accountId && x.Status == EntityStatus.Active)
            .Select(x => (Guid?)x.Id).SingleOrDefaultAsync(ct) ?? throw new NotFoundException("Candidate profile not found.");
        var record = await db.FollowedCompanyRecords.SingleOrDefaultAsync(x => x.CandidateId == candidateId && x.CompanyId == companyId, ct);
        if (record is null)
        {
            if (!followed) return;
            record = new FollowedCompany { CandidateId = candidateId, CompanyId = companyId };
            db.FollowedCompanyRecords.Add(record);
        }
        record.Status = followed ? EntityStatus.Active : EntityStatus.Deleted;
        record.UpdatedDate = DateTimeOffset.UtcNow;
        try { await db.SaveChangesAsync(ct); }
        catch (DbUpdateException ex) when (ex.InnerException is SqlException { Number: 2601 or 2627 })
        {
            db.ChangeTracker.Clear();
            var existing = await db.FollowedCompanyRecords.SingleAsync(x => x.CandidateId == candidateId && x.CompanyId == companyId, ct);
            existing.Status = followed ? EntityStatus.Active : EntityStatus.Deleted;
            await db.SaveChangesAsync(ct);
        }
    }
}
