using System.Net;
using System.Net.Http.Json;
using System.Text;
using JobTot.Application.Authentication;
using System.Net.Http.Headers;
using JobTot.Application.Profiles;
using JobTot.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace JobTot.Domain.Tests;

public sealed class CandidateProfileTests
{
    [Fact]
    public async Task PrimaryCvCanBeChangedOrDemotedAndOtherAccountsCannotChangeIt()
    {
        await using var factory = new ProfileFactory();
        using var owner = factory.CreateClient();
        using var other = factory.CreateClient();
        await Register(owner, "cv-owner@example.com");
        await Register(other, "cv-other@example.com");
        async Task<ProfileCv> Upload(string name)
        {
            using var form = new MultipartFormDataContent();
            form.Add(new ByteArrayContent(Encoding.ASCII.GetBytes("%PDF-1.4 test")), "file", name);
            var response = await owner.PostAsync("/api/candidate/profile/cvs", form);
            response.EnsureSuccessStatusCode();
            return (await response.Content.ReadFromJsonAsync<ProfileCv>())!;
        }
        var first = await Upload("first.pdf");
        var second = await Upload("second.pdf");
        var path = $"/api/candidate/profile/cvs/{first.Id}/default";
        Assert.Equal(HttpStatusCode.NotFound, (await other.PutAsJsonAsync(path, new { isDefault = true })).StatusCode);
        var response = await owner.PutAsJsonAsync(path, new { isDefault = true });
        response.EnsureSuccessStatusCode();
        var cvs = (await response.Content.ReadFromJsonAsync<ProfileCv[]>())!;
        Assert.Equal(first.Id, Assert.Single(cvs.Where(c => c.IsDefault)).Id);
        Assert.False(cvs.Single(c => c.Id == second.Id).IsDefault);
        response = await owner.PutAsJsonAsync(path, new { isDefault = false });
        response.EnsureSuccessStatusCode();
        Assert.All((await response.Content.ReadFromJsonAsync<ProfileCv[]>())!, c => Assert.False(c.IsDefault));
        var persisted = (await owner.GetFromJsonAsync<CandidateProfileResponse>("/api/candidate/profile"))!;
        Assert.All(persisted.Cvs, c => Assert.False(c.IsDefault));
    }

