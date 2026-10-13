using System.Text.RegularExpressions;
using JobTot.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;

namespace JobTot.Domain.Tests;

public sealed class SqlSeedSchemaTests
{
    [Fact]
    public void AllSeedInsertTablesAndColumnsMatchTheSqlServerModel()
    {
        // SQL Server conventions differ from InMemory for DbSet-derived table names.
        using var db = new RecruitmentDbContext(new DbContextOptionsBuilder<RecruitmentDbContext>()
            .UseSqlServer("Server=localhost;Database=SchemaValidationOnly;Trusted_Connection=True;TrustServerCertificate=True")
            .Options);
        var tables = db.Model.GetEntityTypes().GroupBy(e => e.GetTableName()!).ToDictionary(g => g.Key,
            g => g.SelectMany(e => e.GetProperties().Select(p => p.GetColumnName(StoreObjectIdentifier.Table(e.GetTableName()!, e.GetSchema())))).ToHashSet());
        var path = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../SQL/seed-demo.sql"));
        var checkedRows = 0;
        var checkedTables = new HashSet<string>();
        foreach (var line in File.ReadLines(path))
        {
            var match = Regex.Match(line, @"INSERT INTO \[dbo\]\.\[(?<table>\w+)\] \((?<columns>[^)]+)\) VALUES");
            if (!match.Success) continue;
            var table = match.Groups["table"].Value;
            Assert.True(tables.ContainsKey(table), $"Seed targets an unmapped table: {table}");
            foreach (Match column in Regex.Matches(match.Groups["columns"].Value, @"\[(?<name>\w+)\]"))
                Assert.Contains(column.Groups["name"].Value, tables[table]);
            checkedRows++; checkedTables.Add(table);
        }
        Assert.Equal(24276, checkedRows);
        Assert.Equal(22, checkedTables.Count);
    }
}
