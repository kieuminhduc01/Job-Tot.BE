using System.Linq.Expressions;
using System.Security.Claims;
using JobTot.Api.Controllers;
using JobTot.Domain.Entities;
using JobTot.Domain.Enums;
using JobTot.Infrastructure.Persistence;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.EntityFrameworkCore.Query;

namespace JobTot.Domain.Tests;

public sealed class TalentDiscoveryCancellationTests
{
    [Theory]
    [InlineData("metadata")]
    [InlineData("list")]
    [InlineData("detail")]
    [InlineData("interest")]
    [InlineData("saved")]
    public async Task AbortedRequestsReturn499WithoutStartingQueries(string endpoint)
    {
        await using var db = new RecruitmentDbContext(new DbContextOptionsBuilder<RecruitmentDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
        var controller = new EmployerTalentDiscoveryController(db)
        {
            ControllerContext = new() { HttpContext = new DefaultHttpContext { RequestAborted = new CancellationToken(true) } }
        };
        var result = await Invoke(controller, endpoint, new CancellationToken(true));
        Assert.Equal(499, Assert.IsType<StatusCodeResult>(result).StatusCode);
    }

    [Theory]
    [InlineData("metadata")]
    [InlineData("list")]
    [InlineData("detail")]
    public async Task CancellationDuringCandidateQueryReturns499(string endpoint)
    {
        using var cancellation = new CancellationTokenSource();
        var interceptor = new CandidateQueryFailure(cancellation, cancel: true, databaseFailure: false);
        await using var db = CreateDb(interceptor);
        var controller = await Controller(db, cancellation.Token);
        var result = await Invoke(controller, endpoint, cancellation.Token);
        Assert.True(interceptor.Triggered);
        Assert.Equal(499, Assert.IsType<StatusCodeResult>(result).StatusCode);
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task UnrelatedFailuresAreNotReportedAsClientCancellation(bool databaseFailure)
    {
        using var cancellation = new CancellationTokenSource();
        var interceptor = new CandidateQueryFailure(cancellation, cancel: databaseFailure, databaseFailure);
        await using var db = CreateDb(interceptor);
        var controller = await Controller(db, cancellation.Token);
        if (databaseFailure)
            await Assert.ThrowsAsync<InvalidOperationException>(() => controller.List(new(), cancellation.Token));
        else
            await Assert.ThrowsAsync<TaskCanceledException>(() => controller.List(new(), cancellation.Token));
        Assert.True(interceptor.Triggered);
    }

    private static RecruitmentDbContext CreateDb(CandidateQueryFailure interceptor) => new(
        new DbContextOptionsBuilder<RecruitmentDbContext>().UseInMemoryDatabase(Guid.NewGuid().ToString())
            .AddInterceptors(interceptor).Options);

    private static async Task<EmployerTalentDiscoveryController> Controller(RecruitmentDbContext db, CancellationToken ct)
    {
        var account = new Account { FullName = "Recruiter", AccountType = "Employer", AccountStatus = "Active", Status = EntityStatus.Active };
        db.Add(new RecruiterProfile { Account = account, Company = new Company("Company", ""), Status = EntityStatus.Active });
        await db.SaveChangesAsync();
        return new(db)
        {
            ControllerContext = new() { HttpContext = new DefaultHttpContext
            {
                RequestAborted = ct,
                User = new ClaimsPrincipal(new ClaimsIdentity([new Claim(ClaimTypes.NameIdentifier, account.Id.ToString())], "test"))
            } }
        };
    }

    private static Task<IActionResult> Invoke(EmployerTalentDiscoveryController controller, string endpoint, CancellationToken ct) => endpoint switch
    {
        "metadata" => controller.Metadata(ct),
        "list" => controller.List(new(), ct),
        "detail" => controller.Get(Guid.NewGuid(), null, ct),
        "interest" => controller.Interest(Guid.NewGuid(), new(true), ct),
        "saved" => controller.Saved(Guid.NewGuid(), new(true), ct),
        _ => throw new ArgumentOutOfRangeException(nameof(endpoint))
    };

    private sealed class CandidateQueryFailure(CancellationTokenSource cancellation, bool cancel, bool databaseFailure) : IQueryExpressionInterceptor
    {
        public bool Triggered { get; private set; }
        public Expression QueryCompilationStarting(Expression queryExpression, QueryExpressionEventData eventData)
        {
            var finder = new CandidateRootFinder();
            finder.Visit(queryExpression);
            if (finder.Found)
            {
                Triggered = true;
                if (cancel) cancellation.Cancel();
                if (databaseFailure) throw new InvalidOperationException("Database failure");
                throw new TaskCanceledException("Query canceled", null, cancellation.Token);
            }
            return queryExpression;
        }
    }

    private sealed class CandidateRootFinder : ExpressionVisitor
    {
        public bool Found { get; private set; }
        protected override Expression VisitExtension(Expression node)
        {
            if (node is EntityQueryRootExpression root && root.EntityType.ClrType == typeof(CandidateProfile)) Found = true;
            return base.VisitExtension(node);
        }
    }
}
