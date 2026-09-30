IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260924014131_InitialCreate'
)
BEGIN
    CREATE TABLE [Companies] (
        [Id] uniqueidentifier NOT NULL,
        [Name] nvarchar(200) NOT NULL,
        [Description] nvarchar(4000) NOT NULL,
        CONSTRAINT [PK_Companies] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260924014131_InitialCreate'
)
BEGIN
    CREATE TABLE [Jobs] (
        [Id] uniqueidentifier NOT NULL,
        [CompanyId] uniqueidentifier NOT NULL,
        [Title] nvarchar(200) NOT NULL,
        [Description] nvarchar(max) NOT NULL,
        [Location] nvarchar(200) NOT NULL,
        [SalaryMin] decimal(18,2) NULL,
        [SalaryMax] decimal(18,2) NULL,
        [CreatedAt] datetimeoffset NOT NULL,
        [ExpiresAt] datetimeoffset NOT NULL,
        [IsClosed] bit NOT NULL,
        [RowVersion] rowversion NULL,
        CONSTRAINT [PK_Jobs] PRIMARY KEY ([Id]),
        CONSTRAINT [CK_Jobs_Salary] CHECK (([SalaryMin] IS NULL OR [SalaryMin] >= 0) AND ([SalaryMax] IS NULL OR [SalaryMax] >= 0) AND ([SalaryMin] IS NULL OR [SalaryMax] IS NULL OR [SalaryMin] <= [SalaryMax])),
        CONSTRAINT [FK_Jobs_Companies_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [Companies] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260924014131_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Jobs_CompanyId] ON [Jobs] ([CompanyId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260924014131_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Jobs_CreatedAt] ON [Jobs] ([CreatedAt]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260924014131_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Jobs_IsClosed_ExpiresAt] ON [Jobs] ([IsClosed], [ExpiresAt]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260924014131_InitialCreate'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260924014131_InitialCreate', N'9.0.9');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    EXEC sp_rename N'[Companies].[Name]', N'DisplayName', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    EXEC sp_rename N'[Companies].[Description]', N'About', 'COLUMN';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [AddressLine] nvarchar(200) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [CompanySizeMax] int NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [CompanySizeMin] int NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [CoverFileId] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [CreatedAccountId] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET());
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [Culture] nvarchar(max) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [Email] nvarchar(320) NOT NULL DEFAULT N'';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [FoundedYear] int NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [HeadOfficeProvinceId] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [IndustryId] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [LegalName] nvarchar(200) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [LogoFileId] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [Phone] nvarchar(32) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [Slug] nvarchar(200) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [Status] int NOT NULL DEFAULT 1;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [TaxCode] nvarchar(200) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [UpdatedAccountId] uniqueidentifier NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [UpdatedDate] datetimeoffset NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [VerificationStatus] nvarchar(200) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD [WebsiteUrl] nvarchar(2048) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [Account] (
        [Id] uniqueidentifier NOT NULL,
        [Email] nvarchar(320) NOT NULL,
        [Phone] nvarchar(32) NULL,
        [PasswordHash] nvarchar(1024) NULL,
        [FullName] nvarchar(200) NOT NULL,
        [AccountType] nvarchar(200) NULL,
        [AccountStatus] nvarchar(200) NULL,
        [EmailVerifiedAt] datetimeoffset NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_Account] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Account_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_Account_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [ArticleCategory] (
        [Id] uniqueidentifier NOT NULL,
        [CategoryName] nvarchar(200) NOT NULL,
        [Slug] nvarchar(200) NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_ArticleCategory] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_ArticleCategory_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_ArticleCategory_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [Benefit] (
        [Id] uniqueidentifier NOT NULL,
        [BenefitName] nvarchar(200) NOT NULL,
        [Detail] nvarchar(max) NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_Benefit] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Benefit_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_Benefit_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [CvCategory] (
        [Id] uniqueidentifier NOT NULL,
        [Name] nvarchar(200) NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_CvCategory] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_CvCategory_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CvCategory_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [EmploymentType] (
        [Id] uniqueidentifier NOT NULL,
        [TypeName] nvarchar(200) NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_EmploymentType] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_EmploymentType_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_EmploymentType_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [ExternalLogin] (
        [Id] uniqueidentifier NOT NULL,
        [AccountId] uniqueidentifier NOT NULL,
        [Provider] nvarchar(200) NOT NULL,
        [ProviderSubject] nvarchar(256) NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_ExternalLogin] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_ExternalLogin_Account_AccountId] FOREIGN KEY ([AccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_ExternalLogin_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_ExternalLogin_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [Industry] (
        [Id] uniqueidentifier NOT NULL,
        [IndustryName] nvarchar(200) NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_Industry] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Industry_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_Industry_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [Media] (
        [Id] uniqueidentifier NOT NULL,
        [Url] nvarchar(2048) NOT NULL,
        [Type] nvarchar(200) NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_Media] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Media_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_Media_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [Province] (
        [Id] uniqueidentifier NOT NULL,
        [ProvinceName] nvarchar(200) NOT NULL,
        [ProvinceCode] nvarchar(200) NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_Province] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Province_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_Province_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [RecruiterProfile] (
        [Id] uniqueidentifier NOT NULL,
        [AccountId] uniqueidentifier NOT NULL,
        [CompanyId] uniqueidentifier NOT NULL,
        [JobTitle] nvarchar(200) NULL,
        [WorkPhone] nvarchar(32) NULL,
        [IsCompanyAdmin] bit NOT NULL,
        [JoinedAt] datetimeoffset NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_RecruiterProfile] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_RecruiterProfile_Account_AccountId] FOREIGN KEY ([AccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_RecruiterProfile_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_RecruiterProfile_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_RecruiterProfile_Companies_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [Companies] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [Skill] (
        [Id] uniqueidentifier NOT NULL,
        [SkillName] nvarchar(200) NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_Skill] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Skill_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_Skill_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [TalentTag] (
        [Id] uniqueidentifier NOT NULL,
        [CompanyId] uniqueidentifier NOT NULL,
        [TagName] nvarchar(200) NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_TalentTag] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_TalentTag_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_TalentTag_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_TalentTag_Companies_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [Companies] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [Article] (
        [Id] uniqueidentifier NOT NULL,
        [ArticleCategoryId] uniqueidentifier NOT NULL,
        [AuthorAccountId] uniqueidentifier NOT NULL,
        [Title] nvarchar(200) NOT NULL,
        [Slug] nvarchar(200) NULL,
        [Summary] nvarchar(max) NULL,
        [Body] nvarchar(max) NULL,
        [CoverUrl] nvarchar(2048) NULL,
        [PublishedAt] datetimeoffset NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_Article] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Article_Account_AuthorAccountId] FOREIGN KEY ([AuthorAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_Article_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_Article_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_Article_ArticleCategory_ArticleCategoryId] FOREIGN KEY ([ArticleCategoryId]) REFERENCES [ArticleCategory] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [CvTemplate] (
        [Id] uniqueidentifier NOT NULL,
        [Name] nvarchar(200) NOT NULL,
        [CategoryId] uniqueidentifier NOT NULL,
        [PreviewUrl] nvarchar(2048) NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_CvTemplate] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_CvTemplate_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CvTemplate_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CvTemplate_CvCategory_CategoryId] FOREIGN KEY ([CategoryId]) REFERENCES [CvCategory] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [CompanyIndustry] (
        [Id] uniqueidentifier NOT NULL,
        [CompanyId] uniqueidentifier NOT NULL,
        [IndustryId] uniqueidentifier NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_CompanyIndustry] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_CompanyIndustry_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CompanyIndustry_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CompanyIndustry_Companies_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [Companies] ([Id]),
        CONSTRAINT [FK_CompanyIndustry_Industry_IndustryId] FOREIGN KEY ([IndustryId]) REFERENCES [Industry] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [CompanyMedia] (
        [Id] uniqueidentifier NOT NULL,
        [CompanyId] uniqueidentifier NOT NULL,
        [MediaId] uniqueidentifier NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_CompanyMedia] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_CompanyMedia_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CompanyMedia_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CompanyMedia_Companies_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [Companies] ([Id]),
        CONSTRAINT [FK_CompanyMedia_Media_MediaId] FOREIGN KEY ([MediaId]) REFERENCES [Media] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [CandidateProfile] (
        [Id] uniqueidentifier NOT NULL,
        [AccountId] uniqueidentifier NOT NULL,
        [ProvinceId] uniqueidentifier NULL,
        [Headline] nvarchar(200) NULL,
        [BirthDate] date NULL,
        [YearsExperience] int NULL,
        [ExpectedSalaryMin] decimal(18,2) NULL,
        [ExpectedSalaryMax] decimal(18,2) NULL,
        [ReadyStatus] nvarchar(200) NULL,
        [Summary] nvarchar(max) NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_CandidateProfile] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_CandidateProfile_Account_AccountId] FOREIGN KEY ([AccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CandidateProfile_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CandidateProfile_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CandidateProfile_Province_ProvinceId] FOREIGN KEY ([ProvinceId]) REFERENCES [Province] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [RecruitmentCampaign] (
        [Id] uniqueidentifier NOT NULL,
        [CompanyId] uniqueidentifier NOT NULL,
        [OwnerRecruiterId] uniqueidentifier NOT NULL,
        [IndustryId] uniqueidentifier NOT NULL,
        [ProvinceId] uniqueidentifier NOT NULL,
        [EmploymentTypeId] uniqueidentifier NOT NULL,
        [Title] nvarchar(200) NOT NULL,
        [Department] nvarchar(200) NULL,
        [Description] nvarchar(max) NULL,
        [Requirements] nvarchar(max) NULL,
        [WorkAddress] nvarchar(200) NULL,
        [WorkMode] nvarchar(200) NULL,
        [Seniority] nvarchar(200) NULL,
        [EducationLevel] nvarchar(200) NULL,
        [ExperienceMinYears] int NULL,
        [ExperienceMaxYears] int NULL,
        [SalaryMin] decimal(18,2) NULL,
        [SalaryMax] decimal(18,2) NULL,
        [SalaryVisible] bit NOT NULL,
        [AgeMin] int NULL,
        [AgeMax] int NULL,
        [GenderPreference] nvarchar(200) NULL,
        [Openings] int NOT NULL,
        [StartDate] date NULL,
        [EndDate] date NULL,
        [CampaignStatus] nvarchar(200) NULL,
        [Slug] nvarchar(200) NULL,
        [PublishedAt] datetimeoffset NULL,
        [ExpiresAt] datetimeoffset NULL,
        [PostingStatus] nvarchar(200) NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_RecruitmentCampaign] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_RecruitmentCampaign_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_RecruitmentCampaign_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_RecruitmentCampaign_Companies_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [Companies] ([Id]),
        CONSTRAINT [FK_RecruitmentCampaign_EmploymentType_EmploymentTypeId] FOREIGN KEY ([EmploymentTypeId]) REFERENCES [EmploymentType] ([Id]),
        CONSTRAINT [FK_RecruitmentCampaign_Industry_IndustryId] FOREIGN KEY ([IndustryId]) REFERENCES [Industry] ([Id]),
        CONSTRAINT [FK_RecruitmentCampaign_Province_ProvinceId] FOREIGN KEY ([ProvinceId]) REFERENCES [Province] ([Id]),
        CONSTRAINT [FK_RecruitmentCampaign_RecruiterProfile_OwnerRecruiterId] FOREIGN KEY ([OwnerRecruiterId]) REFERENCES [RecruiterProfile] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [CandidateCv] (
        [Id] uniqueidentifier NOT NULL,
        [CandidateId] uniqueidentifier NOT NULL,
        [CvTemplateId] uniqueidentifier NULL,
        [Title] nvarchar(200) NOT NULL,
        [FileUrl] nvarchar(2048) NULL,
        [ContentJson] nvarchar(max) NULL,
        [IsDefault] bit NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_CandidateCv] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_CandidateCv_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CandidateCv_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CandidateCv_CandidateProfile_CandidateId] FOREIGN KEY ([CandidateId]) REFERENCES [CandidateProfile] ([Id]),
        CONSTRAINT [FK_CandidateCv_CvTemplate_CvTemplateId] FOREIGN KEY ([CvTemplateId]) REFERENCES [CvTemplate] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [CandidateSkill] (
        [Id] uniqueidentifier NOT NULL,
        [CandidateId] uniqueidentifier NOT NULL,
        [SkillId] uniqueidentifier NOT NULL,
        [Proficiency] int NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_CandidateSkill] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_CandidateSkill_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CandidateSkill_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CandidateSkill_CandidateProfile_CandidateId] FOREIGN KEY ([CandidateId]) REFERENCES [CandidateProfile] ([Id]),
        CONSTRAINT [FK_CandidateSkill_Skill_SkillId] FOREIGN KEY ([SkillId]) REFERENCES [Skill] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [FollowedCompany] (
        [Id] uniqueidentifier NOT NULL,
        [CandidateId] uniqueidentifier NOT NULL,
        [CompanyId] uniqueidentifier NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_FollowedCompany] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_FollowedCompany_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_FollowedCompany_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_FollowedCompany_CandidateProfile_CandidateId] FOREIGN KEY ([CandidateId]) REFERENCES [CandidateProfile] ([Id]),
        CONSTRAINT [FK_FollowedCompany_Companies_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [Companies] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [TalentPoolEntry] (
        [Id] uniqueidentifier NOT NULL,
        [CompanyId] uniqueidentifier NOT NULL,
        [CandidateId] uniqueidentifier NOT NULL,
        [AddedByRecruiterId] uniqueidentifier NOT NULL,
        [ReadinessStatus] nvarchar(200) NULL,
        [Notes] nvarchar(max) NULL,
        [AddedAt] datetimeoffset NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_TalentPoolEntry] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_TalentPoolEntry_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_TalentPoolEntry_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_TalentPoolEntry_CandidateProfile_CandidateId] FOREIGN KEY ([CandidateId]) REFERENCES [CandidateProfile] ([Id]),
        CONSTRAINT [FK_TalentPoolEntry_Companies_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [Companies] ([Id]),
        CONSTRAINT [FK_TalentPoolEntry_RecruiterProfile_AddedByRecruiterId] FOREIGN KEY ([AddedByRecruiterId]) REFERENCES [RecruiterProfile] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [CampaignBenefit] (
        [Id] uniqueidentifier NOT NULL,
        [CampaignId] uniqueidentifier NOT NULL,
        [BenefitId] uniqueidentifier NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_CampaignBenefit] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_CampaignBenefit_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CampaignBenefit_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CampaignBenefit_Benefit_BenefitId] FOREIGN KEY ([BenefitId]) REFERENCES [Benefit] ([Id]),
        CONSTRAINT [FK_CampaignBenefit_RecruitmentCampaign_CampaignId] FOREIGN KEY ([CampaignId]) REFERENCES [RecruitmentCampaign] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [CampaignSkill] (
        [Id] uniqueidentifier NOT NULL,
        [CampaignId] uniqueidentifier NOT NULL,
        [SkillId] uniqueidentifier NOT NULL,
        [IsRequired] bit NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_CampaignSkill] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_CampaignSkill_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CampaignSkill_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CampaignSkill_RecruitmentCampaign_CampaignId] FOREIGN KEY ([CampaignId]) REFERENCES [RecruitmentCampaign] ([Id]),
        CONSTRAINT [FK_CampaignSkill_Skill_SkillId] FOREIGN KEY ([SkillId]) REFERENCES [Skill] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [CampaignStage] (
        [Id] uniqueidentifier NOT NULL,
        [CampaignId] uniqueidentifier NOT NULL,
        [StageName] nvarchar(200) NOT NULL,
        [StageOrder] int NOT NULL,
        [StageKind] nvarchar(200) NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_CampaignStage] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_CampaignStage_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CampaignStage_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_CampaignStage_RecruitmentCampaign_CampaignId] FOREIGN KEY ([CampaignId]) REFERENCES [RecruitmentCampaign] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [SavedJob] (
        [Id] uniqueidentifier NOT NULL,
        [CandidateId] uniqueidentifier NOT NULL,
        [RecruitmentCampaignId] uniqueidentifier NOT NULL,
        [SavedAt] datetimeoffset NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_SavedJob] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_SavedJob_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_SavedJob_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_SavedJob_CandidateProfile_CandidateId] FOREIGN KEY ([CandidateId]) REFERENCES [CandidateProfile] ([Id]),
        CONSTRAINT [FK_SavedJob_RecruitmentCampaign_RecruitmentCampaignId] FOREIGN KEY ([RecruitmentCampaignId]) REFERENCES [RecruitmentCampaign] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [TalentPoolTag] (
        [Id] uniqueidentifier NOT NULL,
        [TalentPoolEntryId] uniqueidentifier NOT NULL,
        [TalentTagId] uniqueidentifier NOT NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_TalentPoolTag] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_TalentPoolTag_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_TalentPoolTag_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_TalentPoolTag_TalentPoolEntry_TalentPoolEntryId] FOREIGN KEY ([TalentPoolEntryId]) REFERENCES [TalentPoolEntry] ([Id]),
        CONSTRAINT [FK_TalentPoolTag_TalentTag_TalentTagId] FOREIGN KEY ([TalentTagId]) REFERENCES [TalentTag] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [Application] (
        [Id] uniqueidentifier NOT NULL,
        [CampaignId] uniqueidentifier NOT NULL,
        [CandidateId] uniqueidentifier NOT NULL,
        [CvId] uniqueidentifier NULL,
        [StageId] uniqueidentifier NULL,
        [Source] nvarchar(200) NULL,
        [ApplicationStatus] nvarchar(200) NULL,
        [AppliedAt] datetimeoffset NOT NULL,
        [CoverLetter] nvarchar(max) NULL,
        [MatchScore] decimal(18,2) NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_Application] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Application_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_Application_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_Application_CampaignStage_StageId] FOREIGN KEY ([StageId]) REFERENCES [CampaignStage] ([Id]),
        CONSTRAINT [FK_Application_CandidateCv_CvId] FOREIGN KEY ([CvId]) REFERENCES [CandidateCv] ([Id]),
        CONSTRAINT [FK_Application_CandidateProfile_CandidateId] FOREIGN KEY ([CandidateId]) REFERENCES [CandidateProfile] ([Id]),
        CONSTRAINT [FK_Application_RecruitmentCampaign_CampaignId] FOREIGN KEY ([CampaignId]) REFERENCES [RecruitmentCampaign] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [ApplicationStageHistory] (
        [Id] uniqueidentifier NOT NULL,
        [ApplicationId] uniqueidentifier NOT NULL,
        [StageId] uniqueidentifier NOT NULL,
        [ChangedByRecruiterId] uniqueidentifier NOT NULL,
        [Note] nvarchar(max) NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_ApplicationStageHistory] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_ApplicationStageHistory_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_ApplicationStageHistory_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_ApplicationStageHistory_Application_ApplicationId] FOREIGN KEY ([ApplicationId]) REFERENCES [Application] ([Id]),
        CONSTRAINT [FK_ApplicationStageHistory_CampaignStage_StageId] FOREIGN KEY ([StageId]) REFERENCES [CampaignStage] ([Id]),
        CONSTRAINT [FK_ApplicationStageHistory_RecruiterProfile_ChangedByRecruiterId] FOREIGN KEY ([ChangedByRecruiterId]) REFERENCES [RecruiterProfile] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [Interview] (
        [Id] uniqueidentifier NOT NULL,
        [ApplicationId] uniqueidentifier NOT NULL,
        [StageId] uniqueidentifier NOT NULL,
        [ScheduledStart] datetimeoffset NOT NULL,
        [ScheduledEnd] datetimeoffset NOT NULL,
        [MeetingUrl] nvarchar(2048) NULL,
        [Location] nvarchar(200) NULL,
        [InterviewStatus] nvarchar(200) NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_Interview] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Interview_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_Interview_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_Interview_Application_ApplicationId] FOREIGN KEY ([ApplicationId]) REFERENCES [Application] ([Id]),
        CONSTRAINT [FK_Interview_CampaignStage_StageId] FOREIGN KEY ([StageId]) REFERENCES [CampaignStage] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE TABLE [InterviewFeedback] (
        [Id] uniqueidentifier NOT NULL,
        [InterviewId] uniqueidentifier NOT NULL,
        [RecruiterId] uniqueidentifier NOT NULL,
        [Score] decimal(18,2) NULL,
        [Decision] nvarchar(200) NULL,
        [Comment] nvarchar(max) NULL,
        [SubmittedAt] datetimeoffset NULL,
        [Status] int NOT NULL DEFAULT 1,
        [CreatedDate] datetimeoffset NOT NULL DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedAccountId] uniqueidentifier NULL,
        [UpdatedDate] datetimeoffset NULL,
        [UpdatedAccountId] uniqueidentifier NULL,
        CONSTRAINT [PK_InterviewFeedback] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_InterviewFeedback_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_InterviewFeedback_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]),
        CONSTRAINT [FK_InterviewFeedback_Interview_InterviewId] FOREIGN KEY ([InterviewId]) REFERENCES [Interview] ([Id]),
        CONSTRAINT [FK_InterviewFeedback_RecruiterProfile_RecruiterId] FOREIGN KEY ([RecruiterId]) REFERENCES [RecruiterProfile] ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Companies_CoverFileId] ON [Companies] ([CoverFileId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Companies_CreatedAccountId] ON [Companies] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Companies_HeadOfficeProvinceId] ON [Companies] ([HeadOfficeProvinceId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Companies_IndustryId] ON [Companies] ([IndustryId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Companies_LogoFileId] ON [Companies] ([LogoFileId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Companies_UpdatedAccountId] ON [Companies] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Account_CreatedAccountId] ON [Account] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Account_Email] ON [Account] ([Email]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Account_UpdatedAccountId] ON [Account] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Application_CampaignId] ON [Application] ([CampaignId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Application_CandidateId] ON [Application] ([CandidateId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Application_CreatedAccountId] ON [Application] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Application_CvId] ON [Application] ([CvId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Application_StageId] ON [Application] ([StageId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Application_UpdatedAccountId] ON [Application] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_ApplicationStageHistory_ApplicationId] ON [ApplicationStageHistory] ([ApplicationId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_ApplicationStageHistory_ChangedByRecruiterId] ON [ApplicationStageHistory] ([ChangedByRecruiterId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_ApplicationStageHistory_CreatedAccountId] ON [ApplicationStageHistory] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_ApplicationStageHistory_StageId] ON [ApplicationStageHistory] ([StageId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_ApplicationStageHistory_UpdatedAccountId] ON [ApplicationStageHistory] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Article_ArticleCategoryId] ON [Article] ([ArticleCategoryId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Article_AuthorAccountId] ON [Article] ([AuthorAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Article_CreatedAccountId] ON [Article] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Article_UpdatedAccountId] ON [Article] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_ArticleCategory_CreatedAccountId] ON [ArticleCategory] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_ArticleCategory_UpdatedAccountId] ON [ArticleCategory] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Benefit_CreatedAccountId] ON [Benefit] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Benefit_UpdatedAccountId] ON [Benefit] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CampaignBenefit_BenefitId] ON [CampaignBenefit] ([BenefitId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE UNIQUE INDEX [IX_CampaignBenefit_CampaignId_BenefitId] ON [CampaignBenefit] ([CampaignId], [BenefitId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CampaignBenefit_CreatedAccountId] ON [CampaignBenefit] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CampaignBenefit_UpdatedAccountId] ON [CampaignBenefit] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE UNIQUE INDEX [IX_CampaignSkill_CampaignId_SkillId] ON [CampaignSkill] ([CampaignId], [SkillId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CampaignSkill_CreatedAccountId] ON [CampaignSkill] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CampaignSkill_SkillId] ON [CampaignSkill] ([SkillId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CampaignSkill_UpdatedAccountId] ON [CampaignSkill] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CampaignStage_CampaignId] ON [CampaignStage] ([CampaignId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CampaignStage_CreatedAccountId] ON [CampaignStage] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CampaignStage_UpdatedAccountId] ON [CampaignStage] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [IX_CandidateCv_CandidateId] ON [CandidateCv] ([CandidateId]) WHERE [IsDefault] = 1');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CandidateCv_CreatedAccountId] ON [CandidateCv] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CandidateCv_CvTemplateId] ON [CandidateCv] ([CvTemplateId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CandidateCv_UpdatedAccountId] ON [CandidateCv] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE UNIQUE INDEX [IX_CandidateProfile_AccountId] ON [CandidateProfile] ([AccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CandidateProfile_CreatedAccountId] ON [CandidateProfile] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CandidateProfile_ProvinceId] ON [CandidateProfile] ([ProvinceId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CandidateProfile_UpdatedAccountId] ON [CandidateProfile] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE UNIQUE INDEX [IX_CandidateSkill_CandidateId_SkillId] ON [CandidateSkill] ([CandidateId], [SkillId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CandidateSkill_CreatedAccountId] ON [CandidateSkill] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CandidateSkill_SkillId] ON [CandidateSkill] ([SkillId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CandidateSkill_UpdatedAccountId] ON [CandidateSkill] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE UNIQUE INDEX [IX_CompanyIndustry_CompanyId_IndustryId] ON [CompanyIndustry] ([CompanyId], [IndustryId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CompanyIndustry_CreatedAccountId] ON [CompanyIndustry] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CompanyIndustry_IndustryId] ON [CompanyIndustry] ([IndustryId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CompanyIndustry_UpdatedAccountId] ON [CompanyIndustry] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE UNIQUE INDEX [IX_CompanyMedia_CompanyId_MediaId] ON [CompanyMedia] ([CompanyId], [MediaId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CompanyMedia_CreatedAccountId] ON [CompanyMedia] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CompanyMedia_MediaId] ON [CompanyMedia] ([MediaId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CompanyMedia_UpdatedAccountId] ON [CompanyMedia] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CvCategory_CreatedAccountId] ON [CvCategory] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CvCategory_UpdatedAccountId] ON [CvCategory] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CvTemplate_CategoryId] ON [CvTemplate] ([CategoryId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CvTemplate_CreatedAccountId] ON [CvTemplate] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_CvTemplate_UpdatedAccountId] ON [CvTemplate] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_EmploymentType_CreatedAccountId] ON [EmploymentType] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_EmploymentType_UpdatedAccountId] ON [EmploymentType] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_ExternalLogin_AccountId] ON [ExternalLogin] ([AccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_ExternalLogin_CreatedAccountId] ON [ExternalLogin] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE UNIQUE INDEX [IX_ExternalLogin_Provider_ProviderSubject] ON [ExternalLogin] ([Provider], [ProviderSubject]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_ExternalLogin_UpdatedAccountId] ON [ExternalLogin] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE UNIQUE INDEX [IX_FollowedCompany_CandidateId_CompanyId] ON [FollowedCompany] ([CandidateId], [CompanyId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_FollowedCompany_CompanyId] ON [FollowedCompany] ([CompanyId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_FollowedCompany_CreatedAccountId] ON [FollowedCompany] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_FollowedCompany_UpdatedAccountId] ON [FollowedCompany] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Industry_CreatedAccountId] ON [Industry] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Industry_UpdatedAccountId] ON [Industry] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Interview_ApplicationId] ON [Interview] ([ApplicationId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Interview_CreatedAccountId] ON [Interview] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Interview_StageId] ON [Interview] ([StageId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Interview_UpdatedAccountId] ON [Interview] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_InterviewFeedback_CreatedAccountId] ON [InterviewFeedback] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_InterviewFeedback_InterviewId] ON [InterviewFeedback] ([InterviewId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_InterviewFeedback_RecruiterId] ON [InterviewFeedback] ([RecruiterId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_InterviewFeedback_UpdatedAccountId] ON [InterviewFeedback] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Media_CreatedAccountId] ON [Media] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Media_UpdatedAccountId] ON [Media] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Province_CreatedAccountId] ON [Province] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Province_UpdatedAccountId] ON [Province] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_RecruiterProfile_AccountId] ON [RecruiterProfile] ([AccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_RecruiterProfile_CompanyId] ON [RecruiterProfile] ([CompanyId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_RecruiterProfile_CreatedAccountId] ON [RecruiterProfile] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_RecruiterProfile_UpdatedAccountId] ON [RecruiterProfile] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_RecruitmentCampaign_CompanyId] ON [RecruitmentCampaign] ([CompanyId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_RecruitmentCampaign_CreatedAccountId] ON [RecruitmentCampaign] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_RecruitmentCampaign_EmploymentTypeId] ON [RecruitmentCampaign] ([EmploymentTypeId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_RecruitmentCampaign_IndustryId] ON [RecruitmentCampaign] ([IndustryId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_RecruitmentCampaign_OwnerRecruiterId] ON [RecruitmentCampaign] ([OwnerRecruiterId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_RecruitmentCampaign_ProvinceId] ON [RecruitmentCampaign] ([ProvinceId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_RecruitmentCampaign_UpdatedAccountId] ON [RecruitmentCampaign] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE UNIQUE INDEX [IX_SavedJob_CandidateId_RecruitmentCampaignId] ON [SavedJob] ([CandidateId], [RecruitmentCampaignId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_SavedJob_CreatedAccountId] ON [SavedJob] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_SavedJob_RecruitmentCampaignId] ON [SavedJob] ([RecruitmentCampaignId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_SavedJob_UpdatedAccountId] ON [SavedJob] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Skill_CreatedAccountId] ON [Skill] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_Skill_UpdatedAccountId] ON [Skill] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_TalentPoolEntry_AddedByRecruiterId] ON [TalentPoolEntry] ([AddedByRecruiterId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_TalentPoolEntry_CandidateId] ON [TalentPoolEntry] ([CandidateId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_TalentPoolEntry_CompanyId] ON [TalentPoolEntry] ([CompanyId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_TalentPoolEntry_CreatedAccountId] ON [TalentPoolEntry] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_TalentPoolEntry_UpdatedAccountId] ON [TalentPoolEntry] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_TalentPoolTag_CreatedAccountId] ON [TalentPoolTag] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE UNIQUE INDEX [IX_TalentPoolTag_TalentPoolEntryId_TalentTagId] ON [TalentPoolTag] ([TalentPoolEntryId], [TalentTagId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_TalentPoolTag_TalentTagId] ON [TalentPoolTag] ([TalentTagId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_TalentPoolTag_UpdatedAccountId] ON [TalentPoolTag] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_TalentTag_CompanyId] ON [TalentTag] ([CompanyId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_TalentTag_CreatedAccountId] ON [TalentTag] ([CreatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    CREATE INDEX [IX_TalentTag_UpdatedAccountId] ON [TalentTag] ([UpdatedAccountId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD CONSTRAINT [FK_Companies_Account_CreatedAccountId] FOREIGN KEY ([CreatedAccountId]) REFERENCES [Account] ([Id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD CONSTRAINT [FK_Companies_Account_UpdatedAccountId] FOREIGN KEY ([UpdatedAccountId]) REFERENCES [Account] ([Id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD CONSTRAINT [FK_Companies_Industry_IndustryId] FOREIGN KEY ([IndustryId]) REFERENCES [Industry] ([Id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD CONSTRAINT [FK_Companies_Media_CoverFileId] FOREIGN KEY ([CoverFileId]) REFERENCES [Media] ([Id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD CONSTRAINT [FK_Companies_Media_LogoFileId] FOREIGN KEY ([LogoFileId]) REFERENCES [Media] ([Id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    ALTER TABLE [Companies] ADD CONSTRAINT [FK_Companies_Province_HeadOfficeProvinceId] FOREIGN KEY ([HeadOfficeProvinceId]) REFERENCES [Province] ([Id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260929083524_AddErdModels'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260929083524_AddErdModels', N'9.0.9');
END;

COMMIT;
GO

