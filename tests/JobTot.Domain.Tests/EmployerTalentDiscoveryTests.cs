using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using JobTot.Application.Authentication;
using JobTot.Application.Profiles;
using JobTot.Domain.Entities;
using JobTot.Domain.Enums;
using JobTot.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace JobTot.Domain.Tests;

public sealed class EmployerTalentDiscoveryTests
{
    [Fact]
    public async Task DiscoveryRanksProfessionalProfilesFiltersAndProtectsPrivateData()
    {
        await using var factory = new Factory();
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/employer/talent-discovery")).StatusCode);
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var city = new Province { ProvinceName = "Hà Nội", ProvinceCode = "01" };
        var otherCity = new Province { ProvinceName = "Đà Nẵng", ProvinceCode = "48" };
        var industry = new Industry { IndustryName = "IT" };
        var type = new EmploymentType { TypeName = "Full-time" };
        db.AddRange(city, otherCity, industry, type);
        await db.SaveChangesAsync();
        var companyId = await Register(client, city.Id, "one");
        var recruiter = await db.RecruiterProfileRecords.SingleAsync();
        var strong = Candidate("Ứng viên phù hợp", city.Id, "React Developer", 5, "looking", new CandidateProfileDocument
        {
            FullName = "Ứng viên phù hợp", Headline = "React Developer", Location = "Hà Nội",
            DesiredPosition = "React Developer", BirthDate = new DateOnly(1999, 3, 7), Gender = "Nữ",
            Skills = [new() { Title = "React" }, new() { Title = "TypeScript" }],
            Experiences = [new() { Title = "Frontend Developer", Organization = "Previous company", Period = "2020 - 2025" }],
            Education = [new() { Title = "Software Engineering" }]
        });
        strong.CandidateCvs.Add(new CandidateCv { Candidate = strong, Title = "Private CV", ContentJson = "PRIVATE_CV_SECRET" });
        var weak = Candidate("Ứng viên khác", otherCity.Id, "Java Developer", 1, "considering",
            new() { Skills = [new() { Title = "Java" }], DesiredProvinceId = city.Id });
        var paused = Candidate("Hidden profile", city.Id, "React Developer", 6, "paused");
        var inactive = Candidate("Inactive profile", city.Id, "React Developer", 6, "looking");
        inactive.Status = EntityStatus.Inactive;
        var disabled = Candidate("Disabled account", city.Id, "React Developer", 6, "looking");
        disabled.Account.Status = EntityStatus.Inactive;
        var locked = Candidate("Locked account", city.Id, "React Developer", 6, "looking");
        locked.Account.AccountStatus = "Locked";
        var react = new Skill { SkillName = "React" };
        var ts = new Skill { SkillName = "TypeScript" };
        var campaign = new RecruitmentCampaign
        {
            CompanyId = companyId, OwnerRecruiterId = recruiter.Id, IndustryId = industry.Id,
            ProvinceId = city.Id, EmploymentTypeId = type.Id, Title = "React Developer", CampaignStatus = "Running",
            ExperienceMinYears = 3, EndDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(30)),
            CampaignSkills = [new() { Skill = react, IsRequired = true }, new() { Skill = ts, IsRequired = true }]
        };
        var ended = new RecruitmentCampaign
        {
            CompanyId = companyId, OwnerRecruiterId = recruiter.Id, IndustryId = industry.Id,
            ProvinceId = otherCity.Id, EmploymentTypeId = type.Id, Title = "Java Developer", CampaignStatus = "Ended"
        };
        db.AddRange(strong, weak, paused, inactive, disabled, locked, campaign, ended);
        await db.SaveChangesAsync();

