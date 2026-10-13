using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using JobTot.Application.Authentication;
using JobTot.Application.Companies;
using JobTot.Domain.Entities;
using JobTot.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace JobTot.Domain.Tests;
public sealed class EmployerCampaignTests
{
    [Fact]
    public async Task DraftPublishPauseResumeEndRetainStagesAndRejectStaleUpdates()
    {
        await using var factory = new Factory(); using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/employer/campaigns")).StatusCode);
        using var scope = factory.Services.CreateScope(); var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var province = new Province { ProvinceName = "Ha Noi", ProvinceCode = "01" };
        var industry = new Industry { IndustryName = "IT" }; var employment = new EmploymentType { TypeName = "Part-time" };
        db.AddRange(province, industry, employment); await db.SaveChangesAsync();
        var registration = await client.PostAsJsonAsync("/api/employer/auth/register", new EmployerRegisterRequest {
            FullName = "HR Test", Email = "hr@example.com", WorkPhone = "0988123456", CompanyName = "Test Company", TaxCode = "0109867899",
            HeadOfficeProvinceId = province.Id, Password = "testpassword", ConfirmPassword = "testpassword", AcceptTerms = true, RecruitmentCommitment = true });
        Assert.Equal(HttpStatusCode.Created, registration.StatusCode);
        var session = (await registration.Content.ReadFromJsonAsync<EmployerSessionDto>())!;
        client.DefaultRequestHeaders.Authorization = new("Bearer", session.AccessToken);
        var owner = await db.RecruiterProfileRecords.SingleAsync();
        var input = new EmployerCampaignRequest { Title = "Engineer", Department = "Technology", WorkAddress = "Ha Noi", Description = "Build software", Requirements = "Experience",
            IndustryId = industry.Id, ProvinceId = province.Id, EmploymentTypeId = employment.Id, OwnerRecruiterId = owner.Id,
            StartDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-1)), EndDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(30)),
            SalaryMin = 100, SalaryMax = 200, SalaryVisible = false, Skills = ["C#"], Benefits = [new() {Title = "Insurance"}], Stages = [new() {Name = "Screening", Kind = "Online"}] };
        var created = await client.PostAsJsonAsync("/api/employer/campaigns", input); Assert.Equal(HttpStatusCode.OK, created.StatusCode);
        var json = (await created.Content.ReadFromJsonAsync<JsonElement>()); var id = json.GetProperty("id").GetGuid();
        input = json.GetProperty("document").Deserialize<EmployerCampaignRequest>(new JsonSerializerOptions(JsonSerializerDefaults.Web))!;
        Assert.Empty(await db.Jobs.ToListAsync()); var stageId = input.Stages[0].Id;
        input.CampaignStatus = "Running";
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PutAsJsonAsync($"/api/employer/campaigns/{id}", input)).StatusCode);
        var company = await db.Companies.SingleAsync(); company.VerificationStatus = "Verified"; await db.SaveChangesAsync();
        async Task Save(string status) { input.CampaignStatus = status; var response = await client.PutAsJsonAsync($"/api/employer/campaigns/{id}", input); Assert.True(response.StatusCode == HttpStatusCode.OK, await response.Content.ReadAsStringAsync()); input = (await response.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("document").Deserialize<EmployerCampaignRequest>(new JsonSerializerOptions(JsonSerializerDefaults.Web))!; }
        await Save("Running"); db.ChangeTracker.Clear(); var job = await db.Jobs.SingleAsync(); Assert.Equal(id, job.Id); Assert.Null(job.SalaryMin); Assert.Equal("part-time", job.EmploymentType); Assert.False(job.IsClosed);
        var stale = new EmployerCampaignRequest { Title = input.Title, Department = input.Department, WorkAddress = input.WorkAddress, IndustryId = industry.Id, ProvinceId = province.Id, EmploymentTypeId = employment.Id, OwnerRecruiterId = owner.Id };
        Assert.Equal(HttpStatusCode.Conflict, (await client.PutAsJsonAsync($"/api/employer/campaigns/{id}", stale)).StatusCode);
        await Save("Paused"); db.ChangeTracker.Clear(); Assert.True((await db.Jobs.SingleAsync()).IsClosed);
        Assert.Single(input.Skills); Assert.Single(input.Benefits); Assert.Single(input.Stages);
        Assert.Equal(stageId, input.Stages[0].Id);
        await Save("Running"); db.ChangeTracker.Clear(); Assert.False((await db.Jobs.SingleAsync()).IsClosed);
        await Save("Ended"); db.ChangeTracker.Clear(); Assert.True((await db.Jobs.SingleAsync()).IsClosed);
        input.CampaignStatus = "Running"; Assert.Equal(HttpStatusCode.Conflict, (await client.PutAsJsonAsync($"/api/employer/campaigns/{id}", input)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"/api/employer/campaigns/{Guid.NewGuid()}")).StatusCode);
        var list = await client.GetFromJsonAsync<JsonElement>("/api/employer/campaigns?state=Ended"); Assert.Equal(1, list.GetProperty("totalCount").GetInt32());
        Assert.Equal(0, list.GetProperty("stats").GetProperty("running").GetInt32());
    }
    private sealed class Factory : WebApplicationFactory<Program>
    {
        private readonly string name = Guid.NewGuid().ToString();
        protected override void ConfigureWebHost(IWebHostBuilder builder) {
            builder.UseEnvironment("Development"); builder.ConfigureServices(services => {
                services.RemoveAll<RecruitmentDbContext>(); services.RemoveAll<DbContextOptions<RecruitmentDbContext>>();
                services.RemoveAll<IDbContextOptionsConfiguration<RecruitmentDbContext>>();
                services.AddDbContext<RecruitmentDbContext>(options => options.UseInMemoryDatabase(name));
            });
        }
    }
}
