using System.Security.Claims;
using JobTot.Application.Authentication;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace JobTot.Api.Controllers;

[ApiController]
[Route("api/candidate/auth")]
[AutoValidateAntiforgeryToken]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class CandidateAuthController(CandidateAuthService service, IAntiforgery antiforgery) : ControllerBase
{
    [HttpGet("csrf")]
    [AllowAnonymous]
    public ActionResult<CsrfTokenDto> Csrf() => Ok(new CsrfTokenDto(
        antiforgery.GetAndStoreTokens(HttpContext).RequestToken!, CandidateAuthentication.CsrfHeader));

    [HttpPost("register")]
    [AllowAnonymous]
    [EnableRateLimiting(CandidateAuthentication.RateLimitPolicy)]
    [ProducesResponseType<CandidateSessionDto>(StatusCodes.Status201Created)]
    public async Task<ActionResult<CandidateSessionDto>> Register(CandidateRegisterRequest request, CancellationToken ct)
    {
        var account = await service.RegisterAsync(request, ct);
        var session = await SignInAsync(account, rememberMe: false);
        return CreatedAtAction(nameof(Me), session);
    }

    [HttpPost("login")]
    [AllowAnonymous]
    [EnableRateLimiting(CandidateAuthentication.RateLimitPolicy)]
    public async Task<ActionResult<CandidateSessionDto>> Login(CandidateLoginRequest request, CancellationToken ct)
        => Ok(await SignInAsync(await service.LoginAsync(request, ct), request.RememberMe));

    [HttpGet("me")]
    [Authorize(Policy = CandidateAuthentication.Policy)]
    public async Task<ActionResult<CandidateAccountDto>> Me(CancellationToken ct)
    {
        var account = await service.GetActiveAsync(Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!), ct);
        return account is null ? Unauthorized() : Ok(account);
    }

    [HttpPost("logout")]
    [Authorize(Policy = CandidateAuthentication.Policy)]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync(CandidateAuthentication.Scheme);
        return NoContent();
    }

    private async Task<CandidateSessionDto> SignInAsync(CandidateAccountDto account, bool rememberMe)
    {
        var expiresAt = DateTimeOffset.UtcNow.Add(rememberMe ? TimeSpan.FromDays(30) : TimeSpan.FromHours(8));
        var identity = new ClaimsIdentity(new[]
        {
            new Claim(ClaimTypes.NameIdentifier, account.Id.ToString()),
            new Claim(ClaimTypes.Name, account.FullName),
            new Claim(ClaimTypes.Role, CandidateAuthService.CandidateRole)
        }, CandidateAuthentication.Scheme);
        await HttpContext.SignInAsync(CandidateAuthentication.Scheme, new ClaimsPrincipal(identity),
            new AuthenticationProperties { IsPersistent = rememberMe, ExpiresUtc = expiresAt });
        return new CandidateSessionDto(account, expiresAt);
    }
}

public sealed record CsrfTokenDto(string Token, string HeaderName);
