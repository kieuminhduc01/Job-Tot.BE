using System.Security.Claims;
using JobTot.Application.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace JobTot.Api.Controllers;

[ApiController]
[Route("api/candidate/auth")]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class CandidateAuthController(CandidateAuthService service, CandidateTokens tokens, PasswordRecovery recovery) : ControllerBase
{
    [HttpPost("register")]
    [AllowAnonymous]
    [EnableRateLimiting(CandidateAuthentication.RateLimitPolicy)]
    [ProducesResponseType<CandidateSessionDto>(StatusCodes.Status201Created)]
    public async Task<ActionResult<CandidateSessionDto>> Register(CandidateRegisterRequest request, CancellationToken ct)
    {
        var account = await service.RegisterAsync(request, ct);
        var session = await tokens.CreateAsync(account, rememberMe: false, ct);
        return CreatedAtAction(nameof(Me), session);
    }

    [HttpPost("login")]
    [AllowAnonymous]
    [EnableRateLimiting(CandidateAuthentication.RateLimitPolicy)]
    public async Task<ActionResult<CandidateSessionDto>> Login(CandidateLoginRequest request, CancellationToken ct)
        => Ok(await tokens.CreateAsync(await service.LoginAsync(request, ct), request.RememberMe, ct));

    [HttpGet("me")]
    [Authorize(Policy = CandidateAuthentication.Policy)]
    public async Task<ActionResult<CandidateAccountDto>> Me(CancellationToken ct)
    {
        var account = await service.GetActiveAsync(Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!), ct);
        return account is null ? Unauthorized() : Ok(account);
    }

    [HttpPost("forgot-password")]
    [AllowAnonymous]
    [EnableRateLimiting(CandidateAuthentication.RateLimitPolicy)]
    public async Task<IActionResult> ForgotPassword(ForgotPasswordRequest request, CancellationToken ct)
    {
        await recovery.RequestAsync(request.Email, ct);
        return Ok(new { message = "Nếu email liên kết với tài khoản khả dụng, bạn sẽ nhận được hướng dẫn khôi phục mật khẩu." });
    }

    [HttpPost("reset-password")]
    [AllowAnonymous]
    [EnableRateLimiting(CandidateAuthentication.RateLimitPolicy)]
    public async Task<IActionResult> ResetPassword(ResetPasswordRequest request, CancellationToken ct)
    {
        await recovery.ResetAsync(request, ct);
        return NoContent();
    }

    [HttpPost("refresh")]
    [AllowAnonymous]
    [EnableRateLimiting(CandidateAuthentication.RateLimitPolicy)]
    public async Task<ActionResult<CandidateSessionDto>> Refresh(CandidateRefreshRequest request, CancellationToken ct)
        => await tokens.RefreshAsync(request.RefreshToken, ct) is { } session ? Ok(session) : Unauthorized();

    [HttpPost("logout")]
    [AllowAnonymous]
    public async Task<IActionResult> Logout(CandidateRefreshRequest request, CancellationToken ct)
    {
        await tokens.LogoutAsync(request.RefreshToken, ct);
        return NoContent();
    }
}
