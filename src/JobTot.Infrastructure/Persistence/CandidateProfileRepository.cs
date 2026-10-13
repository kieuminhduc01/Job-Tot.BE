using System.Text.Json;
using JobTot.Application.Profiles;
using JobTot.Domain.Entities;
using JobTot.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace JobTot.Infrastructure.Persistence;

public sealed class CandidateProfileRepository(RecruitmentDbContext db) : ICandidateProfileRepository
{
    public async Task<IReadOnlyList<ProfileCv>?> SetCvDefaultAsync(Guid accountId, Guid cvId, bool isDefault, CancellationToken ct)

    {
        try
        {
            return await db.Database.CreateExecutionStrategy().ExecuteAsync(async () =>
            {
                await using var transaction = db.Database.IsRelational() ? await db.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable, ct) : null;
                var cvs = await db.CandidateCvRecords.Where(c => c.Candidate.AccountId == accountId && c.Candidate.Status == EntityStatus.Active && c.Candidate.Account.Status == EntityStatus.Active && c.Status == EntityStatus.Active).ToListAsync(ct);
                var selected = cvs.SingleOrDefault(c => c.Id == cvId);
                if (selected is null)
                    return (IReadOnlyList<ProfileCv>?)null;
                if (isDefault)
                {
                    foreach (var cv in cvs.Where(c => c.Id != cvId))
                        cv.IsDefault = false;
                    // Clear the old primary first to respect the filtered unique index.
                    await db.SaveChangesAsync(ct);
                }

                selected.IsDefault = isDefault;
                await db.SaveChangesAsync(ct);
                if (transaction is not null)
                    await transaction.CommitAsync(ct);
                return (IReadOnlyList<ProfileCv>)cvs.Select(c => new ProfileCv(c.Id, c.Title, c.IsDefault, c.OnlineDocumentJson != null)).ToList();
            });
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception exception)
        {
            global::JobTot.Application.ExceptionDiagnostics.Record(exception, "CandidateProfileRepository.SetCvDefaultAsync");
            throw;
        }
    }

    private async Task<CandidateProfile?> Find(Guid id, CancellationToken ct)
    {
        try
        {
            return await (db.CandidateProfileRecords.Include(x => x.Account).Include(x => x.CandidateCvs).SingleOrDefaultAsync(x => x.AccountId == id && x.Status == EntityStatus.Active && x.Account.Status == EntityStatus.Active, ct));
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception exception)
        {
            global::JobTot.Application.ExceptionDiagnostics.Record(exception, "CandidateProfileRepository.Find");
            throw;
        }
    }

    private static CandidateProfileResponse Response(CandidateProfile p)
    {
        try
        {
            var document = p.DetailsJson is null ? new CandidateProfileDocument
            {
                FullName = p.Account.FullName,
                Headline = p.Headline ?? "",
                Summary = p.Summary ?? "",
                BirthDate = p.BirthDate,
                ReadyStatus = p.ReadyStatus ?? "looking",
                ExpectedSalaryMin = p.ExpectedSalaryMin,
                ExpectedSalaryMax = p.ExpectedSalaryMax
            }

            : JsonSerializer.Deserialize<CandidateProfileDocument>(p.DetailsJson)!;
            return new(document, p.Account.Email, p.Account.Phone, p.CandidateCvs.Where(x => x.Status == EntityStatus.Active).OrderByDescending(x => x.CreatedDate).Select(x => new ProfileCv(x.Id, x.Title, x.IsDefault, x.OnlineDocumentJson != null)).ToList());
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception exception)
        {
            global::JobTot.Application.ExceptionDiagnostics.Record(exception, "CandidateProfileRepository.Response");
            throw;
        }
    }
    public async Task<CandidateProfileResponse?> GetAsync(Guid accountId, CancellationToken ct)

    {
        try
        {
            var p = await Find(accountId, ct);
            if (p is null) return null;
            var since = DateTimeOffset.UtcNow.AddDays(-7);
            var views = await db.CandidateJobSubmissions.AsNoTracking()
                .Where(s => s.CandidateId == p.Id && s.ReviewedAt >= since && s.Job.Company.Status == EntityStatus.Active)
                .OrderByDescending(s => s.ReviewedAt)
                .Select(s => new CandidateProfileVisitor(s.Job.CompanyId, s.Job.Company.Name, s.ReviewedAt!.Value))
                .ToListAsync(ct);
            var invitations = await db.InterviewRecords.AsNoTracking()
                .CountAsync(i => i.Application.CandidateId == p.Id && i.CreatedDate >= since
                    && i.Status == EntityStatus.Active && i.Application.Status == EntityStatus.Active
                    && i.Application.Campaign.Status == EntityStatus.Active && i.Application.Campaign.Company.Status == EntityStatus.Active
                    && i.InterviewStatus != "cancelled" && i.InterviewStatus != "canceled" && i.InterviewStatus != "declined", ct);
            return Response(p) with { Activity = new(views.Count, invitations, views.DistinctBy(v => v.CompanyId).Take(5).ToList()) };
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception exception)
        {
            global::JobTot.Application.ExceptionDiagnostics.Record(exception, "CandidateProfileRepository.GetAsync");
            throw;
        }
    }

    public async Task<CandidateProfileResponse?> SaveAsync(Guid accountId, CandidateProfileDocument document, CancellationToken ct)
    {
        try
        {
            var p = await Find(accountId, ct);
            if (p is null)
                return null;
            var previous = Response(p).Profile;
            document.AvatarUrl = previous.AvatarUrl;
            if (document.ProvinceId is { } addressProvinceId)
            {
                var addressProvince = await db.ProvinceRecords.AsNoTracking().SingleOrDefaultAsync(x => x.Id == addressProvinceId && x.Status == EntityStatus.Active, ct) ?? throw new ArgumentException("Tỉnh/thành của địa chỉ không tồn tại hoặc đã ngừng hoạt động.");
                document.Location = addressProvince.ProvinceName;
                p.ProvinceId = addressProvince.Id;
            }
            else if (!string.IsNullOrEmpty(document.Location) && document.Location != previous.Location)
            {
                var addressProvince = await db.ProvinceRecords.AsNoTracking().SingleOrDefaultAsync(x => x.ProvinceName == document.Location && x.Status == EntityStatus.Active, ct) ?? throw new ArgumentException("Vui lòng chọn địa chỉ từ danh sách tỉnh/thành.");
                document.ProvinceId = addressProvince.Id;
                p.ProvinceId = addressProvince.Id;
            }

            var workTypes = new[]
            {
                "Toàn thời gian",
                "Bán thời gian",
                "Làm việc từ xa",
                "Kết hợp (Hybrid)"
            };
            if (!string.IsNullOrEmpty(document.WorkType) && !workTypes.Contains(document.WorkType) && document.WorkType != previous.WorkType)
                throw new ArgumentException("Vui lòng chọn hình thức làm việc có sẵn.");
            if (document.DesiredProvinceId is { } provinceId)
            {
                var province = await db.ProvinceRecords.AsNoTracking().SingleOrDefaultAsync(x => x.Id == provinceId && x.Status == EntityStatus.Active, ct) ?? throw new ArgumentException("Địa điểm ưu tiên không tồn tại hoặc đã ngừng hoạt động.");
                document.DesiredLocation = province.ProvinceName;
            }
            else if (!string.IsNullOrEmpty(document.DesiredLocation) && document.DesiredLocation != previous.DesiredLocation)
            {
                var province = await db.ProvinceRecords.AsNoTracking().SingleOrDefaultAsync(x => x.ProvinceName == document.DesiredLocation && x.Status == EntityStatus.Active, ct) ?? throw new ArgumentException("Vui lòng chọn địa điểm ưu tiên từ danh sách tỉnh/thành.");
                document.DesiredProvinceId = province.Id;
            }

            p.DetailsJson = JsonSerializer.Serialize(document);
            p.Account.FullName = document.FullName.Trim();
            p.Headline = document.Headline;
            p.Summary = document.Summary;
            p.BirthDate = document.BirthDate;
            p.ReadyStatus = document.ReadyStatus;
            p.ExpectedSalaryMin = document.ExpectedSalaryMin;
            p.ExpectedSalaryMax = document.ExpectedSalaryMax;
            p.UpdatedDate = DateTimeOffset.UtcNow;
            p.UpdatedAccountId = accountId;
            await db.SaveChangesAsync(ct);
            return Response(p);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception exception)
        {
            global::JobTot.Application.ExceptionDiagnostics.Record(exception, "CandidateProfileRepository.SaveAsync");
            throw;
        }
    }
    public async Task<CandidateProfileResponse?> SetAvatarAsync(Guid accountId, string? avatarUrl, CancellationToken ct)
    {
        try
        {
            var p = await Find(accountId, ct);
            if (p is null)
                return null;
            var document = Response(p).Profile;
            document.AvatarUrl = avatarUrl;
            p.DetailsJson = JsonSerializer.Serialize(document);
            p.UpdatedDate = DateTimeOffset.UtcNow;
            p.UpdatedAccountId = accountId;
            await db.SaveChangesAsync(ct);
            return Response(p);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception exception)
        {
            global::JobTot.Application.ExceptionDiagnostics.Record(exception, "CandidateProfileRepository.SetAvatarAsync");
            throw;
        }
    }
    public async Task<ProfileCv?> UploadCvAsync(Guid accountId, string name, byte[] content, CancellationToken ct)
    {
        try
        {
            var p = await Find(accountId, ct);
            if (p is null)
                return null;
            var cv = new CandidateCv
            {
                CandidateId = p.Id,
                Title = name,
                ContentJson = JsonSerializer.Serialize(Convert.ToBase64String(content)),
                IsDefault = true,
                CreatedAccountId = accountId
            };
            foreach (var previous in p.CandidateCvs)
                previous.IsDefault = false;
            db.CandidateCvRecords.Add(cv);
            await db.SaveChangesAsync(ct);
            return new(cv.Id, cv.Title, cv.IsDefault);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception exception)
        {
            global::JobTot.Application.ExceptionDiagnostics.Record(exception, "CandidateProfileRepository.UploadCvAsync");
            throw;
        }
    }
    public async Task<(string Name, byte[] Content)?> GetCvAsync(Guid accountId, Guid cvId, CancellationToken ct)
    {
        try
        {
            var cv = await db.CandidateCvRecords.AsNoTracking().SingleOrDefaultAsync(x => x.Id == cvId && x.Candidate.AccountId == accountId && x.Status == EntityStatus.Active, ct);
            if (cv?.ContentJson is null)
                return null;
            return (cv.Title, Convert.FromBase64String(JsonSerializer.Deserialize<string>(cv.ContentJson)!));
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception exception)
        {
            global::JobTot.Application.ExceptionDiagnostics.Record(exception, "CandidateProfileRepository.GetCvAsync");
            throw;
        }
    }
}
