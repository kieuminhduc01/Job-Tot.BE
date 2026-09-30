using JobTot.Domain.Entities;

namespace JobTot.Application;

public interface IRecruitmentRepository
{
    Task<Company?> GetCompanyAsync(Guid id, CancellationToken ct);
    Task<PageResult<CompanyDto>> GetCompaniesAsync(int page, int pageSize, CancellationToken ct);
    Task<JobPost?> GetJobAsync(Guid id, CancellationToken ct);
    Task<PageResult<JobDto>> SearchJobsAsync(JobSearch query, CancellationToken ct);
    void AddCompany(Company company);
    void AddJob(JobPost job);
    Task SaveChangesAsync(CancellationToken ct);
}
