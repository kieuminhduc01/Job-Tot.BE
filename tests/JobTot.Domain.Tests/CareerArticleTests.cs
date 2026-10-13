using System.Net;
using System.Net.Http.Headers;
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

public class CareerArticleTests
{
    [Fact]
    public async Task AdminCanDraftPublishHideAndCannotOverwriteStaleVersion()
    {
        await using var factory = new Factory();
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/admin/career-articles")).StatusCode);
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
            var account = new Account { Email = "writer@test.local", FullName = "Writer", AccountType = "Admin", AccountStatus = "Active" };
            account.PasswordHash = scope.ServiceProvider.GetRequiredService<IAccountPasswordHasher>().Hash(account, "article-password123");
            db.Add(account); await db.SaveChangesAsync();
        }
        var login = await client.PostAsJsonAsync("/api/admin/auth/login", new { emailOrPhone = "writer@test.local", password = "article-password123" });
        login.EnsureSuccessStatusCode();
        var session = await login.Content.ReadFromJsonAsync<JsonElement>();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", session.GetProperty("accessToken").GetString());
        var create = await client.PostAsJsonAsync("/api/admin/career-articles", new { title = "CV guide", category = "CV", summary = "", content = "", published = false });
        create.EnsureSuccessStatusCode();
        var draft = (await create.Content.ReadFromJsonAsync<CareerArticle>())!;
        using (var upload = new MultipartFormDataContent())
        {
            var image = new ByteArrayContent(Convert.FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a5ZkAAAAASUVORK5CYII="));
            image.Headers.ContentType = new MediaTypeHeaderValue("image/png");
            upload.Add(image, "file", "cover.png");
            upload.Add(new StringContent(draft.Version.ToString()), "version");
            var uploaded = await client.PostAsync($"/api/admin/career-articles/{draft.Id}/cover", upload);
            uploaded.EnsureSuccessStatusCode();
            draft = (await uploaded.Content.ReadFromJsonAsync<CareerArticle>())!;
            Assert.StartsWith("/uploads/articles/", draft.CoverUrl);
            Assert.Equal("cover.png", draft.CoverFileName);
            Assert.Equal("image/png", draft.CoverContentType);
            Assert.True(draft.CoverSize > 0);
        }
        Assert.Empty((await client.GetFromJsonAsync<JsonElement[]>("/api/career-articles"))!);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"/api/career-articles/{draft.Id}")).StatusCode);
        var invalid = await client.PutAsJsonAsync($"/api/admin/career-articles/{draft.Id}", new { draft.Title, draft.Category, draft.Summary, draft.Content, published = true, draft.Version });
        Assert.Equal(HttpStatusCode.BadRequest, invalid.StatusCode);
        var publish = await client.PutAsJsonAsync($"/api/admin/career-articles/{draft.Id}", new { draft.Title, draft.Category, summary = "Write a CV", content = "## Experience\n**Achievements**", published = true, draft.Version });
        publish.EnsureSuccessStatusCode();
        var article = (await publish.Content.ReadFromJsonAsync<CareerArticle>())!;
        Assert.Equal(draft.CoverUrl, article.CoverUrl);
        var publicArticle = await client.GetFromJsonAsync<CareerArticle>($"/api/career-articles/{article.Id}");
        Assert.Equal(article.CoverUrl, publicArticle!.CoverUrl);
        Assert.Single((await client.GetFromJsonAsync<JsonElement[]>("/api/career-articles"))!);
        var stale = await client.PutAsJsonAsync($"/api/admin/career-articles/{draft.Id}", new { draft.Title, draft.Category, summary = "Stale", content = "Old", published = true, draft.Version });
        Assert.Equal(HttpStatusCode.Conflict, stale.StatusCode);
        var hide = await client.PutAsJsonAsync($"/api/admin/career-articles/{draft.Id}", new { article.Title, article.Category, article.Summary, article.Content, published = false, article.Version });
        hide.EnsureSuccessStatusCode();
        Assert.Empty((await client.GetFromJsonAsync<JsonElement[]>("/api/career-articles"))!);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync($"/api/career-articles/{draft.Id}")).StatusCode);
    }
    private sealed class Factory : WebApplicationFactory<Program>
    {
        private readonly string database = Guid.NewGuid().ToString();
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Development");
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<RecruitmentDbContext>(); services.RemoveAll<DbContextOptions<RecruitmentDbContext>>(); services.RemoveAll<IDbContextOptionsConfiguration<RecruitmentDbContext>>();
                services.AddDbContext<RecruitmentDbContext>(options => options.UseInMemoryDatabase(database));
            });
        }
    }
}