        var listResponse = await client.GetAsync("/api/employer/talent-discovery");
        Assert.Equal(HttpStatusCode.OK, listResponse.StatusCode);
        var raw = await listResponse.Content.ReadAsStringAsync();
        Assert.DoesNotContain("private@example", raw);
        Assert.DoesNotContain("0900999888", raw);
        Assert.DoesNotContain("birthDate", raw);
        Assert.DoesNotContain("gender", raw);
        Assert.DoesNotContain("detailsJson", raw);
        Assert.DoesNotContain("PRIVATE_CV_SECRET", raw);
        var list = JsonSerializer.Deserialize<JsonElement>(raw);
        Assert.Equal(2, list.GetProperty("totalCount").GetInt32());
        var best = list.GetProperty("items")[0];
        Assert.Equal(strong.Id, best.GetProperty("candidateId").GetGuid());
        Assert.Equal(strong.AccountId, best.GetProperty("accountId").GetGuid());
        Assert.Equal(100, best.GetProperty("match").GetProperty("score").GetInt32());
        Assert.Equal(campaign.Id, best.GetProperty("match").GetProperty("campaignId").GetGuid());
        Assert.Equal(2, best.GetProperty("match").GetProperty("matchedSkills").GetArrayLength());
        Assert.Equal(1, list.GetProperty("stats").GetProperty("recommended").GetInt32());
        Assert.Equal(1, (await client.GetFromJsonAsync<JsonElement>("/api/employer/talent-discovery?skill=react&minYears=3&minScore=70"))
            .GetProperty("totalCount").GetInt32());
        Assert.Equal(1, (await client.GetFromJsonAsync<JsonElement>("/api/employer/talent-discovery?keyword=ung%20vien%20phu%20hop"))
            .GetProperty("totalCount").GetInt32());
        Assert.Equal(2, (await client.GetFromJsonAsync<JsonElement>($"/api/employer/talent-discovery?provinceId={city.Id}"))
            .GetProperty("totalCount").GetInt32());
        Assert.Equal(HttpStatusCode.BadRequest, (await client.GetAsync("/api/employer/talent-discovery?minYears=7&maxYears=3")).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await client.GetAsync("/api/employer/talent-discovery?sort=random")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"/api/employer/talent-discovery?campaignId={ended.Id}")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"/api/employer/talent-discovery?campaignId={Guid.NewGuid()}")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"/api/employer/talent-discovery/{paused.Id}")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.PutAsJsonAsync($"/api/employer/talent-discovery/{paused.Id}/interest", new { interested = true })).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.PutAsJsonAsync($"/api/employer/talent-discovery/{paused.Id}/saved", new { saved = true })).StatusCode);

        var detail = await client.GetFromJsonAsync<JsonElement>($"/api/employer/talent-discovery/{strong.Id}?campaignId={campaign.Id}");
        Assert.Equal("Frontend Developer", detail.GetProperty("profile").GetProperty("experiences")[0].GetProperty("title").GetString());
        Assert.False(detail.GetProperty("profile").TryGetProperty("email", out _));
        Assert.False(detail.GetProperty("profile").TryGetProperty("birthDate", out _));
        var metadata = await client.GetFromJsonAsync<JsonElement>("/api/employer/talent-discovery/metadata");
        Assert.Single(metadata.GetProperty("campaigns").EnumerateArray());
        Assert.Equal("Hà Nội", metadata.GetProperty("company").GetProperty("provinceName").GetString());

        // No running campaign is a real empty matching context, not an invented match score.
        campaign.CampaignStatus = "Paused";
        await db.SaveChangesAsync();
        var noCampaign = await client.GetFromJsonAsync<JsonElement>("/api/employer/talent-discovery");
        Assert.All(noCampaign.GetProperty("items").EnumerateArray(), c => Assert.Equal(JsonValueKind.Null, c.GetProperty("match").GetProperty("score").ValueKind));
        Assert.Equal(0, noCampaign.GetProperty("stats").GetProperty("recommended").GetInt32());
    }

    [Fact]
    public async Task InterestAndTalentSavesAreIndependentPersistentCompanyScopedAndRespectPause()
    {
        await using var factory = new Factory();
        using var client = factory.CreateClient();
        using var otherClient = factory.CreateClient();
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var city = new Province { ProvinceName = "Hà Nội", ProvinceCode = "01" };
        db.Add(city);
        await db.SaveChangesAsync();
        var companyId = await Register(client, city.Id, "one");
        var otherCompanyId = await Register(otherClient, city.Id, "two");
        var candidate = Candidate("Discovery candidate", city.Id, "Designer", 4, "looking");
        db.Add(candidate);
        await db.SaveChangesAsync();
        // The profile editor persists edited skills in DetailsJson, not CandidateSkill rows.
        var edited = await scope.ServiceProvider.GetRequiredService<ICandidateProfileRepository>().SaveAsync(candidate.AccountId,
            new CandidateProfileDocument { FullName = candidate.Account.FullName, Headline = "Designer", ProvinceId = city.Id,
                ReadyStatus = "looking", Skills = [new() { Title = "React" }, new() { Title = "TypeScript" }, new() { Title = "react" }] }, default);
        Assert.NotNull(edited);
        // Historical JSON casing is accepted by both discovery and the existing talent whitelist.
        candidate.DetailsJson = JsonSerializer.Serialize(edited.Profile).Replace("\"Skills\"", "\"sKiLls\"").Replace("\"Title\"", "\"tItLe\"");
        await db.SaveChangesAsync();
        var path = $"/api/employer/talent-discovery/{candidate.Id}";
        Assert.Equal(HttpStatusCode.OK, (await client.PutAsJsonAsync(path + "/interest", new { interested = true })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.PutAsJsonAsync(path + "/interest", new { interested = true })).StatusCode);
        Assert.Single(await db.EmployerCandidateInterests.ToListAsync());
        Assert.Empty(await db.TalentPoolEntryRecords.ToListAsync());
        var save = await client.PutAsJsonAsync(path + "/saved", new { saved = true });
        Assert.Equal(HttpStatusCode.OK, save.StatusCode);
        var savedState = await save.Content.ReadFromJsonAsync<JsonElement>();
        var talentId = savedState.GetProperty("talentId").GetGuid();
        Assert.True(savedState.GetProperty("isInterested").GetBoolean());
        Assert.True(savedState.GetProperty("isSaved").GetBoolean());
        Assert.Equal(HttpStatusCode.OK, (await client.PutAsJsonAsync(path + "/saved", new { saved = true })).StatusCode);
        Assert.Single(await db.TalentPoolEntryRecords.ToListAsync());
        var pool = await client.GetFromJsonAsync<JsonElement>("/api/employer/candidates/talents");
        var privateProfile = pool.GetProperty("items")[0].GetProperty("profile");
        Assert.Equal(JsonValueKind.Null, privateProfile.GetProperty("email").ValueKind);
        Assert.Equal(JsonValueKind.Null, privateProfile.GetProperty("phone").ValueKind);
        var savedSkills = privateProfile.GetProperty("skills").EnumerateArray().Select(s => s.GetString()).ToArray();
        Assert.Equal(2, savedSkills.Length);
        Assert.Contains("React", savedSkills);
        Assert.Contains("TypeScript", savedSkills);
        Assert.Equal(0, (await client.GetFromJsonAsync<JsonElement>("/api/employer/candidates/talents?keyword=private%40example"))
            .GetProperty("totalCount").GetInt32());
        Assert.Equal(1, (await client.GetFromJsonAsync<JsonElement>("/api/employer/talent-discovery?collection=saved")).GetProperty("totalCount").GetInt32());
        var ownDetail = await client.GetFromJsonAsync<JsonElement>(path);
        Assert.True(ownDetail.GetProperty("isSaved").GetBoolean());
        Assert.True(ownDetail.GetProperty("isInterested").GetBoolean());
        var otherDetail = await otherClient.GetFromJsonAsync<JsonElement>(path);
        Assert.False(otherDetail.GetProperty("isSaved").GetBoolean());
        Assert.False(otherDetail.GetProperty("isInterested").GetBoolean());
        Assert.Equal(HttpStatusCode.NotFound, (await otherClient.PutAsJsonAsync($"/api/employer/candidates/talents/{talentId}",
            new { readiness = "ready", notes = "Foreign write", revision = (DateTimeOffset?)null })).StatusCode);

        await client.PutAsJsonAsync(path + "/saved", new { saved = false });
        var interestedOnly = await client.GetFromJsonAsync<JsonElement>(path);
        Assert.True(interestedOnly.GetProperty("isInterested").GetBoolean());
        Assert.False(interestedOnly.GetProperty("isSaved").GetBoolean());
        var restore = await client.PutAsJsonAsync(path + "/saved", new { saved = true });
        Assert.Equal(talentId, (await restore.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("talentId").GetGuid());
        await client.PutAsJsonAsync(path + "/interest", new { interested = false });
        var savedOnly = await client.GetFromJsonAsync<JsonElement>(path);
        Assert.False(savedOnly.GetProperty("isInterested").GetBoolean());
        Assert.True(savedOnly.GetProperty("isSaved").GetBoolean());
        Assert.Empty(await db.EmployerCandidateInterests.ToListAsync());
        Assert.Single(await db.TalentPoolEntryRecords.ToListAsync());
        Assert.Equal(companyId, (await db.TalentPoolEntryRecords.AsNoTracking().SingleAsync()).CompanyId);
        Assert.NotEqual(companyId, otherCompanyId);

        candidate.ReadyStatus = "paused";
        await db.SaveChangesAsync();
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync(path)).StatusCode);
        Assert.Equal(0, (await client.GetFromJsonAsync<JsonElement>("/api/employer/talent-discovery?collection=saved")).GetProperty("totalCount").GetInt32());
        Assert.Equal(0, (await client.GetFromJsonAsync<JsonElement>("/api/employer/candidates/talents")).GetProperty("totalCount").GetInt32());
    }

    [Fact]
    public async Task ApplicationSaveRestoresDiscoveryTalentIdNotesAndReadinessAfterUnsave()
    {
        await using var factory = new Factory();
        using var client = factory.CreateClient();
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var city = new Province { ProvinceName = "Hà Nội", ProvinceCode = "01" };
        var industry = new Industry { IndustryName = "IT" };
        var type = new EmploymentType { TypeName = "Full-time" };
        db.AddRange(city, industry, type);
        await db.SaveChangesAsync();
        var companyId = await Register(client, city.Id, "one");
        var recruiter = await db.RecruiterProfileRecords.SingleAsync();
        var candidate = Candidate("Applicant with saved notes", city.Id, "Engineer", 4, "looking");
        var campaign = new RecruitmentCampaign { CompanyId = companyId, OwnerRecruiterId = recruiter.Id,
            IndustryId = industry.Id, ProvinceId = city.Id, EmploymentTypeId = type.Id, Title = "Engineer", CampaignStatus = "Running" };
        var application = new JobApplication { Candidate = candidate, Campaign = campaign, Source = "Website" };
        db.AddRange(candidate, campaign, application);
        await db.SaveChangesAsync();
        var path = $"/api/employer/talent-discovery/{candidate.Id}/saved";
        var save = await client.PutAsJsonAsync(path, new { saved = true });
        Assert.Equal(HttpStatusCode.OK, save.StatusCode);
        var talentId = (await save.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("talentId").GetGuid();
        var notes = "Contact next quarter; strong architecture experience";
        Assert.Equal(HttpStatusCode.OK, (await client.PutAsJsonAsync($"/api/employer/candidates/talents/{talentId}",
            new { readiness = "later", notes, revision = (DateTimeOffset?)null })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.PutAsJsonAsync(path, new { saved = false })).StatusCode);
        Assert.Equal(EntityStatus.Inactive, (await db.TalentPoolEntryRecords.AsNoTracking().SingleAsync()).Status);

        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/employer/candidates/talents", new { applicationId = application.Id })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/employer/candidates/talents", new { applicationId = application.Id })).StatusCode);
        var restored = await db.TalentPoolEntryRecords.AsNoTracking().SingleAsync();
        Assert.Equal(talentId, restored.Id);
        Assert.Equal(EntityStatus.Active, restored.Status);
        Assert.Equal(notes, restored.Notes);
        Assert.Equal("later", restored.ReadinessStatus);
        Assert.NotNull(restored.UpdatedDate);
        Assert.Equal(recruiter.AccountId, restored.UpdatedAccountId);
        var discovery = await client.GetFromJsonAsync<JsonElement>($"/api/employer/talent-discovery/{candidate.Id}");
        Assert.True(discovery.GetProperty("isSaved").GetBoolean());
        Assert.Equal(talentId, discovery.GetProperty("talentId").GetGuid());
    }

    [Fact]
    public async Task AssignDoesNotSourcePausedOrLockedApplicantsAndDoesNotDuplicateHiddenApplications()
    {
        await using var factory = new Factory();
        using var client = factory.CreateClient();
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var city = new Province { ProvinceName = "Hà Nội", ProvinceCode = "01" };
        var industry = new Industry { IndustryName = "IT" };
        var type = new EmploymentType { TypeName = "Full-time" };
        db.AddRange(city, industry, type);
        await db.SaveChangesAsync();
        var companyId = await Register(client, city.Id, "one");
        var recruiter = await db.RecruiterProfileRecords.SingleAsync();
        var candidate = Candidate("Applicant who can pause discovery", city.Id, "Engineer", 4, "looking");
        RecruitmentCampaign Campaign(string title) => new() { CompanyId = companyId, OwnerRecruiterId = recruiter.Id,
            IndustryId = industry.Id, ProvinceId = city.Id, EmploymentTypeId = type.Id, Title = title, CampaignStatus = "Running" };
        var originalCampaign = Campaign("Original application");
        var hiddenCampaign = Campaign("Existing sourced application");
        var newCampaign = Campaign("Next campaign");
        var original = new JobApplication { Candidate = candidate, Campaign = originalCampaign, Source = "Website" };
        var previouslySourced = new JobApplication { Candidate = candidate, Campaign = hiddenCampaign, Source = "Talent Pool" };
        db.AddRange(candidate, originalCampaign, hiddenCampaign, newCampaign, original, previouslySourced);
        await db.SaveChangesAsync();
        var save = await client.PutAsJsonAsync($"/api/employer/talent-discovery/{candidate.Id}/saved", new { saved = true });
        Assert.Equal(HttpStatusCode.OK, save.StatusCode);
        var talentId = (await save.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("talentId").GetGuid();
        var assignPath = $"/api/employer/candidates/talents/{talentId}/assign";
        candidate.ReadyStatus = "paused";
        await db.SaveChangesAsync();
        // The actual prior application keeps this talent in the existing pool, while sourced rows are hidden.
        Assert.Equal(1, (await client.GetFromJsonAsync<JsonElement>("/api/employer/candidates/talents")).GetProperty("totalCount").GetInt32());
        Assert.Equal(1, (await client.GetFromJsonAsync<JsonElement>("/api/employer/candidates")).GetProperty("totalCount").GetInt32());
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync(assignPath, new { campaignId = hiddenCampaign.Id })).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync(assignPath, new { campaignId = hiddenCampaign.Id })).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync(assignPath, new { campaignId = newCampaign.Id })).StatusCode);
        Assert.Equal(2, await db.JobApplicationRecords.CountAsync());
        candidate.ReadyStatus = "looking";
        candidate.Account.AccountStatus = "Locked";
        await db.SaveChangesAsync();
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync(assignPath, new { campaignId = newCampaign.Id })).StatusCode);
        Assert.Equal(2, await db.JobApplicationRecords.CountAsync());
        candidate.Account.AccountStatus = "Active";
        await db.SaveChangesAsync();
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync(assignPath, new { campaignId = hiddenCampaign.Id })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync(assignPath, new { campaignId = newCampaign.Id })).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync(assignPath, new { campaignId = newCampaign.Id })).StatusCode);
        Assert.Equal(3, await db.JobApplicationRecords.CountAsync());
        Assert.Equal(1, await db.JobApplicationRecords.CountAsync(a => a.CampaignId == newCampaign.Id && a.CandidateId == candidate.Id));
    }

    [Fact]
    public void MatchingRewardsRequiredSkillsAndDoesNotRequireRemoteResidence()
    {
        var province = Guid.NewGuid();
        var campaign = new DiscoveryCampaign(Guid.NewGuid(), "Software Engineer", "IT", province, "Hà Nội", "remote", 3,
            [new("C#", true), new("Docker", false)]);
        var requiredOnly = TalentDiscoveryMatching.Compare("Software Engineer", "", 4, Guid.NewGuid(), null, ["C#"], campaign);
        var optionalOnly = TalentDiscoveryMatching.Compare("Software Engineer", "", 4, Guid.NewGuid(), null, ["Docker"], campaign);
        Assert.True(requiredOnly.Score > optionalOnly.Score);
        Assert.Contains("Chiến dịch cho phép làm việc từ xa", requiredOnly.Reasons);
        var all = TalentDiscoveryMatching.Compare("Software Engineer", "", 4, null, null, ["C#", "Docker"], campaign);
        Assert.Equal(100, all.Score);
        Assert.Empty(all.MissingSkills);
        Assert.Equal("ung vien da nang", TalentDiscoveryMatching.Normalize("Ứng viên Đà Nẵng"));
    }

    private static CandidateProfile Candidate(string name, Guid provinceId, string headline, int years, string readiness,
        CandidateProfileDocument? document = null)
    {
        var account = new Account { FullName = name, AccountType = "Candidate", AccountStatus = "Active", Email = $"private@example-{Guid.NewGuid()}.com", Phone = "0900999888" };
        return new CandidateProfile { Account = account, AccountId = account.Id, ProvinceId = provinceId,
            Headline = headline, YearsExperience = years, ReadyStatus = readiness, DetailsJson = document is null ? null : JsonSerializer.Serialize(document) };
    }

    private static async Task<Guid> Register(HttpClient client, Guid provinceId, string suffix)
    {
        var response = await client.PostAsJsonAsync("/api/employer/auth/register", new EmployerRegisterRequest
        {
            FullName = "HR " + suffix, Email = $"hr-{suffix}@example.com", WorkPhone = suffix == "one" ? "0988123456" : "0988123457",
            CompanyName = "Company " + suffix, TaxCode = suffix == "one" ? "0109867899" : "0109867898", HeadOfficeProvinceId = provinceId,
            Password = "testpassword", ConfirmPassword = "testpassword", AcceptTerms = true, RecruitmentCommitment = true
        });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var session = (await response.Content.ReadFromJsonAsync<EmployerSessionDto>())!;
        client.DefaultRequestHeaders.Authorization = new("Bearer", session.AccessToken);
        return session.Account.CompanyId;
    }

    private sealed class Factory : WebApplicationFactory<Program>
    {
        private readonly string name = Guid.NewGuid().ToString();
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Development");
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<RecruitmentDbContext>();
                services.RemoveAll<DbContextOptions<RecruitmentDbContext>>();
                services.RemoveAll<IDbContextOptionsConfiguration<RecruitmentDbContext>>();
                services.AddDbContext<RecruitmentDbContext>(options => options.UseInMemoryDatabase(name));
            });
        }
    }
}
