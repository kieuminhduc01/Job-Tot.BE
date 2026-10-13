using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using JobTot.Application.Authentication;
using JobTot.Application.Cvs;
using JobTot.Domain.Entities;
using JobTot.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace JobTot.Domain.Tests;

public sealed class CvStudioTests
{
    [Fact]
    public async Task PublicGalleryOnlyShowsPublishedTemplatesAndCopiesArePrivateVersionedSnapshots()
    {
        await using var factory = new CvFactory();
        using var owner = factory.CreateClient(); using var other = factory.CreateClient();
        await factory.Seed();
        Assert.Single((await owner.GetFromJsonAsync<CvTemplateDto[]>("/api/cv-templates"))!);
        Assert.Equal(HttpStatusCode.NotFound, (await owner.GetAsync($"/api/cv-templates/{factory.Hidden.Id}")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await owner.GetAsync("/api/candidate/online-cvs")).StatusCode);
        await SignIn(owner, "owner@cv.test"); await SignIn(other, "other@cv.test");
        var created = await owner.PostAsync($"/api/candidate/online-cvs/from-template/{factory.Published.Id}", null);
        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        var cv = (await created.Content.ReadFromJsonAsync<OnlineCvDto>())!;
        Assert.Equal("Test Candidate", cv.Document.FullName);
        Assert.Equal(HttpStatusCode.NotFound, (await other.GetAsync($"/api/candidate/online-cvs/{cv.Id}")).StatusCode);
        Assert.Empty((await other.GetFromJsonAsync<OnlineCvListDto[]>("/api/candidate/online-cvs"))!);
        cv.Document.Headline = "Changed by owner";
        var write = new CvWrite { Title = "My CV", Version = cv.Version, Document = cv.Document };
        var saved = await owner.PutAsJsonAsync($"/api/candidate/online-cvs/{cv.Id}", write);
        Assert.Equal(HttpStatusCode.OK, saved.StatusCode);
        var next = (await saved.Content.ReadFromJsonAsync<OnlineCvDto>())!;
        Assert.NotEqual(cv.Version, next.Version);
        Assert.Equal(HttpStatusCode.Conflict, (await owner.PutAsJsonAsync($"/api/candidate/online-cvs/{cv.Id}", write)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.PutAsJsonAsync($"/api/candidate/online-cvs/{cv.Id}", write)).StatusCode);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var template = await db.Set<CvTemplate>().SingleAsync(t => t.Id == factory.Published.Id);
            template.DesignJson = JsonSerializer.Serialize(new CvDocument { Headline = "Admin changed template" }, new JsonSerializerOptions(JsonSerializerDefaults.Web));
            await db.SaveChangesAsync();
        }
        Assert.Equal("Changed by owner", (await owner.GetFromJsonAsync<OnlineCvDto>($"/api/candidate/online-cvs/{cv.Id}"))!.Document.Headline);
        Assert.Equal(HttpStatusCode.Conflict, (await owner.DeleteAsync($"/api/candidate/online-cvs/{cv.Id}?version={cv.Version}")).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await owner.DeleteAsync($"/api/candidate/online-cvs/{cv.Id}?version={next.Version}")).StatusCode);
        Assert.Empty((await owner.GetFromJsonAsync<OnlineCvListDto[]>("/api/candidate/online-cvs"))!);
    }

    [Fact]
    public async Task AdminAuthenticationIsSeparateAndPublishingValidatesDocumentsAndVersions()
    {
        await using var factory = new CvFactory(); using var admin = factory.CreateClient(); using var candidate = factory.CreateClient();
        await factory.Seed(); await SignIn(candidate, "candidate@cv.test");
        Assert.Equal(HttpStatusCode.Unauthorized, (await candidate.GetAsync("/api/admin/cv-templates")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await candidate.PostAsJsonAsync("/api/admin/auth/login", new { emailOrPhone = "candidate@cv.test", password = "password123" })).StatusCode);
        var login = await admin.PostAsJsonAsync("/api/admin/auth/login", new { emailOrPhone = "admin@cv.test", password = "admin-password123" });
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);
        var session = await login.Content.ReadFromJsonAsync<JsonElement>();
        admin.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", session.GetProperty("accessToken").GetString());
        Assert.Equal(2, (await admin.GetFromJsonAsync<CvTemplateDto[]>("/api/admin/cv-templates"))!.Length);
        Assert.Equal(HttpStatusCode.Unauthorized, (await admin.GetAsync("/api/candidate/online-cvs")).StatusCode);
        var input = new CvTemplateWrite { Name = "New Admin Template", Category = "Technology", PublicationState = "draft" };
        var response = await admin.PostAsJsonAsync("/api/admin/cv-templates", input);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var template = (await response.Content.ReadFromJsonAsync<CvTemplateDto>())!;
        Assert.Equal(HttpStatusCode.NotFound, (await candidate.GetAsync($"/api/cv-templates/{template.Id}")).StatusCode);
        input.Version = template.Version; input.PublicationState = "published";
        var published = await admin.PutAsJsonAsync($"/api/admin/cv-templates/{template.Id}", input);
        Assert.Equal(HttpStatusCode.OK, published.StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await candidate.GetAsync($"/api/cv-templates/{template.Id}")).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await admin.PutAsJsonAsync($"/api/admin/cv-templates/{template.Id}", input)).StatusCode);
        input.Document.Color = "url(javascript:alert(1))";
        Assert.Equal(HttpStatusCode.BadRequest, (await admin.PostAsJsonAsync("/api/admin/cv-templates", input)).StatusCode);
        input.Document.Color = "#ff5722"; input.Document.Sections[1].Id = input.Document.Sections[0].Id;
        Assert.Equal(HttpStatusCode.BadRequest, (await admin.PostAsJsonAsync("/api/admin/cv-templates", input)).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await admin.PostAsync("/api/admin/auth/logout", null)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await admin.GetAsync("/api/admin/cv-templates")).StatusCode);
    }

    [Fact]
    public async Task CvRepositoryPreservesCancellation()
    {
        await using var factory = new CvFactory(); using var client = factory.CreateClient();
        using var scope = factory.Services.CreateScope(); using var cancellation = new CancellationTokenSource(); cancellation.Cancel();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => scope.ServiceProvider.GetRequiredService<ICvRepository>().TemplatesAsync(false, cancellation.Token));
    }

    [Fact]
    public async Task OnlineCvCanBeSubmittedAndApplicationKeepsSnapshotAfterCvIsEdited()
    {
        await using var factory = new CvFactory(); using var client = factory.CreateClient();
        await factory.Seed(); await SignIn(client, "applicant@cv.test");
        var created = await client.PostAsync($"/api/candidate/online-cvs/from-template/{factory.Published.Id}", null);
        var cv = (await created.Content.ReadFromJsonAsync<OnlineCvDto>())!;
        using var scope = factory.Services.CreateScope(); var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var company = new Company("CV Company", "Description");
        var job = new JobPost(company.Id, "Engineer", "Description", "Ha Noi", null, null, DateTimeOffset.UtcNow.AddDays(5));
        db.AddRange(company, job); await db.SaveChangesAsync();
        var accountId = await db.AccountRecords.Where(a => a.Email == "applicant@cv.test").Select(a => a.Id).SingleAsync();
        await scope.ServiceProvider.GetRequiredService<JobTot.Application.IRecruitmentRepository>().SubmitAsync(accountId, job.Id,
            new JobTot.Application.SubmitJobApplicationRequest(cv.Id, "Test Candidate", "0900123456", null), default);
        var snapshot = await db.CandidateJobSubmissions.Select(s => s.CvContentJson).SingleAsync();
        cv.Document.Headline = "Updated after application";
        Assert.Equal(HttpStatusCode.OK, (await client.PutAsJsonAsync($"/api/candidate/online-cvs/{cv.Id}", new CvWrite { Title = "Updated CV", Version = cv.Version, Document = cv.Document })).StatusCode);
        Assert.DoesNotContain("Updated after application", snapshot);
        Assert.Equal(JsonValueKind.Object, JsonDocument.Parse(snapshot).RootElement.ValueKind);
        Assert.Equal(snapshot, await db.CandidateJobSubmissions.AsNoTracking().Select(s => s.CvContentJson).SingleAsync());
    }

    private static async Task SignIn(HttpClient client, string email)
    {
        var response = await client.PostAsJsonAsync("/api/candidate/auth/register", new { fullName = "Test Candidate", emailOrPhone = email, password = "password123", confirmPassword = "password123" });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var session = (await response.Content.ReadFromJsonAsync<CandidateSessionDto>())!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", session.AccessToken);
    }
    private sealed class CvFactory : WebApplicationFactory<Program>
    {
        private readonly string database = Guid.NewGuid().ToString();
        public CvTemplate Published { get; } = new() { Name = "Published", PublicationState = "published", DesignJson = JsonSerializer.Serialize(new CvDocument(), new JsonSerializerOptions(JsonSerializerDefaults.Web)) };
        public CvTemplate Hidden { get; } = new() { Name = "Hidden", PublicationState = "hidden", DesignJson = JsonSerializer.Serialize(new CvDocument(), new JsonSerializerOptions(JsonSerializerDefaults.Web)) };
        public async Task Seed()
        {
            using var scope = Services.CreateScope(); var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var category = new CvCategory { Name = "Professional" }; Published.Category = category; Hidden.Category = category;
            var admin = new Account { Email = "admin@cv.test", FullName = "Admin", AccountType = "Admin", AccountStatus = "Active" };
            admin.PasswordHash = scope.ServiceProvider.GetRequiredService<IAccountPasswordHasher>().Hash(admin, "admin-password123");
            db.AddRange(category, Published, Hidden, admin); await db.SaveChangesAsync();
        }
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Development"); builder.ConfigureServices(services =>
            {
                services.RemoveAll<RecruitmentDbContext>(); services.RemoveAll<DbContextOptions<RecruitmentDbContext>>();
                services.RemoveAll<IDbContextOptionsConfiguration<RecruitmentDbContext>>();
                services.AddDbContext<RecruitmentDbContext>(options => options.UseInMemoryDatabase(database));
            });
        }
    }
}
