using System.Reflection;
using System.Linq.Expressions;
using JobTot.Api;
using JobTot.Api.Controllers;
using JobTot.Application;
using JobTot.Application.Authentication;
using JobTot.Infrastructure;
using JobTot.Infrastructure.Persistence;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.IdentityModel.Tokens;

namespace JobTot.Domain.Tests;

public sealed class ExceptionBoundaryTests
{
    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public async Task RefreshQueryFailureIsNotConvertedIntoInvalidCredentials(bool cancelled)
    {
        Exception failure = cancelled ? new TaskCanceledException("Connection cancelled")
            : new InvalidOperationException("Connection failed");
        await using var db = new RecruitmentDbContext(new DbContextOptionsBuilder<RecruitmentDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).EnableServiceProviderCaching(false)
            .AddInterceptors(new FailQuery(failure)).Options);
        var service = new CandidateAuthService(new CandidateAuthRepository(db), new AccountPasswordHasher());
        var tokens = new CandidateTokens(db, service,
            new CandidateJwtSettings("test", "test", new SymmetricSecurityKey(new byte[32])));
        var controller = new CandidateAuthController(service, tokens, null!, null!);

        var caught = await Record.ExceptionAsync(() => controller.Refresh(
            new CandidateRefreshRequest { RefreshToken = $"{Guid.NewGuid():N}.secret" }, default));

        Assert.Same(failure, caught);
        if (cancelled) Assert.False(failure.Data.Contains(ExceptionDiagnostics.OperationsKey));
        else Assert.Equal(new[] { "CandidateTokens.RefreshAsync", "CandidateAuthController.Refresh" },
            Assert.IsType<List<string>>(failure.Data[ExceptionDiagnostics.OperationsKey]));
    }

    [Fact]
    public async Task AsyncFailureKeepsOriginalExceptionAndRecordsServiceAndController()
    {
        var failure = new InvalidOperationException("Database unavailable");
        var repository = DispatchProxy.Create<IRecruitmentRepository, FailingRepository>();
        ((FailingRepository)repository).Failure = failure;
        var controller = new JobsController(new RecruitmentService(repository));

        var caught = await Assert.ThrowsAsync<InvalidOperationException>(() => controller.Filters(default));

        Assert.Same(failure, caught);
        Assert.Equal(new[] { "RecruitmentService.GetJobFiltersAsync", "JobsController.Filters" },
            Assert.IsType<List<string>>(caught.Data[ExceptionDiagnostics.OperationsKey]));
    }

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public async Task CancellationPassesThroughServiceAndControllerToMiddleware(bool disconnect)
    {
        using var cancellation = new CancellationTokenSource();
        var failure = new TaskCanceledException("Read cancelled", null, cancellation.Token);
        var repository = DispatchProxy.Create<IRecruitmentRepository, FailingRepository>();
        var proxy = (FailingRepository)repository;
        proxy.Failure = failure;
        var controller = new JobsController(new RecruitmentService(repository));
        var context = new DefaultHttpContext { RequestAborted = cancellation.Token };
        await using var body = new MemoryStream();
        context.Response.Body = body;
        var middleware = new RequestCancellationMiddleware(async ctx =>
        {
            if (disconnect) cancellation.Cancel();
            await controller.Filters(ctx.RequestAborted);
        });

        if (disconnect)
        {
            await middleware.InvokeAsync(context);
            Assert.Equal(499, context.Response.StatusCode);
            Assert.Equal(0, body.Length);
        }
        else
        {
            Assert.Same(failure, await Assert.ThrowsAsync<TaskCanceledException>(() => middleware.InvokeAsync(context)));
        }
        Assert.Equal(cancellation.Token, proxy.ReceivedToken);
        Assert.False(failure.Data.Contains(ExceptionDiagnostics.OperationsKey));
    }

    public class FailingRepository : DispatchProxy
    {
        public Exception Failure { get; set; } = null!;
        public CancellationToken ReceivedToken { get; private set; }

        protected override object? Invoke(MethodInfo? targetMethod, object?[]? args)
        {
            Assert.Equal(nameof(IRecruitmentRepository.GetJobFiltersAsync), targetMethod!.Name);
            ReceivedToken = (CancellationToken)args![0]!;
            return Task.FromException<JobDirectoryMetadata>(Failure);
        }
    }

    private sealed class FailQuery(Exception failure) : IQueryExpressionInterceptor
    {
        public Expression QueryCompilationStarting(Expression queryExpression, QueryExpressionEventData eventData)
            => throw failure;
    }
}
