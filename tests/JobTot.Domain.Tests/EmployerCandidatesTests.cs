using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using JobTot.Application.Authentication;
using JobTot.Domain.Entities;
using JobTot.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace JobTot.Domain.Tests;
public sealed class EmployerCandidatesTests
{
    [Fact]
    public async Task ImportsOnceMovesStagesSchedulesConfirmsCancelsAndScopesPrivateData()
    {
        await using var factory=new Factory();using var client=factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized,(await client.GetAsync("/api/employer/candidates")).StatusCode);
        using var scope=factory.Services.CreateScope();var db=scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var province=new Province {ProvinceName="Ha Noi",ProvinceCode="01"};var industry=new Industry {IndustryName="IT"};var type=new EmploymentType {TypeName="Full-time"};db.AddRange(province,industry,type);await db.SaveChangesAsync();
        var registration=await client.PostAsJsonAsync("/api/employer/auth/register",new EmployerRegisterRequest {FullName="HR Test",Email="hr@example.com",WorkPhone="0988123456",CompanyName="Company Test",TaxCode="0109867899",HeadOfficeProvinceId=province.Id,Password="testpassword",ConfirmPassword="testpassword",AcceptTerms=true,RecruitmentCommitment=true});
        Assert.Equal(HttpStatusCode.Created,registration.StatusCode);var session=(await registration.Content.ReadFromJsonAsync<EmployerSessionDto>())!;client.DefaultRequestHeaders.Authorization=new("Bearer",session.AccessToken);
        var company=await db.Companies.SingleAsync();var recruiter=await db.RecruiterProfileRecords.SingleAsync();
        var account=new Account {FullName="Candidate Test",Email="candidate@example.com",AccountType="Candidate"};var candidate=new CandidateProfile {Account=account,Headline="Software Engineer",ReadyStatus="looking"};
        var cv=new CandidateCv {Candidate=candidate,Title="Submitted CV",OnlineDocumentJson="{\"name\":\"Candidate Test\"}"};
        var campaign=new RecruitmentCampaign {CompanyId=company.Id,OwnerRecruiterId=recruiter.Id,IndustryId=industry.Id,ProvinceId=province.Id,EmploymentTypeId=type.Id,Title="Engineer",CampaignStatus="Running",Openings=1};
        var stage=new CampaignStage {Campaign=campaign,StageName="Technical",StageOrder=1};var job=new JobPost(campaign.Id,company.Id,"Engineer","Build software","Ha Noi",null,null,DateTimeOffset.UtcNow.AddDays(30));
        var submission=new CandidateJobSubmission {Job=job,Candidate=candidate,Cv=cv,CvTitle=cv.Title,CvContentJson=cv.OnlineDocumentJson,FullName=account.FullName,Phone="0988123456"};
        db.AddRange(account,candidate,cv,campaign,stage,job,submission);await db.SaveChangesAsync();
        var beforeImport = await client.GetFromJsonAsync<JsonElement>("/api/employer/header");
        var newNotice = Assert.Single(beforeImport.GetProperty("notifications").EnumerateArray());
        Assert.Equal("application-" + submission.Id, newNotice.GetProperty("id").GetString());
        Assert.Equal("application", newNotice.GetProperty("kind").GetString());
        Assert.Contains("Candidate Test", newNotice.GetProperty("text").GetString());
        Assert.Equal("/employer/candidates", newNotice.GetProperty("href").GetString());
        Assert.False(newNotice.GetProperty("isRead").GetBoolean());
        using var secondDevice = factory.CreateClient();
        secondDevice.DefaultRequestHeaders.Authorization = client.DefaultRequestHeaders.Authorization;
        var readInput = new { ids = new[] { "application-" + submission.Id } };
        Assert.Equal(HttpStatusCode.NoContent, (await client.PutAsJsonAsync("/api/employer/header/read", readInput)).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await secondDevice.PutAsJsonAsync("/api/employer/header/read", readInput)).StatusCode);
        var otherDeviceHeader = await secondDevice.GetFromJsonAsync<JsonElement>("/api/employer/header");
        Assert.True(Assert.Single(otherDeviceHeader.GetProperty("notifications").EnumerateArray()).GetProperty("isRead").GetBoolean());
        Assert.Equal(HttpStatusCode.OK,(await client.PostAsync("/api/employer/candidates/import",null)).StatusCode);
        Assert.Equal(HttpStatusCode.OK,(await client.PostAsync("/api/employer/candidates/import",null)).StatusCode);Assert.Single(await db.JobApplicationRecords.ToListAsync());
        var afterImport = await client.GetFromJsonAsync<JsonElement>("/api/employer/header");
        Assert.Single(afterImport.GetProperty("notifications").EnumerateArray());
        var importedHistory = await scope.ServiceProvider.GetRequiredService<JobTot.Application.Profiles.ICandidateJobsRepository>()
            .DashboardAsync(account.Id, new JobTot.Application.Profiles.CandidateJobsQuery { Tab = "applied", PageSize = 1 }, default);
        Assert.Equal(1, importedHistory.TotalCount);
        Assert.Equal(1, importedHistory.Stats.Applied);
        Assert.Equal(submission.Id, Assert.Single(importedHistory.Applications).Id);
        Assert.Equal(job.Id, Assert.Single(importedHistory.Jobs).Id);
        var list=await client.GetFromJsonAsync<JsonElement>("/api/employer/candidates");Assert.Equal(1,list.GetProperty("totalCount").GetInt32());
        var campaignList=await client.GetFromJsonAsync<JsonElement>("/api/employer/campaigns");Assert.Equal(1,campaignList.GetProperty("stats").GetProperty("applications").GetInt32());
        Assert.Equal(HttpStatusCode.OK,(await client.GetAsync($"/api/employer/candidates/{submission.Id}/cv")).StatusCode);
        Assert.Equal(HttpStatusCode.OK,(await client.PostAsJsonAsync("/api/employer/candidates/talents",new {applicationId=submission.Id})).StatusCode);
        Assert.Equal(HttpStatusCode.OK,(await client.PostAsJsonAsync("/api/employer/candidates/talents",new {applicationId=submission.Id})).StatusCode);Assert.Single(await db.TalentPoolEntryRecords.ToListAsync());
        var savedList = await client.GetFromJsonAsync<JsonElement>("/api/employer/candidates");
        Assert.True(Assert.Single(savedList.GetProperty("items").EnumerateArray()).GetProperty("isSavedToTalentPool").GetBoolean());
        Assert.Equal(HttpStatusCode.BadRequest,(await client.PostAsJsonAsync("/api/employer/candidates/move",new {applicationIds=new[]{submission.Id,Guid.NewGuid()},stageId=stage.Id})).StatusCode);
        Assert.Equal(HttpStatusCode.OK,(await client.PostAsJsonAsync("/api/employer/candidates/move",new {applicationIds=new[]{submission.Id},stageId=stage.Id})).StatusCode);
        db.ChangeTracker.Clear();Assert.Equal("interview",(await db.CandidateJobSubmissions.SingleAsync()).Status);
        var start=DateTimeOffset.UtcNow.AddDays(1);var schedule=new {applicationId=submission.Id,stageId=stage.Id,start,end=start.AddHours(1),location="Room 1",meetingUrl="https://example.com/meeting"};
        var response=await client.PostAsJsonAsync("/api/employer/candidates/interviews",schedule);Assert.Equal(HttpStatusCode.OK,response.StatusCode);var interviewId=(await response.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();
        Assert.Equal(HttpStatusCode.Conflict,(await client.PostAsJsonAsync("/api/employer/candidates/interviews",schedule)).StatusCode);
        var activity = (await scope.ServiceProvider.GetRequiredService<JobTot.Application.Profiles.ICandidateProfileRepository>().GetAsync(account.Id, default))!.Activity!;
        Assert.Equal(1, activity.Views);
        Assert.Equal(1, activity.Invitations);
        Assert.Equal(company.Id, Assert.Single(activity.Visitors).CompanyId);
        await scope.ServiceProvider.GetRequiredService<JobTot.Application.Profiles.ICandidateJobsRepository>().ConfirmInterviewAsync(account.Id,interviewId,default);db.ChangeTracker.Clear();Assert.Equal("confirmed",(await db.InterviewRecords.SingleAsync()).InterviewStatus);
        Assert.Equal(HttpStatusCode.BadRequest,(await client.PutAsJsonAsync($"/api/employer/candidates/interviews/{interviewId}/feedback",new {score=8,decision="Pass",comment="Good"})).StatusCode);
        Assert.Equal(HttpStatusCode.OK,(await client.PostAsync($"/api/employer/candidates/interviews/{interviewId}/cancel",null)).StatusCode);db.ChangeTracker.Clear();Assert.Equal("cancelled",(await db.InterviewRecords.SingleAsync()).InterviewStatus);
        var cancelledActivity = (await scope.ServiceProvider.GetRequiredService<JobTot.Application.Profiles.ICandidateProfileRepository>().GetAsync(account.Id, default))!.Activity!;
        Assert.Equal(0, cancelledActivity.Invitations);
        Assert.Equal(HttpStatusCode.NotFound,(await client.GetAsync($"/api/employer/candidates/{Guid.NewGuid()}/cv")).StatusCode);
        var past=new Interview {ApplicationId=submission.Id,StageId=stage.Id,ScheduledStart=DateTimeOffset.UtcNow.AddDays(-1),ScheduledEnd=DateTimeOffset.UtcNow.AddDays(-1).AddHours(1),InterviewStatus="pending"};db.InterviewRecords.Add(past);await db.SaveChangesAsync();
        Assert.Equal(HttpStatusCode.OK,(await client.PutAsJsonAsync($"/api/employer/candidates/interviews/{past.Id}/feedback",new {score=8,decision="Pass",comment="Good"})).StatusCode);Assert.Single(await db.InterviewFeedbackRecords.ToListAsync());
        var currentApplication=await db.JobApplicationRecords.AsNoTracking().SingleAsync();
        Assert.Equal(HttpStatusCode.OK,(await client.PutAsJsonAsync($"/api/employer/candidates/{submission.Id}/status",new {state="Hired",revision=currentApplication.UpdatedDate})).StatusCode);
        db.ChangeTracker.Clear();Assert.Equal("hired",(await db.CandidateJobSubmissions.SingleAsync()).Status);
        var hiredHistory = await scope.ServiceProvider.GetRequiredService<JobTot.Application.Profiles.ICandidateJobsRepository>()
            .DashboardAsync(account.Id, new JobTot.Application.Profiles.CandidateJobsQuery { Tab = "hired" }, default);
        Assert.Equal(1, hiredHistory.TotalCount);
        Assert.Equal(1, hiredHistory.Stats.Hired);
        Assert.True(Assert.Single(hiredHistory.Applications).Progress.Completed);
        Assert.Equal(HttpStatusCode.Conflict,(await client.PutAsJsonAsync($"/api/employer/candidates/{submission.Id}/status",new {state="Rejected",revision=currentApplication.UpdatedDate})).StatusCode);
        var other=new Company("Other Company","Private");var foreignCampaign=new RecruitmentCampaign {Company=other,OwnerRecruiterId=recruiter.Id,IndustryId=industry.Id,ProvinceId=province.Id,EmploymentTypeId=type.Id,Title="Private"};var foreignApplication=new JobApplication {Campaign=foreignCampaign,CandidateId=candidate.Id,CvId=cv.Id};db.AddRange(other,foreignCampaign,foreignApplication);await db.SaveChangesAsync();
        Assert.Equal(HttpStatusCode.NotFound,(await client.GetAsync($"/api/employer/candidates/{foreignApplication.Id}/cv")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound,(await client.PostAsJsonAsync("/api/employer/candidates/talents",new {applicationId=foreignApplication.Id})).StatusCode);
        var scopedHeader = await client.GetFromJsonAsync<JsonElement>("/api/employer/header");
        Assert.DoesNotContain(scopedHeader.GetProperty("notifications").EnumerateArray(), n => n.GetProperty("id").GetString() == "application-" + foreignApplication.Id);
    }
    private sealed class Factory:WebApplicationFactory<Program> {
        private readonly string name=Guid.NewGuid().ToString();
        protected override void ConfigureWebHost(IWebHostBuilder builder){builder.UseEnvironment("Development");builder.ConfigureServices(services=>{services.RemoveAll<RecruitmentDbContext>();services.RemoveAll<DbContextOptions<RecruitmentDbContext>>();services.RemoveAll<IDbContextOptionsConfiguration<RecruitmentDbContext>>();services.AddDbContext<RecruitmentDbContext>(options=>options.UseInMemoryDatabase(name));});}
    }
}
