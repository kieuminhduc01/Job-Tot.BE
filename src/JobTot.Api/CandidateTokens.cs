using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using JobTot.Application.Authentication;
using JobTot.Domain.Entities;
using JobTot.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace JobTot.Api;

public sealed record CandidateJwtSettings(string Issuer, string Audience, SymmetricSecurityKey Key);

public sealed class CandidateTokens(RecruitmentDbContext db, CandidateAuthService accounts, CandidateJwtSettings settings)
{
    public async Task<CandidateSessionDto> CreateAsync(CandidateAccountDto account, bool rememberMe, CancellationToken ct)
    {
        var session = new CandidateRefreshSession
        {
            AccountId = account.Id,
            PasswordStamp = (await accounts.GetPasswordStampAsync(account.Id, ct))!,
            ExpiresAt = DateTimeOffset.UtcNow.Add(rememberMe ? TimeSpan.FromDays(30) : TimeSpan.FromHours(8))
        };
        var refreshToken = NewRefreshToken(session.Id);
        session.TokenHash = Hash(refreshToken);
        db.CandidateRefreshSessions.Add(session);
        await db.SaveChangesAsync(ct);
        return Issue(account, session, refreshToken);
    }

    public async Task<CandidateSessionDto?> RefreshAsync(string token, CancellationToken ct)
    {
        if (!TrySessionId(token, out var id)) return null;
        var session = await db.CandidateRefreshSessions.SingleOrDefaultAsync(x => x.Id == id, ct);
        if (session is null || session.RevokedAt is not null || session.ExpiresAt <= DateTimeOffset.UtcNow) return null;
        var hash = Hash(token);
        if (session.TokenHash != hash)
        {
            // A previously consumed token proves replay; revoke this whole login session.
            if (await db.UsedCandidateRefreshTokens.AnyAsync(x => x.SessionId == id && x.TokenHash == hash, ct))
                await RevokeAsync(id, ct);
            return null;
        }
        var account = await accounts.GetActiveAsync(session.AccountId, ct);
        if (account is null || session.PasswordStamp != await accounts.GetPasswordStampAsync(session.AccountId, ct))
        {
            await RevokeAsync(id, ct);
            return null;
        }
        var refreshToken = NewRefreshToken(id);
        db.UsedCandidateRefreshTokens.Add(new UsedCandidateRefreshToken { SessionId = id, TokenHash = hash });
        session.TokenHash = Hash(refreshToken);
        session.Version = Guid.NewGuid();
        try { await db.SaveChangesAsync(ct); }
        catch (DbUpdateConcurrencyException)
        {
            db.ChangeTracker.Clear();
            await RevokeAsync(id, ct);
            return null;
        }
        catch (DbUpdateException)
        {
            // An insert of the consumed hash may report a duplicate before the version check.
            db.ChangeTracker.Clear();
            if (!await db.UsedCandidateRefreshTokens.AnyAsync(x => x.SessionId == id && x.TokenHash == hash, ct)) throw;
            await RevokeAsync(id, ct);
            return null;
        }
        return Issue(account, session, refreshToken);
    }

    public async Task LogoutAsync(string token, CancellationToken ct)
    {
        if (!TrySessionId(token, out var id)) return;
        var hash = Hash(token);
        if (await db.CandidateRefreshSessions.AnyAsync(x => x.Id == id && x.TokenHash == hash, ct)
            || await db.UsedCandidateRefreshTokens.AnyAsync(x => x.SessionId == id && x.TokenHash == hash, ct))
            await RevokeAsync(id, ct);
    }

    public async Task<bool> ValidateAsync(ClaimsPrincipal principal, CancellationToken ct)
    {
        if (!Guid.TryParse(principal.FindFirstValue(ClaimTypes.NameIdentifier), out var accountId)
            || !Guid.TryParse(principal.FindFirstValue("sid"), out var sessionId)) return false;
        var session = await db.CandidateRefreshSessions.AsNoTracking().SingleOrDefaultAsync(x => x.Id == sessionId, ct);
        return session is not null && session.AccountId == accountId && session.RevokedAt is null
            && session.ExpiresAt > DateTimeOffset.UtcNow
            && await accounts.GetActiveAsync(accountId, ct) is not null
            && session.PasswordStamp == await accounts.GetPasswordStampAsync(accountId, ct);
    }

    private async Task RevokeAsync(Guid id, CancellationToken ct)
    {
        // Retry optimistic concurrency so logout cannot lose a race with rotation.
        while (true)
        {
            db.ChangeTracker.Clear();
            var session = await db.CandidateRefreshSessions.SingleOrDefaultAsync(x => x.Id == id, ct);
            if (session is null || session.RevokedAt is not null) return;
            session.RevokedAt = DateTimeOffset.UtcNow;
            session.Version = Guid.NewGuid();
            try { await db.SaveChangesAsync(ct); return; }
            catch (DbUpdateConcurrencyException) { ct.ThrowIfCancellationRequested(); }
        }
    }

    private CandidateSessionDto Issue(CandidateAccountDto account, CandidateRefreshSession session, string refreshToken)
    {
        var now = DateTimeOffset.UtcNow;
        var expiresAt = now.AddMinutes(15);
        if (expiresAt > session.ExpiresAt) expiresAt = session.ExpiresAt;
        var jwt = new JwtSecurityToken(settings.Issuer, settings.Audience,
            [new(ClaimTypes.NameIdentifier, account.Id.ToString()), new(ClaimTypes.Name, account.FullName),
             new(ClaimTypes.Role, CandidateAuthService.CandidateRole), new("sid", session.Id.ToString()),
             new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())],
            now.UtcDateTime, expiresAt.UtcDateTime,
            new SigningCredentials(settings.Key, SecurityAlgorithms.HmacSha256));
        return new(account, new JwtSecurityTokenHandler().WriteToken(jwt), refreshToken, expiresAt, session.ExpiresAt);
    }

    private static string NewRefreshToken(Guid id) => $"{id:N}.{Base64UrlEncoder.Encode(RandomNumberGenerator.GetBytes(48))}";
    private static string Hash(string token) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
    private static bool TrySessionId(string token, out Guid id)
    {
        id = default;
        return token.Length is > 33 and <= 256 && token[32] == '.' && Guid.TryParseExact(token[..32], "N", out id);
    }
}
