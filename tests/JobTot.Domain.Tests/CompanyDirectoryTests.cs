using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using JobTot.Application;
using JobTot.Application.Authentication;
using JobTot.Application.Companies;
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

public sealed class CompanyDirectoryTests
{
    [Theory]
    [InlineData("logos/716c5ddc21e45b469d1285e1e229db31.svg")]
    [InlineData("covers/2b6cdefba63f5c4e82af354ea34161b2.svg")]
    public async Task DemoCompanySvgIsServedByBackend(string filename)
    {
        await using var factory = new DirectoryFactory();
        using var client = factory.CreateClient();
        using var response = await client.GetAsync($"/uploads/companies/{filename}");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("image/svg+xml", response.Content.Headers.ContentType?.MediaType);
        Assert.Contains("<svg", await response.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task EmptyDirectoryMetadataHasZeroCounts()
    {
        await using var factory = new DirectoryFactory();
        using var client = factory.CreateClient();
        var metadata = (await client.GetFromJsonAsync<CompanyDirectoryMetadata>("/api/companies/filters"))!;
        Assert.Equal(new CompanyDirectoryStats(0, 0, 0, 0), metadata.Stats);
        Assert.Empty(metadata.Provinces);
        Assert.Empty(metadata.Industries);
    }

    [Fact]
    public async Task MetadataPreservesCancellationInsteadOfReturningEmptyData()
    {
        await using var factory = new DirectoryFactory();
        using var scope = factory.Services.CreateScope();
        var repository = scope.ServiceProvider.GetRequiredService<ICompanyDirectoryRepository>();
        using var cancellation = new CancellationTokenSource();
        cancellation.Cancel();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => repository.MetadataAsync(cancellation.Token));
    }

    [Fact]
    public async Task IndustryOverviewDeduplicatesMembershipsAndExcludesClosedExpiredInactiveAndHourlySalaries()
    {
        await using var factory = new DirectoryFactory();
        using var client = factory.CreateClient();
        await factory.Seed();
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            db.CompanyIndustryRecords.Add(new CompanyIndustry { CompanyId = factory.Acme.Id, IndustryId = factory.Tech.Id });
            db.Jobs.Add(new JobPost(factory.Acme.Id, "Monthly", "Description", "Ha Noi", 12000000, 35000000, DateTimeOffset.UtcNow.AddDays(5)));
            var hourly = new JobPost(factory.Acme.Id, "Hourly", "Description", "Ha Noi", 50000, 100000, DateTimeOffset.UtcNow.AddDays(5));
            hourly.SetDirectoryDetails(null, null, null, "hourly");
            db.Jobs.Add(hourly);
            var hidden = await db.Companies.SingleAsync(c => c.Status == EntityStatus.Deleted);
            hidden.IndustryId = factory.Tech.Id;
            db.Jobs.Add(new JobPost(hidden.Id, "Hidden", "Description", "Ha Noi", 1000000, 99000000, DateTimeOffset.UtcNow.AddDays(5)));
            await db.SaveChangesAsync();
        }
        var items = (await client.GetFromJsonAsync<System.Text.Json.JsonElement[]>("/api/industries/overview"))!;
        var tech = items.Single(i => i.GetProperty("id").GetGuid() == factory.Tech.Id);
        Assert.Equal(3, tech.GetProperty("openJobs").GetInt32());
        Assert.Equal(3, tech.GetProperty("newJobs").GetInt32());
        Assert.Equal(12000000, tech.GetProperty("salaryMin").GetDecimal());
        Assert.Equal(35000000, tech.GetProperty("salaryMax").GetDecimal());
        var finance = items.Single(i => i.GetProperty("id").GetGuid() == factory.Finance.Id);
        Assert.Equal(0, finance.GetProperty("openJobs").GetInt32());
        Assert.Equal(System.Text.Json.JsonValueKind.Null, finance.GetProperty("salaryMin").ValueKind);
    }

