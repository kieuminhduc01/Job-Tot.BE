using JobTot.Domain.Entities;
using JobTot.Domain.Enums;
using JobTot.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace JobTot.Domain.Tests;

public sealed class ErdModelTests
{
    private static RecruitmentDbContext CreateContext() => new(
        new DbContextOptionsBuilder<RecruitmentDbContext>()
            .UseSqlServer("Server=(localdb)\\MSSQLLocalDB;Database=JobTotModelTests;Trusted_Connection=True")
            .Options);

    [Fact]
    public void AllErdEntitiesHaveAuditForeignKeysAndNoImplicitForeignKeys()
    {
        using var context = CreateContext();
        var entities = context.Model.GetEntityTypes()
            .Where(x => typeof(AuditableEntity).IsAssignableFrom(x.ClrType)).ToArray();
        Assert.Equal(32, entities.Length);
        foreach (var entity in entities)
        {
            var status = entity.FindProperty(nameof(AuditableEntity.Status))!;
            Assert.Equal(typeof(EntityStatus), status.ClrType);
            Assert.Equal(EntityStatus.Active, status.GetDefaultValue());
            var converter = status.GetTypeMapping().Converter!;
            Assert.Equal(typeof(int), converter.ProviderClrType);
            foreach (var value in Enum.GetValues<EntityStatus>())
            {
                Assert.Equal((int)value, converter.ConvertToProvider(value));
                Assert.Equal(value, converter.ConvertFromProvider((int)value));
            }
            Assert.Equal("Id", Assert.Single(entity.FindPrimaryKey()!.Properties).Name);
            foreach (var auditKey in new[] { "CreatedAccountId", "UpdatedAccountId" })
            {
                var fk = Assert.Single(entity.GetForeignKeys(), x => x.Properties.Single().Name == auditKey);
                Assert.Equal(typeof(Account), fk.PrincipalEntityType.ClrType);
                Assert.False(fk.IsRequired);
            }
            foreach (var fk in entity.GetForeignKeys())
            {
                Assert.Equal(DeleteBehavior.NoAction, fk.DeleteBehavior);
                Assert.All(fk.Properties, property => Assert.False(property.IsShadowProperty()));
            }
        }
    }

    [Fact]
    public void CandidateAccountIsOneToOneAndJoinPairsAreUnique()
    {
        using var context = CreateContext();
        var candidate = context.Model.FindEntityType(typeof(CandidateProfile))!;
        Assert.True(candidate.GetForeignKeys().Single(x => x.Properties.Single().Name == "AccountId").IsUnique);
        foreach (var type in new[] { typeof(CandidateSkill), typeof(CampaignSkill), typeof(CampaignBenefit),
                     typeof(CompanyIndustry), typeof(CompanyMedia), typeof(TalentPoolTag), typeof(SavedJob), typeof(FollowedCompany) })
        {
            Assert.Contains(context.Model.FindEntityType(type)!.GetIndexes(), x => x.IsUnique && x.Properties.Count == 2);
        }
        var sql = context.Database.GenerateCreateScript();
        Assert.Contains("CREATE TABLE [Application]", sql);
        Assert.Contains("CREATE TABLE [CvCategory]", sql);
        Assert.Contains("WHERE [IsDefault] = 1", sql);
    }
}
