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
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Development");
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<RecruitmentDbContext>();
                services.RemoveAll<DbContextOptions<RecruitmentDbContext>>();
                services.RemoveAll<IDbContextOptionsConfiguration<RecruitmentDbContext>>();
                services.AddDbContext<RecruitmentDbContext>(o => o.UseInMemoryDatabase(database));
            });
        }
    }
}
