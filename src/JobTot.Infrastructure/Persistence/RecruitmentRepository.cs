using JobTot.Application;
using JobTot.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace JobTot.Infrastructure.Persistence;

internal sealed class RecruitmentRepository(RecruitmentDbContext db) : IRecruitmentRepository
{
    public Task<Company?> GetCompanyAsync(Guid id, CancellationToken ct)
        => db.Companies.AsNoTracking().SingleOrDefaultAsync(x => x.Id == id, ct);
    public async Task<PageResult<CompanyDto>> GetCompaniesAsync(int page, int pageSize, CancellationToken ct)
    {
        var query = db.Companies.AsNoTracking();
        var total = await query.CountAsync(ct);
        var items = await query.OrderBy(x => x.Name).ThenBy(x => x.Id)
            .Skip((page - 1) * pageSize).Take(pageSize)
            .Select(x => new CompanyDto(x.Id, x.Name, x.Description)).ToListAsync(ct);
        return new(items, total, page, pageSize);
    }
    public Task<JobPost?> GetJobAsync(Guid id, CancellationToken ct)
        => db.Jobs.SingleOrDefaultAsync(x => x.Id == id, ct);
    public async Task<PageResult<JobDto>> SearchJobsAsync(JobSearch query, CancellationToken ct)
    {
        var jobs = db.Jobs.AsNoTracking();
        var now = DateTimeOffset.UtcNow;
        if (!query.IncludeClosed) jobs = jobs.Where(x => !x.IsClosed && x.ExpiresAt > now);
        if (query.CompanyId.HasValue) jobs = jobs.Where(x => x.CompanyId == query.CompanyId);
        if (!string.IsNullOrWhiteSpace(query.Keyword))
        {
            var keyword = query.Keyword.Trim();
            jobs = jobs.Where(x => x.Title.Contains(keyword) || x.Description.Contains(keyword));
        }
        if (!string.IsNullOrWhiteSpace(query.Location))
        {
            var location = query.Location.Trim();
            jobs = jobs.Where(x => x.Location.Contains(location));
        }
        var total = await jobs.CountAsync(ct);
        var items = await jobs.OrderByDescending(x => x.CreatedAt).ThenBy(x => x.Id)
            .Skip((query.Page - 1) * query.PageSize).Take(query.PageSize)
            .Select(x => new JobDto(x.Id, x.CompanyId, x.Title, x.Description, x.Location,
                x.SalaryMin, x.SalaryMax, x.CreatedAt, x.ExpiresAt, x.IsClosed)).ToListAsync(ct);
        return new(items, total, query.Page, query.PageSize);
    }
    public void AddCompany(Company company) => db.Companies.Add(company);
    public void AddJob(JobPost job) => db.Jobs.Add(job);
    public async Task SaveChangesAsync(CancellationToken ct) => await db.SaveChangesAsync(ct);
}
