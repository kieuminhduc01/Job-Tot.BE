using JobTot.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace JobTot.Infrastructure.Persistence;

public sealed class RecruitmentDbContext(DbContextOptions<RecruitmentDbContext> options) : DbContext(options)
{
    public DbSet<Company> Companies => Set<Company>();
    public DbSet<JobPost> Jobs => Set<JobPost>();
    public DbSet<Account> AccountRecords => Set<Account>();
    public DbSet<CandidateRefreshSession> CandidateRefreshSessions => Set<CandidateRefreshSession>();
    public DbSet<UsedCandidateRefreshToken> UsedCandidateRefreshTokens => Set<UsedCandidateRefreshToken>();
    public DbSet<ExternalLogin> ExternalLoginRecords => Set<ExternalLogin>();
    public DbSet<Province> ProvinceRecords => Set<Province>();
    public DbSet<Industry> IndustryRecords => Set<Industry>();
    public DbSet<CompanyMedia> CompanyMediaRecords => Set<CompanyMedia>();
    public DbSet<RecruiterProfile> RecruiterProfileRecords => Set<RecruiterProfile>();
    public DbSet<CandidateProfile> CandidateProfileRecords => Set<CandidateProfile>();
    public DbSet<Skill> SkillRecords => Set<Skill>();
    public DbSet<CandidateSkill> CandidateSkillRecords => Set<CandidateSkill>();
    public DbSet<CvTemplate> CvTemplateRecords => Set<CvTemplate>();
    public DbSet<CandidateCv> CandidateCvRecords => Set<CandidateCv>();
    public DbSet<EmploymentType> EmploymentTypeRecords => Set<EmploymentType>();
    public DbSet<RecruitmentCampaign> RecruitmentCampaignRecords => Set<RecruitmentCampaign>();
    public DbSet<CampaignSkill> CampaignSkillRecords => Set<CampaignSkill>();
    public DbSet<CampaignBenefit> CampaignBenefitRecords => Set<CampaignBenefit>();
    public DbSet<CampaignStage> CampaignStageRecords => Set<CampaignStage>();
    public DbSet<JobApplication> JobApplicationRecords => Set<JobApplication>();
    public DbSet<ApplicationStageHistory> ApplicationStageHistoryRecords => Set<ApplicationStageHistory>();
    public DbSet<Interview> InterviewRecords => Set<Interview>();
    public DbSet<InterviewFeedback> InterviewFeedbackRecords => Set<InterviewFeedback>();
    public DbSet<TalentTag> TalentTagRecords => Set<TalentTag>();
    public DbSet<TalentPoolTag> TalentPoolTagRecords => Set<TalentPoolTag>();
    public DbSet<SavedJob> SavedJobRecords => Set<SavedJob>();
    public DbSet<FollowedCompany> FollowedCompanyRecords => Set<FollowedCompany>();
    public DbSet<ArticleCategory> ArticleCategoryRecords => Set<ArticleCategory>();
    public DbSet<Article> ArticleRecords => Set<Article>();
    public DbSet<Media> MediaRecords => Set<Media>();
    public DbSet<TalentPoolEntry> TalentPoolEntryRecords => Set<TalentPoolEntry>();
    public DbSet<CompanyIndustry> CompanyIndustryRecords => Set<CompanyIndustry>();
    public DbSet<Benefit> BenefitRecords => Set<Benefit>();
    public DbSet<CvCategory> CvCategoryRecords => Set<CvCategory>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        ErdModelConfiguration.Configure(modelBuilder);
        var session = modelBuilder.Entity<CandidateRefreshSession>();
        session.HasKey(x => x.Id);
        session.Property(x => x.TokenHash).HasMaxLength(64).IsRequired();
        session.Property(x => x.PasswordStamp).HasMaxLength(64).IsRequired();
        session.Property(x => x.Version).IsConcurrencyToken();
        session.HasOne<Account>().WithMany().HasForeignKey(x => x.AccountId).OnDelete(DeleteBehavior.Cascade);
        session.HasIndex(x => x.AccountId);
        var usedToken = modelBuilder.Entity<UsedCandidateRefreshToken>();
        usedToken.HasKey(x => x.TokenHash);
        usedToken.Property(x => x.TokenHash).HasMaxLength(64);
        usedToken.HasOne<CandidateRefreshSession>().WithMany().HasForeignKey(x => x.SessionId).OnDelete(DeleteBehavior.Cascade);
        var company = modelBuilder.Entity<Company>();
        company.HasKey(x => x.Id);
        company.Property(x => x.Name).HasMaxLength(200).IsRequired();
        company.Property(x => x.Description).HasMaxLength(4000).IsRequired();
        var job = modelBuilder.Entity<JobPost>();
        job.HasKey(x => x.Id);
        job.Property(x => x.Title).HasMaxLength(200).IsRequired();
        job.Property(x => x.Description).HasMaxLength(10000).IsRequired();
        job.Property(x => x.Location).HasMaxLength(200).IsRequired();
        job.Property(x => x.SalaryMin).HasPrecision(18, 2);
        job.Property(x => x.SalaryMax).HasPrecision(18, 2);
        job.Property<byte[]>("RowVersion").IsRowVersion();
        job.HasOne<Company>().WithMany().HasForeignKey(x => x.CompanyId).OnDelete(DeleteBehavior.Restrict);
        job.HasIndex(x => new { x.IsClosed, x.ExpiresAt });
        job.HasIndex(x => x.CreatedAt);
        job.ToTable("Jobs", table => table.HasCheckConstraint("CK_Jobs_Salary",
            "([SalaryMin] IS NULL OR [SalaryMin] >= 0) AND ([SalaryMax] IS NULL OR [SalaryMax] >= 0) AND ([SalaryMin] IS NULL OR [SalaryMax] IS NULL OR [SalaryMin] <= [SalaryMax])"));
    }
}
