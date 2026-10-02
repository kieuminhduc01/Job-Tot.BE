using System.ComponentModel.DataAnnotations;

namespace JobTot.Application.Profiles;

public sealed class CandidateProfileDocument : IValidatableObject
{
    [Required, StringLength(200)] public string FullName { get; set; } = "";
    [StringLength(200)] public string Headline { get; set; } = "";
    [StringLength(200)] public string Location { get; set; } = "";
    public DateOnly? BirthDate { get; set; }
    [StringLength(30)] public string Gender { get; set; } = "";
    [StringLength(10000)] public string Summary { get; set; } = "";
    [Required, RegularExpression("^(looking|considering|paused)$")] public string ReadyStatus { get; set; } = "looking";
    [Range(0, 1000000000)] public decimal? ExpectedSalaryMin { get; set; }
    [Range(0, 1000000000)] public decimal? ExpectedSalaryMax { get; set; }
    [StringLength(200)] public string DesiredPosition { get; set; } = "";
    [StringLength(100)] public string WorkType { get; set; } = "";
    [StringLength(200)] public string DesiredLocation { get; set; } = "";
    [MaxLength(50)] public List<ProfileEntry> Experiences { get; set; } = [];
    [MaxLength(100)] public List<ProfileEntry> Skills { get; set; } = [];
    [MaxLength(30)] public List<ProfileEntry> Education { get; set; } = [];
    [MaxLength(50)] public List<ProfileEntry> Certificates { get; set; } = [];
    [MaxLength(50)] public List<ProfileEntry> Projects { get; set; } = [];

    public IEnumerable<ValidationResult> Validate(ValidationContext context)
    {
        if (string.IsNullOrWhiteSpace(FullName)) yield return new("Họ tên không được để trống.", [nameof(FullName)]);
        if (ExpectedSalaryMin > ExpectedSalaryMax) yield return new("Lương tối đa phải lớn hơn hoặc bằng lương tối thiểu.", [nameof(ExpectedSalaryMax)]);
        if (BirthDate > DateOnly.FromDateTime(DateTime.UtcNow)) yield return new("Ngày sinh không hợp lệ.", [nameof(BirthDate)]);
        if (new[] { Experiences, Skills, Education, Certificates, Projects }.Any(x => x is null))
            yield return new("Danh sách hồ sơ không được null.");
    }
}

public sealed class ProfileEntry
{
    [Required, StringLength(200)] public string Title { get; set; } = "";
    [StringLength(200)] public string Organization { get; set; } = "";
    [StringLength(100)] public string Period { get; set; } = "";
    [StringLength(10000)] public string Description { get; set; } = "";
    [StringLength(1000)] public string Tags { get; set; } = "";
}

public record CandidateProfileResponse(CandidateProfileDocument Profile, string? Email, string? Phone, IReadOnlyList<ProfileCv> Cvs);
public record ProfileCv(Guid Id, string Title, bool IsDefault);
public interface ICandidateProfileRepository
{
    Task<CandidateProfileResponse?> GetAsync(Guid accountId, CancellationToken ct);
    Task<CandidateProfileResponse?> SaveAsync(Guid accountId, CandidateProfileDocument document, CancellationToken ct);
    Task<ProfileCv?> UploadCvAsync(Guid accountId, string name, byte[] content, CancellationToken ct);
    Task<(string Name, byte[] Content)?> GetCvAsync(Guid accountId, Guid cvId, CancellationToken ct);
}
