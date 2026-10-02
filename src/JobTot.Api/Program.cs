using JobTot.Api;
using JobTot.Application;
using JobTot.Infrastructure;
using Microsoft.OpenApi.Models;
using Microsoft.AspNetCore.Authorization;

var builder = WebApplication.CreateBuilder(args);
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Services.AddControllers();
builder.Services.AddOpenApi(options =>
{
    options.AddDocumentTransformer((document, context, ct) =>
    {
        document.Components ??= new OpenApiComponents();
        document.Components.SecuritySchemes["Bearer"] = new OpenApiSecurityScheme
        {
            Type = SecuritySchemeType.Http, Scheme = "bearer", BearerFormat = "JWT"
        };
        return Task.CompletedTask;
    });
    options.AddOperationTransformer((operation, context, ct) =>
    {
        var metadata = context.Description.ActionDescriptor.EndpointMetadata;
        if (metadata.OfType<IAuthorizeData>().Any() && !metadata.OfType<IAllowAnonymous>().Any())
            operation.Security = [new OpenApiSecurityRequirement
            {
                [new OpenApiSecurityScheme { Reference = new OpenApiReference
                    { Type = ReferenceType.SecurityScheme, Id = "Bearer" } }] = []
            }];
        return Task.CompletedTask;
    });
});
builder.Services.AddCandidateAuthentication(builder.Configuration, builder.Environment.IsDevelopment());
builder.Services.AddScoped<PasswordRecovery>();
builder.Services.AddScoped<IRecoveryEmailSender, SmtpRecoveryEmailSender>();
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
