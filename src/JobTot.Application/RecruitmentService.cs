using JobTot.Domain.Entities;

namespace JobTot.Application;

public sealed class RecruitmentService(IRecruitmentRepository repository)
{
    public Task<PageResult<CompanyDto>> GetCompaniesAsync(int page, int size, CancellationToken ct)
        => repository.GetCompaniesAsync(page, size, ct);
    public async Task<CompanyDto> GetCompanyAsync(Guid id, CancellationToken ct)
    {
        var company = await repository.GetCompanyAsync(id, ct)
            ?? throw new NotFoundException("Company not found.");
        return new(company.Id, company.Name, company.Description);
    }
    public async Task<CompanyDto> CreateCompanyAsync(CreateCompanyRequest request, CancellationToken ct)
    {
        var company = new Company(request.Name, request.Description);
        repository.AddCompany(company);
        await repository.SaveChangesAsync(ct);
        return new(company.Id, company.Name, company.Description);
    }
    public Task<PageResult<JobDto>> SearchAsync(JobSearch query, CancellationToken ct)
        => repository.SearchJobsAsync(query, ct);
    public async Task<JobDto> GetAsync(Guid id, CancellationToken ct) => Map(await FindAsync(id, ct));
    public async Task<JobDto> CreateAsync(CreateJobRequest request, CancellationToken ct)
    {
        _ = await repository.GetCompanyAsync(request.CompanyId, ct)
            ?? throw new NotFoundException("Company not found.");
        var input = request.Job;
        var job = new JobPost(request.CompanyId, input.Title, input.Description, input.Location,
            input.SalaryMin, input.SalaryMax, input.ExpiresAt);
        repository.AddJob(job);
        await repository.SaveChangesAsync(ct);
        return Map(job);
    }
    public async Task<JobDto> UpdateAsync(Guid id, SaveJobRequest input, CancellationToken ct)
    {
        var job = await FindAsync(id, ct);
        job.Update(input.Title, input.Description, input.Location, input.SalaryMin, input.SalaryMax, input.ExpiresAt);
        await repository.SaveChangesAsync(ct);
        return Map(job);
    }
    public async Task CloseAsync(Guid id, CancellationToken ct)
    {
        var job = await FindAsync(id, ct);
        job.Close();
        await repository.SaveChangesAsync(ct);
    }
    private async Task<JobPost> FindAsync(Guid id, CancellationToken ct)
        => await repository.GetJobAsync(id, ct) ?? throw new NotFoundException("Job not found.");
    private static JobDto Map(JobPost job) => new(job.Id, job.CompanyId, job.Title, job.Description,
        job.Location, job.SalaryMin, job.SalaryMax, job.CreatedAt, job.ExpiresAt, job.IsClosed);
}
