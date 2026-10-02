using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using JobTot.Api;
using System.Net.Http.Headers;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.IdentityModel.Tokens;
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
    public async Task RegistrationIssuesTokensAndLogoutRevokesAccessAndRefresh()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/candidate/auth/me")).StatusCode);
        var session = await RegisterClient(client);
        Assert.Equal("test@example.com", session.Account.Email);
        Assert.Equal("Candidate", session.Account.AccountType);
        Assert.NotEqual(Guid.Empty, session.Account.CandidateProfileId);
        Assert.Equal(3, session.AccessToken.Split('.').Length);
        Assert.InRange(session.ExpiresAt - DateTimeOffset.UtcNow, TimeSpan.FromMinutes(14), TimeSpan.FromMinutes(16));
        Assert.InRange(session.RefreshExpiresAt - DateTimeOffset.UtcNow, TimeSpan.FromHours(7.9), TimeSpan.FromHours(8.1));
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/candidate/auth/me")).StatusCode);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var stored = await db.CandidateRefreshSessions.SingleAsync();
            Assert.DoesNotContain(session.RefreshToken, stored.TokenHash);
            Assert.Equal(64, stored.TokenHash.Length);
            Assert.NotEqual("matkhau123", (await db.AccountRecords.SingleAsync()).PasswordHash);
        }
        Assert.Equal(HttpStatusCode.NoContent, (await client.PostAsJsonAsync("/api/candidate/auth/logout", new { session.RefreshToken })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/candidate/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await Refresh(client, session.RefreshToken)).StatusCode);
    }

    [Fact]
    public async Task RefreshRotatesTokensAndReplayRevokesTheLoginSession()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        var first = await RegisterClient(client);
        var response = await Refresh(client, first.RefreshToken);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var second = (await response.Content.ReadFromJsonAsync<CandidateSessionDto>())!;
        Assert.NotEqual(first.RefreshToken, second.RefreshToken);
        Assert.NotEqual(first.AccessToken, second.AccessToken);
        Assert.Equal(first.RefreshExpiresAt, second.RefreshExpiresAt);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", second.AccessToken);
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/candidate/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await Refresh(client, first.RefreshToken)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await Refresh(client, second.RefreshToken)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/candidate/auth/me")).StatusCode);
    }

    [Fact]
    public async Task InvalidRefreshTokenCannotRevokeAnotherSessionAndLogoutWorksWithoutAccessToken()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        var session = await RegisterClient(client);
        var forged = session.RefreshToken[..33] + "forged";
        Assert.Equal(HttpStatusCode.Unauthorized, (await Refresh(client, forged)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/candidate/auth/me")).StatusCode);
        client.DefaultRequestHeaders.Authorization = null;
        Assert.Equal(HttpStatusCode.NoContent, (await client.PostAsJsonAsync("/api/candidate/auth/logout", new { session.RefreshToken })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await Refresh(client, session.RefreshToken)).StatusCode);
    }

    [Fact]
    public async Task RememberMeAndPhoneNormalizationWorkWithoutCookies()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        var registration = await client.PostAsJsonAsync("/api/candidate/auth/register", Register("0912345678"));
        Assert.Equal(HttpStatusCode.Created, registration.StatusCode);
        Assert.False(registration.Headers.Contains("Set-Cookie"));
        var first = (await registration.Content.ReadFromJsonAsync<CandidateSessionDto>())!;
        Assert.Equal("+84912345678", first.Account.Phone);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync("/api/candidate/auth/register", Register("+84 912 345 678"))).StatusCode);
        var response = await client.PostAsJsonAsync("/api/candidate/auth/login", new { emailOrPhone = "+84912345678", password = "matkhau123", rememberMe = true });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var session = (await response.Content.ReadFromJsonAsync<CandidateSessionDto>())!;
        Assert.InRange(session.RefreshExpiresAt - DateTimeOffset.UtcNow, TimeSpan.FromDays(29.9), TimeSpan.FromDays(30.1));
        Assert.False(response.Headers.Contains("Set-Cookie"));
    }

    [Theory]
    [InlineData("expired")]
    [InlineData("issuer")]
    [InlineData("audience")]
    [InlineData("signature")]
    [InlineData("role")]
    public async Task JwtValidationRejectsInvalidTokens(string reason)
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        var session = await RegisterClient(client);
        var settings = factory.Services.GetRequiredService<CandidateJwtSettings>();
        var claims = new JwtSecurityTokenHandler().ReadJwtToken(session.AccessToken).Claims
            .Where(x => x.Type is not ("exp" or "nbf" or "iss" or "aud" or "iat") && x.Type != ClaimTypes.Role).ToList();
        claims.Add(new Claim(ClaimTypes.Role, reason == "role" ? "Employer" : "Candidate"));
        var jwt = new JwtSecurityToken(reason == "issuer" ? "wrong" : settings.Issuer,
            reason == "audience" ? "wrong" : settings.Audience, claims,
            DateTime.UtcNow.AddMinutes(-30), reason == "expired" ? DateTime.UtcNow.AddMinutes(-1) : DateTime.UtcNow.AddMinutes(15),
            new SigningCredentials(reason == "signature" ? new SymmetricSecurityKey(new byte[32]) : settings.Key, SecurityAlgorithms.HmacSha256));
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", new JwtSecurityTokenHandler().WriteToken(jwt));
        Assert.Equal(reason == "role" ? HttpStatusCode.Forbidden : HttpStatusCode.Unauthorized,
            (await client.GetAsync("/api/candidate/auth/me")).StatusCode);
    }

    [Theory]
    [InlineData("inactive")]
    [InlineData("deleted")]
    [InlineData("locked")]
    [InlineData("employer")]
    [InlineData("profile")]
    [InlineData("password")]
    [InlineData("expired")]
    public async Task ChangedAccountOrExpiredSessionCannotUseTokens(string reason)
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        var session = await RegisterClient(client);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var account = await db.AccountRecords.Include(x => x.CandidateProfile).SingleAsync();
            if (reason == "inactive") account.Status = EntityStatus.Inactive;
            if (reason == "deleted") account.Status = EntityStatus.Deleted;
            if (reason == "locked") account.AccountStatus = "Locked";
            if (reason == "employer") account.AccountType = "Employer";
            if (reason == "profile") account.CandidateProfile!.Status = EntityStatus.Inactive;
            if (reason == "password") account.PasswordHash = "changed-password-hash";
            if (reason == "expired") (await db.CandidateRefreshSessions.SingleAsync()).ExpiresAt = DateTimeOffset.UtcNow.AddMinutes(-1);
            await db.SaveChangesAsync();
        }
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/candidate/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await Refresh(client, session.RefreshToken)).StatusCode);
    }

    [Fact]
    public async Task InvalidInputsAndWrongPasswordAreRejectedAndLoginIsRateLimited()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/candidate/auth/register", new { fullName = "Test", emailOrPhone = "invalid", password = "short", confirmPassword = "different" })).StatusCode);
        for (var i = 0; i < 9; i++)
            Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync("/api/candidate/auth/login", new { emailOrPhone = "missing@example.com", password = "wrong123" })).StatusCode);
        Assert.Equal(HttpStatusCode.TooManyRequests, (await client.PostAsJsonAsync("/api/candidate/auth/login", new { emailOrPhone = "missing@example.com", password = "wrong123" })).StatusCode);
    }

    [Fact]
    public async Task OpenApiDescribesBearerAndRefreshWithoutCsrf()
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        var document = await client.GetFromJsonAsync<JsonElement>("/openapi/v1.json");
        Assert.Equal("bearer", document.GetProperty("components").GetProperty("securitySchemes").GetProperty("Bearer").GetProperty("scheme").GetString());
        Assert.True(document.GetProperty("paths").TryGetProperty("/api/candidate/auth/refresh", out _));
        Assert.False(document.GetProperty("paths").TryGetProperty("/api/candidate/auth/csrf", out _));
        Assert.True(document.GetProperty("paths").GetProperty("/api/candidate/auth/me")
            .GetProperty("get").GetProperty("security")[0].TryGetProperty("Bearer", out _));
    }

    [Theory]
    [InlineData("http://localhost:5173", true)]
    [InlineData("https://untrusted.example", false)]
    public async Task CorsAllowsOnlyConfiguredOrigins(string origin, bool allowed)
    {
        await using var factory = new AuthFactory();
        using var client = factory.CreateClient();
        using var request = new HttpRequestMessage(HttpMethod.Options, "/api/candidate/auth/login");
        request.Headers.Add("Origin", origin);
        request.Headers.Add("Access-Control-Request-Method", "POST");
        request.Headers.Add("Access-Control-Request-Headers", "content-type,authorization");
        var response = await client.SendAsync(request);
        Assert.Equal(allowed, response.Headers.Contains("Access-Control-Allow-Origin"));
    }

    private static Task<HttpResponseMessage> Refresh(HttpClient client, string refreshToken)
        => client.PostAsJsonAsync("/api/candidate/auth/refresh", new { refreshToken });

    private static async Task<CandidateSessionDto> RegisterClient(HttpClient client)
    {
        var response = await client.PostAsJsonAsync("/api/candidate/auth/register", Register("test@example.com"));
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var session = (await response.Content.ReadFromJsonAsync<CandidateSessionDto>())!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", session.AccessToken);
        return session;
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
