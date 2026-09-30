using JobTot.Application.Authentication;
using JobTot.Domain.Entities;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace JobTot.Infrastructure.Persistence;

public sealed class CandidateAuthRepository(RecruitmentDbContext db) : ICandidateAuthRepository
{
    public Task<Account?> FindAsync(CandidateIdentifier identifier, CancellationToken ct) =>
        identifier.Email is not null
            ? db.AccountRecords.Include(x => x.CandidateProfile).SingleOrDefaultAsync(x => x.Email == identifier.Email, ct)
            : db.AccountRecords.Include(x => x.CandidateProfile).SingleOrDefaultAsync(x => x.Phone == identifier.Phone, ct);

    public Task<Account?> GetAsync(Guid id, CancellationToken ct) => db.AccountRecords
        .AsNoTracking().Include(x => x.CandidateProfile).SingleOrDefaultAsync(x => x.Id == id, ct);

    public async Task AddAsync(Account account, CancellationToken ct)
    {
        db.AccountRecords.Add(account);
        try { await db.SaveChangesAsync(ct); }
        catch (DbUpdateException ex) when (ex.InnerException is SqlException { Number: 2601 or 2627 })
        {
            // Database uniqueness also handles concurrent registrations.
            throw new DuplicateAccountException();
        }
    }

    public async Task SaveChangesAsync(CancellationToken ct) => await db.SaveChangesAsync(ct);
}
