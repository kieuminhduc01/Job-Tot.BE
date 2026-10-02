# Candidate authentication: JWT access and rotating refresh tokens

Candidate login and registration accept email or Vietnamese mobile number plus password. Passwords continue to use ASP.NET Core Identity PasswordHasher. Password recovery configuration is in [password-recovery.md](password-recovery.md).

## Local setup

Apply migrations from `BE/JobTot`, then restart the API in Visual Studio:

```powershell
dotnet ef database update --project src/JobTot.Infrastructure --startup-project src/JobTot.Api
dotnet run --project src/JobTot.Api --launch-profile http
```

If Visual Studio locks the Debug binaries, migration and tests can use `--configuration Jwt`. Migration `AddCandidateRefreshSessions` adds two tables; it does not remove existing accounts or profiles. Existing authentication cookies are no longer accepted; sign in again.

## API contract

Prefix: `/api/candidate/auth`.

| Method | Path | Request / result |
| --- | --- | --- |
| POST | `/register` | `{ fullName, emailOrPhone, password, confirmPassword }`; 201, account and token pair |
| POST | `/login` | `{ emailOrPhone, password, rememberMe }`; 200, account and token pair |
| POST | `/refresh` | `{ refreshToken }`; 200, account and NEW token pair; 401 if invalid |
| GET | `/me` | Bearer access token; 200, account; 401 if invalid or expired |
| POST | `/logout` | `{ refreshToken }`; 204, revokes the whole login session, including access tokens |
| POST | `/forgot-password` | `{ email }`; generic delivery result |
| POST | `/reset-password` | `{ token, password, confirmPassword }`; 204 |

Login/register/refresh return:

```json
{
  "account": {
    "id": "<account-guid>",
    "candidateProfileId": "<profile-guid>",
    "fullName": "Candidate",
    "email": "candidate@example.com",
    "phone": null,
    "accountType": "Candidate"
  },
  "accessToken": "<signed JWT>",
  "refreshToken": "<opaque random token>",
  "expiresAt": "<access expiry UTC>",
  "refreshExpiresAt": "<absolute refresh/session expiry UTC>"
}
```

JWT access tokens last up to 15 minutes and include the account, Candidate role, login-session ID and unique token ID. Refresh tokens last 8 hours, or 30 days with `rememberMe: true`. Refresh does not extend the original session deadline. The API stores SHA-256 hashes of refresh tokens, never the raw refresh token. Each refresh consumes the previous token and records its hash. Reusing a consumed token revokes that login session. Optimistic concurrency prevents two simultaneous rotations from both succeeding. Other devices have independent sessions.

Protected endpoints require `Authorization: Bearer <accessToken>`. They validate signature, issuer, audience, lifetime, session revocation, account/profile status and password stamp. Changing the password makes existing access and refresh tokens unusable. No cookie authentication or `/csrf` request is used. Logout accepts the refresh token so it also works after access-token expiration.

## Frontend storage and renewal

`FE/src/shared/api/candidate-session.js` owns storage and authorized fetches. Both tokens are stored under `jobtot.candidate.tokens`: sessionStorage by default and localStorage with Remember me. Reloading the page preserves the session. Closing the tab ends sessionStorage persistence. Both storage locations are cleared on logout and definitive refresh rejection. Browser storage is accessible to JavaScript, so preventing XSS is essential.

On a protected 401, the client rotates the refresh token and retries the request once. Concurrent requests share one refresh promise. Web Locks serialize refreshes across tabs for persistent sessions where supported. A response arriving after logout cannot recreate the session. Temporary network/server errors preserve the token pair. CV downloads use an authorized fetch and a temporary blob URL; tokens are not placed in download URLs.

## Signing-key configuration

Production requires `Jwt__SigningKey`: a Base64-encoded cryptographically random key of at least 32 bytes. Set it through environment variables or a secret provider; never commit it. Optional `Jwt__Issuer` and `Jwt__Audience` default to `JobTot.Api` and `JobTot.Web`. All API instances must use the same key, issuer and audience. Production uses HTTPS.

Development without a configured key creates a random in-memory key at startup. Restarting invalidates old access tokens; a still-valid refresh token obtains a new access token. Configure a shared key for multiple development instances.

Password recovery still uses Data Protection; keep those keys persistent across production restarts/instances. CORS allows only `Cors:AllowedOrigins`, with Authorization and Content-Type headers, and does not enable cookie credentials. Auth/recovery/refresh requests are rate limited per IP.

## Swagger and checks

Call register/login, copy `accessToken`, then use Swagger Authorize with the Bearer scheme to call `/me` and profile endpoints. Refresh and logout take the refresh token in their JSON body.

```powershell
dotnet test tests/JobTot.Domain.Tests --configuration Jwt
```

HTTP tests use EF InMemory and cover issuance, validation, rotation, replay, logout, account changes, expiry, rate limiting and private profile/CV access. InMemory tests do not prove SQL Server transactions or uniqueness constraints; SQL model tests and generated migrations cover the schema.

References: [ASP.NET Core JWT bearer authentication](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/configure-jwt-bearer-authentication?view=aspnetcore-9.0), [refresh token rotation](https://www.rfc-editor.org/rfc/rfc9700.html#section-4.14).
