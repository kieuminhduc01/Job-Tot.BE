-- Additive, idempotent deployment of the talent discovery interest table only.
-- Existing candidate profiles, applications and talent-pool entries are retained.
-- Run against the intended JobTot database; no database selection is hardcoded.
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID(N'dbo.EmployerCandidateInterests', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.EmployerCandidateInterests (
        Id uniqueidentifier NOT NULL,
        CompanyId uniqueidentifier NOT NULL,
        CandidateId uniqueidentifier NOT NULL,
        InterestedByRecruiterId uniqueidentifier NOT NULL,
        InterestedAt datetimeoffset NOT NULL,
        CONSTRAINT PK_EmployerCandidateInterests PRIMARY KEY (Id),
        CONSTRAINT FK_EmployerCandidateInterests_Companies_CompanyId
            FOREIGN KEY (CompanyId) REFERENCES dbo.Companies (Id),
        CONSTRAINT FK_EmployerCandidateInterests_CandidateProfile_CandidateId
            FOREIGN KEY (CandidateId) REFERENCES dbo.CandidateProfile (Id),
        CONSTRAINT FK_EmployerCandidateInterests_RecruiterProfile_InterestedByRecruiterId
            FOREIGN KEY (InterestedByRecruiterId) REFERENCES dbo.RecruiterProfile (Id)
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.EmployerCandidateInterests') AND name = N'IX_EmployerCandidateInterests_CompanyId_CandidateId')
    CREATE UNIQUE INDEX IX_EmployerCandidateInterests_CompanyId_CandidateId
        ON dbo.EmployerCandidateInterests (CompanyId, CandidateId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.EmployerCandidateInterests') AND name = N'IX_EmployerCandidateInterests_CandidateId')
    CREATE INDEX IX_EmployerCandidateInterests_CandidateId ON dbo.EmployerCandidateInterests (CandidateId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.EmployerCandidateInterests') AND name = N'IX_EmployerCandidateInterests_InterestedByRecruiterId')
    CREATE INDEX IX_EmployerCandidateInterests_InterestedByRecruiterId ON dbo.EmployerCandidateInterests (InterestedByRecruiterId);

-- Keep the EF migration history in sync when this focused script is used.
IF OBJECT_ID(N'dbo.__EFMigrationsHistory', N'U') IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM dbo.__EFMigrationsHistory WHERE MigrationId = N'20261011125002_AddEmployerCandidateInterest')
    INSERT dbo.__EFMigrationsHistory (MigrationId, ProductVersion)
        VALUES (N'20261011125002_AddEmployerCandidateInterest', N'9.0.9');

COMMIT TRANSACTION;
