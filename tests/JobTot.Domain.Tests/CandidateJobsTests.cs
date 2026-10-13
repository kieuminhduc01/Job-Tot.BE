using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using JobTot.Application;
using JobTot.Application.Authentication;
using JobTot.Application.Profiles;
using JobTot.Domain.Entities;
using JobTot.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace JobTot.Domain.Tests;

public sealed class CandidateJobsTests
{
    [Fact]
    public async Task SavedJobsArePrivateIdempotentPaginatedAndPersistAfterUnsave()
    {
        await using var factory = new Factory();
        using var owner = factory.CreateClient(); using var other = factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await owner.GetAsync("/api/candidate/my-jobs")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await owner.PutAsync($"/api/candidate/saved-jobs/{Guid.NewGuid()}", null)).StatusCode);
        await Register(owner, "saved-owner@example.com"); await Register(other, "saved-other@example.com");
        var company = new Company("Acme", "A company");
        var jobs = Enumerable.Range(1, 4).Select(i => new JobPost(company.Id, $"Engineer {i}", "Build systems", "Ha Noi", 15000000, 25000000, DateTimeOffset.UtcNow.AddDays(i))).ToArray();
        using (var scope = factory.Services.CreateScope())
        { var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>(); db.Add(company); db.AddRange(jobs); await db.SaveChangesAsync(); }
        foreach (var job in jobs) Assert.Equal(HttpStatusCode.NoContent, (await owner.PutAsync($"/api/candidate/saved-jobs/{job.Id}", null)).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await owner.PutAsync($"/api/candidate/saved-jobs/{jobs[0].Id}", null)).StatusCode);
        Assert.Equal(4, (await owner.GetFromJsonAsync<Guid[]>("/api/candidate/saved-jobs"))!.Length);
        Assert.Empty((await other.GetFromJsonAsync<Guid[]>("/api/candidate/saved-jobs"))!);
        var page = (await owner.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=saved&pageSize=3"))!;
        Assert.Equal(4, page.Stats.Saved); Assert.Equal(4, page.TotalCount); Assert.Equal(3, page.Jobs.Count);
        Assert.Equal(jobs[3].Id, page.Jobs[0].Id);
        Assert.Equal(2, page.Deadlines.Count);
        var second = (await owner.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=saved&pageSize=3&page=2"))!;
        Assert.Single(second.Jobs); Assert.Equal(jobs[0].Id, second.Jobs[0].Id);
        var privatePage = (await other.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs"))!;
        Assert.Equal(0, privatePage.Stats.Saved); Assert.Empty(privatePage.Jobs); Assert.Empty(privatePage.Deadlines);
        Assert.Equal(HttpStatusCode.NoContent, (await other.DeleteAsync($"/api/candidate/saved-jobs/{jobs[0].Id}")).StatusCode);
        Assert.Equal(4, (await owner.GetFromJsonAsync<Guid[]>("/api/candidate/saved-jobs"))!.Length);
        Assert.Equal(HttpStatusCode.NoContent, (await owner.DeleteAsync($"/api/candidate/saved-jobs/{jobs[0].Id}")).StatusCode);
        Assert.Equal(3, (await owner.GetFromJsonAsync<Guid[]>("/api/candidate/saved-jobs"))!.Length);
        Assert.Equal(HttpStatusCode.NotFound, (await owner.PutAsync($"/api/candidate/saved-jobs/{Guid.NewGuid()}", null)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await owner.GetAsync("/api/candidate/my-jobs?tab=invalid")).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await owner.GetAsync("/api/candidate/my-jobs?page=0")).StatusCode);
    }

    [Fact]
    public async Task DashboardUsesOwnApplicationDataAndAvailabilityStaysInSyncWithProfile()
    {
        await using var factory = new Factory();
        using var client = factory.CreateClient(); var account = await Register(client, "dashboard@example.com");
        var profile = (await client.GetFromJsonAsync<CandidateProfileResponse>("/api/candidate/profile"))!.Profile;
        profile.Headline = "Cloud Engineer";
        Assert.Equal(HttpStatusCode.OK, (await client.PutAsJsonAsync("/api/candidate/profile", profile)).StatusCode);
        var company = new Company("Cloud Acme", "Cloud company");
        var job = new JobPost(company.Id, "Cloud Engineer", "Build cloud", "Ha Noi", 15000000, 20000000, DateTimeOffset.UtcNow.AddDays(30));
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var candidate = await db.CandidateProfileRecords.SingleAsync(x => x.AccountId == account);
            var cv = new CandidateCv { CandidateId = candidate.Id, Title = "My CV.pdf", ContentJson = "CV", IsDefault = true };
            db.AddRange(company, job, cv);
            db.CandidateJobSubmissions.Add(new CandidateJobSubmission { JobId = job.Id, CandidateId = candidate.Id, CvId = cv.Id,
                CvTitle = cv.Title, CvContentJson = "Snapshot", FullName = "Candidate", Phone = "0912345678", ReviewedAt = DateTimeOffset.UtcNow });
            await db.SaveChangesAsync();
        }
        Assert.Equal(HttpStatusCode.NoContent, (await client.PutAsync($"/api/candidate/followed-companies/{company.Id}", null)).StatusCode);
        var dashboard = (await client.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=applied"))!;
        Assert.Equal(1, dashboard.Stats.Applied); Assert.Equal(1, dashboard.Stats.Viewed); Assert.Equal(0, dashboard.Stats.Interviews);
        Assert.Equal(job.Id, Assert.Single(dashboard.Jobs).Id); Assert.Equal("My CV.pdf", dashboard.CvTitle);
        Assert.Equal("Cloud Engineer", dashboard.Headline);
        var companies = (await client.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=companies"))!;
        Assert.Equal(0, companies.TotalCount); Assert.Empty(companies.EmployerInterests);
        Assert.Empty(companies.Companies);
        Assert.Equal(HttpStatusCode.NoContent, (await client.PutAsJsonAsync("/api/candidate/my-jobs/availability", new { openToWork = false })).StatusCode);
        Assert.False((await client.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs"))!.OpenToWork);
        Assert.Equal("paused", (await client.GetFromJsonAsync<CandidateProfileResponse>("/api/candidate/profile"))!.Profile.ReadyStatus);
        foreach (var status in new[] { "considering", "paused", "looking" })
        {
            Assert.Equal(HttpStatusCode.NoContent, (await client.PutAsJsonAsync("/api/candidate/my-jobs/status", new { readyStatus = status })).StatusCode);
            var updated = (await client.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs"))!;
            Assert.Equal(status, updated.ReadyStatus);
            Assert.Equal(status == "looking", updated.OpenToWork);
            Assert.Equal(status, (await client.GetFromJsonAsync<CandidateProfileResponse>("/api/candidate/profile"))!.Profile.ReadyStatus);
        }
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PutAsJsonAsync("/api/candidate/my-jobs/status", new { readyStatus = "invalid" })).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PutAsJsonAsync("/api/candidate/my-jobs/status", new { readyStatus = "" })).StatusCode);
    }
    [Fact]
    public async Task EmployerInterestsReadExplicitInterestAndExcludeReviewedOnlyAndOtherCandidates()
    {
        await using var factory = new Factory();
        using var owner = factory.CreateClient();
        using var other = factory.CreateClient();
        var ownerId = await Register(owner, "interest-owner@example.com");
        var otherId = await Register(other, "interest-other@example.com");
        Guid interestId;
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var candidate = await db.CandidateProfileRecords.SingleAsync(x => x.AccountId == ownerId);
            var otherCandidate = await db.CandidateProfileRecords.SingleAsync(x => x.AccountId == otherId);
            var company = new Company("Interested company", "Company");
            var hidden = new Company("Hidden company", "Company") { Status = JobTot.Domain.Enums.EntityStatus.Inactive };
            var hr = new RecruiterProfile { CompanyId = company.Id, Account = new Account { FullName = "HR owner", Email = "hr@example.com" } };
            var interest = new EmployerCandidateInterest { Company = company, CandidateId = candidate.Id, InterestedByRecruiter = hr };
            interestId = interest.Id;
            db.AddRange(company, hidden, hr, interest,
                new EmployerCandidateInterest { CompanyId = company.Id, CandidateId = otherCandidate.Id, InterestedByRecruiter = hr },
                new EmployerCandidateInterest { Company = hidden, CandidateId = candidate.Id, InterestedByRecruiter = hr });
            await db.SaveChangesAsync();
        }
        var first = (await owner.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=companies&pageSize=2"))!;
        Assert.Equal(1, first.TotalCount);
        Assert.Equal(1, first.Stats.InterestedEmployers);
        Assert.Equal(interestId, Assert.Single(first.EmployerInterests).Id);
        Assert.Equal("HR owner", first.EmployerInterests[0].RecruiterName);
        Assert.Null(first.EmployerInterests[0].Position);
        var privatePage = (await other.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=companies"))!;
        Assert.Equal(1, privatePage.TotalCount);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            db.EmployerCandidateInterests.Remove(await db.EmployerCandidateInterests.SingleAsync(x => x.Id == interestId));
            await db.SaveChangesAsync();
        }
        var removed = (await owner.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=companies"))!;
        Assert.Equal(0, removed.TotalCount);
    }
    [Fact]
    public async Task InterviewScheduleCalendarAndConfirmationArePrivateAndPersisted()
    {
        await using var factory = new Factory();
        using var owner = factory.CreateClient();
        using var other = factory.CreateClient();
        var ownerId = await Register(owner, "interview-owner@example.com");
        var otherId = await Register(other, "interview-other@example.com");
        var futureMonth = DateTimeOffset.UtcNow.ToOffset(TimeSpan.FromHours(7)).AddMonths(1);
        var firstStart = new DateTimeOffset(futureMonth.Year, futureMonth.Month, 15, 14, 30, 0, TimeSpan.FromHours(7));
        var pendingId = Guid.NewGuid();
        var cancelledId = Guid.NewGuid();
        var pastId = Guid.NewGuid();
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var candidate = await db.CandidateProfileRecords.SingleAsync(x => x.AccountId == ownerId);
            var otherCandidate = await db.CandidateProfileRecords.SingleAsync(x => x.AccountId == otherId);
            var company = new Company("Interview company", "Company") { VerificationStatus = "Verified" };
            var hrAccount = new Account { FullName = "Recruiter HR", Email = "hr@example.com" };
            var hr = new RecruiterProfile { AccountId = hrAccount.Id, CompanyId = company.Id, JobTitle = "Lead Recruiter" };
            var campaign = new RecruitmentCampaign { CompanyId = company.Id, OwnerRecruiterId = hr.Id,
                Title = "Senior Engineer", Requirements = "Chuẩn bị tài khoản GitHub và dự án thực tế." };
            var stage = new CampaignStage { CampaignId = campaign.Id, StageName = "Technical interview", StageOrder = 2 };
            var application = new JobApplication { CandidateId = candidate.Id, CampaignId = campaign.Id };
            var otherApplication = new JobApplication { CandidateId = otherCandidate.Id, CampaignId = campaign.Id };
            db.AddRange(company, hrAccount, hr, campaign, stage, application, otherApplication);
            db.InterviewRecords.AddRange(
                new Interview { ApplicationId = application.Id, StageId = stage.Id, ScheduledStart = firstStart,
                    ScheduledEnd = firstStart.AddMinutes(60), MeetingUrl = "https://meet.example.com/room", InterviewStatus = "confirmed" },
                new Interview { Id = pendingId, ApplicationId = application.Id, StageId = stage.Id, ScheduledStart = firstStart.AddDays(1),
                    ScheduledEnd = firstStart.AddDays(1).AddMinutes(45), MeetingUrl = "https://meet.example.com/proposal", InterviewStatus = "pending" },
                new Interview { ApplicationId = application.Id, StageId = stage.Id, ScheduledStart = firstStart.AddDays(2),
                    ScheduledEnd = firstStart.AddDays(2).AddMinutes(60), Location = "Tầng 28, Keangnam", InterviewStatus = "confirmed" },
                new Interview { Id = cancelledId, ApplicationId = application.Id, StageId = stage.Id, ScheduledStart = firstStart.AddDays(3),
                    ScheduledEnd = firstStart.AddDays(3).AddMinutes(60), InterviewStatus = "cancelled" },
                new Interview { Id = pastId, ApplicationId = application.Id, StageId = stage.Id, ScheduledStart = DateTimeOffset.UtcNow.AddDays(-1),
                    ScheduledEnd = DateTimeOffset.UtcNow.AddDays(-1).AddHours(1), InterviewStatus = "pending" },
                new Interview { ApplicationId = otherApplication.Id, StageId = stage.Id, ScheduledStart = firstStart.AddDays(4),
                    ScheduledEnd = firstStart.AddDays(4).AddMinutes(60), InterviewStatus = "confirmed" });
            await db.SaveChangesAsync();
        }
        var calendarQuery = $"calendarMonth={firstStart:yyyy-MM}&timeZoneOffsetMinutes=420";
        var dashboard = (await owner.GetFromJsonAsync<CandidateJobsDashboard>($"/api/candidate/my-jobs?tab=interviews&pageSize=2&{calendarQuery}"))!;
        Assert.Equal(3, dashboard.Stats.Interviews);
        Assert.Equal(3, dashboard.TotalCount);
        Assert.Equal(2, dashboard.Interviews.Count);
        Assert.Equal(3, dashboard.InterviewCalendar.Count); // Includes appointments beyond the current page.
        Assert.Equal(2, dashboard.InterviewCalendar.Count(x => x.Online));
        Assert.Equal("Recruiter HR", dashboard.Interviews[0].RecruiterName);
        Assert.Equal("hr@example.com", dashboard.Interviews[0].RecruiterEmail);
        Assert.Equal("Technical interview", dashboard.Interviews[0].StageName);
        Assert.True(dashboard.Interviews[0].CompanyVerified);
        var filtered = (await owner.GetFromJsonAsync<CandidateJobsDashboard>($"/api/candidate/my-jobs?tab=interviews&{calendarQuery}&interviewDate={firstStart.AddDays(1):yyyy-MM-dd}"))!;
        Assert.Equal(1, filtered.TotalCount);
        Assert.Equal(pendingId, Assert.Single(filtered.Interviews).Id);
        Assert.Equal(3, filtered.InterviewCalendar.Count);
        var appliedSummary = (await owner.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=applied"))!;
        Assert.Equal(firstStart, appliedSummary.NextInterview!.Start);
        Assert.Equal("hr@example.com", appliedSummary.NextInterview.RecruiterEmail);
        Assert.Single(appliedSummary.Applications); // Campaign applications share the candidate history.
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var application = await db.JobApplicationRecords.SingleAsync(x => x.Id == appliedSummary.Applications[0].Id);
            application.ApplicationStatus = "Offer";
            await db.SaveChangesAsync();
        }
        var offered = (await owner.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=applied"))!;
        Assert.Equal("Đã gửi offer", Assert.Single(offered.Applications).Progress.Label);
        var noHire = (await owner.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=hired"))!;
        Assert.Empty(noHire.Applications);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var application = await db.JobApplicationRecords.SingleAsync(x => x.Id == appliedSummary.Applications[0].Id);
            application.ApplicationStatus = "Hired";
            await db.SaveChangesAsync();
        }
        var hiredCampaign = (await owner.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=hired"))!;
        Assert.Equal(1, hiredCampaign.Stats.Hired);
        Assert.True(Assert.Single(hiredCampaign.Applications).Progress.Completed);
        Assert.Equal("Senior Engineer", Assert.Single(hiredCampaign.Jobs).Title);
        var otherHires = (await other.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=hired"))!;
        Assert.Empty(otherHires.Applications);
        // IDs are unique within each table, but can overlap across the two sources.
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var candidate = await db.CandidateProfileRecords.SingleAsync(x => x.AccountId == ownerId);
            var companyId = hiredCampaign.Jobs[0].CompanyId;
            var job = new JobPost(companyId, "Direct submission", "Description", "Ha Noi", null, null, DateTimeOffset.UtcNow.AddDays(30));
            var cv = new CandidateCv { CandidateId = candidate.Id, Title = "CV", ContentJson = "{}" };
            db.AddRange(job, cv);
            db.CandidateJobSubmissions.Add(new CandidateJobSubmission {
                Id = appliedSummary.Applications[0].Id, CandidateId = candidate.Id,
                JobId = job.Id, CvId = cv.Id, Status = "submitted", AppliedAt = DateTimeOffset.UtcNow
            });
            await db.SaveChangesAsync();
        }
        var overlappingIds = (await owner.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=applied"))!;
        Assert.Equal(2, overlappingIds.TotalCount);
        Assert.Equal(2, overlappingIds.Applications.Count);
        Assert.Single(overlappingIds.Applications.Where(x => x.DetailUrl != null));
        Assert.Single(overlappingIds.Applications.Where(x => x.DetailUrl == null));
        Assert.Contains(overlappingIds.Applications, x => x.Progress.Label == "Mới ứng tuyển");
        Assert.Contains(overlappingIds.Applications, x => x.Progress.Completed);
        var otherSummary = (await other.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=applied"))!;
        Assert.Equal(firstStart.AddDays(4), otherSummary.NextInterview!.Start);
        Assert.Equal(HttpStatusCode.NotFound, (await other.PutAsync($"/api/candidate/interviews/{pendingId}/confirm", null)).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await owner.PutAsync($"/api/candidate/interviews/{pendingId}/confirm", null)).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await owner.PutAsync($"/api/candidate/interviews/{pendingId}/confirm", null)).StatusCode);
        var updated = (await owner.GetFromJsonAsync<CandidateJobsDashboard>($"/api/candidate/my-jobs?tab=interviews&{calendarQuery}"))!;
        Assert.Equal("confirmed", updated.Interviews.Single(x => x.Id == pendingId).Status);
        Assert.Equal(HttpStatusCode.Conflict, (await owner.PutAsync($"/api/candidate/interviews/{cancelledId}/confirm", null)).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await owner.PutAsync($"/api/candidate/interviews/{pastId}/confirm", null)).StatusCode);
        var privatePage = (await other.GetFromJsonAsync<CandidateJobsDashboard>($"/api/candidate/my-jobs?tab=interviews&{calendarQuery}"))!;
        Assert.Single(privatePage.Interviews);
        Assert.Single(privatePage.InterviewCalendar);
        Assert.Equal(HttpStatusCode.BadRequest, (await owner.GetAsync("/api/candidate/my-jobs?tab=interviews&calendarMonth=2026-99")).StatusCode);
    }
    [Fact]
    public async Task AppliedJobsExposeRecordedProgressContactAndStablePrivatePagination()
    {
        await using var factory = new Factory();
        using var owner = factory.CreateClient();
        using var other = factory.CreateClient();
        var ownerId = await Register(owner, "applied-owner@example.com");
        var otherId = await Register(other, "applied-other@example.com");
        var statuses = new[] { "submitted", "reviewed", "accepted", "interview", "offered", "hired", "rejected", "unmapped_status", "submitted" };
        var now = DateTimeOffset.UtcNow;
        var company = new Company("Application company", "Company");
        var inactive = new Company("Inactive company", "Excluded") { Status = JobTot.Domain.Enums.EntityStatus.Inactive };
        var jobs = statuses.Select((_, index) => new JobPost(company.Id, $"Engineer {index}", "Description", "Ha Noi",
            35000000, 55000000, now.AddDays(30))).ToArray();
        foreach (var job in jobs) job.SetCandidateDetails(null, null, null, null, null, "Recruiter owner", "HR", "hr@example.com");
        jobs[8].Close(); // Closed postings remain available in the application history.
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var candidate = await db.CandidateProfileRecords.SingleAsync(x => x.AccountId == ownerId);
            var otherCandidate = await db.CandidateProfileRecords.SingleAsync(x => x.AccountId == otherId);
            var cv = new CandidateCv { CandidateId = candidate.Id, Title = "Owner CV", ContentJson = "Owner private CV" };
            var otherCv = new CandidateCv { CandidateId = otherCandidate.Id, Title = "Other CV", ContentJson = "Other private CV" };
            var inactiveJob = new JobPost(inactive.Id, "Hidden", "Description", "Ha Noi", null, null, now.AddDays(30));
            db.AddRange(company, inactive, cv, otherCv, inactiveJob);
            db.AddRange(jobs);
            for (var index = 0; index < statuses.Length; index++)
                db.CandidateJobSubmissions.Add(new CandidateJobSubmission { CandidateId = candidate.Id, CvId = cv.Id,
                    JobId = jobs[index].Id, CvTitle = "CV snapshot", Status = statuses[index], AppliedAt = now.AddMinutes(-index),
                    ReviewedAt = index is 0 or 7 ? null : now });
            db.CandidateJobSubmissions.Add(new CandidateJobSubmission { CandidateId = candidate.Id, CvId = cv.Id,
                JobId = inactiveJob.Id, Status = "hired", AppliedAt = now.AddMinutes(1) });
            db.CandidateJobSubmissions.Add(new CandidateJobSubmission { CandidateId = otherCandidate.Id, CvId = otherCv.Id,
                JobId = jobs[0].Id, Status = "hired", AppliedAt = now.AddMinutes(1) });
            await db.SaveChangesAsync();
        }
        var first = (await owner.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=applied&pageSize=4"))!;
        Assert.Equal(9, first.TotalCount);
        Assert.Equal(9, first.Stats.Applied);
        Assert.Equal(jobs.Take(4).Select(x => x.Id), first.Jobs.Select(x => x.Id));
        Assert.Equal(new[] { 1, 1, 1, 2 }, first.Applications.Select(x => x.Progress.CurrentStep));
        Assert.Equal("Đang phỏng vấn", first.Applications[3].Progress.Label);
        Assert.All(first.Applications, x => {
            Assert.NotEqual(Guid.Empty, x.Id);
            Assert.Equal("CV snapshot", x.CvTitle);
            Assert.Equal("Recruiter owner", x.RecruiterName);
            Assert.Equal("hr@example.com", x.RecruiterEmail);
        });
        Assert.Null(first.Applications[0].ReviewedAt); // Loading the tab must not invent a CV view.
        Assert.Null(first.NextInterview);
        var second = (await owner.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=applied&pageSize=4&page=2"))!;
        Assert.Equal(new[] { 3, 4, 5, 1 }, second.Applications.Select(x => x.Progress.CurrentStep));
        Assert.False(second.Applications[0].Progress.Completed); // An offer is not a confirmed hire.
        Assert.True(second.Applications[1].Progress.Completed);
        Assert.True(second.Applications[2].Progress.Stopped);
        Assert.Equal("Mới ứng tuyển", second.Applications[3].Progress.Label);
        var third = (await owner.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=applied&pageSize=4&page=3"))!;
        Assert.True(Assert.Single(third.Jobs).IsClosed);
        Assert.Equal(1, Assert.Single(third.Applications).Progress.CurrentStep);
        var hired = (await owner.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=hired"))!;
        Assert.Equal(1, hired.TotalCount);
        Assert.Equal(1, hired.Stats.Hired);
        Assert.Equal(jobs[5].Id, Assert.Single(hired.Jobs).Id);
        Assert.True(Assert.Single(hired.Applications).Progress.Completed);
        var privatePage = (await other.GetFromJsonAsync<CandidateJobsDashboard>("/api/candidate/my-jobs?tab=applied"))!;
        Assert.Equal(1, privatePage.TotalCount);
        Assert.True(Assert.Single(privatePage.Applications).Progress.Completed);
    }
    private static async Task<Guid> Register(HttpClient client, string email)
    {
        var response = await client.PostAsJsonAsync("/api/candidate/auth/register", new { fullName = "Candidate", emailOrPhone = email, password = "matkhau123", confirmPassword = "matkhau123" });
        var session = (await response.Content.ReadFromJsonAsync<CandidateSessionDto>())!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", session.AccessToken);
        return session.Account.Id;
    }
    private sealed class Factory : WebApplicationFactory<Program>
    {
        private readonly string database = Guid.NewGuid().ToString();
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Development");
            builder.ConfigureServices(services => {
                services.RemoveAll<RecruitmentDbContext>(); services.RemoveAll<DbContextOptions<RecruitmentDbContext>>();
                services.RemoveAll<IDbContextOptionsConfiguration<RecruitmentDbContext>>();
                services.AddDbContext<RecruitmentDbContext>(options => options.UseInMemoryDatabase(database));
            });
        }
    }
}
