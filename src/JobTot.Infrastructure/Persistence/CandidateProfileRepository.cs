using System.Text.Json;
using JobTot.Application.Profiles;
using JobTot.Domain.Entities;
using JobTot.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace JobTot.Infrastructure.Persistence;

public sealed class CandidateProfileRepository(RecruitmentDbContext db) : ICandidateProfileRepository
{
    private Task<CandidateProfile?> Find(Guid id, CancellationToken ct) => db.CandidateProfileRecords
        .Include(x => x.Account).Include(x => x.CandidateCvs)
        .SingleOrDefaultAsync(x => x.AccountId == id && x.Status == EntityStatus.Active && x.Account.Status == EntityStatus.Active, ct);

    private static CandidateProfileResponse Response(CandidateProfile p)
    {
        var document = p.DetailsJson is null ? new CandidateProfileDocument
        {
            FullName = p.Account.FullName, Headline = p.Headline ?? "", Summary = p.Summary ?? "",
            BirthDate = p.BirthDate, ReadyStatus = p.ReadyStatus ?? "looking",
            ExpectedSalaryMin = p.ExpectedSalaryMin, ExpectedSalaryMax = p.ExpectedSalaryMax
        } : JsonSerializer.Deserialize<CandidateProfileDocument>(p.DetailsJson)!;
        return new(document, p.Account.Email, p.Account.Phone,
            p.CandidateCvs.Where(x => x.Status == EntityStatus.Active).OrderByDescending(x => x.CreatedDate)
                .Select(x => new ProfileCv(x.Id, x.Title, x.IsDefault)).ToList());
    }
    public async Task<CandidateProfileResponse?> GetAsync(Guid accountId, CancellationToken ct)
        => await Find(accountId, ct) is { } p ? Response(p) : null;

    public async Task<CandidateProfileResponse?> SaveAsync(Guid accountId, CandidateProfileDocument document, CancellationToken ct)
    {
        var p = await Find(accountId, ct);
        if (p is null) return null;
        p.DetailsJson = JsonSerializer.Serialize(document);
        p.Account.FullName = document.FullName.Trim();
        p.Headline = document.Headline; p.Summary = document.Summary; p.BirthDate = document.BirthDate;
        p.ReadyStatus = document.ReadyStatus; p.ExpectedSalaryMin = document.ExpectedSalaryMin;
        p.ExpectedSalaryMax = document.ExpectedSalaryMax; p.UpdatedDate = DateTimeOffset.UtcNow; p.UpdatedAccountId = accountId;
        await db.SaveChangesAsync(ct);
        return Response(p);
    }
    public async Task<ProfileCv?> UploadCvAsync(Guid accountId, string name, byte[] content, CancellationToken ct)
    {
        var p = await Find(accountId, ct);
        if (p is null) return null;
        var cv = new CandidateCv { CandidateId = p.Id, Title = name, ContentJson = JsonSerializer.Serialize(Convert.ToBase64String(content)), IsDefault = true, CreatedAccountId = accountId };
        foreach (var previous in p.CandidateCvs) previous.IsDefault = false;
        db.CandidateCvRecords.Add(cv);
        await db.SaveChangesAsync(ct);
        return new(cv.Id, cv.Title, cv.IsDefault);
    }
    public async Task<(string Name, byte[] Content)?> GetCvAsync(Guid accountId, Guid cvId, CancellationToken ct)
    {
        var cv = await db.CandidateCvRecords.AsNoTracking().SingleOrDefaultAsync(x => x.Id == cvId && x.Candidate.AccountId == accountId && x.Status == EntityStatus.Active, ct);
        if (cv?.ContentJson is null) return null;
        return (cv.Title, Convert.FromBase64String(JsonSerializer.Deserialize<string>(cv.ContentJson)!));
    }
}
