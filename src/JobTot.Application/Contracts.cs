using System.ComponentModel.DataAnnotations;

namespace JobTot.Application;

public sealed record CreateCompanyRequest(
    [Required, StringLength(200)] string Name,
    [Required, StringLength(4000)] string Description);
public sealed record CompanyDto(Guid Id, string Name, string Description);
public sealed record SaveJobRequest(
    [Required, StringLength(200)] string Title,
    [Required, StringLength(10000)] string Description,
    [Required, StringLength(200)] string Location,
    decimal? SalaryMin, decimal? SalaryMax, DateTimeOffset ExpiresAt);
public sealed record CreateJobRequest(Guid CompanyId, [Required] SaveJobRequest Job);
public sealed record JobDto(Guid Id, Guid CompanyId, string Title, string Description,
    string Location, decimal? SalaryMin, decimal? SalaryMax, DateTimeOffset CreatedAt,
    DateTimeOffset ExpiresAt, bool IsClosed);
public sealed class JobSearch
{
    [StringLength(200)] public string? Keyword { get; set; }
    [StringLength(200)] public string? Location { get; set; }
    public Guid? CompanyId { get; set; }
    public bool IncludeClosed { get; set; }
    [Range(1, 1000000)] public int Page { get; set; } = 1;
    [Range(1, 100)] public int PageSize { get; set; } = 20;
}
public sealed record PageResult<T>(IReadOnlyList<T> Items, int TotalCount, int Page, int PageSize);
public sealed class NotFoundException(string message) : Exception(message);