    [Fact]
    public async Task PublicDirectoryFiltersSortsAndCountsOnlyActiveCompaniesAndOpenJobs()
    {
        await using var factory = new DirectoryFactory();
        using var client = factory.CreateClient();
        await factory.Seed();
        var all = (await client.GetFromJsonAsync<PageResult<CompanyListingDto>>("/api/companies"))!;
        Assert.Equal(2, all.TotalCount);
        Assert.Equal("Acme Cloud", all.Items[0].Name);
        Assert.Equal(1, all.Items[0].OpenJobCount);
        Assert.Equal("Cloud Engineer", Assert.Single(all.Items[0].HiringTitles));
        Assert.True(all.Items[0].IsVerified);
        Assert.Equal("Ha Noi", all.Items[0].Province);
        var filtered = (await client.GetFromJsonAsync<PageResult<CompanyListingDto>>($"/api/companies?provinceId={factory.Hanoi.Id}&industryId={factory.Tech.Id}&CompanySizeMin=1001&verifiedOnly=true&hiringOnly=true&keyword=Acme"))!;
        Assert.Equal("Acme Cloud", Assert.Single(filtered.Items).Name);
        var secondaryIndustry = (await client.GetFromJsonAsync<PageResult<CompanyListingDto>>($"/api/companies?industryId={factory.Tech.Id}"))!;
        Assert.Equal(2, secondaryIndustry.TotalCount);
        var noMatch = (await client.GetFromJsonAsync<PageResult<CompanyListingDto>>("/api/companies?keyword=missing"))!;
        Assert.Empty(noMatch.Items);
        var page = (await client.GetFromJsonAsync<PageResult<CompanyListingDto>>("/api/companies?sort=name&pageSize=1&page=2"))!;
        Assert.Equal(2, page.TotalCount);
        Assert.Equal("Beta Bank", Assert.Single(page.Items).Name);
        var detail = (await client.GetFromJsonAsync<PageResult<CompanyListingDto>>($"/api/companies?companyId={factory.Acme.Id}&pageSize=1"))!;
        Assert.Equal(1, detail.TotalCount);
        Assert.Equal(factory.Acme.Id, Assert.Single(detail.Items).Id);
        var missing = (await client.GetFromJsonAsync<PageResult<CompanyListingDto>>($"/api/companies?companyId={Guid.NewGuid()}"))!;
        Assert.Empty(missing.Items);
    }

    [Fact]
    public async Task MetadataAndFeaturedMatchDirectoryData()
    {
        await using var factory = new DirectoryFactory();
        using var client = factory.CreateClient();
        await factory.Seed();
        var metadata = (await client.GetFromJsonAsync<CompanyDirectoryMetadata>("/api/companies/filters"))!;
        Assert.Equal(new CompanyDirectoryStats(2, 1, 1, 1), metadata.Stats);
        Assert.Equal(2, metadata.Provinces.Count);
        Assert.Equal(2, metadata.Industries.Single(x => x.Id == factory.Tech.Id).Count);
        var featured = (await client.GetFromJsonAsync<CompanyListingDto[]>("/api/companies/featured"))!;
        Assert.Equal("Acme Cloud", Assert.Single(featured).Name);
    }

