using JobTot.Api;
using JobTot.Application.Authentication;
using JobTot.Domain.Entities;
using JobTot.Infrastructure;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.Extensions.Configuration;

namespace JobTot.Domain.Tests;

public sealed class EmployerPasswordRecoveryTests
{
    [Fact]
    public async Task RecoveryUsesEmployerLinkAndSingleUseRoleSpecificTicket()
    {
        var passwords = new AccountPasswordHasher();
        var account = new Account { FullName = "HR", Email = "hr@example.com", AccountType = "Employer", AccountStatus = "Active" };
        account.RecruiterProfiles.Add(new RecruiterProfile { AccountId = account.Id, Company = new Company("Tốt Tech", "") });
        account.PasswordHash = passwords.Hash(account, "oldpassword");
        var repository = new RecoveryRepository(account);
        var sender = new RecordingSender();
        var protection = new EphemeralDataProtectionProvider();
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["PasswordRecovery:FrontendUrl"] = "https://jobtot.example",
            ["PasswordRecovery:Smtp:Host"] = "configured",
            ["PasswordRecovery:Smtp:From"] = "support@jobtot.example"
        }).Build();
        var recovery = new EmployerPasswordRecovery(repository, passwords, protection, sender, config);
        await recovery.RequestAsync("hr@example.com", CancellationToken.None);
        Assert.StartsWith("https://jobtot.example/reset-password?role=employer#token=", sender.Link);
        var token = Uri.UnescapeDataString(sender.Link!.Split("#token=")[1]);
        await Assert.ThrowsAsync<ArgumentException>(() => recovery.ResetAsync(new ResetPasswordRequest
        { Token = protection.CreateProtector("JobTot.Candidate.PasswordReset.v1").Protect("invalid"), Password = "newpassword", ConfirmPassword = "newpassword" }, CancellationToken.None));
        var request = new ResetPasswordRequest { Token = token, Password = "newpassword", ConfirmPassword = "newpassword" };
        await recovery.ResetAsync(request, CancellationToken.None);
        Assert.True(passwords.Verify(account, "newpassword", out _));
        Assert.False(passwords.Verify(account, "oldpassword", out _));
        await Assert.ThrowsAsync<ArgumentException>(() => recovery.ResetAsync(request, CancellationToken.None));
        sender.Link = null;
        account.AccountType = "Candidate";
        await recovery.RequestAsync("hr@example.com", CancellationToken.None);
        Assert.Null(sender.Link);
    }
    private sealed class RecordingSender : IRecoveryEmailSender
    {
        public string? Link;
        public Task SendAsync(string email, string link, CancellationToken ct) { ct.ThrowIfCancellationRequested(); Link = link; return Task.CompletedTask; }
    }
    private sealed class RecoveryRepository(Account account) : IEmployerAuthRepository
    {
        public Task<Account?> FindAsync(CandidateIdentifier identifier, CancellationToken ct) => Task.FromResult<Account?>(identifier.Email == account.Email ? account : null);
        public Task<Account?> GetAsync(Guid id, CancellationToken ct) => Task.FromResult<Account?>(id == account.Id ? account : null);
        public Task<EmployerRegistrationStatus> AddAsync(Account value, CancellationToken ct) => throw new NotSupportedException();
        public Task SaveChangesAsync(CancellationToken ct) => Task.CompletedTask;
        public Task<bool> ResetPasswordAsync(Guid id, string expectedHash, string newHash, CancellationToken ct)
        {
            ct.ThrowIfCancellationRequested();
            if (id != account.Id || expectedHash != account.PasswordHash) return Task.FromResult(false);
            account.PasswordHash = newHash;
            return Task.FromResult(true);
        }
    }
}