    [Fact]
    public async Task ProfileQueryCancellationIsHandledWithoutAnErrorBody()
    {
        await using var factory = new ProfileFactory();
        using var scope = factory.Services.CreateScope();
        using var cancellation = new CancellationTokenSource();
        var context = new Microsoft.AspNetCore.Http.DefaultHttpContext { RequestAborted = cancellation.Token };
        context.User = new System.Security.Claims.ClaimsPrincipal(new System.Security.Claims.ClaimsIdentity(
            new[] { new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.NameIdentifier, Guid.NewGuid().ToString()) }, "test"));
        context.Response.Body = new MemoryStream();
        var controller = new JobTot.Api.Controllers.CandidateProfileController(scope.ServiceProvider.GetRequiredService<ICandidateProfileRepository>(), scope.ServiceProvider.GetRequiredService<JobTot.Api.AvatarFileStorage>())
        { ControllerContext = new Microsoft.AspNetCore.Mvc.ControllerContext { HttpContext = context } };
        var middleware = new JobTot.Api.RequestCancellationMiddleware(async ctx =>
        {
            cancellation.Cancel();
            await controller.Get(ctx.RequestAborted);
        });
        await middleware.InvokeAsync(context);
        Assert.Equal(499, context.Response.StatusCode);
        Assert.Equal(0, context.Response.Body.Length);
    }

    [Fact]
    public async Task PreferencesPersistCatalogProvinceAndRejectInvalidChoices()
    {
        await using var factory = new ProfileFactory();
        using var client = factory.CreateClient();
        await Register(client, "preferences@example.com");
        var province = new JobTot.Domain.Entities.Province { ProvinceName = "Thành phố Hà Nội", ProvinceCode = "01" };
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            db.ProvinceRecords.Add(province);
            await db.SaveChangesAsync();
        }
        var profile = (await client.GetFromJsonAsync<CandidateProfileResponse>("/api/candidate/profile"))!.Profile;
        profile.DesiredProvinceId = province.Id;
        profile.ProvinceId = province.Id;
        profile.Gender = "Nữ";
        profile.Location = "Client address label";
        profile.DesiredLocation = "Client-provided label is not trusted";
        foreach (var workType in new[] { "Toàn thời gian", "Bán thời gian", "Làm việc từ xa", "Kết hợp (Hybrid)" })
        {
            profile.WorkType = workType;
            Assert.Equal(HttpStatusCode.OK, (await client.PutAsJsonAsync("/api/candidate/profile", profile)).StatusCode);
            var saved = (await client.GetFromJsonAsync<CandidateProfileResponse>("/api/candidate/profile"))!.Profile;
            Assert.Equal(workType, saved.WorkType);
            Assert.Equal(province.Id, saved.DesiredProvinceId);
            Assert.Equal(province.ProvinceName, saved.DesiredLocation);
            Assert.Equal(province.Id, saved.ProvinceId);
            Assert.Equal(province.ProvinceName, saved.Location);
            Assert.Equal("Nữ", saved.Gender);
        }
        profile.WorkType = "An arbitrary working arrangement";
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PutAsJsonAsync("/api/candidate/profile", profile)).StatusCode);
        profile.WorkType = "Toàn thời gian";
        profile.Gender = "Invalid gender";
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PutAsJsonAsync("/api/candidate/profile", profile)).StatusCode);
        profile.Gender = "Khác";
        profile.ProvinceId = Guid.NewGuid();
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PutAsJsonAsync("/api/candidate/profile", profile)).StatusCode);
        profile.ProvinceId = province.Id;
        profile.DesiredProvinceId = Guid.NewGuid();
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PutAsJsonAsync("/api/candidate/profile", profile)).StatusCode);
        profile.DesiredProvinceId = null;
        profile.DesiredLocation = "An arbitrary address";
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PutAsJsonAsync("/api/candidate/profile", profile)).StatusCode);
        profile.DesiredProvinceId = province.Id;
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            (await db.ProvinceRecords.FindAsync(province.Id))!.Status = JobTot.Domain.Enums.EntityStatus.Deleted;
            await db.SaveChangesAsync();
        }
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PutAsJsonAsync("/api/candidate/profile", profile)).StatusCode);
    }

    [Fact]
    public async Task ProfileRequiresBearerAndPersistsSections()
    {
        await using var factory = new ProfileFactory();
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/candidate/profile")).StatusCode);
        await Register(client, "profile@example.com");
        var profile = (await client.GetFromJsonAsync<CandidateProfileResponse>("/api/candidate/profile"))!.Profile;
        Assert.Empty(profile.Experiences);
        profile.FullName = "Updated Candidate";
        profile.Experiences.Add(new ProfileEntry { Title = "Engineer", Organization = "Job Tot" });
        Assert.Equal(HttpStatusCode.OK, (await client.PutAsJsonAsync("/api/candidate/profile", profile)).StatusCode);
        var saved = (await client.GetFromJsonAsync<CandidateProfileResponse>("/api/candidate/profile"))!.Profile;
        Assert.Equal("Updated Candidate", saved.FullName);
        Assert.Equal("Engineer", Assert.Single(saved.Experiences).Title);
        profile.ExpectedSalaryMin = 55000000; profile.ExpectedSalaryMax = 40000000;
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PutAsJsonAsync("/api/candidate/profile", profile)).StatusCode);
        profile.ExpectedSalaryMin = null; profile.ExpectedSalaryMax = null; profile.ReadyStatus = "invalid";
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PutAsJsonAsync("/api/candidate/profile", profile)).StatusCode);
    }

    [Fact]
    public async Task PdfUploadsAreValidatedAndPrivateToTheirOwner()
    {
        await using var factory = new ProfileFactory();
        using var owner = factory.CreateClient(); using var other = factory.CreateClient();
        await Register(owner, "owner@example.com"); await Register(other, "other@example.com");
        using var invalid = Pdf("not a PDF");
        Assert.Equal(HttpStatusCode.BadRequest, (await owner.PostAsync("/api/candidate/profile/cvs", invalid)).StatusCode);
        using var file = Pdf("%PDF-1.7\nexample");
        var upload = await owner.PostAsync("/api/candidate/profile/cvs", file);
        Assert.Equal(HttpStatusCode.OK, upload.StatusCode);
        var cv = (await upload.Content.ReadFromJsonAsync<ProfileCv>())!;
        Assert.Equal(HttpStatusCode.OK, (await owner.GetAsync($"/api/candidate/profile/cvs/{cv.Id}")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.GetAsync($"/api/candidate/profile/cvs/{cv.Id}")).StatusCode);
        var otherProfile = (await other.GetFromJsonAsync<CandidateProfileResponse>("/api/candidate/profile"))!;
        Assert.Empty(otherProfile.Cvs);
    }

    [Fact]
    public async Task AvatarFileIsPublicButProfileEditsRemainOwnerOnlyAndRemovalDeletesFile()
    {
        await using var factory = new ProfileFactory();
        using var owner = factory.CreateClient(); using var other = factory.CreateClient();
        await Register(owner, "avatar-owner@example.com"); await Register(other, "avatar-other@example.com");
        const string png = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4n6D3HwAGfAKNNP+fVwAAAABJRU5ErkJggg==";
        using var body = new MultipartFormDataContent();
        body.Add(new ByteArrayContent(Convert.FromBase64String(png)), "file", "avatar.png");
        Assert.Equal(HttpStatusCode.OK, (await owner.PostAsync("/api/candidate/profile/avatar", body)).StatusCode);
        var profile = (await owner.GetFromJsonAsync<CandidateProfileResponse>("/api/candidate/profile"))!.Profile;
        var avatarUrl = profile.AvatarUrl!;
        Assert.Matches("^/uploads/avatars/[a-f0-9]{32}\\.png$", avatarUrl);
        using var publicClient = factory.CreateClient();
        var image = await publicClient.GetAsync(avatarUrl);
        Assert.Equal(HttpStatusCode.OK, image.StatusCode);
        Assert.Equal("image/png", image.Content.Headers.ContentType!.MediaType);
        Assert.Equal(Convert.FromBase64String(png), await image.Content.ReadAsByteArrayAsync());
        Assert.True(File.Exists(Path.Combine(factory.MediaDirectory, Path.GetFileName(avatarUrl))));
        Assert.Null((await other.GetFromJsonAsync<CandidateProfileResponse>("/api/candidate/profile"))!.Profile.AvatarUrl);
        profile.AvatarUrl = "https://untrusted.example/avatar.svg";
        profile.Summary = "Updated summary";
        Assert.Equal(HttpStatusCode.OK, (await owner.PutAsJsonAsync("/api/candidate/profile", profile)).StatusCode);
        Assert.Equal(avatarUrl, (await owner.GetFromJsonAsync<CandidateProfileResponse>("/api/candidate/profile"))!.Profile.AvatarUrl);
        using var invalid = Pdf("not an image");
        Assert.Equal(HttpStatusCode.BadRequest, (await owner.PostAsync("/api/candidate/profile/avatar", invalid)).StatusCode);
        using var large = new MultipartFormDataContent();
        large.Add(new ByteArrayContent(new byte[2 * 1024 * 1024 + 1]), "file", "large.png");
        Assert.Equal(HttpStatusCode.BadRequest, (await owner.PostAsync("/api/candidate/profile/avatar", large)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await owner.DeleteAsync("/api/candidate/profile/avatar")).StatusCode);
        Assert.Null((await owner.GetFromJsonAsync<CandidateProfileResponse>("/api/candidate/profile"))!.Profile.AvatarUrl);
        Assert.False(File.Exists(Path.Combine(factory.MediaDirectory, Path.GetFileName(avatarUrl))));
        Assert.Equal(HttpStatusCode.NotFound, (await publicClient.GetAsync(avatarUrl)).StatusCode);
    }
    [Fact]
    public async Task LegacyAvatarMigrationPreservesProfileAndIsIdempotent()
    {
        await using var factory = new ProfileFactory(); using var client = factory.CreateClient();
        await Register(client, "legacy-avatar@example.com");
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var profile = await db.CandidateProfileRecords.SingleAsync();
        const string png = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4n6D3HwAGfAKNNP+fVwAAAABJRU5ErkJggg==";
        profile.DetailsJson = System.Text.Json.JsonSerializer.Serialize(new CandidateProfileDocument { FullName = "Legacy", Summary = "Keep summary", AvatarUrl = $"data:image/png;base64,{png}" });
        await db.SaveChangesAsync();
        var files = scope.ServiceProvider.GetRequiredService<JobTot.Api.AvatarFileStorage>();
        Assert.Equal(1, await JobTot.Api.AvatarMigration.RunAsync(db, files, default));
        Assert.Equal(0, await JobTot.Api.AvatarMigration.RunAsync(db, files, default));
        var loaded = (await client.GetFromJsonAsync<CandidateProfileResponse>("/api/candidate/profile"))!.Profile;
        Assert.Equal("Keep summary", loaded.Summary);
        Assert.StartsWith("/uploads/avatars/", loaded.AvatarUrl);
        Assert.Equal(Convert.FromBase64String(png), await client.GetByteArrayAsync(loaded.AvatarUrl));
    }

    [Fact]
    public async Task CancelledAvatarWriteDoesNotLeaveAPartialFile()
    {
        await using var factory = new ProfileFactory();
        var files = factory.Services.GetRequiredService<JobTot.Api.AvatarFileStorage>();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => files.SaveAsync(new byte[32], true, new CancellationToken(true)));
        Assert.Empty(Directory.GetFiles(factory.MediaDirectory));
    }

    private static MultipartFormDataContent Pdf(string text)
    {
        var body = new MultipartFormDataContent();
        body.Add(new ByteArrayContent(Encoding.ASCII.GetBytes(text)), "file", "resume.pdf");
        return body;
    }
    private static async Task Register(HttpClient client, string email)
    {
        var result = await client.PostAsJsonAsync("/api/candidate/auth/register", new { fullName = "Candidate", emailOrPhone = email, password = "matkhau123", confirmPassword = "matkhau123" });
        Assert.Equal(HttpStatusCode.Created, result.StatusCode);
        var session = (await result.Content.ReadFromJsonAsync<CandidateSessionDto>())!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", session.AccessToken);
    }
    private sealed class ProfileFactory : WebApplicationFactory<Program>
    {
        private readonly string database = Guid.NewGuid().ToString();
        public string MediaDirectory { get; } = Path.Combine(Path.GetTempPath(), "jobtot-avatar-tests", Guid.NewGuid().ToString("N"));
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Development");
            builder.UseSetting("Media:AvatarDirectory", MediaDirectory);
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<RecruitmentDbContext>();
                services.RemoveAll<DbContextOptions<RecruitmentDbContext>>();
                services.RemoveAll<IDbContextOptionsConfiguration<RecruitmentDbContext>>();
                services.AddDbContext<RecruitmentDbContext>(o => o.UseInMemoryDatabase(database));
            });
        }
        public override async ValueTask DisposeAsync()
        {
            await base.DisposeAsync();
            var allowedRoot = Path.GetFullPath(Path.Combine(Path.GetTempPath(), "jobtot-avatar-tests")) + Path.DirectorySeparatorChar;
            if (!Path.GetFullPath(MediaDirectory).StartsWith(allowedRoot, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("Unexpected test media directory.");
            if (Directory.Exists(MediaDirectory)) Directory.Delete(MediaDirectory, true);
        }
    }
}
