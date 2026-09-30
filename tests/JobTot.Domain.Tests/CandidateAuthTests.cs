using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using JobTot.Api.Controllers;
using JobTot.Application.Authentication;
using JobTot.Domain.Entities;
using JobTot.Domain.Enums;
using JobTot.Infrastructure;
using JobTot.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace JobTot.Domain.Tests;

public sealed class CandidateAuthTests
{
    [Theory]
    [InlineData(" Test@Example.com ", "test@example.com", null)]
    [InlineData("0912 345 678", null, "+84912345678")]
    [InlineData("+84 912 345 678", null, "+84912345678")]
    [InlineData("84912345678", null, "+84912345678")]
    public void IdentifiersAreNormalized(string input, string? email, string? phone)
        => Assert.Equal(new CandidateIdentifier(email, phone), CandidateIdentifier.Parse(input));

    [Theory]
    [InlineData("invalid")]
    [InlineData("1234567890")]
    [InlineData("test@@example.com")]
    public void InvalidIdentifiersAreRejected(string input)
        => Assert.Throws<ArgumentException>(() => CandidateIdentifier.Parse(input));

    [Fact]
    public void PasswordsAreSaltedAndVerified()
    {
        var hasher = new AccountPasswordHasher();
        var account = new Account();
        account.PasswordHash = hasher.Hash(account, "matkhau123");
        Assert.NotEqual("matkhau123", account.PasswordHash);
        Assert.NotEqual(account.PasswordHash, hasher.Hash(account, "matkhau123"));
        Assert.True(hasher.Verify(account, "matkhau123", out _));
        Assert.False(hasher.Verify(account, "wrong-password", out _));
        Assert.False(hasher.Verify(new Account(), "matkhau123", out _));
    }

