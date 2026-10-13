using System.Security.Claims;
using JobTot.Api;
using JobTot.Application.Authentication;
using JobTot.Domain.Entities;
using JobTot.Infrastructure;
using JobTot.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace JobTot.Domain.Tests;

public sealed class JwtCancellationTests
{
    [Theory]
    [InlineData(true, CandidateAuthentication.Scheme, false)]
    [InlineData(false, CandidateAuthentication.Scheme, false)]
    [InlineData(true, EmployerAuthentication.Scheme, true)]
    [InlineData(false, EmployerAuthentication.Scheme, true)]
    [InlineData(true, CandidateAuthentication.Scheme, true)]
    [InlineData(false, CandidateAuthentication.Scheme, true)]
    [InlineData(true, AdminAuthentication.Scheme, true)]
    [InlineData(false, AdminAuthentication.Scheme, true)]
    public async Task JwtHandlesOnlyClientCancellation(bool disconnect, string scheme, bool sql)
    {
        using var cancellation = new CancellationTokenSource();
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddCandidateAuthentication(new ConfigurationBuilder().Build(), true);
        services.AddEmployerAuthentication(); services.AddAdminAuthentication();
        Exception failure = sql ? CancelledSqlCommand() : new TaskCanceledException();
        services.AddDbContext<RecruitmentDbContext>(options => options.UseInMemoryDatabase(Guid.NewGuid().ToString())
            // A cached query from another test must not bypass this interceptor.
            .EnableServiceProviderCaching(false)
            .AddInterceptors(new CancelQuery(() => { if (disconnect) cancellation.Cancel(); }, failure)));
        services.AddScoped<ICandidateAuthRepository, CandidateAuthRepository>();
        services.AddScoped<CandidateAuthService>();
        services.AddScoped<IEmployerAuthRepository, EmployerAuthRepository>();
        services.AddScoped<EmployerAuthService>();
        services.AddSingleton<IAccountPasswordHasher, AccountPasswordHasher>();
        await using var provider = services.BuildServiceProvider();
        await using var scope = provider.CreateAsyncScope();
        var options = provider.GetRequiredService<IOptionsMonitor<JwtBearerOptions>>().Get(scheme);
        var http = new DefaultHttpContext { RequestServices = scope.ServiceProvider, RequestAborted = cancellation.Token };
        var context = new TokenValidatedContext(http, new AuthenticationScheme(scheme, null, typeof(JwtBearerHandler)), options)
        {
            Principal = new ClaimsPrincipal(new ClaimsIdentity([new Claim(ClaimTypes.NameIdentifier, Guid.NewGuid().ToString()), new Claim("sid", Guid.NewGuid().ToString())]))
        };
        if (!disconnect)
            Assert.Same(failure, await Record.ExceptionAsync(() => options.Events.TokenValidated(context)));
        else
        {
            await options.Events.TokenValidated(context);
            Assert.True(context.Result!.None);
            var called = false;
            await new RequestCancellationMiddleware(_ => { called = true; return Task.CompletedTask; }).InvokeAsync(http);
            Assert.False(called);
            Assert.Equal(499, http.Response.StatusCode);
        }
    }

    [Fact]
    public async Task AuthenticationAccountReadDoesNotMaterializeAvatarOrProfileJson()
    {
        await using var db = new RecruitmentDbContext(new DbContextOptionsBuilder<RecruitmentDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
        var account = new Account { FullName = "Candidate", AccountType = "Candidate", AccountStatus = "Active", PasswordHash = "hash" };
        account.CandidateProfile = new CandidateProfile { AccountId = account.Id, Account = account, DetailsJson = new string('x', 2800000) };
        db.Add(account); await db.SaveChangesAsync(); db.ChangeTracker.Clear();
        var loaded = await new CandidateAuthRepository(db).GetAsync(account.Id, default);
        Assert.NotNull(loaded);
        Assert.True(CandidateAuthService.IsActiveCandidate(loaded));
        Assert.Null(loaded.CandidateProfile!.DetailsJson);
        Assert.Equal(account.PasswordHash, loaded.PasswordHash);
    }

    [Fact]
    public void DisconnectDoesNotSuppressUnrelatedSqlFailures()
    {
        Assert.False(RequestCancellation.IsClientCancellation(CancelledSqlCommand("Database unavailable"), new CancellationToken(true)));
        Assert.False(RequestCancellation.IsClientCancellation(CancelledSqlCommand(), CancellationToken.None));
    }

    private static Microsoft.Data.SqlClient.SqlException CancelledSqlCommand(string message = "Operation cancelled by user.")
    {
        const System.Reflection.BindingFlags flags = System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance;
        var constructor = typeof(Microsoft.Data.SqlClient.SqlError).GetConstructors(flags).First(c => c.GetParameters().Length == 9);
        var error = constructor.Invoke([0, (byte)0, (byte)11, "test", message, "", 0, (uint)0, null]);
        var errors = (Microsoft.Data.SqlClient.SqlErrorCollection)Activator.CreateInstance(typeof(Microsoft.Data.SqlClient.SqlErrorCollection), true)!;
        typeof(Microsoft.Data.SqlClient.SqlErrorCollection).GetMethod("Add", flags)!.Invoke(errors, [error]);
        var create = typeof(Microsoft.Data.SqlClient.SqlException).GetMethods(System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static)
            .First(m => m.Name == "CreateException" && m.GetParameters().Length == 2);
        return (Microsoft.Data.SqlClient.SqlException)create.Invoke(null, [errors, "16.0"])!;
    }

    private sealed class CancelQuery(Action cancel, Exception failure) : IQueryExpressionInterceptor
    {
        public System.Linq.Expressions.Expression QueryCompilationStarting(System.Linq.Expressions.Expression query, QueryExpressionEventData eventData)
        { cancel(); throw failure; }
    }
}
