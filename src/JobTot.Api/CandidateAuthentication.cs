using System.Globalization;
using System.Security.Claims;
using System.Threading.RateLimiting;
using JobTot.Application.Authentication;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.RateLimiting;

namespace JobTot.Api;

public static class CandidateAuthentication
{
    public const string Scheme = "CandidateCookie";
    public const string Policy = "CandidateOnly";
    public const string RateLimitPolicy = "CandidateAuth";
    public const string CsrfHeader = "X-CSRF-TOKEN";

    public static IServiceCollection AddCandidateAuthentication(this IServiceCollection services,
        IConfiguration configuration, bool development)
    {
        services.AddAuthentication(Scheme).AddCookie(Scheme, options =>
        {
            options.Cookie.Name = "JobTot.Candidate";
            options.Cookie.HttpOnly = true;
            options.Cookie.SameSite = SameSiteMode.Lax;
            options.Cookie.SecurePolicy = development ? CookieSecurePolicy.SameAsRequest : CookieSecurePolicy.Always;
            options.ExpireTimeSpan = TimeSpan.FromHours(8);
            options.SlidingExpiration = false;
            options.Events = new CookieAuthenticationEvents
            {
                OnRedirectToLogin = context => { context.Response.StatusCode = 401; return Task.CompletedTask; },
                OnRedirectToAccessDenied = context => { context.Response.StatusCode = 403; return Task.CompletedTask; },
                OnValidatePrincipal = async context =>
                {
                    var service = context.HttpContext.RequestServices.GetRequiredService<CandidateAuthService>();
                    if (!Guid.TryParse(context.Principal?.FindFirstValue(ClaimTypes.NameIdentifier), out var id)
                        || await service.GetActiveAsync(id, context.HttpContext.RequestAborted) is null)
                    {
                        context.RejectPrincipal();
                        await context.HttpContext.SignOutAsync(Scheme);
                    }
                }
            };
        });
        services.AddAuthorization(options => options.AddPolicy(Policy,
            policy => policy.AddAuthenticationSchemes(Scheme).RequireAuthenticatedUser()
                .RequireRole(CandidateAuthService.CandidateRole)));
        services.AddAntiforgery(options =>
        {
            options.HeaderName = CsrfHeader;
            options.Cookie.Name = "JobTot.Csrf";
            options.Cookie.HttpOnly = true;
            options.Cookie.SameSite = SameSiteMode.Lax;
            options.Cookie.SecurePolicy = development ? CookieSecurePolicy.SameAsRequest : CookieSecurePolicy.Always;
        });
        services.AddCors(options => options.AddPolicy("CandidateWeb", policy =>
        {
            var origins = configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
            if (origins.Length > 0)
                policy.WithOrigins(origins).AllowAnyHeader().AllowAnyMethod().AllowCredentials();
        }));
        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            options.AddPolicy(RateLimitPolicy, context => RateLimitPartition.GetFixedWindowLimiter(
                context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
                _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = 10, Window = TimeSpan.FromMinutes(1), QueueLimit = 0
                }));
            options.OnRejected = async (context, ct) =>
            {
                if (context.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retry))
                    context.HttpContext.Response.Headers.RetryAfter =
                        Math.Ceiling(retry.TotalSeconds).ToString(CultureInfo.InvariantCulture);
                await Results.Problem(statusCode: 429, title: "Quá nhiều yêu cầu. Vui lòng thử lại sau.")
                    .ExecuteAsync(context.HttpContext);
            };
        });
        return services;
    }
}
