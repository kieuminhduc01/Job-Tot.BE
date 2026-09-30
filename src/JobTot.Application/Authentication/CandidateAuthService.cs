using System.ComponentModel.DataAnnotations;
using JobTot.Domain.Entities;
using JobTot.Domain.Enums;

namespace JobTot.Application.Authentication;

public sealed class CandidateAuthService(ICandidateAuthRepository repository, IAccountPasswordHasher passwords)
{
    public const string CandidateRole = "Candidate";
    public const string ActiveStatus = "Active";

    public async Task<CandidateAccountDto> RegisterAsync(CandidateRegisterRequest request, CancellationToken ct)
    {
        Validate(request);
        var identifier = CandidateIdentifier.Parse(request.EmailOrPhone);
        if (await repository.FindAsync(identifier, ct) is not null)
            throw new DuplicateAccountException();

        var account = new Account
        {
            FullName = request.FullName.Trim(), Email = identifier.Email, Phone = identifier.Phone,
            AccountType = CandidateRole, AccountStatus = ActiveStatus
        };
        account.PasswordHash = passwords.Hash(account, request.Password);
        account.CandidateProfile = new CandidateProfile { AccountId = account.Id, Account = account };
        await repository.AddAsync(account, ct);
        return ToDto(account);
    }

    public async Task<CandidateAccountDto> LoginAsync(CandidateLoginRequest request, CancellationToken ct)
    {
        Validate(request);
        CandidateIdentifier identifier;
        try { identifier = CandidateIdentifier.Parse(request.EmailOrPhone); }
        catch (ArgumentException) { throw new InvalidCredentialsException(); }
        var account = await repository.FindAsync(identifier, ct);
        // The password implementation also performs a hash verification for unknown accounts.
        var validPassword = passwords.Verify(account ?? new Account(), request.Password, out var rehash);
        if (!validPassword || account is null || !IsActiveCandidate(account))
            throw new InvalidCredentialsException();

        if (rehash)
        {
            account.PasswordHash = passwords.Hash(account, request.Password);
            await repository.SaveChangesAsync(ct);
        }
        return ToDto(account);
    }

    public async Task<CandidateAccountDto?> GetActiveAsync(Guid id, CancellationToken ct)
    {
        var account = await repository.GetAsync(id, ct);
        return account is not null && IsActiveCandidate(account) ? ToDto(account) : null;
    }

    private static bool IsActiveCandidate(Account account) =>
        account.Status == EntityStatus.Active && account.AccountType == CandidateRole &&
        account.AccountStatus == ActiveStatus && account.CandidateProfile?.Status == EntityStatus.Active;

    private static CandidateAccountDto ToDto(Account account) => new(account.Id,
        account.CandidateProfile!.Id, account.FullName, account.Email, account.Phone, CandidateRole);

    private static void Validate(object request)
    {
        var errors = new List<ValidationResult>();
        if (!Validator.TryValidateObject(request, new ValidationContext(request), errors, true))
            throw new ArgumentException(string.Join(" ", errors.Select(x => x.ErrorMessage)));
    }
}
