using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Text.Json;
using JobTot.Api;
using JobTot.Api.Controllers;
using JobTot.Application.Administration;
using JobTot.Application.Authentication;
using JobTot.Domain.Entities;
using JobTot.Domain.Enums;
using JobTot.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace JobTot.Domain.Tests;

public sealed class AdminManagementTests
{
    [Fact]
    public async Task AnonymousAndCandidateCannotReadOrMutateAdminResources()
    {
        await using var factory = new AdminFactory();
        await factory.Seed();
        using var client = factory.CreateClient();
        foreach (var path in new[] { "companies", "users", "industries", "auth/me" })
            Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync($"/api/admin/{path}")).StatusCode);
        var session = await CandidateLogin(client);
        client.DefaultRequestHeaders.Authorization = new("Bearer", session.AccessToken);
        foreach (var path in new[] { "companies", "users", "industries", "auth/me" })
            Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync($"/api/admin/{path}")).StatusCode);
        foreach (var path in new[] { $"companies/{factory.Company.Id}/status", $"users/{factory.Candidate.Id}/status", $"industries/{factory.Industry.Id}/status" })
            Assert.Equal(HttpStatusCode.Unauthorized, (await client.PutAsJsonAsync($"/api/admin/{path}", new { active = false })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PutAsJsonAsync($"/api/admin/users/{factory.Candidate.Id}/password", new { password = "new-password123" })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PutAsJsonAsync($"/api/admin/companies/{factory.Company.Id}/verification", new { verificationStatus = "Verified" })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/admin/industries", new { name = "Unauthorized" })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PutAsJsonAsync($"/api/admin/industries/{factory.Industry.Id}", new { name = "Unauthorized" })).StatusCode);
    }

    [Fact]
    public async Task CompanyVerificationAndStatusPersistAndHidePublicCompanyAndJobs()
    {
        await using var factory = new AdminFactory(); await factory.Seed();
        using var admin = await factory.AdminClient(); using var publicClient = factory.CreateClient();
        var list = (await admin.GetFromJsonAsync<AdminPage<AdminCompanyRow>>("/api/admin/companies?keyword=Acme&size=1"))!;
        Assert.Equal(1, list.Total); Assert.Single(list.Items);
        var path = $"/api/admin/companies/{factory.Company.Id}";
        Assert.Equal(HttpStatusCode.BadRequest, (await admin.PutAsJsonAsync(path + "/verification", new { verificationStatus = "Invalid" })).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await admin.PutAsJsonAsync(path + "/verification", new { verificationStatus = "Verified" })).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await admin.PutAsJsonAsync(path + "/status", new { active = false })).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await publicClient.GetAsync($"/api/companies/{factory.Company.Id}")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await publicClient.GetAsync($"/api/jobs/{factory.Job.Id}")).StatusCode);
        Assert.Equal(0, (await admin.GetFromJsonAsync<AdminPage<AdminCompanyRow>>("/api/admin/companies?status=Active"))!.Total);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var company = await db.Companies.FindAsync(factory.Company.Id);
            Assert.Equal("Verified", company!.VerificationStatus);
            Assert.Equal(factory.Admin.Id, company.UpdatedAccountId); Assert.NotNull(company.UpdatedDate);
        }
        Assert.Equal(HttpStatusCode.NoContent, (await admin.PutAsJsonAsync(path + "/status", new { active = true })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await publicClient.GetAsync($"/api/companies/{factory.Company.Id}")).StatusCode);
    }

    [Fact]
    public async Task VerificationRequiresLegalInformationAndUnknownIdsAreNotFound()
    {
        await using var factory = new AdminFactory(); await factory.Seed(); using var admin = await factory.AdminClient();
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            (await db.Companies.FindAsync(factory.Company.Id))!.TaxCode = null; await db.SaveChangesAsync();
        }
        Assert.Equal(HttpStatusCode.BadRequest, (await admin.PutAsJsonAsync($"/api/admin/companies/{factory.Company.Id}/verification", new { verificationStatus = "Verified" })).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await admin.PutAsJsonAsync($"/api/admin/users/{Guid.NewGuid()}/status", new { active = true })).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await admin.PutAsJsonAsync($"/api/admin/users/{factory.Candidate.Id}/status", new { })).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await admin.GetAsync("/api/admin/users?page=0")).StatusCode);
    }

    [Fact]
    public async Task PasswordChangeHashesPasswordAndRevokesAccessAndRefreshTokens()
    {
        await using var factory = new AdminFactory(); await factory.Seed();
        using var admin = await factory.AdminClient(); using var candidate = factory.CreateClient();
        var oldSession = await CandidateLogin(candidate);
        candidate.DefaultRequestHeaders.Authorization = new("Bearer", oldSession.AccessToken);
        var path = $"/api/admin/users/{factory.Candidate.Id}/password";
        Assert.Equal(HttpStatusCode.BadRequest, (await admin.PutAsJsonAsync(path, new { password = "short" })).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await admin.PutAsJsonAsync(path, new { password = "new-password123" })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await candidate.GetAsync("/api/candidate/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await candidate.PostAsJsonAsync("/api/candidate/auth/refresh", new { oldSession.RefreshToken })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await candidate.PostAsJsonAsync("/api/candidate/auth/login", new { emailOrPhone = factory.Candidate.Email, password = "candidate-password123" })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await candidate.PostAsJsonAsync("/api/candidate/auth/login", new { emailOrPhone = factory.Candidate.Email, password = "new-password123" })).StatusCode);
        using var scope = factory.Services.CreateScope();
        var account = await scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>().AccountRecords.FindAsync(factory.Candidate.Id);
        Assert.NotEqual("new-password123", account!.PasswordHash);
        Assert.True(scope.ServiceProvider.GetRequiredService<IAccountPasswordHasher>().Verify(account, "new-password123", out _));
        var response = await admin.GetAsync("/api/admin/users");
        var json = await response.Content.ReadAsStringAsync();
        Assert.DoesNotContain("passwordHash", json, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("new-password123", json);
    }

    [Fact]
    public async Task InactiveUserCannotLoginAndReactivationDoesNotReviveOldSessions()
    {
        await using var factory = new AdminFactory(); await factory.Seed();
        using var admin = await factory.AdminClient(); using var candidate = factory.CreateClient();
        var session = await CandidateLogin(candidate);
        candidate.DefaultRequestHeaders.Authorization = new("Bearer", session.AccessToken);
        var path = $"/api/admin/users/{factory.Candidate.Id}/status";
        Assert.Equal(HttpStatusCode.BadRequest, (await admin.PutAsJsonAsync($"/api/admin/users/{factory.Admin.Id}/status", new { active = false })).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await admin.PutAsJsonAsync(path, new { active = false })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await candidate.PostAsJsonAsync("/api/candidate/auth/login", new { emailOrPhone = factory.Candidate.Email, password = "candidate-password123" })).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await admin.PutAsJsonAsync(path, new { active = true })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await candidate.GetAsync("/api/candidate/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await candidate.PostAsJsonAsync("/api/candidate/auth/login", new { emailOrPhone = factory.Candidate.Email, password = "candidate-password123" })).StatusCode);
    }

    [Fact]
    public async Task IndustryManagementPreservesRelationshipsAndFiltersPublicCatalog()
    {
        await using var factory = new AdminFactory(); await factory.Seed();
        using var admin = await factory.AdminClient(); using var publicClient = factory.CreateClient();
        Assert.Equal(HttpStatusCode.Created, (await admin.PostAsJsonAsync("/api/admin/industries", new { name = " Finance " })).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await admin.PostAsJsonAsync("/api/admin/industries", new { name = "finance" })).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await admin.PostAsJsonAsync("/api/admin/industries", new { name = "   " })).StatusCode);
        var path = $"/api/admin/industries/{factory.Industry.Id}";
        Assert.Equal(HttpStatusCode.NoContent, (await admin.PutAsJsonAsync(path, new { name = "Software" })).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await admin.PutAsJsonAsync(path + "/status", new { active = false })).StatusCode);
        var overview = await publicClient.GetFromJsonAsync<JsonElement[]>("/api/industries/overview");
        Assert.DoesNotContain(overview!, row => row.GetProperty("id").GetGuid() == factory.Industry.Id);
        using var scope = factory.Services.CreateScope(); var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        Assert.Equal(factory.Industry.Id, (await db.Companies.FindAsync(factory.Company.Id))!.IndustryId);
        Assert.Equal("Software", (await db.IndustryRecords.FindAsync(factory.Industry.Id))!.IndustryName);
    }

    [Fact]
    public async Task EmployerCannotUseAdminApisAndCompanyDeactivationBlocksEmployerAccess()
    {
        await using var factory = new AdminFactory(); await factory.Seed();
        using var admin = await factory.AdminClient(); using var employer = factory.CreateClient();
        var login = await employer.PostAsJsonAsync("/api/employer/auth/login", new { email = factory.Employer.Email, password = "employer-password123" });
        login.EnsureSuccessStatusCode();
        var session = (await login.Content.ReadFromJsonAsync<EmployerSessionDto>())!;
        employer.DefaultRequestHeaders.Authorization = new("Bearer", session.AccessToken);
        Assert.Equal(HttpStatusCode.Unauthorized, (await employer.GetAsync("/api/admin/users")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await employer.GetAsync("/api/employer/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await admin.PutAsJsonAsync($"/api/admin/companies/{factory.Company.Id}/status", new { active = false })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await employer.GetAsync("/api/employer/auth/me")).StatusCode);
    }

    [Fact]
    public async Task EmployerPasswordChangeInvalidatesAccessAndRefreshAndRequiresNewPassword()
    {
        await using var factory = new AdminFactory(); await factory.Seed();
        using var admin = await factory.AdminClient(); using var employer = factory.CreateClient();
        var login = await employer.PostAsJsonAsync("/api/employer/auth/login", new { email = factory.Employer.Email, password = "employer-password123" });
        login.EnsureSuccessStatusCode(); var session = (await login.Content.ReadFromJsonAsync<EmployerSessionDto>())!;
        employer.DefaultRequestHeaders.Authorization = new("Bearer", session.AccessToken);
        Assert.Equal(HttpStatusCode.NoContent, (await admin.PutAsJsonAsync($"/api/admin/users/{factory.Employer.Id}/password", new { password = "new-employer-password" })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await employer.GetAsync("/api/employer/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await employer.PostAsJsonAsync("/api/employer/auth/refresh", new { session.RefreshToken })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await employer.PostAsJsonAsync("/api/employer/auth/login", new { email = factory.Employer.Email, password = "new-employer-password" })).StatusCode);
    }

    [Fact]
    public async Task AdminQueryCancellationStillReachesRequestCancellationMiddleware()
    {
        await using var factory = new AdminFactory(); await factory.Seed();
        using var scope = factory.Services.CreateScope(); using var cancellation = new CancellationTokenSource();
        var context = new DefaultHttpContext { RequestAborted = cancellation.Token };
        context.User = new ClaimsPrincipal(new ClaimsIdentity([new Claim(ClaimTypes.NameIdentifier, factory.Admin.Id.ToString())], "test"));
        await using var body = new MemoryStream(); context.Response.Body = body;
        var controller = new AdminManagementController(scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>(), scope.ServiceProvider.GetRequiredService<IAccountPasswordHasher>())
            { ControllerContext = new ControllerContext { HttpContext = context } };
        await new RequestCancellationMiddleware(async ctx => { cancellation.Cancel(); await controller.Companies(new AdminListQuery(), ctx.RequestAborted); }).InvokeAsync(context);
        Assert.Equal(499, context.Response.StatusCode); Assert.Equal(0, body.Length);
    }

    private static async Task<CandidateSessionDto> CandidateLogin(HttpClient client)
    {
        var response = await client.PostAsJsonAsync("/api/candidate/auth/login", new { emailOrPhone = "candidate@admin.test", password = "candidate-password123" });
        response.EnsureSuccessStatusCode(); return (await response.Content.ReadFromJsonAsync<CandidateSessionDto>())!;
    }

    private sealed class AdminFactory : WebApplicationFactory<Program>
    {
        private readonly string database = Guid.NewGuid().ToString();
        public Account Admin { get; } = new() { Email = "admin@admin.test", FullName = "Administrator", AccountType = "Admin", AccountStatus = "Active" };
        public Account Candidate { get; } = new() { Email = "candidate@admin.test", FullName = "Candidate", AccountType = "Candidate", AccountStatus = "Active" };
        public Account Employer { get; } = new() { Email = "employer@admin.test", FullName = "Employer", AccountType = "Employer", AccountStatus = "Active" };
        public Industry Industry { get; } = new() { IndustryName = "Technology" };
        public Company Company { get; } = new("Acme", "Company description") { LegalName = "Acme Ltd", TaxCode = "0101234567", Email = "hr@acme.test", AddressLine = "Hanoi", VerificationStatus = "Pending" };
        public JobPost Job { get; private set; } = null!;
        public async Task Seed()
        {
            using var scope = Services.CreateScope(); var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var hasher = scope.ServiceProvider.GetRequiredService<IAccountPasswordHasher>();
            Admin.PasswordHash = hasher.Hash(Admin, "admin-password123"); Candidate.PasswordHash = hasher.Hash(Candidate, "candidate-password123");
            Employer.PasswordHash = hasher.Hash(Employer, "employer-password123");
            Candidate.CandidateProfile = new CandidateProfile { AccountId = Candidate.Id, Account = Candidate };
            Company.IndustryId = Industry.Id; Company.Industry = Industry;
            Employer.RecruiterProfiles.Add(new RecruiterProfile { AccountId = Employer.Id, Account = Employer, CompanyId = Company.Id, Company = Company, JoinedAt = DateTimeOffset.UtcNow, IsCompanyAdmin = true });
            Job = new JobPost(Company.Id, "Engineer", "Job description", "Hanoi", null, null, DateTimeOffset.UtcNow.AddDays(30));
            db.AddRange(Admin, Candidate, Employer, Industry, Company, Job); await db.SaveChangesAsync();
        }
        public async Task<HttpClient> AdminClient()
        {
            var client = CreateClient();
            var response = await client.PostAsJsonAsync("/api/admin/auth/login", new { emailOrPhone = Admin.Email, password = "admin-password123" });
            response.EnsureSuccessStatusCode(); var data = await response.Content.ReadFromJsonAsync<JsonElement>();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", data.GetProperty("accessToken").GetString()); return client;
        }
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Development"); builder.ConfigureServices(services =>
            {
                services.RemoveAll<RecruitmentDbContext>(); services.RemoveAll<DbContextOptions<RecruitmentDbContext>>(); services.RemoveAll<IDbContextOptionsConfiguration<RecruitmentDbContext>>();
                services.AddDbContext<RecruitmentDbContext>(options => options.UseInMemoryDatabase(database));
            });
        }
    }
}
