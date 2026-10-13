using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
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

public sealed class EmployerCompanyTests
{
    [Fact]
    public async Task IndustryMustComeFromActiveCatalog()
    {
        await using var factory = new Factory();
        using var client = factory.CreateClient();
        var session = await Register(factory, client);
        client.DefaultRequestHeaders.Authorization = new("Bearer", session.AccessToken);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            db.IndustryRecords.Add(new Industry { IndustryName = "Thể thao", Status = JobTot.Domain.Enums.EntityStatus.Active });
            await db.SaveChangesAsync();
        }
        var profile = (await client.GetFromJsonAsync<EmployerCompanyResponse>("/api/employer/company"))!;
        profile.Document.Brand.Industry = "Tự nhập bất kỳ";
        profile.Document.Brand.IndustryIds = null;
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PutAsJsonAsync("/api/employer/company", profile.Document)).StatusCode);
        profile.Document.Brand.Industry = "Thể thao";
        Assert.Equal(HttpStatusCode.OK, (await client.PutAsJsonAsync("/api/employer/company", profile.Document)).StatusCode);
        var saved = (await client.GetFromJsonAsync<EmployerCompanyResponse>("/api/employer/company"))!;
        var second = new Industry { IndustryName = "Kinh doanh", Status = JobTot.Domain.Enums.EntityStatus.Active };
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            db.IndustryRecords.Add(second); await db.SaveChangesAsync();
        }
        saved.Document.Brand.IndustryIds!.Add(second.Id);
        var result = await client.PutAsJsonAsync("/api/employer/company", saved.Document);
        Assert.Equal(HttpStatusCode.OK, result.StatusCode);
        Assert.Equal(2, (await result.Content.ReadFromJsonAsync<EmployerCompanyResponse>())!.Document.Brand.IndustryIds!.Count);
    }
    [Theory]
    [InlineData("logo", "logos")]
    [InlineData("cover", "covers")]
    [InlineData("gallery", "gallery")]
    public async Task UploadedCompanyImageIsPublicAndLinkedInMedia(string kind, string folder)
    {
        await using var factory = new Factory();
        using var client = factory.CreateClient();
        var session = await Register(factory, client);
        client.DefaultRequestHeaders.Authorization = new("Bearer", session.AccessToken);
        var profile = (await client.GetFromJsonAsync<EmployerCompanyResponse>("/api/employer/company"))!;
        var bytes = Convert.FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4n6D3HwAGfAKNNP+fVwAAAABJRU5ErkJggg==");
        MultipartFormDataContent Body(string revision, byte[] content, string mime = "image/png")
        {
            var body = new MultipartFormDataContent();
            var image = new ByteArrayContent(content); image.Headers.ContentType = new(mime);
            body.Add(image, "file", "../../untrusted-name.svg"); body.Add(new StringContent(revision), "revision"); return body;
        }
        using var upload = Body(profile.Document.Revision, bytes);
        var response = await client.PostAsync($"/api/employer/company/images/{kind}", upload);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var saved = (await response.Content.ReadFromJsonAsync<EmployerCompanyResponse>())!;
        var url = kind == "logo" ? saved.Document.Brand.LogoUrl : kind == "cover" ? saved.Document.Brand.CoverUrl : Assert.Single(saved.Document.Brand.Gallery);
        Assert.Matches($"^/uploads/companies/{folder}/[a-f0-9]{{32}}\\.png$", url);
        var header = await client.GetFromJsonAsync<System.Text.Json.JsonElement>("/api/employer/header");
        Assert.Equal(kind == "logo" ? url : "", header.GetProperty("companyLogoUrl").GetString());
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var company = await db.Companies.SingleAsync();
            if (kind == "gallery") { Assert.Null(company.LogoFileId); Assert.Null(company.CoverFileId); }
            else Assert.Equal((await db.MediaRecords.SingleAsync()).Id, kind == "logo" ? company.LogoFileId : company.CoverFileId);
        }
        using var stale = Body(profile.Document.Revision, bytes);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsync($"/api/employer/company/images/{kind}", stale)).StatusCode);
        using var invalid = Body(saved.Document.Revision, "<svg/>"u8.ToArray(), "image/svg+xml");
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsync($"/api/employer/company/images/{kind}", invalid)).StatusCode);
        saved.Document.Description = "After image upload";
        Assert.Equal(HttpStatusCode.OK, (await client.PutAsJsonAsync("/api/employer/company", saved.Document)).StatusCode);
        client.DefaultRequestHeaders.Authorization = null;
        Assert.Equal(bytes, await client.GetByteArrayAsync(url));
        using var anonymous = Body(saved.Document.Revision, bytes);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsync($"/api/employer/company/images/{kind}", anonymous)).StatusCode);
    }

    [Fact]
    public async Task FounderEditsOwnCompanyAndBrandingAppearsPubliclyWithoutTeamData()
    {
        await using var factory = new Factory();
        using var client = factory.CreateClient();
        var session = await Register(factory, client);
        client.DefaultRequestHeaders.Authorization = new("Bearer", session.AccessToken);
        var profile = (await client.GetFromJsonAsync<EmployerCompanyResponse>("/api/employer/company"))!;
        Assert.True(profile.CanEdit);
        Assert.Equal(session.Account.CompanyId, profile.Id);
        Assert.Single(profile.Team);
        var oldRevision = profile.Document.Revision;
        profile.Document.Name = "Tốt Tech Việt Nam";
        profile.Document.Description = "Doanh nghiệp công nghệ";
        profile.Document.Brand.Story = "Câu chuyện doanh nghiệp";
        profile.Document.Brand.Benefits.Add(new() { Title = "Bảo hiểm sức khỏe", Description = "Chăm sóc sức khỏe toàn diện" });
        var saved = await client.PutAsJsonAsync("/api/employer/company", profile.Document);
        Assert.Equal(HttpStatusCode.OK, saved.StatusCode);
        var result = (await saved.Content.ReadFromJsonAsync<EmployerCompanyResponse>())!;
        Assert.NotEqual(oldRevision, result.Document.Revision);
        Assert.Equal("Pending", result.VerificationStatus);
        Assert.Equal("Tốt Tech Việt Nam", result.Document.Name);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PutAsJsonAsync("/api/employer/company", profile.Document)).StatusCode);
        var publicResponse = await client.GetFromJsonAsync<JobTot.Application.PageResult<CompanyListingDto>>($"/api/companies?companyId={profile.Id}&pageSize=1");
        var item = Assert.Single(publicResponse!.Items);
        Assert.Equal("Bảo hiểm sức khỏe", Assert.Single(item.Brand!.Benefits).Title);
        Assert.Null(item.CoverUrl);
        Assert.Equal("Công ty Tốt Tech", result.LegalName);
    }
    [Fact]
    public async Task VerifiedHrCanEditEvenWithLegacyNonAdminFlag()
    {
        await using var factory = new Factory();
        using var client = factory.CreateClient();
        var session = await Register(factory, client);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", session.AccessToken);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            (await db.Companies.SingleAsync()).VerificationStatus = "Verified";
            (await db.RecruiterProfileRecords.SingleAsync()).IsCompanyAdmin = false;
            await db.SaveChangesAsync();
        }
        var profile = (await client.GetFromJsonAsync<EmployerCompanyResponse>("/api/employer/company"))!;
        Assert.True(profile.CanEdit);
        Assert.All(profile.Team, member => Assert.True(member.IsCompanyAdmin));
        Assert.Equal(HttpStatusCode.OK, (await client.PutAsJsonAsync("/api/employer/company", profile.Document)).StatusCode);

    }
    [Fact]
    public async Task InvalidBrandLinksAndMissingFieldsAreRejected()
    {
        await using var factory = new Factory();
        using var client = factory.CreateClient();
        var session = await Register(factory, client);
        client.DefaultRequestHeaders.Authorization = new("Bearer", session.AccessToken);
        var profile = (await client.GetFromJsonAsync<EmployerCompanyResponse>("/api/employer/company"))!;
        profile.Document.Brand.CoverUrl = "javascript:alert(1)";
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PutAsJsonAsync("/api/employer/company", profile.Document)).StatusCode);
        profile.Document.Brand.CoverUrl = "";
        profile.Document.Brand.Benefits.Add(new() { Title = "" });
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PutAsJsonAsync("/api/employer/company", profile.Document)).StatusCode);
        client.DefaultRequestHeaders.Authorization = null;
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/employer/company")).StatusCode);
    }
    [Fact]
    public async Task CompanySelectionComesFromMembershipInsteadOfClientCompanyId()
    {
        await using var factory = new Factory();
        using var client = factory.CreateClient();
        var session = await Register(factory, client);
        Guid otherId;
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var other = new Company("Other Company", "Private company"); otherId = other.Id;
            db.Companies.Add(other); await db.SaveChangesAsync();
        }
        client.DefaultRequestHeaders.Authorization = new("Bearer", session.AccessToken);
        var profile = (await client.GetFromJsonAsync<EmployerCompanyResponse>($"/api/employer/company?companyId={otherId}"))!;
        Assert.Equal(session.Account.CompanyId, profile.Id);
        Assert.NotEqual(otherId, profile.Id);
    }
    private static async Task<EmployerSessionDto> Register(Factory factory, HttpClient client)
    {
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var province = new Province { ProvinceName = "Hà Nội", ProvinceCode = "01" };
        db.ProvinceRecords.Add(province); await db.SaveChangesAsync();
        var response = await client.PostAsJsonAsync("/api/employer/auth/register", new EmployerRegisterRequest
        { FullName = "HR Test", Email = "hr@example.com", WorkPhone = "0988123456", CompanyName = "Công ty Tốt Tech", TaxCode = "0109867899", HeadOfficeProvinceId = province.Id,
            Password = "testpassword", ConfirmPassword = "testpassword", AcceptTerms = true, RecruitmentCommitment = true });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<EmployerSessionDto>())!;
    }
    private sealed class Factory : WebApplicationFactory<Program>
    {
        private readonly string name = Guid.NewGuid().ToString();
        public string ImageDirectory { get; } = Path.Combine(Path.GetTempPath(), "jobtot-company-image-tests", Guid.NewGuid().ToString("N"));
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Development");
            builder.UseSetting("Media:CompanyDirectory", ImageDirectory);
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<RecruitmentDbContext>(); services.RemoveAll<DbContextOptions<RecruitmentDbContext>>();
                services.RemoveAll<IDbContextOptionsConfiguration<RecruitmentDbContext>>();
                services.AddDbContext<RecruitmentDbContext>(options => options.UseInMemoryDatabase(name));
            });
        }
        public override async ValueTask DisposeAsync()
        {
            await base.DisposeAsync();
            var root = Path.GetFullPath(Path.Combine(Path.GetTempPath(), "jobtot-company-image-tests")) + Path.DirectorySeparatorChar;
            if (!Path.GetFullPath(ImageDirectory).StartsWith(root, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("Unexpected test directory.");
            if (Directory.Exists(ImageDirectory)) Directory.Delete(ImageDirectory, true);
        }
    }
}
