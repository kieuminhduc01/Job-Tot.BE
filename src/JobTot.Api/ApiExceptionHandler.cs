using JobTot.Application;
using JobTot.Application.Authentication;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace JobTot.Api;

public sealed class ApiExceptionHandler(ILogger<ApiExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext context, Exception exception, CancellationToken ct)
    {
        var (status, title) = exception switch
        {
            DuplicateAccountException => (409, "Tài khoản đã tồn tại"),
            InvalidCredentialsException => (401, "Đăng nhập không thành công"),
            NotFoundException => (404, "Resource not found"),
            ArgumentException => (400, "Invalid request"),
            InvalidOperationException when exception.Message == "Closed jobs cannot be edited."
                => (409, "Job is closed"),
            DbUpdateConcurrencyException => (409, "Data changed; reload and retry"),
            _ => (500, "An unexpected error occurred")
        };
        if (status == 500) logger.LogError(exception, "Request failed: {TraceId}", context.TraceIdentifier);
        context.Response.StatusCode = status;
        await context.Response.WriteAsJsonAsync(new ProblemDetails
        {
            Status = status, Title = title,
            Detail = status < 500 ? exception.Message : null,
            Instance = context.Request.Path,
            Extensions = { ["traceId"] = context.TraceIdentifier }
        }, options: (System.Text.Json.JsonSerializerOptions?)null,
            contentType: "application/problem+json", cancellationToken: ct);
        return true;
    }
}
