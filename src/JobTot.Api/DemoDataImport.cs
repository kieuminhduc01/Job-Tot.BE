using System.Text.Json;
using System.Text.Json.Nodes;
using JobTot.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace JobTot.Api;

internal static class DemoDataImport
{
    internal static async Task RunAsync(RecruitmentDbContext db, string path)
    {
        using var document = JsonDocument.Parse(await File.ReadAllTextAsync(path));
        var rows = document.RootElement.EnumerateArray().Select(row => new DemoDataset
        {
            Key = row.GetProperty("key").GetString() ?? throw new InvalidDataException("Missing key."),
            Payload = row.GetProperty("payload").GetRawText()
        }).ToArray();
        if (rows.Any(x => x.Key.Length > 100) || rows.Select(x => x.Key).Distinct().Count() != rows.Length)
            throw new InvalidDataException("Invalid or duplicate dataset keys.");
        await db.Database.CreateExecutionStrategy().ExecuteAsync(async () =>
        {
            await using var transaction = await db.Database.BeginTransactionAsync();
            await db.Database.ExecuteSqlRawAsync("IF OBJECT_ID(N'dbo.DemoDatasets', N'U') IS NULL CREATE TABLE dbo.DemoDatasets ([Key] nvarchar(100) NOT NULL PRIMARY KEY, Payload nvarchar(max) NOT NULL CHECK (ISJSON(Payload)=1));");
            foreach (var row in rows)
            {
                // Re-running provisioning preserves database edits.
                await db.Database.ExecuteSqlInterpolatedAsync($"IF NOT EXISTS (SELECT 1 FROM dbo.DemoDatasets WITH (UPDLOCK, HOLDLOCK) WHERE [Key]={row.Key}) INSERT INTO dbo.DemoDatasets ([Key], Payload) VALUES ({row.Key}, {row.Payload});");
                var stored = await db.DemoDatasets.AsNoTracking().Where(x => x.Key == row.Key).Select(x => x.Payload).SingleAsync();
                if (JsonNode.Parse(stored) is JsonObject existing && JsonNode.Parse(row.Payload) is JsonObject incoming)
                {
                    var added = false;
                    foreach (var field in incoming)
                        if (!existing.ContainsKey(field.Key)) { existing.Add(field.Key, field.Value?.DeepClone()); added = true; }
                    if (added)
                    {
                        var enriched = existing.ToJsonString();
                        await db.Database.ExecuteSqlInterpolatedAsync($"UPDATE dbo.DemoDatasets SET Payload={enriched} WHERE [Key]={row.Key};");
                    }
                }
            }
            await transaction.CommitAsync();
        });
        Console.WriteLine($"Imported {rows.Length} datasets (existing records preserved).");
    }
}
