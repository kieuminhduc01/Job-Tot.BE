using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using JobTot.Application.Authentication;
using JobTot.Domain.Entities;
using JobTot.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace JobTot.Domain.Tests;

public sealed class EmployerAuthTests
{
    private static EmployerRegisterRequest Registration(Guid province, string email = "hr@example.com", string tax = "0109867899") => new()
    {
        FullName = "Nguyễn Văn An", Email = email, WorkPhone = "0988 123 456",
        CompanyName = "Công ty Tốt Tech", TaxCode = tax, HeadOfficeProvinceId = province,
        Password = "matkhau123", ConfirmPassword = "matkhau123", AcceptTerms = true, RecruitmentCommitment = true
    };
    [Fact]
    public async Task RegistrationCreatesPendingCompanyAndSeparateSecureSession()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        var province = await factory.SeedProvince();
        var response = await client.PostAsJsonAsync("/api/employer/auth/register", Registration(province, "HR@Example.com"));
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var session = (await response.Content.ReadFromJsonAsync<EmployerSessionDto>())!;
        Assert.Equal("Employer", session.Account.AccountType);
        Assert.Equal("hr@example.com", session.Account.Email);
        Assert.Equal("+84988123456", session.Account.Phone);
        Assert.Equal("Pending", session.Account.VerificationStatus);
        Assert.InRange(session.RefreshExpiresAt - DateTimeOffset.UtcNow, TimeSpan.FromHours(7.9), TimeSpan.FromHours(8.1));
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var account = await db.AccountRecords.SingleAsync();
            Assert.NotEqual("matkhau123", account.PasswordHash);
            Assert.Empty(db.CandidateProfileRecords);
            Assert.False((await db.RecruiterProfileRecords.SingleAsync()).IsCompanyAdmin);
        }
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", session.AccessToken);
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/employer/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/candidate/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/candidate/auth/refresh", new { session.RefreshToken })).StatusCode);
        await client.PostAsJsonAsync("/api/candidate/auth/logout", new { session.RefreshToken });
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/employer/auth/me")).StatusCode);
        var refreshed = (await (await client.PostAsJsonAsync("/api/employer/auth/refresh", new { session.RefreshToken })).Content.ReadFromJsonAsync<EmployerSessionDto>())!;
        Assert.NotEqual(session.RefreshToken, refreshed.RefreshToken);
        await client.PostAsJsonAsync("/api/employer/auth/logout", new { refreshed.RefreshToken });
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/employer/auth/me")).StatusCode);
    }
    [Fact]
    public async Task ExistingCompanyCannotBeClaimedAndInvalidProvinceIsRejected()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        var province = await factory.SeedProvince();
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            db.Companies.Add(new Company("Existing company", "") { TaxCode = "0109867899" });
            await db.SaveChangesAsync();
        }
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync("/api/employer/auth/register", Registration(province))).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/employer/auth/register", Registration(Guid.NewGuid(), tax: "0109867800"))).StatusCode);
        using var check = factory.Services.CreateScope();
        var database = check.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        Assert.Empty(database.AccountRecords);
        Assert.Empty(database.RecruiterProfileRecords);
        Assert.Single(database.Companies);
    }
    [Fact]
    public async Task LoginRememberMeAndCandidateIsolation()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        var province = await factory.SeedProvince();
        await client.PostAsJsonAsync("/api/employer/auth/register", Registration(province));
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/candidate/auth/login", new { emailOrPhone = "hr@example.com", password = "matkhau123" })).StatusCode);
        var rejected = await client.PostAsJsonAsync("/api/employer/auth/login", new { email = "hr@example.com", password = "wrong" });
        Assert.Equal(HttpStatusCode.Unauthorized, rejected.StatusCode);
        var problem = (await rejected.Content.ReadFromJsonAsync<Microsoft.AspNetCore.Mvc.ProblemDetails>())!;
        Assert.Equal(401, problem.Status);
        Assert.Contains("Email", problem.Detail);
        using (var scope = factory.Services.CreateScope())
        {
            var service = scope.ServiceProvider.GetRequiredService<EmployerAuthService>();
            Assert.Null(await service.LoginAsync(new EmployerLoginRequest { Email = "hr@example.com", Password = "wrong" }, CancellationToken.None));
            Assert.Null(await service.LoginAsync(new EmployerLoginRequest { Email = "missing@example.com", Password = "wrong" }, CancellationToken.None));
        }
        var login = await client.PostAsJsonAsync("/api/employer/auth/login", new { email = "HR@example.com", password = "matkhau123", rememberMe = true });
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);
        var session = (await login.Content.ReadFromJsonAsync<EmployerSessionDto>())!;
        Assert.InRange(session.RefreshExpiresAt - DateTimeOffset.UtcNow, TimeSpan.FromDays(29.9), TimeSpan.FromDays(30.1));
        var duplicate = await client.PostAsJsonAsync("/api/employer/auth/register", Registration(province));
        Assert.Equal(HttpStatusCode.Conflict, duplicate.StatusCode);
        var duplicateProblem = (await duplicate.Content.ReadFromJsonAsync<Microsoft.AspNetCore.Mvc.ProblemDetails>())!;
        Assert.Contains("Email", duplicateProblem.Detail);
        using (var scope = factory.Services.CreateScope())
        {
            var result = await scope.ServiceProvider.GetRequiredService<EmployerAuthService>()
                .RegisterAsync(Registration(province), CancellationToken.None);
            Assert.Equal(EmployerRegistrationStatus.DuplicateAccount, result.Status);
            Assert.Null(result.Account);
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            Assert.Single(await db.AccountRecords.ToListAsync());
        }
        await client.PostAsJsonAsync("/api/employer/auth/refresh", new { session.RefreshToken });
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/employer/auth/refresh", new { session.RefreshToken })).StatusCode);
        client.DefaultRequestHeaders.Authorization = new("Bearer", session.AccessToken);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/employer/auth/me")).StatusCode);
    }
    [Fact]
    public async Task ConsentRequiredAndCancellationPropagates()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/employer/auth/register", new
        { fullName = "Nguyễn Văn An", email = "hr@example.com", workPhone = "0988123456", companyName = "Tốt Tech", taxCode = "0109867899", headOfficeProvinceId = Guid.NewGuid(), password = "matkhau123", confirmPassword = "matkhau123", acceptTerms = false, recruitmentCommitment = true })).StatusCode);
        using var scope = factory.Services.CreateScope();
        using var cancellation = new CancellationTokenSource(); cancellation.Cancel();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => scope.ServiceProvider.GetRequiredService<IEmployerAuthRepository>().GetAsync(Guid.NewGuid(), cancellation.Token));
    }
    private sealed class AuthFactory : WebApplicationFactory<Program>
    {
        private readonly string databaseName = Guid.NewGuid().ToString();
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Development");
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<RecruitmentDbContext>();
                services.RemoveAll<DbContextOptions<RecruitmentDbContext>>();
                services.RemoveAll<IDbContextOptionsConfiguration<RecruitmentDbContext>>();
                services.AddDbContext<RecruitmentDbContext>(options => options.UseInMemoryDatabase(databaseName));
            });
        }
        public async Task<Guid> SeedProvince()
        {
            using var scope = Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var province = new Province { ProvinceName = "Hà Nội", ProvinceCode = "01" };
            db.ProvinceRecords.Add(province); await db.SaveChangesAsync(); return province.Id;
        }
    }
}
