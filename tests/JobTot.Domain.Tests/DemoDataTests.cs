using System.Net;
using System.Net.Http.Json;
using JobTot.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace JobTot.Domain.Tests;

public sealed class DemoDataTests
{
    [Fact]
    public async Task ReadsDatabaseChangesAndDoesNotInventMissingDatasets()
    {
        await using var factory = new Factory();
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync("/api/demo-data/messages-candidate")).StatusCode);
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<RecruitmentDbContext>();
        var row = new DemoDataset { Key = "messages-candidate", Payload = "[{\"name\":\"Database record\"}]" };
        db.Add(row); await db.SaveChangesAsync();
        var data = await client.GetFromJsonAsync<System.Text.Json.JsonElement>("/api/demo-data/messages-candidate");
        Assert.Equal("Database record", data[0].GetProperty("name").GetString());
        row.Payload = "[]"; await db.SaveChangesAsync();
        data = await client.GetFromJsonAsync<System.Text.Json.JsonElement>("/api/demo-data/messages-candidate");
        Assert.Equal(0, data.GetArrayLength());
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync("/api/demo-data/private-key")).StatusCode);
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