    [Fact]
    public async Task EmailRegistrationCreatesProfileAndSessionAndLogoutClearsIt()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/candidate/auth/me")).StatusCode);
        await SetCsrf(client);
        var response = await client.PostAsJsonAsync("/api/candidate/auth/register", Register(" Test@Example.com "));
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var session = (await response.Content.ReadFromJsonAsync<CandidateSessionDto>())!;
        Assert.Equal("test@example.com", session.Account.Email);
        Assert.Equal("Nguyễn Văn A", session.Account.FullName);
        Assert.Equal("Candidate", session.Account.AccountType);
        Assert.NotEqual(Guid.Empty, session.Account.CandidateProfileId);
        var cookie = Assert.Single(response.Headers.GetValues("Set-Cookie"), x => x.StartsWith("JobTot.Candidate="));
        Assert.Contains("httponly", cookie, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("expires=", cookie, StringComparison.OrdinalIgnoreCase);
        Assert.InRange(session.ExpiresAt - DateTimeOffset.UtcNow, TimeSpan.FromHours(7.9), TimeSpan.FromHours(8.1));
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/candidate/auth/me")).StatusCode);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            Assert.Single(await db.CandidateProfileRecords.ToListAsync());
            Assert.NotEqual("matkhau123", (await db.AccountRecords.SingleAsync()).PasswordHash);
        }
        await SetCsrf(client);
        Assert.Equal(HttpStatusCode.NoContent, (await client.PostAsync("/api/candidate/auth/logout", null)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/candidate/auth/me")).StatusCode);
    }

    [Fact]
    public async Task PhoneRegistrationNormalizesDuplicatesAndRememberMePersistsCookie()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        await SetCsrf(client);
        var register = await client.PostAsJsonAsync("/api/candidate/auth/register", Register("0912345678"));
        Assert.Equal(HttpStatusCode.Created, register.StatusCode);
        var account = (await register.Content.ReadFromJsonAsync<CandidateSessionDto>())!.Account;
        Assert.Null(account.Email);
        Assert.Equal("+84912345678", account.Phone);
        await SetCsrf(client);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync("/api/candidate/auth/register",
            Register("+84 912 345 678"))).StatusCode);
        await client.PostAsync("/api/candidate/auth/logout", null);
        await SetCsrf(client);
        var login = await client.PostAsJsonAsync("/api/candidate/auth/login", new
        {
            emailOrPhone = "+84912345678", password = "matkhau123", rememberMe = true
        });
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);
        var cookie = Assert.Single(login.Headers.GetValues("Set-Cookie"), x => x.StartsWith("JobTot.Candidate="));
        Assert.Contains("expires=", cookie, StringComparison.OrdinalIgnoreCase);
        var session = (await login.Content.ReadFromJsonAsync<CandidateSessionDto>())!;
        Assert.InRange(session.ExpiresAt - DateTimeOffset.UtcNow, TimeSpan.FromDays(29.9), TimeSpan.FromDays(30.1));
    }

    [Fact]
    public async Task InvalidRegistrationAndMissingCsrfDoNotCreateAccounts()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/candidate/auth/register",
            Register("test@example.com"))).StatusCode);
        await SetCsrf(client);
        foreach (var request in new[]
        {
            new { fullName = "Test", emailOrPhone = "test@example.com", password = "short", confirmPassword = "short" },
            new { fullName = "Test", emailOrPhone = "test@example.com", password = "matkhau123", confirmPassword = "different" },
            new { fullName = "   ", emailOrPhone = "test@example.com", password = "matkhau123", confirmPassword = "matkhau123" },
            new { fullName = "Test", emailOrPhone = "invalid", password = "matkhau123", confirmPassword = "matkhau123" }
        })
            Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/candidate/auth/register", request)).StatusCode);
        using var scope = factory.Services.CreateScope();
        Assert.Empty(await scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>().AccountRecords.ToListAsync());
    }

    [Fact]
    public async Task DuplicateEmailAndWrongPasswordAreRejected()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        await SetCsrf(client);
        Assert.Equal(HttpStatusCode.Created, (await client.PostAsJsonAsync("/api/candidate/auth/register", Register("test@example.com"))).StatusCode);
        await SetCsrf(client);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync("/api/candidate/auth/register", Register("TEST@example.com"))).StatusCode);
        await client.PostAsync("/api/candidate/auth/logout", null);
        await SetCsrf(client);
        var wrong = await client.PostAsJsonAsync("/api/candidate/auth/login", new { emailOrPhone = "test@example.com", password = "wrong123" });
        var missing = await client.PostAsJsonAsync("/api/candidate/auth/login", new { emailOrPhone = "missing@example.com", password = "wrong123" });
        Assert.Equal(HttpStatusCode.Unauthorized, wrong.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, missing.StatusCode);
        var wrongBody = await wrong.Content.ReadFromJsonAsync<JsonElement>();
        var missingBody = await missing.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(wrongBody.GetProperty("detail").GetString(), missingBody.GetProperty("detail").GetString());
        var valid = await client.PostAsJsonAsync("/api/candidate/auth/login", new { emailOrPhone = "TEST@example.com", password = "matkhau123" });
        Assert.Equal(HttpStatusCode.OK, valid.StatusCode);
    }

    [Theory]
    [InlineData("inactive")]
    [InlineData("deleted")]
    [InlineData("locked")]
    [InlineData("employer")]
    [InlineData("profile")]
    public async Task DisabledOrNonCandidateAccountCannotUseSessionOrLogin(string reason)
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        await SetCsrf(client);
        Assert.Equal(HttpStatusCode.Created, (await client.PostAsJsonAsync("/api/candidate/auth/register", Register("test@example.com"))).StatusCode);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var account = await db.AccountRecords.Include(x => x.CandidateProfile).SingleAsync();
            if (reason == "inactive") account.Status = EntityStatus.Inactive;
            if (reason == "deleted") account.Status = EntityStatus.Deleted;
            if (reason == "locked") account.AccountStatus = "Locked";
            if (reason == "employer") account.AccountType = "Employer";
            if (reason == "profile") account.CandidateProfile!.Status = EntityStatus.Inactive;
            await db.SaveChangesAsync();
        }
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/candidate/auth/me")).StatusCode);
        await SetCsrf(client);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/candidate/auth/login",
            new { emailOrPhone = "test@example.com", password = "matkhau123" })).StatusCode);
    }

    [Fact]
    public async Task LoginIsRateLimited()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        await SetCsrf(client);
        for (var i = 0; i < 10; i++)
            Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/candidate/auth/login",
                new { emailOrPhone = "missing@example.com", password = "wrong123" })).StatusCode);
        Assert.Equal(HttpStatusCode.TooManyRequests, (await client.PostAsJsonAsync("/api/candidate/auth/login",
            new { emailOrPhone = "missing@example.com", password = "wrong123" })).StatusCode);
    }

    [Fact]
    public async Task LoginAndLogoutRequireValidCsrfAndFailedLogoutKeepsSession()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/candidate/auth/login",
            new { emailOrPhone = "test@example.com", password = "matkhau123" })).StatusCode);
        await SetCsrf(client);
        Assert.Equal(HttpStatusCode.Created, (await client.PostAsJsonAsync("/api/candidate/auth/register", Register("test@example.com"))).StatusCode);
        client.DefaultRequestHeaders.Remove("X-CSRF-TOKEN");
        client.DefaultRequestHeaders.Add("X-CSRF-TOKEN", "forged-token");
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsync("/api/candidate/auth/logout", null)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/candidate/auth/me")).StatusCode);
    }

    [Fact]
    public async Task SwaggerDescribesAuthEndpointsAndCsrfHeader()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/swagger/index.html")).StatusCode);
        var document = await client.GetFromJsonAsync<JsonElement>("/openapi/v1.json");
        var paths = document.GetProperty("paths");
        foreach (var name in new[] { "register", "login", "logout" })
        {
            var parameters = paths.GetProperty($"/api/candidate/auth/{name}").GetProperty("post").GetProperty("parameters");
            Assert.Contains(parameters.EnumerateArray(), x => x.GetProperty("name").GetString() == "X-CSRF-TOKEN"
                && x.GetProperty("required").GetBoolean());
        }
        Assert.True(paths.TryGetProperty("/api/candidate/auth/me", out _));
        Assert.True(paths.TryGetProperty("/api/candidate/auth/csrf", out _));
    }

    [Theory]
    [InlineData("http://localhost:5173", true)]
    [InlineData("https://untrusted.example", false)]
    public async Task CorsOnlyAllowsConfiguredFrontendOrigins(string origin, bool allowed)
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        using var request = new HttpRequestMessage(HttpMethod.Options, "/api/candidate/auth/login");
        request.Headers.Add("Origin", origin);
        request.Headers.Add("Access-Control-Request-Method", "POST");
        request.Headers.Add("Access-Control-Request-Headers", "content-type,x-csrf-token");
        var response = await client.SendAsync(request);
        Assert.Equal(allowed, response.Headers.Contains("Access-Control-Allow-Origin"));
        if (allowed)
        {
            Assert.Equal(origin, Assert.Single(response.Headers.GetValues("Access-Control-Allow-Origin")));
            Assert.Equal("true", Assert.Single(response.Headers.GetValues("Access-Control-Allow-Credentials")));
        }
    }

    [Fact]
    public void SqlServerModelHasFilteredUniqueEmailAndPhone()
    {
        using var db = new RecruitmentDbContext(new DbContextOptionsBuilder<RecruitmentDbContext>()
            .UseSqlServer("Server=localhost;Database=ModelOnly;Trusted_Connection=True").Options);
        var account = db.Model.FindEntityType(typeof(Account))!;
        Assert.True(account.FindProperty(nameof(Account.Email))!.IsNullable);
        foreach (var property in new[] { nameof(Account.Email), nameof(Account.Phone) })
        {
            var index = Assert.Single(account.GetIndexes(), x => x.Properties.Single().Name == property);
            Assert.True(index.IsUnique);
            Assert.Equal($"[{property}] IS NOT NULL", index.GetFilter());
        }
    }

    private static CandidateRegisterRequest Register(string identifier) => new()
    {
        FullName = " Nguyễn Văn A ", EmailOrPhone = identifier,
        Password = "matkhau123", ConfirmPassword = "matkhau123"
    };

    private static async Task SetCsrf(HttpClient client)
    {
        var token = (await client.GetFromJsonAsync<CsrfTokenDto>("/api/candidate/auth/csrf"))!;
        client.DefaultRequestHeaders.Remove(token.HeaderName);
        client.DefaultRequestHeaders.Add(token.HeaderName, token.Token);
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
    }
}
