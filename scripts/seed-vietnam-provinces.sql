-- Official province catalog, Decision 19/2025/QD-TTg, effective 2025-07-01.
-- Source: https://chinhphu.vn/?classid=1&docid=214409&orggroupid=3&pageid=27160
-- Catalog: https://baochinhphu.vn/bang-danh-muc-va-ma-so-cua-34-tinh-thanh-moi-3321-don-vi-hanh-chinh-cap-xa-moi-102250704153652947.htm
-- Updates the eight old demo codes in place and inserts missing provinces; no records or foreign keys are deleted.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N'JobTot' THROW 51000, 'This seed is intended for the JobTot database.', 1;
DECLARE @Now datetimeoffset = TODATETIMEOFFSET(SYSUTCDATETIME(), '+00:00');
BEGIN TRY
    BEGIN TRANSACTION;
    -- Official 34-province catalog; preserve existing IDs referenced by company/profile/campaign records.
    DECLARE @ProvinceLock int;
    EXEC @ProvinceLock = sp_getapplock @Resource = N'JobTot.ProvinceCatalog2025.v1', @LockMode = N'Exclusive', @LockOwner = N'Transaction', @LockTimeout = 10000;
    IF @ProvinceLock < 0 THROW 51010, 'Could not acquire the province-catalog lock.', 1;
    DECLARE @Provinces TABLE (SeedKey int PRIMARY KEY, Id uniqueidentifier NOT NULL, Code nvarchar(2) NOT NULL,
        Name nvarchar(200) NOT NULL, LegacyCode nvarchar(32), ShortName nvarchar(200));
    INSERT @Provinces VALUES
    (0, '54bd3831-74df-5b54-85ff-02737690b10d', N'01', N'Thành phố Hà Nội', N'HN', N'Hà Nội'),
    (1, '2e82ceac-e076-5cf7-bccc-0697742e11c0', N'04', N'Tỉnh Cao Bằng', NULL, N'Cao Bằng'),
    (2, 'e29a9af8-17ff-5a80-ba10-f754b263e56a', N'08', N'Tỉnh Tuyên Quang', NULL, N'Tuyên Quang'),
    (3, 'b136712b-1043-53b9-8374-3aef559ab837', N'11', N'Tỉnh Điện Biên', NULL, N'Điện Biên'),
    (4, 'b382665b-7a93-5eec-933b-8c70092c0481', N'12', N'Tỉnh Lai Châu', NULL, N'Lai Châu'),
    (5, 'cd80a8b4-5370-5e1b-afc6-ff8eec7ed59b', N'14', N'Tỉnh Sơn La', NULL, N'Sơn La'),
    (6, 'a69b05cb-7a45-5085-8d71-33b45bd9a6b3', N'15', N'Tỉnh Lào Cai', NULL, N'Lào Cai'),
    (7, '81fa4959-d918-5355-b43e-ca08a395f6bc', N'19', N'Tỉnh Thái Nguyên', NULL, N'Thái Nguyên'),
    (8, 'c106084d-8cbd-5a6e-b047-82b7350ceff7', N'20', N'Tỉnh Lạng Sơn', NULL, N'Lạng Sơn'),
    (9, '64717ea7-3cc2-5c44-ac4e-21c49ccc8fc9', N'22', N'Tỉnh Quảng Ninh', NULL, N'Quảng Ninh'),
    (10, 'e313f03a-2648-507e-8b69-b747e5907025', N'24', N'Tỉnh Bắc Ninh', N'BN', N'Bắc Ninh'),
    (11, 'da030fb6-0491-557a-a803-563cda99e347', N'25', N'Tỉnh Phú Thọ', NULL, N'Phú Thọ'),
    (12, '9736c8ad-7d6b-5b1c-b380-a7f9c525af73', N'31', N'Thành phố Hải Phòng', N'HP', N'Hải Phòng'),
    (13, '7ca50baa-9bfb-5621-a39e-08c4ad41610c', N'33', N'Tỉnh Hưng Yên', NULL, N'Hưng Yên'),
    (14, '9c403db3-5c06-5a0e-8bfa-0d6eb845d52d', N'37', N'Tỉnh Ninh Bình', NULL, N'Ninh Bình'),
    (15, '20bfc303-33dc-56fd-812a-7a562e1401bd', N'38', N'Tỉnh Thanh Hóa', NULL, N'Thanh Hóa'),
    (16, '2ee614a2-e520-517e-814d-d271462492a2', N'40', N'Tỉnh Nghệ An', NULL, N'Nghệ An'),
    (17, '3a6255bd-7cc4-5c0d-bb40-54cc0b74e99e', N'42', N'Tỉnh Hà Tĩnh', NULL, N'Hà Tĩnh'),
    (18, '40ff6d5e-b1b1-5dd9-9044-afbe03753cb1', N'44', N'Tỉnh Quảng Trị', NULL, N'Quảng Trị'),
    (19, 'bf429093-e00d-5d42-a3c5-7efe10681191', N'46', N'Thành phố Huế', NULL, N'Huế'),
    (20, '81d762a0-acb6-50ce-982f-157aa1ce0d4e', N'48', N'Thành phố Đà Nẵng', N'DN', N'Đà Nẵng'),
    (21, '3e08c994-e270-5983-8950-b90aa3e0daf0', N'51', N'Tỉnh Quảng Ngãi', NULL, N'Quảng Ngãi'),
    (22, 'd2e60022-ae89-5b22-81ff-8768a53f09cf', N'52', N'Tỉnh Gia Lai', NULL, N'Gia Lai'),
    (23, '3ec9bb20-9119-58e5-a4a9-ab76cdcef57e', N'56', N'Tỉnh Khánh Hòa', N'KH', N'Khánh Hòa'),
    (24, '81046739-9f76-5ddc-91d4-414b08915f4a', N'66', N'Tỉnh Đắk Lắk', NULL, N'Đắk Lắk'),
    (25, '5d24cf49-f06b-5b20-80b4-44f6fdeb8551', N'68', N'Tỉnh Lâm Đồng', NULL, N'Lâm Đồng'),
    (26, '1f0a8110-a932-5cbd-bc2d-1c2a2c433782', N'75', N'Tỉnh Đồng Nai', N'DNA', N'Đồng Nai'),
    (27, '5a6bc8d3-830f-5ed3-9176-32fc48ac1ad7', N'79', N'Thành phố Hồ Chí Minh', N'HCM', N'Hồ Chí Minh'),
    (28, '94710927-f472-5de6-8ace-a52f907c9360', N'80', N'Tỉnh Tây Ninh', NULL, N'Tây Ninh'),
    (29, 'f4f9a378-e2ea-5050-93ec-e3afc0951909', N'82', N'Tỉnh Đồng Tháp', NULL, N'Đồng Tháp'),
    (30, '5905d630-f549-5669-a331-a893b90e5996', N'86', N'Tỉnh Vĩnh Long', NULL, N'Vĩnh Long'),
    (31, 'd73e9eff-4c48-5f1a-b3fb-7d48dd297e47', N'91', N'Tỉnh An Giang', NULL, N'An Giang'),
    (32, '872256a7-7240-5fb3-8f0f-ee9613ac3adb', N'92', N'Thành phố Cần Thơ', N'CT', N'Cần Thơ'),
    (33, 'd13562d7-6b66-560f-b939-54ba89322c20', N'96', N'Tỉnh Cà Mau', NULL, N'Cà Mau');
    IF EXISTS (SELECT seed.SeedKey FROM @Provinces seed JOIN dbo.Province actual
        ON actual.ProvinceCode = seed.Code OR actual.ProvinceCode = seed.LegacyCode
        OR actual.ProvinceName = seed.Name OR actual.ProvinceName = seed.ShortName
        GROUP BY seed.SeedKey HAVING COUNT(*) > 1)
        THROW 51011, 'Duplicate province matches must be reconciled before importing the catalog.', 1;
    UPDATE seed SET Id = existing.Id FROM @Provinces seed CROSS APPLY
        (SELECT TOP (1) Id FROM dbo.Province WHERE ProvinceCode = seed.Code OR ProvinceCode = seed.LegacyCode
            OR ProvinceName = seed.Name OR ProvinceName = seed.ShortName ORDER BY Id) existing;
    UPDATE actual SET ProvinceCode = seed.Code, ProvinceName = seed.Name, Status = 1, UpdatedDate = @Now
    FROM dbo.Province actual JOIN @Provinces seed ON actual.Id = seed.Id
    WHERE actual.ProvinceCode <> seed.Code OR actual.ProvinceName <> seed.Name OR actual.Status <> 1;
    DECLARE @UpdatedProvinces int = @@ROWCOUNT;
    INSERT dbo.Province (Id, ProvinceCode, ProvinceName, Status, CreatedDate)
    SELECT Id, Code, Name, 1, @Now FROM @Provinces seed WHERE NOT EXISTS (SELECT 1 FROM dbo.Province actual WHERE actual.Id = seed.Id);
    DECLARE @InsertedProvinces int = @@ROWCOUNT;
    IF (SELECT COUNT(*) FROM dbo.Province actual JOIN @Provinces seed ON actual.Id = seed.Id
        WHERE actual.ProvinceCode = seed.Code AND actual.ProvinceName = seed.Name AND actual.Status = 1) <> 34
        THROW 51012, 'Expected 34 active provinces with official names and codes.', 1;

    COMMIT TRANSACTION;
    SELECT @InsertedProvinces AS InsertedProvinces, @UpdatedProvinces AS UpdatedProvinces,
        (SELECT COUNT(*) FROM dbo.Province actual JOIN @Provinces seed ON actual.Id = seed.Id WHERE actual.Status = 1) AS OfficialProvinces;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
