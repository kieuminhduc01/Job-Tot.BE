using System.Net.Http.Json;
using JobTot.Application;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using JobTot.Infrastructure.Persistence;
using JobTot.Application.Profiles;

namespace JobTot.Domain.Tests;

// Opt-in, read-only verification of the migrated development database; does not start an external API process.
public sealed class SqlJobDetailTests
{
    [SqlReadOnlyFact]
    public async Task CvStudioReadsSeededTemplatesAndDocumentsOnMigratedSqlServer()
    {
        await using var factory = new SqlFactory(); using var client = factory.CreateClient();
        var templates = (await client.GetFromJsonAsync<JobTot.Application.Cvs.CvTemplateDto[]>("/api/cv-templates"))!;
        Assert.True(templates.Count(t => t.Id.ToString().StartsWith("c8000000-0000-4000-8000-")) == 9);
        Assert.All(templates, t => Assert.NotEmpty(t.Document.Sections));
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var accountId = await db.CandidateProfileRecords.Select(c => c.AccountId).FirstAsync();
        _ = await scope.ServiceProvider.GetRequiredService<JobTot.Application.Cvs.ICvRepository>().ListAsync(accountId, default);
    }
    [SqlReadOnlyFact]
    public async Task LightweightAuthenticationQueriesRunOnSqlServer()
    {
        await using var factory = new SqlFactory();
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var id = await db.CandidateProfileRecords.Select(x => x.AccountId).FirstAsync();
        var repository = scope.ServiceProvider.GetRequiredService<JobTot.Application.Authentication.ICandidateAuthRepository>();
        var account = await repository.GetAsync(id, default);
        Assert.NotNull(account);
        Assert.Null(account.CandidateProfile!.DetailsJson);
        var principal = new System.Security.Claims.ClaimsPrincipal(new System.Security.Claims.ClaimsIdentity([
            new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.NameIdentifier, id.ToString()),
            new System.Security.Claims.Claim("sid", Guid.NewGuid().ToString())]));
        Assert.False(await scope.ServiceProvider.GetRequiredService<JobTot.Api.CandidateTokens>().ValidateAsync(principal, default));
    }
    [SqlReadOnlyFact]
    public async Task CandidateDashboardQueriesRunOnMigratedSqlServer()
    {
        await using var factory = new SqlFactory();
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var accountId = await db.CandidateProfileRecords.Where(x => x.Status == JobTot.Domain.Enums.EntityStatus.Active && x.Account.Status == JobTot.Domain.Enums.EntityStatus.Active)
            .Select(x => x.AccountId).FirstAsync();
        var repository = scope.ServiceProvider.GetRequiredService<ICandidateJobsRepository>();
        _ = await repository.SavedIdsAsync(accountId, default);
        foreach (var tab in new[] { "saved", "applied", "companies", "interviews" })
        {
            var data = await repository.DashboardAsync(accountId, new CandidateJobsQuery { Tab = tab }, default);
            Assert.Equal(tab, data.Tab);
            Assert.False(string.IsNullOrWhiteSpace(data.FullName));
            Assert.True(data.TotalCount >= 0);
        }
    }

    [SqlReadOnlyFact]
    public async Task DetailReadsMigratedCandidateFieldsFromSqlServer()
    {
        await using var factory = new SqlFactory();
        using var client = factory.CreateClient();
        var directory = (await client.GetFromJsonAsync<PageResult<JobDto>>("/api/jobs?keyword=Demo&pageSize=1"))!;
        var first = Assert.Single(directory.Items);
        var job = (await client.GetFromJsonAsync<JobDto>($"/api/jobs/{first.Id}"))!;
        Assert.False(string.IsNullOrWhiteSpace(job.CompanyName));
        Assert.False(string.IsNullOrWhiteSpace(job.Requirements));
        Assert.False(string.IsNullOrWhiteSpace(job.HiringProcess));
        Assert.Equal(2, job.Vacancies);
        Assert.NotNull(job.ProvinceId);
    }

    private sealed class SqlFactory : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Development");
            builder.UseSetting("ConnectionStrings:SqlServer", "Server=.\\SQLEXPRESS;Database=JobTot;Trusted_Connection=True;TrustServerCertificate=True;");
        }
    }
}
public sealed class SqlReadOnlyFactAttribute : FactAttribute
{
    public SqlReadOnlyFactAttribute()
    {
        if (Environment.GetEnvironmentVariable("JOBTOT_VERIFY_SQL") != "1") Skip = "Set JOBTOT_VERIFY_SQL=1 to verify the migrated development database.";
    }
}
