using JobTot.Api;
using JobTot.Application;
using JobTot.Infrastructure;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
// MVC view services register the authorization filter used by AutoValidateAntiforgeryToken.
builder.Services.AddControllersWithViews();
builder.Services.AddOpenApi(options => options.AddOperationTransformer((operation, context, ct) =>
{
    if (context.Description.RelativePath?.StartsWith("api/candidate/auth/") == true &&
        context.Description.HttpMethod == "POST")
    {
        operation.Parameters ??= [];
        operation.Parameters.Add(new OpenApiParameter
        {
            Name = CandidateAuthentication.CsrfHeader, In = ParameterLocation.Header, Required = true,
            Description = "Get token from GET /api/candidate/auth/csrf. Get a fresh token after login/register.",
            Schema = new OpenApiSchema { Type = "string" }
        });
    }
    return Task.CompletedTask;
}));
builder.Services.AddCandidateAuthentication(builder.Configuration, builder.Environment.IsDevelopment());
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<ApiExceptionHandler>();
builder.Services.AddScoped<RecruitmentService>();
builder.Services.AddInfrastructure(builder.Configuration.GetConnectionString("SqlServer")
    ?? throw new InvalidOperationException("ConnectionStrings:SqlServer is required."));
var app = builder.Build();
app.UseExceptionHandler();
app.UseStatusCodePages();
// Allow both local launch profiles without redirecting Swagger's fetch to another origin.
if (!app.Environment.IsDevelopment()) app.UseHttpsRedirection();
app.UseRouting();
app.UseCors("CandidateWeb");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("../openapi/v1.json", "JobTot API v1");
        options.DocumentTitle = "JobTot API";
    });
}
app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "ok" })).ExcludeFromDescription();
app.Run();
public partial class Program;
