using System.Text.Json;
using JobTot.Api;
using JobTot.Application.Authentication;
using JobTot.Domain.Entities;
using JobTot.Infrastructure;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.Extensions.Configuration;

namespace JobTot.Domain.Tests;

public sealed class PasswordRecoveryTests
{
    private readonly EphemeralDataProtectionProvider protection = new();
    private readonly AccountPasswordHasher passwords = new();
    private readonly RecoveryRepository repository = new();
    private readonly CaptureSender sender = new();

    private PasswordRecovery Service() => new(repository, passwords, protection, sender,
        new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["PasswordRecovery:FrontendUrl"] = "https://jobs.example.com",
            ["PasswordRecovery:Smtp:Host"] = "smtp.example.com",
            ["PasswordRecovery:Smtp:From"] = "noreply@example.com"
        }).Build());

    [Fact]
    public async Task RecoveryResetsPasswordOnceAndChangesSessionStamp()
    {
        var account = repository.Account;
        account.PasswordHash = passwords.Hash(account, "oldpassword123");
        var auth = new CandidateAuthService(repository, passwords);
        var stamp = await auth.GetPasswordStampAsync(account.Id, default);
        var service = Service();
        await service.RequestAsync(" Candidate@Example.com ", default);
        Assert.Equal(account.Email, sender.Email);
        Assert.StartsWith("https://jobs.example.com/reset-password#token=", sender.Link);
        var token = Uri.UnescapeDataString(sender.Link!.Split("#token=")[1]);
        var request = new ResetPasswordRequest { Token = token, Password = "newpassword123", ConfirmPassword = "newpassword123" };
        await service.ResetAsync(request, default);
        Assert.True(passwords.Verify(account, request.Password, out _));
        Assert.False(passwords.Verify(account, "oldpassword123", out _));
        Assert.NotEqual(stamp, await auth.GetPasswordStampAsync(account.Id, default));
        await Assert.ThrowsAsync<ArgumentException>(() => service.ResetAsync(request, default));
    }

    [Theory]
    [InlineData("unknown@example.com")]
    [InlineData("candidate@example.com", true)]
    public async Task UnknownAndInactiveAccountsDoNotReceiveMail(string email, bool inactive = false)
    {
        repository.Account.PasswordHash = passwords.Hash(repository.Account, "oldpassword123");
        if (inactive) repository.Account.AccountStatus = "Locked";
        await Service().RequestAsync(email, default);
        Assert.Null(sender.Link);
    }

    [Fact]
    public async Task TamperedAndExpiredTokensAreRejected()
    {
        var service = Service();
        await Assert.ThrowsAsync<ArgumentException>(() => service.ResetAsync(new ResetPasswordRequest { Token = "invalid" }, default));
        var token = protection.CreateProtector("JobTot.Candidate.PasswordReset.v1").Protect(JsonSerializer.Serialize(new
        {
            AccountId = repository.Account.Id, PasswordHash = "oldhash", ExpiresAt = DateTimeOffset.UtcNow.AddMinutes(-1)
        }));
        await Assert.ThrowsAsync<ArgumentException>(() => service.ResetAsync(new ResetPasswordRequest { Token = token }, default));
    }

    private sealed class CaptureSender : IRecoveryEmailSender
    {
        public string? Email { get; private set; }
        public string? Link { get; private set; }
        public Task SendAsync(string email, string link, CancellationToken ct)
        { Email = email; Link = link; return Task.CompletedTask; }
    }

    private sealed class RecoveryRepository : ICandidateAuthRepository
    {
        public Account Account { get; } = new()
        {
            Email = "candidate@example.com", AccountType = "Candidate", AccountStatus = "Active",
            CandidateProfile = new CandidateProfile()
        };
        public Task<Account?> FindAsync(CandidateIdentifier identifier, CancellationToken ct)
            => Task.FromResult(identifier.Email == Account.Email ? Account : null);
        public Task<Account?> GetAsync(Guid id, CancellationToken ct) => Task.FromResult(id == Account.Id ? Account : null);
        public Task AddAsync(Account account, CancellationToken ct) => throw new NotSupportedException();
        public Task SaveChangesAsync(CancellationToken ct) => Task.CompletedTask;
        public Task<bool> ResetPasswordAsync(Guid id, string expectedHash, string newHash, CancellationToken ct)
        {
            if (id != Account.Id || Account.PasswordHash != expectedHash) return Task.FromResult(false);
            Account.PasswordHash = newHash;
            return Task.FromResult(true);
        }
    }
}