    [Theory]
    [InlineData("page=0")]
    [InlineData("pageSize=101")]
    [InlineData("sort=invalid")]
    [InlineData("CompanySizeMin=0")]
    [InlineData("CompanySizeMax=-1")]
    [InlineData("CompanySizeMin=501&CompanySizeMax=200")]
    [InlineData("provinceId=invalid")]
    public async Task InvalidFiltersReturnValidationError(string query)
    {
        await using var factory = new DirectoryFactory();
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.BadRequest, (await client.GetAsync($"/api/companies?{query}")).StatusCode);
    }

    [Fact]
    public async Task ProvinceFilterIncludesActiveLocationsWithoutCompanies()
    {
        await using var factory = new DirectoryFactory();
        using var client = factory.CreateClient();
        await factory.Seed();
        var province = new Province { ProvinceName = "Cao Bang", ProvinceCode = "04" };
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            db.ProvinceRecords.Add(province);
            await db.SaveChangesAsync();
        }
        var metadata = (await client.GetFromJsonAsync<CompanyDirectoryMetadata>("/api/companies/filters"))!;
        Assert.Equal(3, metadata.Provinces.Count);
        Assert.Equal(0, metadata.Provinces.Single(x => x.Id == province.Id).Count);
    }

    [Fact]
    public async Task FollowingRequiresJwtIsIdempotentAndIsPrivateToTheCandidate()
    {
        await using var factory = new DirectoryFactory();
        using var owner = factory.CreateClient();
        using var other = factory.CreateClient();
        await factory.Seed();
        var path = $"/api/candidate/followed-companies/{factory.Acme.Id}";
        Assert.Equal(HttpStatusCode.Unauthorized, (await owner.PutAsync(path, null)).StatusCode);
        await SignIn(owner, "owner@example.com");
        await SignIn(other, "other@example.com");
        Assert.Equal(HttpStatusCode.NoContent, (await owner.PutAsync(path, null)).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await owner.PutAsync(path, null)).StatusCode);
        Assert.Equal(factory.Acme.Id, Assert.Single((await owner.GetFromJsonAsync<Guid[]>("/api/candidate/followed-companies"))!));
        Assert.Empty((await other.GetFromJsonAsync<Guid[]>("/api/candidate/followed-companies"))!);
        Assert.Equal(HttpStatusCode.NoContent, (await owner.DeleteAsync(path)).StatusCode);
        Assert.Empty((await owner.GetFromJsonAsync<Guid[]>("/api/candidate/followed-companies"))!);
        Assert.Equal(HttpStatusCode.NoContent, (await owner.PutAsync(path, null)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await owner.PutAsync($"/api/candidate/followed-companies/{Guid.NewGuid()}", null)).StatusCode);
        using var scope = factory.Services.CreateScope();
        Assert.Single(await scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>().FollowedCompanyRecords.ToListAsync());
    }

    private static async Task SignIn(HttpClient client, string email)
    {
        var response = await client.PostAsJsonAsync("/api/candidate/auth/register", new { fullName = "Test Candidate", emailOrPhone = email, password = "password123", confirmPassword = "password123" });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var session = (await response.Content.ReadFromJsonAsync<CandidateSessionDto>())!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", session.AccessToken);
    }

    private sealed class DirectoryFactory : WebApplicationFactory<Program>
    {
        private readonly string database = Guid.NewGuid().ToString();
        public Province Hanoi { get; } = new() { ProvinceName = "Ha Noi", ProvinceCode = "HN" };
        public Province Hcm { get; } = new() { ProvinceName = "Ho Chi Minh", ProvinceCode = "HCM" };
        public Industry Tech { get; } = new() { IndustryName = "Technology" };
        public Industry Finance { get; } = new() { IndustryName = "Finance" };
        public Company Acme { get; } = new("Acme Cloud", "Cloud infrastructure") { CompanySizeMin = 1500, CompanySizeMax = 3000, VerificationStatus = "Verified" };
        public async Task Seed()
        {
            using var scope = Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            Acme.HeadOfficeProvinceId = Hanoi.Id; Acme.IndustryId = Tech.Id;
            var beta = new Company("Beta Bank", "Financial services") { HeadOfficeProvinceId = Hcm.Id, IndustryId = Finance.Id, CompanySizeMin = 80, CompanySizeMax = 150 };
            db.AddRange(Hanoi, Hcm, Tech, Finance, Acme, beta, new Company("Hidden Company", "Not public") { Status = EntityStatus.Deleted });
            db.CompanyIndustryRecords.Add(new CompanyIndustry { CompanyId = beta.Id, IndustryId = Tech.Id });
            var closed = new JobPost(Acme.Id, "Closed Role", "Description", "Ha Noi", null, null, DateTimeOffset.UtcNow.AddDays(30)); closed.Close();
            var expired = new JobPost(Acme.Id, "Expired Role", "Description", "Ha Noi", null, null, DateTimeOffset.UtcNow.AddDays(30));
            db.Jobs.AddRange(new JobPost(Acme.Id, "Cloud Engineer", "Build infrastructure", "Ha Noi", null, null, DateTimeOffset.UtcNow.AddDays(30)), closed, expired);
            db.Entry(expired).Property(x => x.ExpiresAt).CurrentValue = DateTimeOffset.UtcNow.AddDays(-1);
            await db.SaveChangesAsync();
        }
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Development");
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<RecruitmentDbContext>();
                services.RemoveAll<DbContextOptions<RecruitmentDbContext>>();
                services.RemoveAll<IDbContextOptionsConfiguration<RecruitmentDbContext>>();
                services.AddDbContext<RecruitmentDbContext>(options => options.UseInMemoryDatabase(database));
            });
        }
    }
}
