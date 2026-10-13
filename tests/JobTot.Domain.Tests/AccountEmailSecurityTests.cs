using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.RegularExpressions;
using JobTot.Api;
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

public sealed class AccountEmailSecurityTests
{
    [Theory]
    [InlineData("candidate")]
    [InlineData("employer")]
    public async Task RegistrationRequiresVerifiedEmailAndTemporaryPasswordRequiresChange(string role)
    {
        await using var factory = new Factory();
        using var client = factory.CreateClient();
        var email = role + "@example.com";
        Guid provinceId;
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var province = new Province { ProvinceName = "Ha Noi", ProvinceCode = "01" };
            db.Add(province); await db.SaveChangesAsync(); provinceId = province.Id;
        }
        object Registration(string? proof) => role == "candidate"
            ? new { fullName = "Verified candidate", emailOrPhone = email, password = "password123!", confirmPassword = "password123!", emailVerificationToken = proof }
            : new { fullName = "Verified employer", email, workPhone = "0988123456", companyName = "Verified company", taxCode = "0109867899", headOfficeProvinceId = provinceId, password = "password123!", confirmPassword = "password123!", acceptTerms = true, recruitmentCommitment = true, emailVerificationToken = proof };
        var root = $"/api/{role}/auth";
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync(root + "/register", Registration(null))).StatusCode);
        var requested = await client.PostAsJsonAsync(root + "/email/request", new { email });
        requested.EnsureSuccessStatusCode();
        var id = (await requested.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("challengeId").GetGuid();
        var code = Regex.Match(factory.Mail.Body, "[0-9]{6}").Value;
        var verified = await client.PostAsJsonAsync(root + "/email/verify", new { email, challengeId = id, code });
        verified.EnsureSuccessStatusCode();
        var proof = (await verified.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("verificationToken").GetString();
        var registered = await client.PostAsJsonAsync(root + "/register", Registration(proof));
        Assert.Equal(HttpStatusCode.Created, registered.StatusCode);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            Assert.NotNull((await db.AccountRecords.SingleAsync(a => a.Email == email)).EmailVerifiedAt);
            Assert.DoesNotContain(code, (await db.AccountEmailChallenges.SingleAsync()).SecretHash);
            await Assert.ThrowsAsync<EmailSecurityException>(() => scope.ServiceProvider.GetRequiredService<AccountEmailSecurity>().RequireVerification(email, role == "employer" ? "Employer" : "Candidate", proof, default));
        }
        (await client.PostAsJsonAsync(root + "/forgot-password", new { email })).EnsureSuccessStatusCode();
        var temporary = Regex.Match(factory.Mail.Body, @"[A-F0-9]{24}a!").Value;
        Assert.NotEmpty(temporary);
        object Login(string password) => role == "candidate" ? new { emailOrPhone = email, password } : new { email, password };
        // Requesting recovery does not invalidate a legitimate existing password.
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync(root + "/login", Login("password123!"))).StatusCode);
        var login = await client.PostAsJsonAsync(root + "/login", Login(temporary));
        Assert.Equal(428, (int)login.StatusCode);
        var response = await login.Content.ReadFromJsonAsync<JsonElement>();
        Assert.False(response.TryGetProperty("accessToken", out _));
        var token = response.GetProperty("changeToken").GetString();
        var changed = new { token, password = "newpassword456!", confirmPassword = "newpassword456!" };
        Assert.Equal(HttpStatusCode.NoContent, (await client.PostAsJsonAsync(root + "/email/change-temporary-password", changed)).StatusCode);
        using (var scope = factory.Services.CreateScope())
            await Assert.ThrowsAsync<EmailSecurityException>(() => scope.ServiceProvider.GetRequiredService<AccountEmailSecurity>().ChangeTemporaryPassword(role == "employer" ? "Employer" : "Candidate", token!, changed.password, default));
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsJsonAsync(root + "/login", Login(temporary))).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync(root + "/login", Login("newpassword456!"))).StatusCode);
    }

    [Fact]
    public async Task WrongVerificationCodeReturnsBadRequestAndRecordsAttempt()
    {
        await using var factory = new Factory();
        using var client = factory.CreateClient();
        var requested = await client.PostAsJsonAsync("/api/candidate/auth/email/request", new { email = "wrong@example.com" });
        requested.EnsureSuccessStatusCode();
        var id = (await requested.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("challengeId").GetGuid();
        var correct = Regex.Match(factory.Mail.Body, "[0-9]{6}").Value;
        var response = await client.PostAsJsonAsync("/api/candidate/auth/email/verify", new { email = "wrong@example.com", challengeId = id, code = correct == "000000" ? "111111" : "000000" });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal("Mã xác thực không đúng.", (await response.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("detail").GetString());
        using var scope = factory.Services.CreateScope();
        var row = await scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>().AccountEmailChallenges.SingleAsync(x => x.Id == id);
        Assert.Equal(1, row.Attempts);
        Assert.Null(row.VerifiedAt);
    }

    [Fact]
    public async Task VerificationExpiresAndLocksAfterFiveWrongCodes()
    {
        await using var factory = new Factory();
        using var scope = factory.Services.CreateScope();
        var security = scope.ServiceProvider.GetRequiredService<AccountEmailSecurity>();
        var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var id = await security.RequestVerification("lock@example.com", "Candidate", default);
        var correct = Regex.Match(factory.Mail.Body, "[0-9]{6}").Value;
        var wrong = correct == "000000" ? "111111" : "000000";
        for (var index = 0; index < 5; index++) Assert.Equal("Mã xác thực không đúng.", (await security.Verify(id, "lock@example.com", "Candidate", wrong, default)).Error);
        Assert.Null((await security.Verify(id, "lock@example.com", "Candidate", correct, default)).Token);
        var expired = await security.RequestVerification("expired@example.com", "Candidate", default);
        var row = await db.AccountEmailChallenges.SingleAsync(x => x.Id == expired);
        row.ExpiresAt = DateTimeOffset.UtcNow.AddMinutes(-1); await db.SaveChangesAsync();
        Assert.NotNull((await security.Verify(expired, "expired@example.com", "Candidate", Regex.Match(factory.Mail.Body, "[0-9]{6}").Value, default)).Error);
    }
    private sealed class Mail : IAccountEmailSender
    {
        public string Body { get; private set; } = "";
        public Task SendAsync(string email, string subject, string body, CancellationToken ct) { Body = body; return Task.CompletedTask; }
    }
    private sealed class Factory : WebApplicationFactory<Program>
    {
        private readonly string database = Guid.NewGuid().ToString();
        public Mail Mail { get; } = new();
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Development");
            builder.ConfigureServices(services => {
                services.RemoveAll<RecruitmentDbContext>(); services.RemoveAll<DbContextOptions<RecruitmentDbContext>>(); services.RemoveAll<IDbContextOptionsConfiguration<RecruitmentDbContext>>();
                services.AddDbContext<RecruitmentDbContext>(options => options.UseInMemoryDatabase(database));
                services.RemoveAll<IAccountEmailSender>(); services.AddSingleton<IAccountEmailSender>(Mail);
            });
        }
    }
}
