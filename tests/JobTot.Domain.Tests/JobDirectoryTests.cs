using System.Net;
using System.Net.Http.Json;
using JobTot.Application;
using JobTot.Domain.Entities;
using JobTot.Domain.Enums;
using JobTot.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace JobTot.Domain.Tests;

public sealed class JobDirectoryTests
{
    [Fact]
    public async Task DirectoryEnrichesJobsAndCombinesServerFiltersBeforePagination()
    {
        await using var factory = new JobFactory();
        using var client = factory.CreateClient();
        await factory.Seed();
        var all = (await client.GetFromJsonAsync<PageResult<JobDto>>("/api/jobs?pageSize=1"))!;
        Assert.Equal(3, all.TotalCount);
        Assert.Single(all.Items);
        var query = $"/api/jobs?verifiedOnly=true&industryId={factory.Tech.Id}&keyword=Cloud&provinceId={factory.Hanoi.Id}&salaryBand=15-20&experienceLevels=1-3&positionLevels=employee&employmentTypes=full-time";
        var filtered = (await client.GetFromJsonAsync<PageResult<JobDto>>(query))!;
        var job = Assert.Single(filtered.Items);
        Assert.Equal(factory.Engineer.Id, job.Id);
        Assert.Equal(factory.Hanoi.Id, job.ProvinceId);
        Assert.Equal("Cloud Acme", job.CompanyName);
        Assert.True(job.IsVerified);
        Assert.Equal("Technology", job.Industry);
        Assert.Equal("1-3", job.ExperienceLevel);
        Assert.Equal("employee", job.PositionLevel);
        Assert.Equal("full-time", job.EmploymentType);
        Assert.Equal("monthly", job.SalaryPeriod);
        Assert.Equal("Training|Insurance", job.Benefits);
        Assert.Equal("09:00 – 18:00", job.WorkSchedule);
        var multiple = (await client.GetFromJsonAsync<PageResult<JobDto>>("/api/jobs?experienceLevels=none&experienceLevels=1-3"))!;
        Assert.Equal(2, multiple.TotalCount);
        var saved = (await client.GetFromJsonAsync<PageResult<JobDto>>($"/api/jobs?jobIds={factory.Engineer.Id}"))!;
        Assert.Equal(factory.Engineer.Id, Assert.Single(saved.Items).Id);
        var second = (await client.GetFromJsonAsync<PageResult<JobDto>>("/api/jobs?pageSize=1&page=2"))!;
        Assert.NotEqual(all.Items[0].Id, Assert.Single(second.Items).Id);
        Assert.Equal(3, second.TotalCount);
        Assert.Empty((await client.GetFromJsonAsync<PageResult<JobDto>>("/api/jobs?keyword=no-match"))!.Items);
        var detail = (await client.GetFromJsonAsync<JobDto>($"/api/jobs/{factory.Engineer.Id}"))!;
        Assert.Equal(job.CompanyName, detail.CompanyName);
        Assert.Equal(job.Benefits, detail.Benefits);
    }

    [Fact]
    public async Task ProvinceFilterUsesJobProvinceInsteadOfCompanyOfficeOrAddressText()
    {
        await using var factory = new JobFactory();
        using var client = factory.CreateClient();
        await factory.Seed();
        var hanoi = (await client.GetFromJsonAsync<PageResult<JobDto>>($"/api/jobs?provinceId={factory.Hanoi.Id}"))!;
        Assert.Equal(factory.Engineer.Id, Assert.Single(hanoi.Items).Id);
        var hcm = (await client.GetFromJsonAsync<PageResult<JobDto>>($"/api/jobs?provinceId={factory.Hcm.Id}"))!;
        Assert.Equal(2, hcm.TotalCount);
        Assert.DoesNotContain(hcm.Items, x => x.Id == factory.Engineer.Id);
        var legacy = (await client.GetFromJsonAsync<PageResult<JobDto>>("/api/jobs?location=Th%C3%A0nh%20ph%E1%BB%91%20H%C3%A0%20N%E1%BB%99i"))!;
        Assert.Equal(factory.Engineer.Id, Assert.Single(legacy.Items).Id);
        Assert.Empty((await client.GetFromJsonAsync<PageResult<JobDto>>($"/api/jobs?provinceId={Guid.NewGuid()}"))!.Items);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            (await db.ProvinceRecords.FindAsync(factory.Hanoi.Id))!.Status = EntityStatus.Deleted;
            await db.SaveChangesAsync();
        }
        Assert.Empty((await client.GetFromJsonAsync<PageResult<JobDto>>($"/api/jobs?provinceId={factory.Hanoi.Id}"))!.Items);
    }

    [Fact]
    public async Task FacetsExcludeInactiveExpiredAndClosedJobsAndSeparateHourlySalary()
    {
        await using var factory = new JobFactory();
        using var client = factory.CreateClient();
        await factory.Seed();
        var metadata = (await client.GetFromJsonAsync<JobDirectoryMetadata>("/api/jobs/filters"))!;
        Assert.Equal(3, metadata.TotalJobs);
        Assert.Equal(2, metadata.TotalCompanies);
        Assert.Equal(0, metadata.SalaryBands.Single(x => x.Value == "under-10").Count);
        Assert.Equal(1, metadata.SalaryBands.Single(x => x.Value == "15-20").Count);
        Assert.Equal(1, metadata.SalaryBands.Single(x => x.Value == "negotiable").Count);
        Assert.Equal(1, metadata.ExperienceLevels.Single(x => x.Value == "none").Count);
        Assert.Equal(1, metadata.EmploymentTypes.Single(x => x.Value == "part-time").Count);
        var hourly = (await client.GetFromJsonAsync<PageResult<JobDto>>("/api/jobs?employmentTypes=part-time"))!;
        Assert.Equal("hourly", Assert.Single(hourly.Items).SalaryPeriod);
        Assert.Empty((await client.GetFromJsonAsync<PageResult<JobDto>>("/api/jobs?salaryBand=under-10"))!.Items);
    }

    [Theory]
    [InlineData("page=0")]
    [InlineData("pageSize=101")]
    [InlineData("salaryBand=unknown")]
    [InlineData("experienceLevels=unknown")]
    [InlineData("positionLevels=unknown")]
    [InlineData("employmentTypes=unknown")]
    [InlineData("industryId=invalid")]
    [InlineData("provinceId=invalid")]
    [InlineData("jobIds=invalid")]
    public async Task InvalidDirectoryFiltersReturn400(string query)
    {
        await using var factory = new JobFactory();
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.BadRequest, (await client.GetAsync($"/api/jobs?{query}")).StatusCode);
    }

    [Fact]
    public async Task JobWriteEndpointsPersistDirectoryFieldsAndRejectInvalidValues()
    {
        await using var factory = new JobFactory();
        using var client = factory.CreateClient();
        await factory.Seed();
        var input = new SaveJobRequest("Service staff", "Serve customers", "Ha Noi", 25000, 32000, DateTimeOffset.UtcNow.AddDays(30))
        { ProvinceId = factory.Hanoi.Id, ExperienceLevel = "none", PositionLevel = "employee", EmploymentType = "part-time", SalaryPeriod = "hourly", SalaryNote = "Tips", WorkSchedule = "4 – 6 hours", Benefits = "Weekly pay|Flexible shifts",
          Requirements = "Customer service skills\nTeamwork", HiringProcess = "CV review|Review within 2 days\nInterview|Meet the team", Vacancies = 2, RecruiterName = "Recruiter", RecruiterEmail = "recruiter@example.com" };
        var response = await client.PostAsJsonAsync("/api/jobs", new CreateJobRequest(factory.Acme.Id, input));
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var job = (await response.Content.ReadFromJsonAsync<JobDto>())!;
        var persisted = (await client.GetFromJsonAsync<JobDto>($"/api/jobs/{job.Id}"))!;
        Assert.Equal("hourly", persisted.SalaryPeriod);
        Assert.Equal(factory.Hanoi.Id, persisted.ProvinceId);
        Assert.Equal("Weekly pay|Flexible shifts", persisted.Benefits);
        Assert.Equal(input.Requirements, persisted.Requirements);
        Assert.Equal(input.HiringProcess, persisted.HiringProcess);
        Assert.Equal(2, persisted.Vacancies);
        Assert.Equal(input.RecruiterEmail, persisted.RecruiterEmail);
        var update = await client.PutAsJsonAsync($"/api/jobs/{job.Id}", input with { EmploymentType = "full-time", SalaryPeriod = "monthly", SalaryMin = 15000000, SalaryMax = 20000000 });
        Assert.Equal(HttpStatusCode.OK, update.StatusCode);
        Assert.Equal("full-time", (await client.GetFromJsonAsync<JobDto>($"/api/jobs/{job.Id}"))!.EmploymentType);
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/jobs", new CreateJobRequest(factory.Acme.Id, input with { EmploymentType = "invalid" }))).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/jobs", new CreateJobRequest(factory.Acme.Id, input with { ProvinceId = Guid.NewGuid() }))).StatusCode);
    }

    [Fact]
    public async Task ApplicationPersistsOwnedCvAndRejectsDuplicateForeignCvAndClosedJobs()
    {
        await using var factory = new JobFactory();
        using var owner = factory.CreateClient();
        using var other = factory.CreateClient();
        await factory.Seed();
        var endpoint = $"/api/candidate/jobs/{factory.Engineer.Id}/application";
        Assert.Equal(HttpStatusCode.Unauthorized, (await owner.GetAsync(endpoint)).StatusCode);
        var register = await owner.PostAsJsonAsync("/api/candidate/auth/register", new { fullName = "Candidate", emailOrPhone = "applicant@example.com", password = "matkhau123", confirmPassword = "matkhau123" });
        var session = (await register.Content.ReadFromJsonAsync<JobTot.Application.Authentication.CandidateSessionDto>())!;
        owner.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", session.AccessToken);
        var another = await other.PostAsJsonAsync("/api/candidate/auth/register", new { fullName = "Other", emailOrPhone = "another@example.com", password = "matkhau123", confirmPassword = "matkhau123" });
        var second = (await another.Content.ReadFromJsonAsync<JobTot.Application.Authentication.CandidateSessionDto>())!;
        other.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", second.AccessToken);
        using var pdf = new MultipartFormDataContent();
        pdf.Add(new ByteArrayContent(System.Text.Encoding.ASCII.GetBytes("%PDF-1.7 demo CV")), "file", "my-cv.pdf");
        var uploaded = await owner.PostAsync("/api/candidate/profile/cvs", pdf);
        var cv = (await uploaded.Content.ReadFromJsonAsync<JobTot.Application.Profiles.ProfileCv>())!;
        var input = new SubmitJobApplicationRequest(cv.Id, "Candidate", "0912345678", "I build cloud systems.");
        Assert.Equal(HttpStatusCode.BadRequest, (await other.PostAsJsonAsync(endpoint, input)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await owner.PostAsJsonAsync(endpoint, input with { FullName = " " })).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await owner.PostAsJsonAsync(endpoint, input with { Phone = "invalid" })).StatusCode);
        var applied = await owner.PostAsJsonAsync(endpoint, input);
        Assert.Equal(HttpStatusCode.Created, applied.StatusCode);
        var result = (await applied.Content.ReadFromJsonAsync<JobSubmissionDto>())!;
        Assert.Equal(cv.Id, result.CvId);
        Assert.Equal("submitted", result.Status);
        Assert.DoesNotContain("cvContentJson", await applied.Content.ReadAsStringAsync());
        Assert.Equal(result.Id, (await owner.GetFromJsonAsync<JobSubmissionDto>(endpoint))!.Id);
        var otherStatus = await (await other.GetAsync(endpoint)).Content.ReadAsStringAsync();
        Assert.True(string.IsNullOrEmpty(otherStatus) || otherStatus == "null");
        Assert.Equal(HttpStatusCode.Conflict, (await owner.PostAsJsonAsync(endpoint, input)).StatusCode);
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var stored = await db.CandidateJobSubmissions.SingleAsync();
        Assert.Equal(input.CoverLetter, stored.CoverLetter);
        Assert.False(string.IsNullOrEmpty(stored.CvContentJson));
        var closed = await db.Jobs.FirstAsync(x => x.IsClosed);
        Assert.Equal(HttpStatusCode.Conflict, (await owner.PostAsJsonAsync($"/api/candidate/jobs/{closed.Id}/application", input)).StatusCode);
        var expired = await db.Jobs.FirstAsync(x => x.ExpiresAt < DateTimeOffset.UtcNow);
        Assert.Equal(HttpStatusCode.Conflict, (await owner.PostAsJsonAsync($"/api/candidate/jobs/{expired.Id}/application", input)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await owner.PostAsJsonAsync($"/api/candidate/jobs/{Guid.NewGuid()}/application", input)).StatusCode);
        var hidden = await db.Jobs.FirstAsync(x => x.Company.Status == EntityStatus.Deleted);
        Assert.Equal(HttpStatusCode.NotFound, (await owner.GetAsync($"/api/jobs/{hidden.Id}")).StatusCode);
    }

    private sealed class JobFactory : WebApplicationFactory<Program>
    {
        private readonly string database = Guid.NewGuid().ToString();
        public Industry Tech { get; } = new() { IndustryName = "Technology" };
        public Province Hanoi { get; } = new() { ProvinceName = "Thành phố Hà Nội", ProvinceCode = "01" };
        public Province Hcm { get; } = new() { ProvinceName = "Thành phố Hồ Chí Minh", ProvinceCode = "79" };
        public Company Acme { get; } = new("Cloud Acme", "Technology company") { VerificationStatus = "Verified" };
        public JobPost Engineer { get; private set; } = null!;
        public async Task Seed()
        {
            using var scope = Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            Acme.IndustryId = Tech.Id;
            Acme.HeadOfficeProvinceId = Hcm.Id;
            var beta = new Company("Beta Hospitality", "Service company");
            var hidden = new Company("Hidden", "Deleted company") { Status = EntityStatus.Deleted };
            db.AddRange(Tech, Hanoi, Hcm, Acme, beta, hidden);
            Engineer = new(Acme.Id, "Cloud Engineer", "Build infrastructure", "Ha Noi", 15000000, 20000000, DateTimeOffset.UtcNow.AddDays(30));
            Engineer.SetDirectoryDetails("1-3", "employee", "full-time", "monthly", "09:00 – 18:00", null, "Training|Insurance");
            Engineer.SetProvince(Hanoi.Id);
            var hourly = new JobPost(beta.Id, "Service staff", "Serve customers", "Ho Chi Minh", 25000, 32000, DateTimeOffset.UtcNow.AddDays(30));
            hourly.SetDirectoryDetails("none", "employee", "part-time", "hourly");
            hourly.SetProvince(Hcm.Id);
            var negotiable = new JobPost(beta.Id, "Manager", "Manage team", "Ho Chi Minh", null, null, DateTimeOffset.UtcNow.AddDays(30));
            negotiable.SetDirectoryDetails("over-5", "manager", "full-time");
            negotiable.SetProvince(Hcm.Id);
            var closed = new JobPost(Acme.Id, "Closed", "Description", "Ha Noi", null, null, DateTimeOffset.UtcNow.AddDays(30)); closed.Close();
            var expired = new JobPost(Acme.Id, "Expired", "Description", "Ha Noi", null, null, DateTimeOffset.UtcNow.AddDays(30));
            db.Jobs.AddRange(Engineer, hourly, negotiable, closed, expired, new JobPost(hidden.Id, "Hidden role", "Description", "Ha Noi", null, null, DateTimeOffset.UtcNow.AddDays(30)));
            db.Entry(expired).Property(x => x.ExpiresAt).CurrentValue = DateTimeOffset.UtcNow.AddDays(-1);
            await db.SaveChangesAsync();
        }
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Development");
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<RecruitmentDbContext>();
                services.RemoveAll<DbContextOptions<RecruitmentDbContext>>();
                services.RemoveAll<IDbContextOptionsConfiguration<RecruitmentDbContext>>();
                services.AddDbContext<RecruitmentDbContext>(options => options.UseInMemoryDatabase(database));
            });
        }
    }
}
