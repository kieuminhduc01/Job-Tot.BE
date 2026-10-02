-- JobTot development fixture: 100 fictional companies and 500 linked job posts.
-- Generated IDs are deterministic. Re-running inserts missing rows only.
-- No existing accounts, companies, jobs, or application data are deleted or updated.
-- Run from BE/JobTot with sqlcmd -S '.\SQLEXPRESS' -d JobTot -E -C -b -f 65001 -i scripts/seed-company-directory.sql
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N'JobTot' THROW 51000, 'This development seed is intended for the JobTot database.', 1;
DECLARE @Now datetimeoffset = TODATETIMEOFFSET(SYSUTCDATETIME(), '+00:00');
DECLARE @AddedCompanies int = 0, @AddedJobs int = 0;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @LockResult int;
    EXEC @LockResult = sp_getapplock @Resource = N'JobTot.CompanyDirectoryDemoSeed.v1', @LockMode = N'Exclusive', @LockOwner = N'Transaction', @LockTimeout = 10000;
    IF @LockResult < 0 THROW 51001, 'Could not acquire the demo-seed lock.', 1;

    DECLARE @Industries TABLE (SeedKey int PRIMARY KEY, Id uniqueidentifier NOT NULL, Name nvarchar(200) NOT NULL);
    INSERT @Industries VALUES
    (0, 'af4ecc51-6b06-5534-9dd7-b877ce65c8dd', N'Công nghệ thông tin'),
    (1, '606b76ae-c049-56fd-a9a7-922a6c7723ee', N'Ngân hàng & Tài chính'),
    (2, '620288c4-d445-5619-847e-be963246e5f6', N'Thương mại điện tử'),
    (3, '6934c8d0-c6a9-57fe-a667-c919fbf91477', N'Logistics & Chuỗi cung ứng'),
    (4, '8c46739c-657b-5d03-8172-88de4c4cf6a3', N'Sản xuất & Kỹ thuật'),
    (5, '325b9f41-732c-5706-95d9-56e443cbd48f', N'Giáo dục & Đào tạo'),
    (6, '75397ff5-e6bd-590e-8724-fa51b1f44b05', N'Y tế & Chăm sóc sức khỏe'),
    (7, '83047ab2-aea6-5c4f-81d3-9f85a02dd31e', N'Du lịch & Khách sạn'),
    (8, '08c6a422-b68a-50dd-9ca2-7970b45477f1', N'Xây dựng & Bất động sản'),
    (9, '877ab4eb-d1f7-5676-a23b-6d0a22ec8eff', N'Truyền thông & Thiết kế');
    UPDATE seed SET Id = existing.Id FROM @Industries seed CROSS APPLY
        (SELECT TOP (1) Id FROM dbo.Industry WHERE IndustryName = seed.Name ORDER BY Id) existing;
    INSERT dbo.Industry (Id, IndustryName, Status, CreatedDate)
    SELECT Id, Name, 1, @Now FROM @Industries seed WHERE NOT EXISTS (SELECT 1 FROM dbo.Industry actual WHERE actual.Id = seed.Id);

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


    DECLARE @Images TABLE (Id uniqueidentifier PRIMARY KEY, Url nvarchar(2048), Type nvarchar(200));
    INSERT @Images VALUES
    ('e8541eb9-9ce9-5049-afaa-33836243ee3a', N'/images/demo-companies/cover-01.svg', N'CompanyCover'),
    ('6c14ffe4-e635-5118-a339-60998b2053b4', N'/images/demo-companies/cover-02.svg', N'CompanyCover'),
    ('be04e479-e762-5bc6-b24e-a7e6eebfbc01', N'/images/demo-companies/cover-03.svg', N'CompanyCover'),
    ('c26f7514-5aae-5cef-9074-669241d4ab7f', N'/images/demo-companies/cover-04.svg', N'CompanyCover'),
    ('7c11da0b-ea99-5e94-8e57-b576ec985b93', N'/images/demo-companies/cover-05.svg', N'CompanyCover'),
    ('2bfe1315-2733-55f7-971a-be3f2a9c3829', N'/images/demo-companies/cover-06.svg', N'CompanyCover'),
    ('d310be06-cf0c-59af-b3f8-9857a492f4bd', N'/images/demo-companies/cover-07.svg', N'CompanyCover'),
    ('aa5116eb-cf88-5dba-ac12-6583cf1245d3', N'/images/demo-companies/cover-08.svg', N'CompanyCover'),
    ('b171d966-7156-5892-9a95-6219098d55c0', N'/images/demo-companies/cover-09.svg', N'CompanyCover'),
    ('f441acfc-4eac-58a2-9305-f27c14221f76', N'/images/demo-companies/cover-10.svg', N'CompanyCover'),
    ('abb01a0d-d9d3-5376-babe-8ac49aafc931', N'/images/demo-companies/logo-001.svg', N'CompanyLogo'),
    ('06e03fa6-0f91-5600-a4ed-da4fbe0cfb56', N'/images/demo-companies/logo-002.svg', N'CompanyLogo'),
    ('74b4832a-7bbd-589e-9402-0e1468a5f783', N'/images/demo-companies/logo-003.svg', N'CompanyLogo'),
    ('5cd01cca-b78b-521e-8f20-15e7e1db2cf5', N'/images/demo-companies/logo-004.svg', N'CompanyLogo'),
    ('e0e654bf-ee42-55d9-878b-88d3e234ca38', N'/images/demo-companies/logo-005.svg', N'CompanyLogo'),
    ('5e299125-2f6d-5c96-8318-53b7e7c26771', N'/images/demo-companies/logo-006.svg', N'CompanyLogo'),
    ('5a3f5e6e-f207-520a-b106-679e163a1561', N'/images/demo-companies/logo-007.svg', N'CompanyLogo'),
    ('69527e82-1f51-5c5b-b959-93d6a3132504', N'/images/demo-companies/logo-008.svg', N'CompanyLogo'),
    ('abc26507-44db-5c9e-8a72-b62a003c5634', N'/images/demo-companies/logo-009.svg', N'CompanyLogo'),
    ('9126ec63-a9dc-55a5-ab94-7df75e8ee482', N'/images/demo-companies/logo-010.svg', N'CompanyLogo'),
    ('78fa1e3b-8bc2-5f19-8ccb-22b80c803aa8', N'/images/demo-companies/logo-011.svg', N'CompanyLogo'),
    ('70414d3f-cba2-5f4e-a84e-4f38ad99a733', N'/images/demo-companies/logo-012.svg', N'CompanyLogo'),
    ('132ee626-972c-59fb-8403-fee66b886bfd', N'/images/demo-companies/logo-013.svg', N'CompanyLogo'),
    ('daa0ad39-91a8-5ff7-936f-8fc10de17b09', N'/images/demo-companies/logo-014.svg', N'CompanyLogo'),
    ('3cd5207d-0652-54fc-9a55-8b0e023b720a', N'/images/demo-companies/logo-015.svg', N'CompanyLogo'),
    ('763497bf-486c-52a1-a26f-c8cc0fabc853', N'/images/demo-companies/logo-016.svg', N'CompanyLogo'),
    ('66837afd-f946-55f5-8421-84a90bdaa44b', N'/images/demo-companies/logo-017.svg', N'CompanyLogo'),
    ('603119bf-68be-5861-bca8-46ec191dd17a', N'/images/demo-companies/logo-018.svg', N'CompanyLogo'),
    ('98a47ee0-167b-5f2c-bb73-7f51ddf6fd26', N'/images/demo-companies/logo-019.svg', N'CompanyLogo'),
    ('5fd4e73c-b281-58b7-9554-84fcda683a2e', N'/images/demo-companies/logo-020.svg', N'CompanyLogo'),
    ('ede4bd42-430b-57d9-9bdf-39eee924a38c', N'/images/demo-companies/logo-021.svg', N'CompanyLogo'),
    ('ad8e8d62-6a09-5143-8a27-72f373967115', N'/images/demo-companies/logo-022.svg', N'CompanyLogo'),
    ('c48e4813-9f41-524d-bdab-e75bd0d96793', N'/images/demo-companies/logo-023.svg', N'CompanyLogo'),
    ('5994c096-6634-520f-8c9c-4c8e18a2fd56', N'/images/demo-companies/logo-024.svg', N'CompanyLogo'),
    ('970e2d14-5e43-52a7-92e8-a202d0f720a8', N'/images/demo-companies/logo-025.svg', N'CompanyLogo'),
    ('c93883ce-3430-5d9c-855e-05670163d3fb', N'/images/demo-companies/logo-026.svg', N'CompanyLogo'),
    ('e5b25a59-5d4f-5fb6-b2f0-6ff59513a471', N'/images/demo-companies/logo-027.svg', N'CompanyLogo'),
    ('551aae78-c531-5893-b6e4-34a4944ef50e', N'/images/demo-companies/logo-028.svg', N'CompanyLogo'),
    ('7855c0c4-fd93-530c-ba29-19621e82bac6', N'/images/demo-companies/logo-029.svg', N'CompanyLogo'),
    ('5bd14a28-bc1a-565f-b715-7de7439800b9', N'/images/demo-companies/logo-030.svg', N'CompanyLogo'),
    ('e95ac58a-6dec-598e-b91c-1e62e064ead3', N'/images/demo-companies/logo-031.svg', N'CompanyLogo'),
    ('3a1d981f-026c-5e3e-84aa-ce2f803463cd', N'/images/demo-companies/logo-032.svg', N'CompanyLogo'),
    ('cbd98cc6-7436-5ab6-8100-668c4a6862cb', N'/images/demo-companies/logo-033.svg', N'CompanyLogo'),
    ('c7226fde-dc8f-5299-8bea-81a3363e602e', N'/images/demo-companies/logo-034.svg', N'CompanyLogo'),
    ('7523b462-f3e1-572e-9dae-62a4bb047882', N'/images/demo-companies/logo-035.svg', N'CompanyLogo'),
    ('3381e971-bfdb-5f42-804c-b3d6958605cf', N'/images/demo-companies/logo-036.svg', N'CompanyLogo'),
    ('e0674c5b-8d0d-5d4c-a97b-9794e5ce7bc6', N'/images/demo-companies/logo-037.svg', N'CompanyLogo'),
    ('8bf9ceec-d6ef-5622-9bfd-88351db3d8db', N'/images/demo-companies/logo-038.svg', N'CompanyLogo'),
    ('c0a14267-43d7-54bc-807b-6d933e42a991', N'/images/demo-companies/logo-039.svg', N'CompanyLogo'),
    ('06567352-cc21-51a3-a21d-85a1c8f8711b', N'/images/demo-companies/logo-040.svg', N'CompanyLogo'),
    ('a2c1b5c0-3540-5fe5-a5ed-c30eed1273a3', N'/images/demo-companies/logo-041.svg', N'CompanyLogo'),
    ('87a3a32a-acc8-5f60-bfef-d684fcdf705a', N'/images/demo-companies/logo-042.svg', N'CompanyLogo'),
    ('24ed8eb3-e750-5045-aaed-d6b042c9fb3c', N'/images/demo-companies/logo-043.svg', N'CompanyLogo'),
    ('dd4ab0b0-c36c-5541-b3fe-e5b92e0cf25a', N'/images/demo-companies/logo-044.svg', N'CompanyLogo'),
    ('764ad3a5-9ed8-5347-83d6-591d4fa03373', N'/images/demo-companies/logo-045.svg', N'CompanyLogo'),
    ('a64e7a65-12a3-5282-98ec-f1049d0d4958', N'/images/demo-companies/logo-046.svg', N'CompanyLogo'),
    ('d8054743-0eb3-5213-b25e-e1b2411f23d3', N'/images/demo-companies/logo-047.svg', N'CompanyLogo'),
    ('0b4bf75d-1eee-5402-919b-296a6f0cd940', N'/images/demo-companies/logo-048.svg', N'CompanyLogo'),
    ('5b8d3379-9ae4-5ef8-9226-f655fdaac833', N'/images/demo-companies/logo-049.svg', N'CompanyLogo'),
    ('ae449637-269d-5ed1-859d-c2bd82cab848', N'/images/demo-companies/logo-050.svg', N'CompanyLogo'),
    ('a0a7d9dd-0d42-5fbd-bd35-d0651648ec8f', N'/images/demo-companies/logo-051.svg', N'CompanyLogo'),
    ('8f6543ea-0eb7-517e-87af-63677bc60f55', N'/images/demo-companies/logo-052.svg', N'CompanyLogo'),
    ('b486f278-96b8-5bcc-9724-58a465d10173', N'/images/demo-companies/logo-053.svg', N'CompanyLogo'),
    ('be698dda-cf65-5b79-859f-708d3671e71d', N'/images/demo-companies/logo-054.svg', N'CompanyLogo'),
    ('3f66a1af-d0e9-5371-8781-01a579f6b29c', N'/images/demo-companies/logo-055.svg', N'CompanyLogo'),
    ('303b0b8a-764b-5ed5-969c-98dfa5e28758', N'/images/demo-companies/logo-056.svg', N'CompanyLogo'),
    ('b582d350-2cf5-5176-a5fe-aa71d1f5d154', N'/images/demo-companies/logo-057.svg', N'CompanyLogo'),
    ('953768f5-224b-521c-af67-006b9f12f69f', N'/images/demo-companies/logo-058.svg', N'CompanyLogo'),
    ('bcf3d3c1-613d-586c-9599-0b1afeded74a', N'/images/demo-companies/logo-059.svg', N'CompanyLogo'),
    ('13260622-b95d-5376-aaca-65f395411a22', N'/images/demo-companies/logo-060.svg', N'CompanyLogo'),
    ('e2f31011-f317-56e1-b4d3-e1b842a739d0', N'/images/demo-companies/logo-061.svg', N'CompanyLogo'),
    ('85f34cf1-73c9-5a57-9e14-40561c557dea', N'/images/demo-companies/logo-062.svg', N'CompanyLogo'),
    ('efad99d9-fd1d-5567-b9e8-9874d1d8984a', N'/images/demo-companies/logo-063.svg', N'CompanyLogo'),
    ('8101acc7-b5d5-5f66-a3e4-4165e7988a8d', N'/images/demo-companies/logo-064.svg', N'CompanyLogo'),
    ('2fc602ff-7f91-58f9-afe7-664dc0fa7e3b', N'/images/demo-companies/logo-065.svg', N'CompanyLogo'),
    ('0001f464-ab21-5eb0-b8f5-1463ea4ba9c0', N'/images/demo-companies/logo-066.svg', N'CompanyLogo'),
    ('814af29e-cd70-5d6c-b460-c543169b6767', N'/images/demo-companies/logo-067.svg', N'CompanyLogo'),
    ('da7b6d9f-34a8-5b8f-91cc-5c7c5b7725df', N'/images/demo-companies/logo-068.svg', N'CompanyLogo'),
    ('8e23a98a-f878-5f60-9d78-75bf5585ef18', N'/images/demo-companies/logo-069.svg', N'CompanyLogo'),
    ('62815d49-8fd6-5c38-9777-51afec83bd40', N'/images/demo-companies/logo-070.svg', N'CompanyLogo'),
    ('025fcc35-648b-5856-87bf-d789b2109b34', N'/images/demo-companies/logo-071.svg', N'CompanyLogo'),
    ('67b1ede1-cab2-5b83-86e2-3f0eb2337080', N'/images/demo-companies/logo-072.svg', N'CompanyLogo'),
    ('47c1ff9b-c1a3-5d61-8ea3-1408ca33dbd3', N'/images/demo-companies/logo-073.svg', N'CompanyLogo'),
    ('3b2630a0-db12-5d9f-a084-e8a53fd36252', N'/images/demo-companies/logo-074.svg', N'CompanyLogo'),
    ('f4515214-d065-57a8-a4c0-f8bfb64d4222', N'/images/demo-companies/logo-075.svg', N'CompanyLogo'),
    ('a889a2a3-f4b1-5d71-a046-077cf7769bbe', N'/images/demo-companies/logo-076.svg', N'CompanyLogo'),
    ('62f7cb6b-36fb-55e6-a91f-52f0cab31f7f', N'/images/demo-companies/logo-077.svg', N'CompanyLogo'),
    ('e94a4423-e97b-5bcc-a176-5b1f9565463e', N'/images/demo-companies/logo-078.svg', N'CompanyLogo'),
    ('c50d6faa-043f-5ecf-bdb3-0acf7f9ed07f', N'/images/demo-companies/logo-079.svg', N'CompanyLogo'),
    ('dd703261-7bb2-50ac-b5e8-93fdcb096f36', N'/images/demo-companies/logo-080.svg', N'CompanyLogo'),
    ('0bdc7158-95bf-5859-9900-0beb5402a81e', N'/images/demo-companies/logo-081.svg', N'CompanyLogo'),
    ('ae3b91e4-78ac-5b61-8d7a-17315a5266f1', N'/images/demo-companies/logo-082.svg', N'CompanyLogo'),
    ('15939fb3-a480-5c82-b7e7-ea9564d7a43d', N'/images/demo-companies/logo-083.svg', N'CompanyLogo'),
    ('860ce60f-ed1c-5fcd-84d7-06d310a20d61', N'/images/demo-companies/logo-084.svg', N'CompanyLogo'),
    ('411c76c9-7176-5402-a70d-abfa74eab168', N'/images/demo-companies/logo-085.svg', N'CompanyLogo'),
    ('9487df7b-2120-5273-a17f-d83c43c0c778', N'/images/demo-companies/logo-086.svg', N'CompanyLogo'),
    ('8866dd1e-0c54-524f-a4f2-8d0dc6e4f017', N'/images/demo-companies/logo-087.svg', N'CompanyLogo'),
    ('d90f9f1b-988e-5830-b36c-2f6e4899129e', N'/images/demo-companies/logo-088.svg', N'CompanyLogo'),
    ('b6717b3f-fe92-55b0-b48e-aeec38c5ff35', N'/images/demo-companies/logo-089.svg', N'CompanyLogo'),
    ('5dbe9d47-482c-586b-aa45-2a600d3f3bcd', N'/images/demo-companies/logo-090.svg', N'CompanyLogo'),
    ('6c25f35b-1dc7-593e-b60e-8d77883e38a0', N'/images/demo-companies/logo-091.svg', N'CompanyLogo'),
    ('f33cf6e4-a614-5e5d-aea5-ef5803b6ab19', N'/images/demo-companies/logo-092.svg', N'CompanyLogo'),
    ('8d37f5bd-6123-5ef6-a98b-92f773430a64', N'/images/demo-companies/logo-093.svg', N'CompanyLogo'),
    ('c0aa5832-0877-5fe0-9a23-d37ba9149989', N'/images/demo-companies/logo-094.svg', N'CompanyLogo'),
    ('2f6883fe-f0e3-55de-9259-ce9c36759435', N'/images/demo-companies/logo-095.svg', N'CompanyLogo'),
    ('56389389-38ac-532e-bed3-01aeea8d84d7', N'/images/demo-companies/logo-096.svg', N'CompanyLogo'),
    ('d196ff02-e847-5829-a9fd-55ecd9bb19ff', N'/images/demo-companies/logo-097.svg', N'CompanyLogo'),
    ('7861f676-8d15-5915-bcd5-9988f6335b19', N'/images/demo-companies/logo-098.svg', N'CompanyLogo'),
    ('a48de814-ca1f-5e17-b228-b967785b8028', N'/images/demo-companies/logo-099.svg', N'CompanyLogo'),
    ('ce01abdf-f919-5a96-a07a-da97153e25b9', N'/images/demo-companies/logo-100.svg', N'CompanyLogo');
    INSERT dbo.Media (Id, Url, Type, Status, CreatedDate)
    SELECT Id, Url, Type, 1, @Now FROM @Images seed WHERE NOT EXISTS (SELECT 1 FROM dbo.Media actual WHERE actual.Id = seed.Id);

    DECLARE @Companies TABLE (Id uniqueidentifier PRIMARY KEY, Name nvarchar(200), About nvarchar(4000), IndustryKey int, ProvinceKey int,
        Address nvarchar(200), SizeMin int, SizeMax int, LogoId uniqueidentifier, CoverId uniqueidentifier, Slug nvarchar(200),
        Email nvarchar(320), FoundedYear int, Culture nvarchar(max), Verification nvarchar(200));
    INSERT @Companies VALUES
    ('4a837a19-7363-5e3b-aa33-e69f3548d2f3', N'Công ty Công nghệ Bình Minh (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Công nghệ Bình Minh (Demo) là doanh nghiệp giả lập trong lĩnh vực công nghệ thông tin, có trụ sở tại Thành phố Hà Nội. Không phải thông tin tuyển dụng thực tế.', 0, 0, N'20 đường Minh Khai, Khu văn phòng Demo', 15, 45, 'abb01a0d-d9d3-5376-babe-8ac49aafc931', 'e8541eb9-9ce9-5049-afaa-33836243ee3a', N'demo-company-001', N'careers-001@example.invalid', 2000, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('14bb0e80-8e98-57ed-a3da-947ac1a7946f', N'Công ty Tài chính Bình Minh (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Tài chính Bình Minh (Demo) là doanh nghiệp giả lập trong lĩnh vực ngân hàng & tài chính, có trụ sở tại Tỉnh Điện Biên. Không phải thông tin tuyển dụng thực tế.', 1, 3, N'21 đường Minh Khai, Khu văn phòng Demo', 15, 45, '06e03fa6-0f91-5600-a4ed-da4fbe0cfb56', '6c14ffe4-e635-5118-a339-60998b2053b4', N'demo-company-002', N'careers-002@example.invalid', 2001, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('b869e635-f170-55b7-b5de-ae1dbcc5e8ed', N'Công ty Thương mại Bình Minh (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Thương mại Bình Minh (Demo) là doanh nghiệp giả lập trong lĩnh vực thương mại điện tử, có trụ sở tại Tỉnh Lào Cai. Không phải thông tin tuyển dụng thực tế.', 2, 6, N'22 đường Minh Khai, Khu văn phòng Demo', 60, 180, '74b4832a-7bbd-589e-9402-0e1468a5f783', 'be04e479-e762-5bc6-b24e-a7e6eebfbc01', N'demo-company-003', N'careers-003@example.invalid', 2002, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('48752bb2-64c8-5270-8ea5-bba98aed8643', N'Công ty Logistics Bình Minh (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Logistics Bình Minh (Demo) là doanh nghiệp giả lập trong lĩnh vực logistics & chuỗi cung ứng, có trụ sở tại Tỉnh Quảng Ninh. Không phải thông tin tuyển dụng thực tế.', 3, 9, N'23 đường Minh Khai, Khu văn phòng Demo', 60, 180, '5cd01cca-b78b-521e-8f20-15e7e1db2cf5', 'c26f7514-5aae-5cef-9074-669241d4ab7f', N'demo-company-004', N'careers-004@example.invalid', 2003, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('617b24e4-567c-5109-9094-b3787b1f4b48', N'Công ty Sản xuất Bình Minh (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sản xuất Bình Minh (Demo) là doanh nghiệp giả lập trong lĩnh vực sản xuất & kỹ thuật, có trụ sở tại Thành phố Hải Phòng. Không phải thông tin tuyển dụng thực tế.', 4, 12, N'24 đường Minh Khai, Khu văn phòng Demo', 220, 450, 'e0e654bf-ee42-55d9-878b-88d3e234ca38', '7c11da0b-ea99-5e94-8e57-b576ec985b93', N'demo-company-005', N'careers-005@example.invalid', 2004, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('70cdc04e-b825-5ec6-8713-8c458bb2deb2', N'Công ty Giáo dục Bình Minh (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Giáo dục Bình Minh (Demo) là doanh nghiệp giả lập trong lĩnh vực giáo dục & đào tạo, có trụ sở tại Tỉnh Thanh Hóa. Không phải thông tin tuyển dụng thực tế.', 5, 15, N'25 đường Minh Khai, Khu văn phòng Demo', 220, 450, '5e299125-2f6d-5c96-8318-53b7e7c26771', '2bfe1315-2733-55f7-971a-be3f2a9c3829', N'demo-company-006', N'careers-006@example.invalid', 2005, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('3fdb6e38-85d8-5ac8-9b96-24b88c4a271c', N'Công ty Sức khỏe Bình Minh (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sức khỏe Bình Minh (Demo) là doanh nghiệp giả lập trong lĩnh vực y tế & chăm sóc sức khỏe, có trụ sở tại Tỉnh Quảng Trị. Không phải thông tin tuyển dụng thực tế.', 6, 18, N'26 đường Minh Khai, Khu văn phòng Demo', 550, 950, '5a3f5e6e-f207-520a-b106-679e163a1561', 'd310be06-cf0c-59af-b3f8-9857a492f4bd', N'demo-company-007', N'careers-007@example.invalid', 2006, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('fdaa4d8c-0f20-5eba-83a9-894bf1b31de3', N'Công ty Du lịch Bình Minh (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Du lịch Bình Minh (Demo) là doanh nghiệp giả lập trong lĩnh vực du lịch & khách sạn, có trụ sở tại Tỉnh Quảng Ngãi. Không phải thông tin tuyển dụng thực tế.', 7, 21, N'27 đường Minh Khai, Khu văn phòng Demo', 550, 950, '69527e82-1f51-5c5b-b959-93d6a3132504', 'aa5116eb-cf88-5dba-ac12-6583cf1245d3', N'demo-company-008', N'careers-008@example.invalid', 2007, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('f4b041a1-d22a-5630-afde-2b5c0a1c61b3', N'Công ty Xây dựng Bình Minh (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Xây dựng Bình Minh (Demo) là doanh nghiệp giả lập trong lĩnh vực xây dựng & bất động sản, có trụ sở tại Tỉnh Đắk Lắk. Không phải thông tin tuyển dụng thực tế.', 8, 24, N'28 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, 'abc26507-44db-5c9e-8a72-b62a003c5634', 'b171d966-7156-5892-9a95-6219098d55c0', N'demo-company-009', N'careers-009@example.invalid', 2008, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('5d96e158-3c12-5d6a-a487-b407ba52ee13', N'Công ty Sáng tạo Bình Minh (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sáng tạo Bình Minh (Demo) là doanh nghiệp giả lập trong lĩnh vực truyền thông & thiết kế, có trụ sở tại Thành phố Hồ Chí Minh. Không phải thông tin tuyển dụng thực tế.', 9, 27, N'29 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, '9126ec63-a9dc-55a5-ab94-7df75e8ee482', 'f441acfc-4eac-58a2-9305-f27c14221f76', N'demo-company-010', N'careers-010@example.invalid', 2009, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('d29659a5-b173-5586-8d9b-8d5aac6c7d28', N'Công ty Công nghệ Hải Đăng (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Công nghệ Hải Đăng (Demo) là doanh nghiệp giả lập trong lĩnh vực công nghệ thông tin, có trụ sở tại Tỉnh An Giang. Không phải thông tin tuyển dụng thực tế.', 0, 31, N'30 đường Minh Khai, Khu văn phòng Demo', 15, 45, '78fa1e3b-8bc2-5f19-8ccb-22b80c803aa8', 'e8541eb9-9ce9-5049-afaa-33836243ee3a', N'demo-company-011', N'careers-011@example.invalid', 2010, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('c8156833-0c4b-5502-9cad-8ece54d27023', N'Công ty Tài chính Hải Đăng (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Tài chính Hải Đăng (Demo) là doanh nghiệp giả lập trong lĩnh vực ngân hàng & tài chính, có trụ sở tại Thành phố Hà Nội. Không phải thông tin tuyển dụng thực tế.', 1, 0, N'31 đường Minh Khai, Khu văn phòng Demo', 15, 45, '70414d3f-cba2-5f4e-a84e-4f38ad99a733', '6c14ffe4-e635-5118-a339-60998b2053b4', N'demo-company-012', N'careers-012@example.invalid', 2011, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('2b704e8c-71e9-554e-9979-36f18ae9c930', N'Công ty Thương mại Hải Đăng (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Thương mại Hải Đăng (Demo) là doanh nghiệp giả lập trong lĩnh vực thương mại điện tử, có trụ sở tại Tỉnh Điện Biên. Không phải thông tin tuyển dụng thực tế.', 2, 3, N'32 đường Minh Khai, Khu văn phòng Demo', 60, 180, '132ee626-972c-59fb-8403-fee66b886bfd', 'be04e479-e762-5bc6-b24e-a7e6eebfbc01', N'demo-company-013', N'careers-013@example.invalid', 2012, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('5715cd40-e2d5-5424-9879-802a9090440e', N'Công ty Logistics Hải Đăng (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Logistics Hải Đăng (Demo) là doanh nghiệp giả lập trong lĩnh vực logistics & chuỗi cung ứng, có trụ sở tại Tỉnh Lào Cai. Không phải thông tin tuyển dụng thực tế.', 3, 6, N'33 đường Minh Khai, Khu văn phòng Demo', 60, 180, 'daa0ad39-91a8-5ff7-936f-8fc10de17b09', 'c26f7514-5aae-5cef-9074-669241d4ab7f', N'demo-company-014', N'careers-014@example.invalid', 2013, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('5779faef-4869-5314-ad70-efb376b1aec9', N'Công ty Sản xuất Hải Đăng (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sản xuất Hải Đăng (Demo) là doanh nghiệp giả lập trong lĩnh vực sản xuất & kỹ thuật, có trụ sở tại Tỉnh Quảng Ninh. Không phải thông tin tuyển dụng thực tế.', 4, 9, N'34 đường Minh Khai, Khu văn phòng Demo', 220, 450, '3cd5207d-0652-54fc-9a55-8b0e023b720a', '7c11da0b-ea99-5e94-8e57-b576ec985b93', N'demo-company-015', N'careers-015@example.invalid', 2014, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('8bfa1442-cca1-5bc6-8dff-37063a398cd5', N'Công ty Giáo dục Hải Đăng (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Giáo dục Hải Đăng (Demo) là doanh nghiệp giả lập trong lĩnh vực giáo dục & đào tạo, có trụ sở tại Thành phố Hải Phòng. Không phải thông tin tuyển dụng thực tế.', 5, 12, N'35 đường Minh Khai, Khu văn phòng Demo', 220, 450, '763497bf-486c-52a1-a26f-c8cc0fabc853', '2bfe1315-2733-55f7-971a-be3f2a9c3829', N'demo-company-016', N'careers-016@example.invalid', 2015, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('df3e7bde-a59d-5254-b642-23429cf781ad', N'Công ty Sức khỏe Hải Đăng (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sức khỏe Hải Đăng (Demo) là doanh nghiệp giả lập trong lĩnh vực y tế & chăm sóc sức khỏe, có trụ sở tại Tỉnh Thanh Hóa. Không phải thông tin tuyển dụng thực tế.', 6, 15, N'36 đường Minh Khai, Khu văn phòng Demo', 550, 950, '66837afd-f946-55f5-8421-84a90bdaa44b', 'd310be06-cf0c-59af-b3f8-9857a492f4bd', N'demo-company-017', N'careers-017@example.invalid', 2016, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('e1bce78f-d113-5f6b-a178-7ff31a6f57eb', N'Công ty Du lịch Hải Đăng (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Du lịch Hải Đăng (Demo) là doanh nghiệp giả lập trong lĩnh vực du lịch & khách sạn, có trụ sở tại Tỉnh Quảng Trị. Không phải thông tin tuyển dụng thực tế.', 7, 18, N'37 đường Minh Khai, Khu văn phòng Demo', 550, 950, '603119bf-68be-5861-bca8-46ec191dd17a', 'aa5116eb-cf88-5dba-ac12-6583cf1245d3', N'demo-company-018', N'careers-018@example.invalid', 2017, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('6e0be351-ca7d-51ff-bdc7-2f8eb50e4e7b', N'Công ty Xây dựng Hải Đăng (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Xây dựng Hải Đăng (Demo) là doanh nghiệp giả lập trong lĩnh vực xây dựng & bất động sản, có trụ sở tại Tỉnh Quảng Ngãi. Không phải thông tin tuyển dụng thực tế.', 8, 21, N'38 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, '98a47ee0-167b-5f2c-bb73-7f51ddf6fd26', 'b171d966-7156-5892-9a95-6219098d55c0', N'demo-company-019', N'careers-019@example.invalid', 2018, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('f3539610-9992-536c-a291-cfc3a1af84f4', N'Công ty Sáng tạo Hải Đăng (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sáng tạo Hải Đăng (Demo) là doanh nghiệp giả lập trong lĩnh vực truyền thông & thiết kế, có trụ sở tại Tỉnh Đắk Lắk. Không phải thông tin tuyển dụng thực tế.', 9, 24, N'39 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, '5fd4e73c-b281-58b7-9554-84fcda683a2e', 'f441acfc-4eac-58a2-9305-f27c14221f76', N'demo-company-020', N'careers-020@example.invalid', 2019, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('f0cb2b01-af76-5b3c-9a21-1f7fd1338d04', N'Công ty Công nghệ Sao Mai (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Công nghệ Sao Mai (Demo) là doanh nghiệp giả lập trong lĩnh vực công nghệ thông tin, có trụ sở tại Tỉnh Tây Ninh. Không phải thông tin tuyển dụng thực tế.', 0, 28, N'40 đường Minh Khai, Khu văn phòng Demo', 15, 45, 'ede4bd42-430b-57d9-9bdf-39eee924a38c', 'e8541eb9-9ce9-5049-afaa-33836243ee3a', N'demo-company-021', N'careers-021@example.invalid', 2020, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('64b09208-021e-51b3-b0be-d1a4477a17ba', N'Công ty Tài chính Sao Mai (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Tài chính Sao Mai (Demo) là doanh nghiệp giả lập trong lĩnh vực ngân hàng & tài chính, có trụ sở tại Tỉnh An Giang. Không phải thông tin tuyển dụng thực tế.', 1, 31, N'41 đường Minh Khai, Khu văn phòng Demo', 15, 45, 'ad8e8d62-6a09-5143-8a27-72f373967115', '6c14ffe4-e635-5118-a339-60998b2053b4', N'demo-company-022', N'careers-022@example.invalid', 2021, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('c157fd7f-84a7-5197-b55d-0c42d7509975', N'Công ty Thương mại Sao Mai (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Thương mại Sao Mai (Demo) là doanh nghiệp giả lập trong lĩnh vực thương mại điện tử, có trụ sở tại Thành phố Hà Nội. Không phải thông tin tuyển dụng thực tế.', 2, 0, N'42 đường Minh Khai, Khu văn phòng Demo', 60, 180, 'c48e4813-9f41-524d-bdab-e75bd0d96793', 'be04e479-e762-5bc6-b24e-a7e6eebfbc01', N'demo-company-023', N'careers-023@example.invalid', 2022, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('d6422993-3652-5a57-9945-d1ec8ed8ee16', N'Công ty Logistics Sao Mai (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Logistics Sao Mai (Demo) là doanh nghiệp giả lập trong lĩnh vực logistics & chuỗi cung ứng, có trụ sở tại Tỉnh Điện Biên. Không phải thông tin tuyển dụng thực tế.', 3, 3, N'43 đường Minh Khai, Khu văn phòng Demo', 60, 180, '5994c096-6634-520f-8c9c-4c8e18a2fd56', 'c26f7514-5aae-5cef-9074-669241d4ab7f', N'demo-company-024', N'careers-024@example.invalid', 2023, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('fc2f34ba-b663-5394-b064-f68cb1407bf4', N'Công ty Sản xuất Sao Mai (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sản xuất Sao Mai (Demo) là doanh nghiệp giả lập trong lĩnh vực sản xuất & kỹ thuật, có trụ sở tại Tỉnh Lào Cai. Không phải thông tin tuyển dụng thực tế.', 4, 6, N'44 đường Minh Khai, Khu văn phòng Demo', 220, 450, '970e2d14-5e43-52a7-92e8-a202d0f720a8', '7c11da0b-ea99-5e94-8e57-b576ec985b93', N'demo-company-025', N'careers-025@example.invalid', 2000, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('f04a6647-a309-5d0b-a030-9090dda4e6a4', N'Công ty Giáo dục Sao Mai (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Giáo dục Sao Mai (Demo) là doanh nghiệp giả lập trong lĩnh vực giáo dục & đào tạo, có trụ sở tại Tỉnh Quảng Ninh. Không phải thông tin tuyển dụng thực tế.', 5, 9, N'45 đường Minh Khai, Khu văn phòng Demo', 220, 450, 'c93883ce-3430-5d9c-855e-05670163d3fb', '2bfe1315-2733-55f7-971a-be3f2a9c3829', N'demo-company-026', N'careers-026@example.invalid', 2001, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('05ded8f4-940a-5f16-9b2f-aeda74dcbd99', N'Công ty Sức khỏe Sao Mai (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sức khỏe Sao Mai (Demo) là doanh nghiệp giả lập trong lĩnh vực y tế & chăm sóc sức khỏe, có trụ sở tại Thành phố Hải Phòng. Không phải thông tin tuyển dụng thực tế.', 6, 12, N'46 đường Minh Khai, Khu văn phòng Demo', 550, 950, 'e5b25a59-5d4f-5fb6-b2f0-6ff59513a471', 'd310be06-cf0c-59af-b3f8-9857a492f4bd', N'demo-company-027', N'careers-027@example.invalid', 2002, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('2ddc58ae-655b-5ff5-90fa-56cda5cb0e9c', N'Công ty Du lịch Sao Mai (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Du lịch Sao Mai (Demo) là doanh nghiệp giả lập trong lĩnh vực du lịch & khách sạn, có trụ sở tại Tỉnh Thanh Hóa. Không phải thông tin tuyển dụng thực tế.', 7, 15, N'47 đường Minh Khai, Khu văn phòng Demo', 550, 950, '551aae78-c531-5893-b6e4-34a4944ef50e', 'aa5116eb-cf88-5dba-ac12-6583cf1245d3', N'demo-company-028', N'careers-028@example.invalid', 2003, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('d6faaaa7-72af-5a76-8a5f-4bbaa010a53f', N'Công ty Xây dựng Sao Mai (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Xây dựng Sao Mai (Demo) là doanh nghiệp giả lập trong lĩnh vực xây dựng & bất động sản, có trụ sở tại Tỉnh Quảng Trị. Không phải thông tin tuyển dụng thực tế.', 8, 18, N'48 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, '7855c0c4-fd93-530c-ba29-19621e82bac6', 'b171d966-7156-5892-9a95-6219098d55c0', N'demo-company-029', N'careers-029@example.invalid', 2004, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('f2855ed2-3b8b-52ee-a809-7848c82dc510', N'Công ty Sáng tạo Sao Mai (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sáng tạo Sao Mai (Demo) là doanh nghiệp giả lập trong lĩnh vực truyền thông & thiết kế, có trụ sở tại Tỉnh Quảng Ngãi. Không phải thông tin tuyển dụng thực tế.', 9, 21, N'49 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, '5bd14a28-bc1a-565f-b715-7de7439800b9', 'f441acfc-4eac-58a2-9305-f27c14221f76', N'demo-company-030', N'careers-030@example.invalid', 2005, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('48bf565a-61ee-5efe-a5c8-c0f477305e82', N'Công ty Công nghệ Thanh Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Công nghệ Thanh Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực công nghệ thông tin, có trụ sở tại Tỉnh Lâm Đồng. Không phải thông tin tuyển dụng thực tế.', 0, 25, N'50 đường Minh Khai, Khu văn phòng Demo', 15, 45, 'e95ac58a-6dec-598e-b91c-1e62e064ead3', 'e8541eb9-9ce9-5049-afaa-33836243ee3a', N'demo-company-031', N'careers-031@example.invalid', 2006, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('92cf5fe8-b865-562c-9aa5-137051ae64a6', N'Công ty Tài chính Thanh Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Tài chính Thanh Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực ngân hàng & tài chính, có trụ sở tại Tỉnh Tây Ninh. Không phải thông tin tuyển dụng thực tế.', 1, 28, N'51 đường Minh Khai, Khu văn phòng Demo', 15, 45, '3a1d981f-026c-5e3e-84aa-ce2f803463cd', '6c14ffe4-e635-5118-a339-60998b2053b4', N'demo-company-032', N'careers-032@example.invalid', 2007, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('97a4c0a1-2d68-5e15-b704-a846d7ae7379', N'Công ty Thương mại Thanh Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Thương mại Thanh Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực thương mại điện tử, có trụ sở tại Tỉnh An Giang. Không phải thông tin tuyển dụng thực tế.', 2, 31, N'52 đường Minh Khai, Khu văn phòng Demo', 60, 180, 'cbd98cc6-7436-5ab6-8100-668c4a6862cb', 'be04e479-e762-5bc6-b24e-a7e6eebfbc01', N'demo-company-033', N'careers-033@example.invalid', 2008, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('7f64c4f6-dea1-572f-87e1-b2baf0652e1d', N'Công ty Logistics Thanh Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Logistics Thanh Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực logistics & chuỗi cung ứng, có trụ sở tại Thành phố Hà Nội. Không phải thông tin tuyển dụng thực tế.', 3, 0, N'53 đường Minh Khai, Khu văn phòng Demo', 60, 180, 'c7226fde-dc8f-5299-8bea-81a3363e602e', 'c26f7514-5aae-5cef-9074-669241d4ab7f', N'demo-company-034', N'careers-034@example.invalid', 2009, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('a1ec7855-c9f9-5052-975d-6db8a3eb613a', N'Công ty Sản xuất Thanh Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sản xuất Thanh Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực sản xuất & kỹ thuật, có trụ sở tại Tỉnh Điện Biên. Không phải thông tin tuyển dụng thực tế.', 4, 3, N'54 đường Minh Khai, Khu văn phòng Demo', 220, 450, '7523b462-f3e1-572e-9dae-62a4bb047882', '7c11da0b-ea99-5e94-8e57-b576ec985b93', N'demo-company-035', N'careers-035@example.invalid', 2010, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('6c2147a1-cebd-54e0-91d4-4c4c9695d532', N'Công ty Giáo dục Thanh Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Giáo dục Thanh Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực giáo dục & đào tạo, có trụ sở tại Tỉnh Lào Cai. Không phải thông tin tuyển dụng thực tế.', 5, 6, N'55 đường Minh Khai, Khu văn phòng Demo', 220, 450, '3381e971-bfdb-5f42-804c-b3d6958605cf', '2bfe1315-2733-55f7-971a-be3f2a9c3829', N'demo-company-036', N'careers-036@example.invalid', 2011, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('c26c54ce-7f9b-5ecd-aae4-9b2555cb78bc', N'Công ty Sức khỏe Thanh Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sức khỏe Thanh Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực y tế & chăm sóc sức khỏe, có trụ sở tại Tỉnh Quảng Ninh. Không phải thông tin tuyển dụng thực tế.', 6, 9, N'56 đường Minh Khai, Khu văn phòng Demo', 550, 950, 'e0674c5b-8d0d-5d4c-a97b-9794e5ce7bc6', 'd310be06-cf0c-59af-b3f8-9857a492f4bd', N'demo-company-037', N'careers-037@example.invalid', 2012, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('8843a009-4ac8-5cb7-afcd-880abeae7eac', N'Công ty Du lịch Thanh Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Du lịch Thanh Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực du lịch & khách sạn, có trụ sở tại Thành phố Hải Phòng. Không phải thông tin tuyển dụng thực tế.', 7, 12, N'57 đường Minh Khai, Khu văn phòng Demo', 550, 950, '8bf9ceec-d6ef-5622-9bfd-88351db3d8db', 'aa5116eb-cf88-5dba-ac12-6583cf1245d3', N'demo-company-038', N'careers-038@example.invalid', 2013, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('f9eeea98-be44-5455-bedd-f494149db24f', N'Công ty Xây dựng Thanh Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Xây dựng Thanh Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực xây dựng & bất động sản, có trụ sở tại Tỉnh Thanh Hóa. Không phải thông tin tuyển dụng thực tế.', 8, 15, N'58 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, 'c0a14267-43d7-54bc-807b-6d933e42a991', 'b171d966-7156-5892-9a95-6219098d55c0', N'demo-company-039', N'careers-039@example.invalid', 2014, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('a1fb5b7b-8c05-5cfd-a137-59116fbe6f47', N'Công ty Sáng tạo Thanh Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sáng tạo Thanh Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực truyền thông & thiết kế, có trụ sở tại Tỉnh Quảng Trị. Không phải thông tin tuyển dụng thực tế.', 9, 18, N'59 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, '06567352-cc21-51a3-a21d-85a1c8f8711b', 'f441acfc-4eac-58a2-9305-f27c14221f76', N'demo-company-040', N'careers-040@example.invalid', 2015, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('41f52010-8697-5d78-b94e-55f2b7e46e83', N'Công ty Công nghệ An Phú (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Công nghệ An Phú (Demo) là doanh nghiệp giả lập trong lĩnh vực công nghệ thông tin, có trụ sở tại Tỉnh Gia Lai. Không phải thông tin tuyển dụng thực tế.', 0, 22, N'60 đường Minh Khai, Khu văn phòng Demo', 15, 45, 'a2c1b5c0-3540-5fe5-a5ed-c30eed1273a3', 'e8541eb9-9ce9-5049-afaa-33836243ee3a', N'demo-company-041', N'careers-041@example.invalid', 2016, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('062abf3f-fcf3-5745-89eb-dd4f64cfa7a4', N'Công ty Tài chính An Phú (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Tài chính An Phú (Demo) là doanh nghiệp giả lập trong lĩnh vực ngân hàng & tài chính, có trụ sở tại Tỉnh Lâm Đồng. Không phải thông tin tuyển dụng thực tế.', 1, 25, N'61 đường Minh Khai, Khu văn phòng Demo', 15, 45, '87a3a32a-acc8-5f60-bfef-d684fcdf705a', '6c14ffe4-e635-5118-a339-60998b2053b4', N'demo-company-042', N'careers-042@example.invalid', 2017, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('aeae827e-47c4-57a1-a510-53d1c791682f', N'Công ty Thương mại An Phú (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Thương mại An Phú (Demo) là doanh nghiệp giả lập trong lĩnh vực thương mại điện tử, có trụ sở tại Tỉnh Tây Ninh. Không phải thông tin tuyển dụng thực tế.', 2, 28, N'62 đường Minh Khai, Khu văn phòng Demo', 60, 180, '24ed8eb3-e750-5045-aaed-d6b042c9fb3c', 'be04e479-e762-5bc6-b24e-a7e6eebfbc01', N'demo-company-043', N'careers-043@example.invalid', 2018, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('7d1eaff4-9d15-5ef0-8126-33282093b5c3', N'Công ty Logistics An Phú (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Logistics An Phú (Demo) là doanh nghiệp giả lập trong lĩnh vực logistics & chuỗi cung ứng, có trụ sở tại Tỉnh An Giang. Không phải thông tin tuyển dụng thực tế.', 3, 31, N'63 đường Minh Khai, Khu văn phòng Demo', 60, 180, 'dd4ab0b0-c36c-5541-b3fe-e5b92e0cf25a', 'c26f7514-5aae-5cef-9074-669241d4ab7f', N'demo-company-044', N'careers-044@example.invalid', 2019, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('635c7a43-6213-5519-82ce-00591852cf8b', N'Công ty Sản xuất An Phú (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sản xuất An Phú (Demo) là doanh nghiệp giả lập trong lĩnh vực sản xuất & kỹ thuật, có trụ sở tại Thành phố Hà Nội. Không phải thông tin tuyển dụng thực tế.', 4, 0, N'64 đường Minh Khai, Khu văn phòng Demo', 220, 450, '764ad3a5-9ed8-5347-83d6-591d4fa03373', '7c11da0b-ea99-5e94-8e57-b576ec985b93', N'demo-company-045', N'careers-045@example.invalid', 2020, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('203c8dae-265e-533c-a51d-66ec00f1ad3d', N'Công ty Giáo dục An Phú (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Giáo dục An Phú (Demo) là doanh nghiệp giả lập trong lĩnh vực giáo dục & đào tạo, có trụ sở tại Tỉnh Điện Biên. Không phải thông tin tuyển dụng thực tế.', 5, 3, N'65 đường Minh Khai, Khu văn phòng Demo', 220, 450, 'a64e7a65-12a3-5282-98ec-f1049d0d4958', '2bfe1315-2733-55f7-971a-be3f2a9c3829', N'demo-company-046', N'careers-046@example.invalid', 2021, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('84155ef7-7f5a-5119-bd92-0b82718eb783', N'Công ty Sức khỏe An Phú (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sức khỏe An Phú (Demo) là doanh nghiệp giả lập trong lĩnh vực y tế & chăm sóc sức khỏe, có trụ sở tại Tỉnh Lào Cai. Không phải thông tin tuyển dụng thực tế.', 6, 6, N'66 đường Minh Khai, Khu văn phòng Demo', 550, 950, 'd8054743-0eb3-5213-b25e-e1b2411f23d3', 'd310be06-cf0c-59af-b3f8-9857a492f4bd', N'demo-company-047', N'careers-047@example.invalid', 2022, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('bde8b5ea-5821-57ce-aaf8-de0e47994ac7', N'Công ty Du lịch An Phú (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Du lịch An Phú (Demo) là doanh nghiệp giả lập trong lĩnh vực du lịch & khách sạn, có trụ sở tại Tỉnh Quảng Ninh. Không phải thông tin tuyển dụng thực tế.', 7, 9, N'67 đường Minh Khai, Khu văn phòng Demo', 550, 950, '0b4bf75d-1eee-5402-919b-296a6f0cd940', 'aa5116eb-cf88-5dba-ac12-6583cf1245d3', N'demo-company-048', N'careers-048@example.invalid', 2023, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('7cab1b98-2436-5ada-b0af-5d44f8ffb959', N'Công ty Xây dựng An Phú (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Xây dựng An Phú (Demo) là doanh nghiệp giả lập trong lĩnh vực xây dựng & bất động sản, có trụ sở tại Thành phố Hải Phòng. Không phải thông tin tuyển dụng thực tế.', 8, 12, N'68 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, '5b8d3379-9ae4-5ef8-9226-f655fdaac833', 'b171d966-7156-5892-9a95-6219098d55c0', N'demo-company-049', N'careers-049@example.invalid', 2000, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('48a0b715-d220-5f61-8bc2-8595f64e95b9', N'Công ty Sáng tạo An Phú (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sáng tạo An Phú (Demo) là doanh nghiệp giả lập trong lĩnh vực truyền thông & thiết kế, có trụ sở tại Tỉnh Thanh Hóa. Không phải thông tin tuyển dụng thực tế.', 9, 15, N'69 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, 'ae449637-269d-5ed1-859d-c2bd82cab848', 'f441acfc-4eac-58a2-9305-f27c14221f76', N'demo-company-050', N'careers-050@example.invalid', 2001, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('f24d1d72-e77e-56bd-965d-b5d741f59baf', N'Công ty Công nghệ Vạn An (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Công nghệ Vạn An (Demo) là doanh nghiệp giả lập trong lĩnh vực công nghệ thông tin, có trụ sở tại Thành phố Huế. Không phải thông tin tuyển dụng thực tế.', 0, 19, N'70 đường Minh Khai, Khu văn phòng Demo', 15, 45, 'a0a7d9dd-0d42-5fbd-bd35-d0651648ec8f', 'e8541eb9-9ce9-5049-afaa-33836243ee3a', N'demo-company-051', N'careers-051@example.invalid', 2002, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('32a8aa15-f7b7-5f43-b8c0-2f07733983af', N'Công ty Tài chính Vạn An (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Tài chính Vạn An (Demo) là doanh nghiệp giả lập trong lĩnh vực ngân hàng & tài chính, có trụ sở tại Tỉnh Gia Lai. Không phải thông tin tuyển dụng thực tế.', 1, 22, N'71 đường Minh Khai, Khu văn phòng Demo', 15, 45, '8f6543ea-0eb7-517e-87af-63677bc60f55', '6c14ffe4-e635-5118-a339-60998b2053b4', N'demo-company-052', N'careers-052@example.invalid', 2003, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('f12d95cc-3212-549e-80f6-fb6b092316cf', N'Công ty Thương mại Vạn An (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Thương mại Vạn An (Demo) là doanh nghiệp giả lập trong lĩnh vực thương mại điện tử, có trụ sở tại Tỉnh Lâm Đồng. Không phải thông tin tuyển dụng thực tế.', 2, 25, N'72 đường Minh Khai, Khu văn phòng Demo', 60, 180, 'b486f278-96b8-5bcc-9724-58a465d10173', 'be04e479-e762-5bc6-b24e-a7e6eebfbc01', N'demo-company-053', N'careers-053@example.invalid', 2004, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('03c155ec-1d26-5907-93b6-b948daf6c1d3', N'Công ty Logistics Vạn An (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Logistics Vạn An (Demo) là doanh nghiệp giả lập trong lĩnh vực logistics & chuỗi cung ứng, có trụ sở tại Tỉnh Tây Ninh. Không phải thông tin tuyển dụng thực tế.', 3, 28, N'73 đường Minh Khai, Khu văn phòng Demo', 60, 180, 'be698dda-cf65-5b79-859f-708d3671e71d', 'c26f7514-5aae-5cef-9074-669241d4ab7f', N'demo-company-054', N'careers-054@example.invalid', 2005, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('d3c30ccb-ed8c-5392-8c9e-9eb59092e51f', N'Công ty Sản xuất Vạn An (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sản xuất Vạn An (Demo) là doanh nghiệp giả lập trong lĩnh vực sản xuất & kỹ thuật, có trụ sở tại Tỉnh An Giang. Không phải thông tin tuyển dụng thực tế.', 4, 31, N'74 đường Minh Khai, Khu văn phòng Demo', 220, 450, '3f66a1af-d0e9-5371-8781-01a579f6b29c', '7c11da0b-ea99-5e94-8e57-b576ec985b93', N'demo-company-055', N'careers-055@example.invalid', 2006, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('82fc2ae1-0f12-5025-9d95-c2bbb922e29e', N'Công ty Giáo dục Vạn An (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Giáo dục Vạn An (Demo) là doanh nghiệp giả lập trong lĩnh vực giáo dục & đào tạo, có trụ sở tại Thành phố Hà Nội. Không phải thông tin tuyển dụng thực tế.', 5, 0, N'75 đường Minh Khai, Khu văn phòng Demo', 220, 450, '303b0b8a-764b-5ed5-969c-98dfa5e28758', '2bfe1315-2733-55f7-971a-be3f2a9c3829', N'demo-company-056', N'careers-056@example.invalid', 2007, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('83a412e7-ac58-5287-aa90-c025fee82507', N'Công ty Sức khỏe Vạn An (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sức khỏe Vạn An (Demo) là doanh nghiệp giả lập trong lĩnh vực y tế & chăm sóc sức khỏe, có trụ sở tại Tỉnh Điện Biên. Không phải thông tin tuyển dụng thực tế.', 6, 3, N'76 đường Minh Khai, Khu văn phòng Demo', 550, 950, 'b582d350-2cf5-5176-a5fe-aa71d1f5d154', 'd310be06-cf0c-59af-b3f8-9857a492f4bd', N'demo-company-057', N'careers-057@example.invalid', 2008, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('078602d5-75dd-5a3e-a4fe-db70739cf5b7', N'Công ty Du lịch Vạn An (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Du lịch Vạn An (Demo) là doanh nghiệp giả lập trong lĩnh vực du lịch & khách sạn, có trụ sở tại Tỉnh Lào Cai. Không phải thông tin tuyển dụng thực tế.', 7, 6, N'77 đường Minh Khai, Khu văn phòng Demo', 550, 950, '953768f5-224b-521c-af67-006b9f12f69f', 'aa5116eb-cf88-5dba-ac12-6583cf1245d3', N'demo-company-058', N'careers-058@example.invalid', 2009, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('272bee99-42e4-50d2-99fe-09a415cd0619', N'Công ty Xây dựng Vạn An (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Xây dựng Vạn An (Demo) là doanh nghiệp giả lập trong lĩnh vực xây dựng & bất động sản, có trụ sở tại Tỉnh Quảng Ninh. Không phải thông tin tuyển dụng thực tế.', 8, 9, N'78 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, 'bcf3d3c1-613d-586c-9599-0b1afeded74a', 'b171d966-7156-5892-9a95-6219098d55c0', N'demo-company-059', N'careers-059@example.invalid', 2010, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('666abe98-ecb0-5cf0-ae57-05ce8c38ae4e', N'Công ty Sáng tạo Vạn An (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sáng tạo Vạn An (Demo) là doanh nghiệp giả lập trong lĩnh vực truyền thông & thiết kế, có trụ sở tại Thành phố Hải Phòng. Không phải thông tin tuyển dụng thực tế.', 9, 12, N'79 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, '13260622-b95d-5376-aaca-65f395411a22', 'f441acfc-4eac-58a2-9305-f27c14221f76', N'demo-company-060', N'careers-060@example.invalid', 2011, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('02e2cde5-7040-5f37-9777-bd0c0d665e6a', N'Công ty Công nghệ Thiên Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Công nghệ Thiên Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực công nghệ thông tin, có trụ sở tại Tỉnh Nghệ An. Không phải thông tin tuyển dụng thực tế.', 0, 16, N'80 đường Minh Khai, Khu văn phòng Demo', 15, 45, 'e2f31011-f317-56e1-b4d3-e1b842a739d0', 'e8541eb9-9ce9-5049-afaa-33836243ee3a', N'demo-company-061', N'careers-061@example.invalid', 2012, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('13e1ac49-bdeb-5700-bb70-db51049c29a1', N'Công ty Tài chính Thiên Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Tài chính Thiên Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực ngân hàng & tài chính, có trụ sở tại Thành phố Huế. Không phải thông tin tuyển dụng thực tế.', 1, 19, N'81 đường Minh Khai, Khu văn phòng Demo', 15, 45, '85f34cf1-73c9-5a57-9e14-40561c557dea', '6c14ffe4-e635-5118-a339-60998b2053b4', N'demo-company-062', N'careers-062@example.invalid', 2013, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('1e915b2a-fd19-54d2-a72a-744771d6fec9', N'Công ty Thương mại Thiên Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Thương mại Thiên Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực thương mại điện tử, có trụ sở tại Tỉnh Gia Lai. Không phải thông tin tuyển dụng thực tế.', 2, 22, N'82 đường Minh Khai, Khu văn phòng Demo', 60, 180, 'efad99d9-fd1d-5567-b9e8-9874d1d8984a', 'be04e479-e762-5bc6-b24e-a7e6eebfbc01', N'demo-company-063', N'careers-063@example.invalid', 2014, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('1cd9db77-0efb-560b-9d01-b4b572499c5b', N'Công ty Logistics Thiên Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Logistics Thiên Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực logistics & chuỗi cung ứng, có trụ sở tại Tỉnh Lâm Đồng. Không phải thông tin tuyển dụng thực tế.', 3, 25, N'83 đường Minh Khai, Khu văn phòng Demo', 60, 180, '8101acc7-b5d5-5f66-a3e4-4165e7988a8d', 'c26f7514-5aae-5cef-9074-669241d4ab7f', N'demo-company-064', N'careers-064@example.invalid', 2015, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('6a94f72c-6026-5e4b-b196-75ebc283a0ae', N'Công ty Sản xuất Thiên Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sản xuất Thiên Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực sản xuất & kỹ thuật, có trụ sở tại Tỉnh Tây Ninh. Không phải thông tin tuyển dụng thực tế.', 4, 28, N'84 đường Minh Khai, Khu văn phòng Demo', 220, 450, '2fc602ff-7f91-58f9-afe7-664dc0fa7e3b', '7c11da0b-ea99-5e94-8e57-b576ec985b93', N'demo-company-065', N'careers-065@example.invalid', 2016, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('a5b4c183-6b02-5eef-8717-caab064c27d3', N'Công ty Giáo dục Thiên Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Giáo dục Thiên Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực giáo dục & đào tạo, có trụ sở tại Tỉnh An Giang. Không phải thông tin tuyển dụng thực tế.', 5, 31, N'85 đường Minh Khai, Khu văn phòng Demo', 220, 450, '0001f464-ab21-5eb0-b8f5-1463ea4ba9c0', '2bfe1315-2733-55f7-971a-be3f2a9c3829', N'demo-company-066', N'careers-066@example.invalid', 2017, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('f492136a-f672-5bb7-ad96-7795bae3974e', N'Công ty Sức khỏe Thiên Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sức khỏe Thiên Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực y tế & chăm sóc sức khỏe, có trụ sở tại Thành phố Hà Nội. Không phải thông tin tuyển dụng thực tế.', 6, 0, N'86 đường Minh Khai, Khu văn phòng Demo', 550, 950, '814af29e-cd70-5d6c-b460-c543169b6767', 'd310be06-cf0c-59af-b3f8-9857a492f4bd', N'demo-company-067', N'careers-067@example.invalid', 2018, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('78869b06-538e-593b-b173-3e5f9e0bf389', N'Công ty Du lịch Thiên Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Du lịch Thiên Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực du lịch & khách sạn, có trụ sở tại Tỉnh Điện Biên. Không phải thông tin tuyển dụng thực tế.', 7, 3, N'87 đường Minh Khai, Khu văn phòng Demo', 550, 950, 'da7b6d9f-34a8-5b8f-91cc-5c7c5b7725df', 'aa5116eb-cf88-5dba-ac12-6583cf1245d3', N'demo-company-068', N'careers-068@example.invalid', 2019, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('c71832d4-2fdc-5414-93fd-c987ae700e3a', N'Công ty Xây dựng Thiên Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Xây dựng Thiên Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực xây dựng & bất động sản, có trụ sở tại Tỉnh Lào Cai. Không phải thông tin tuyển dụng thực tế.', 8, 6, N'88 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, '8e23a98a-f878-5f60-9d78-75bf5585ef18', 'b171d966-7156-5892-9a95-6219098d55c0', N'demo-company-069', N'careers-069@example.invalid', 2020, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('0426a190-c63d-5bba-88bc-1f1fa871dce0', N'Công ty Sáng tạo Thiên Hà (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sáng tạo Thiên Hà (Demo) là doanh nghiệp giả lập trong lĩnh vực truyền thông & thiết kế, có trụ sở tại Tỉnh Quảng Ninh. Không phải thông tin tuyển dụng thực tế.', 9, 9, N'89 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, '62815d49-8fd6-5c38-9777-51afec83bd40', 'f441acfc-4eac-58a2-9305-f27c14221f76', N'demo-company-070', N'careers-070@example.invalid', 2021, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('44b2fa56-c57e-5239-83f7-7a74c03d002c', N'Công ty Công nghệ Minh Sơn (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Công nghệ Minh Sơn (Demo) là doanh nghiệp giả lập trong lĩnh vực công nghệ thông tin, có trụ sở tại Tỉnh Hưng Yên. Không phải thông tin tuyển dụng thực tế.', 0, 13, N'90 đường Minh Khai, Khu văn phòng Demo', 15, 45, '025fcc35-648b-5856-87bf-d789b2109b34', 'e8541eb9-9ce9-5049-afaa-33836243ee3a', N'demo-company-071', N'careers-071@example.invalid', 2022, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('21e3b2af-9a1a-55da-8d29-577e1a92890a', N'Công ty Tài chính Minh Sơn (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Tài chính Minh Sơn (Demo) là doanh nghiệp giả lập trong lĩnh vực ngân hàng & tài chính, có trụ sở tại Tỉnh Nghệ An. Không phải thông tin tuyển dụng thực tế.', 1, 16, N'91 đường Minh Khai, Khu văn phòng Demo', 15, 45, '67b1ede1-cab2-5b83-86e2-3f0eb2337080', '6c14ffe4-e635-5118-a339-60998b2053b4', N'demo-company-072', N'careers-072@example.invalid', 2023, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('cada2d90-3f1a-519f-bf02-d904dbc6b8c9', N'Công ty Thương mại Minh Sơn (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Thương mại Minh Sơn (Demo) là doanh nghiệp giả lập trong lĩnh vực thương mại điện tử, có trụ sở tại Thành phố Huế. Không phải thông tin tuyển dụng thực tế.', 2, 19, N'92 đường Minh Khai, Khu văn phòng Demo', 60, 180, '47c1ff9b-c1a3-5d61-8ea3-1408ca33dbd3', 'be04e479-e762-5bc6-b24e-a7e6eebfbc01', N'demo-company-073', N'careers-073@example.invalid', 2000, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('5c8bb042-3a7b-51e0-94d8-c6deb9b28311', N'Công ty Logistics Minh Sơn (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Logistics Minh Sơn (Demo) là doanh nghiệp giả lập trong lĩnh vực logistics & chuỗi cung ứng, có trụ sở tại Tỉnh Gia Lai. Không phải thông tin tuyển dụng thực tế.', 3, 22, N'93 đường Minh Khai, Khu văn phòng Demo', 60, 180, '3b2630a0-db12-5d9f-a084-e8a53fd36252', 'c26f7514-5aae-5cef-9074-669241d4ab7f', N'demo-company-074', N'careers-074@example.invalid', 2001, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('e1adacfe-4bf1-5324-ad95-16c61010c220', N'Công ty Sản xuất Minh Sơn (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sản xuất Minh Sơn (Demo) là doanh nghiệp giả lập trong lĩnh vực sản xuất & kỹ thuật, có trụ sở tại Tỉnh Lâm Đồng. Không phải thông tin tuyển dụng thực tế.', 4, 25, N'94 đường Minh Khai, Khu văn phòng Demo', 220, 450, 'f4515214-d065-57a8-a4c0-f8bfb64d4222', '7c11da0b-ea99-5e94-8e57-b576ec985b93', N'demo-company-075', N'careers-075@example.invalid', 2002, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('43a30852-8eef-5fe4-beb6-edd81897025f', N'Công ty Giáo dục Minh Sơn (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Giáo dục Minh Sơn (Demo) là doanh nghiệp giả lập trong lĩnh vực giáo dục & đào tạo, có trụ sở tại Tỉnh Tây Ninh. Không phải thông tin tuyển dụng thực tế.', 5, 28, N'95 đường Minh Khai, Khu văn phòng Demo', 220, 450, 'a889a2a3-f4b1-5d71-a046-077cf7769bbe', '2bfe1315-2733-55f7-971a-be3f2a9c3829', N'demo-company-076', N'careers-076@example.invalid', 2003, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('0ed91b3e-1603-5fa6-99c0-bddb536e17ac', N'Công ty Sức khỏe Minh Sơn (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sức khỏe Minh Sơn (Demo) là doanh nghiệp giả lập trong lĩnh vực y tế & chăm sóc sức khỏe, có trụ sở tại Tỉnh An Giang. Không phải thông tin tuyển dụng thực tế.', 6, 31, N'96 đường Minh Khai, Khu văn phòng Demo', 550, 950, '62f7cb6b-36fb-55e6-a91f-52f0cab31f7f', 'd310be06-cf0c-59af-b3f8-9857a492f4bd', N'demo-company-077', N'careers-077@example.invalid', 2004, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('0e52d5a5-da80-5394-b923-84f74c5d2921', N'Công ty Du lịch Minh Sơn (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Du lịch Minh Sơn (Demo) là doanh nghiệp giả lập trong lĩnh vực du lịch & khách sạn, có trụ sở tại Thành phố Hà Nội. Không phải thông tin tuyển dụng thực tế.', 7, 0, N'97 đường Minh Khai, Khu văn phòng Demo', 550, 950, 'e94a4423-e97b-5bcc-a176-5b1f9565463e', 'aa5116eb-cf88-5dba-ac12-6583cf1245d3', N'demo-company-078', N'careers-078@example.invalid', 2005, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('9a70e94a-7836-5d01-a4b3-edd830474bcd', N'Công ty Xây dựng Minh Sơn (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Xây dựng Minh Sơn (Demo) là doanh nghiệp giả lập trong lĩnh vực xây dựng & bất động sản, có trụ sở tại Tỉnh Điện Biên. Không phải thông tin tuyển dụng thực tế.', 8, 3, N'98 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, 'c50d6faa-043f-5ecf-bdb3-0acf7f9ed07f', 'b171d966-7156-5892-9a95-6219098d55c0', N'demo-company-079', N'careers-079@example.invalid', 2006, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('f578cad6-ae06-5707-99f9-c6e7b3925811', N'Công ty Sáng tạo Minh Sơn (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sáng tạo Minh Sơn (Demo) là doanh nghiệp giả lập trong lĩnh vực truyền thông & thiết kế, có trụ sở tại Tỉnh Lào Cai. Không phải thông tin tuyển dụng thực tế.', 9, 6, N'99 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, 'dd703261-7bb2-50ac-b5e8-93fdcb096f36', 'f441acfc-4eac-58a2-9305-f27c14221f76', N'demo-company-080', N'careers-080@example.invalid', 2007, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('79031059-3750-54f3-aaed-c13f19ccaa22', N'Công ty Công nghệ Tân Việt (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Công nghệ Tân Việt (Demo) là doanh nghiệp giả lập trong lĩnh vực công nghệ thông tin, có trụ sở tại Tỉnh Bắc Ninh. Không phải thông tin tuyển dụng thực tế.', 0, 10, N'100 đường Minh Khai, Khu văn phòng Demo', 15, 45, '0bdc7158-95bf-5859-9900-0beb5402a81e', 'e8541eb9-9ce9-5049-afaa-33836243ee3a', N'demo-company-081', N'careers-081@example.invalid', 2008, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('31602d3c-c648-5be5-93ce-5b4b24019610', N'Công ty Tài chính Tân Việt (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Tài chính Tân Việt (Demo) là doanh nghiệp giả lập trong lĩnh vực ngân hàng & tài chính, có trụ sở tại Tỉnh Hưng Yên. Không phải thông tin tuyển dụng thực tế.', 1, 13, N'101 đường Minh Khai, Khu văn phòng Demo', 15, 45, 'ae3b91e4-78ac-5b61-8d7a-17315a5266f1', '6c14ffe4-e635-5118-a339-60998b2053b4', N'demo-company-082', N'careers-082@example.invalid', 2009, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('54f6de28-a740-5089-8e5f-5e4e170a62d4', N'Công ty Thương mại Tân Việt (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Thương mại Tân Việt (Demo) là doanh nghiệp giả lập trong lĩnh vực thương mại điện tử, có trụ sở tại Tỉnh Nghệ An. Không phải thông tin tuyển dụng thực tế.', 2, 16, N'102 đường Minh Khai, Khu văn phòng Demo', 60, 180, '15939fb3-a480-5c82-b7e7-ea9564d7a43d', 'be04e479-e762-5bc6-b24e-a7e6eebfbc01', N'demo-company-083', N'careers-083@example.invalid', 2010, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('ed3d579d-027b-566e-97d9-b363f38162ec', N'Công ty Logistics Tân Việt (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Logistics Tân Việt (Demo) là doanh nghiệp giả lập trong lĩnh vực logistics & chuỗi cung ứng, có trụ sở tại Thành phố Huế. Không phải thông tin tuyển dụng thực tế.', 3, 19, N'103 đường Minh Khai, Khu văn phòng Demo', 60, 180, '860ce60f-ed1c-5fcd-84d7-06d310a20d61', 'c26f7514-5aae-5cef-9074-669241d4ab7f', N'demo-company-084', N'careers-084@example.invalid', 2011, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('7ec29f01-9a06-554b-bfd3-1bb40f7350c3', N'Công ty Sản xuất Tân Việt (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sản xuất Tân Việt (Demo) là doanh nghiệp giả lập trong lĩnh vực sản xuất & kỹ thuật, có trụ sở tại Tỉnh Gia Lai. Không phải thông tin tuyển dụng thực tế.', 4, 22, N'104 đường Minh Khai, Khu văn phòng Demo', 220, 450, '411c76c9-7176-5402-a70d-abfa74eab168', '7c11da0b-ea99-5e94-8e57-b576ec985b93', N'demo-company-085', N'careers-085@example.invalid', 2012, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('16d99124-eff5-54cf-b295-d8a7b4f01a69', N'Công ty Giáo dục Tân Việt (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Giáo dục Tân Việt (Demo) là doanh nghiệp giả lập trong lĩnh vực giáo dục & đào tạo, có trụ sở tại Tỉnh Lâm Đồng. Không phải thông tin tuyển dụng thực tế.', 5, 25, N'105 đường Minh Khai, Khu văn phòng Demo', 220, 450, '9487df7b-2120-5273-a17f-d83c43c0c778', '2bfe1315-2733-55f7-971a-be3f2a9c3829', N'demo-company-086', N'careers-086@example.invalid', 2013, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('a50cb7d2-3dc3-554f-9495-e73298d1be2c', N'Công ty Sức khỏe Tân Việt (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sức khỏe Tân Việt (Demo) là doanh nghiệp giả lập trong lĩnh vực y tế & chăm sóc sức khỏe, có trụ sở tại Tỉnh Tây Ninh. Không phải thông tin tuyển dụng thực tế.', 6, 28, N'106 đường Minh Khai, Khu văn phòng Demo', 550, 950, '8866dd1e-0c54-524f-a4f2-8d0dc6e4f017', 'd310be06-cf0c-59af-b3f8-9857a492f4bd', N'demo-company-087', N'careers-087@example.invalid', 2014, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('4e2cd592-87bd-56c8-893b-318c85005b3f', N'Công ty Du lịch Tân Việt (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Du lịch Tân Việt (Demo) là doanh nghiệp giả lập trong lĩnh vực du lịch & khách sạn, có trụ sở tại Tỉnh An Giang. Không phải thông tin tuyển dụng thực tế.', 7, 31, N'107 đường Minh Khai, Khu văn phòng Demo', 550, 950, 'd90f9f1b-988e-5830-b36c-2f6e4899129e', 'aa5116eb-cf88-5dba-ac12-6583cf1245d3', N'demo-company-088', N'careers-088@example.invalid', 2015, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('fc3cfce6-06a0-5453-ba31-dee1626da3cb', N'Công ty Xây dựng Tân Việt (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Xây dựng Tân Việt (Demo) là doanh nghiệp giả lập trong lĩnh vực xây dựng & bất động sản, có trụ sở tại Thành phố Hà Nội. Không phải thông tin tuyển dụng thực tế.', 8, 0, N'108 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, 'b6717b3f-fe92-55b0-b48e-aeec38c5ff35', 'b171d966-7156-5892-9a95-6219098d55c0', N'demo-company-089', N'careers-089@example.invalid', 2016, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('b35c57ab-1da0-5df1-b038-34cb54aed01a', N'Công ty Sáng tạo Tân Việt (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sáng tạo Tân Việt (Demo) là doanh nghiệp giả lập trong lĩnh vực truyền thông & thiết kế, có trụ sở tại Tỉnh Điện Biên. Không phải thông tin tuyển dụng thực tế.', 9, 3, N'109 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, '5dbe9d47-482c-586b-aa45-2a600d3f3bcd', 'f441acfc-4eac-58a2-9305-f27c14221f76', N'demo-company-090', N'careers-090@example.invalid', 2017, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('4a0da68e-ebdf-5715-a2ee-a777a4c46b5f', N'Công ty Công nghệ Đông Phong (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Công nghệ Đông Phong (Demo) là doanh nghiệp giả lập trong lĩnh vực công nghệ thông tin, có trụ sở tại Tỉnh Thái Nguyên. Không phải thông tin tuyển dụng thực tế.', 0, 7, N'110 đường Minh Khai, Khu văn phòng Demo', 15, 45, '6c25f35b-1dc7-593e-b60e-8d77883e38a0', 'e8541eb9-9ce9-5049-afaa-33836243ee3a', N'demo-company-091', N'careers-091@example.invalid', 2018, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('8370ed33-18e7-5cb9-aea7-ca98c8db2313', N'Công ty Tài chính Đông Phong (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Tài chính Đông Phong (Demo) là doanh nghiệp giả lập trong lĩnh vực ngân hàng & tài chính, có trụ sở tại Tỉnh Bắc Ninh. Không phải thông tin tuyển dụng thực tế.', 1, 10, N'111 đường Minh Khai, Khu văn phòng Demo', 15, 45, 'f33cf6e4-a614-5e5d-aea5-ef5803b6ab19', '6c14ffe4-e635-5118-a339-60998b2053b4', N'demo-company-092', N'careers-092@example.invalid', 2019, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('76841e48-1916-5c2e-a94a-dc98dee018a9', N'Công ty Thương mại Đông Phong (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Thương mại Đông Phong (Demo) là doanh nghiệp giả lập trong lĩnh vực thương mại điện tử, có trụ sở tại Tỉnh Hưng Yên. Không phải thông tin tuyển dụng thực tế.', 2, 13, N'112 đường Minh Khai, Khu văn phòng Demo', 60, 180, '8d37f5bd-6123-5ef6-a98b-92f773430a64', 'be04e479-e762-5bc6-b24e-a7e6eebfbc01', N'demo-company-093', N'careers-093@example.invalid', 2020, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('3f470166-5e17-59da-8b3e-3ae731ee7254', N'Công ty Logistics Đông Phong (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Logistics Đông Phong (Demo) là doanh nghiệp giả lập trong lĩnh vực logistics & chuỗi cung ứng, có trụ sở tại Tỉnh Nghệ An. Không phải thông tin tuyển dụng thực tế.', 3, 16, N'113 đường Minh Khai, Khu văn phòng Demo', 60, 180, 'c0aa5832-0877-5fe0-9a23-d37ba9149989', 'c26f7514-5aae-5cef-9074-669241d4ab7f', N'demo-company-094', N'careers-094@example.invalid', 2021, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('5c8c91f5-50a3-553e-b9b5-760e0fa45762', N'Công ty Sản xuất Đông Phong (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sản xuất Đông Phong (Demo) là doanh nghiệp giả lập trong lĩnh vực sản xuất & kỹ thuật, có trụ sở tại Thành phố Huế. Không phải thông tin tuyển dụng thực tế.', 4, 19, N'114 đường Minh Khai, Khu văn phòng Demo', 220, 450, '2f6883fe-f0e3-55de-9259-ce9c36759435', '7c11da0b-ea99-5e94-8e57-b576ec985b93', N'demo-company-095', N'careers-095@example.invalid', 2022, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('e22151d1-bc72-57b3-8b3a-ed22cc2c73e8', N'Công ty Giáo dục Đông Phong (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Giáo dục Đông Phong (Demo) là doanh nghiệp giả lập trong lĩnh vực giáo dục & đào tạo, có trụ sở tại Tỉnh Gia Lai. Không phải thông tin tuyển dụng thực tế.', 5, 22, N'115 đường Minh Khai, Khu văn phòng Demo', 220, 450, '56389389-38ac-532e-bed3-01aeea8d84d7', '2bfe1315-2733-55f7-971a-be3f2a9c3829', N'demo-company-096', N'careers-096@example.invalid', 2023, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Pending'),
    ('48a22bc5-be81-531d-933d-557a40f16e85', N'Công ty Sức khỏe Đông Phong (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sức khỏe Đông Phong (Demo) là doanh nghiệp giả lập trong lĩnh vực y tế & chăm sóc sức khỏe, có trụ sở tại Tỉnh Lâm Đồng. Không phải thông tin tuyển dụng thực tế.', 6, 25, N'116 đường Minh Khai, Khu văn phòng Demo', 550, 950, 'd196ff02-e847-5829-a9fd-55ecd9bb19ff', 'd310be06-cf0c-59af-b3f8-9857a492f4bd', N'demo-company-097', N'careers-097@example.invalid', 2000, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('73b886b4-db23-5559-b243-765b1bc1bdcf', N'Công ty Du lịch Đông Phong (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Du lịch Đông Phong (Demo) là doanh nghiệp giả lập trong lĩnh vực du lịch & khách sạn, có trụ sở tại Tỉnh Tây Ninh. Không phải thông tin tuyển dụng thực tế.', 7, 28, N'117 đường Minh Khai, Khu văn phòng Demo', 550, 950, '7861f676-8d15-5915-bcd5-9988f6335b19', 'aa5116eb-cf88-5dba-ac12-6583cf1245d3', N'demo-company-098', N'careers-098@example.invalid', 2001, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('29691523-762c-5517-8dad-a455d88fd4ff', N'Công ty Xây dựng Đông Phong (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Xây dựng Đông Phong (Demo) là doanh nghiệp giả lập trong lĩnh vực xây dựng & bất động sản, có trụ sở tại Tỉnh An Giang. Không phải thông tin tuyển dụng thực tế.', 8, 31, N'118 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, 'a48de814-ca1f-5e17-b228-b967785b8028', 'b171d966-7156-5892-9a95-6219098d55c0', N'demo-company-099', N'careers-099@example.invalid', 2002, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified'),
    ('11674ab5-3cf2-550a-8311-c9c5ba1f60fa', N'Công ty Sáng tạo Đông Phong (Demo)', N'Dữ liệu minh họa phục vụ phát triển và kiểm thử Job Tốt. Công ty Sáng tạo Đông Phong (Demo) là doanh nghiệp giả lập trong lĩnh vực truyền thông & thiết kế, có trụ sở tại Thành phố Hà Nội. Không phải thông tin tuyển dụng thực tế.', 9, 0, N'119 đường Minh Khai, Khu văn phòng Demo', 1200, 3500, 'ce01abdf-f919-5a96-a07a-da97153e25b9', 'f441acfc-4eac-58a2-9305-f27c14221f76', N'demo-company-100', N'careers-100@example.invalid', 2003, N'Môi trường hợp tác, đào tạo chuyên môn, đánh giá năng lực định kỳ và hỗ trợ phát triển sự nghiệp. Toàn bộ thông tin là dữ liệu demo.', N'Verified');
    INSERT dbo.Companies (Id, DisplayName, LegalName, About, IndustryId, HeadOfficeProvinceId, AddressLine, CompanySizeMin, CompanySizeMax,
        LogoFileId, CoverFileId, Slug, Email, FoundedYear, Culture, VerificationStatus, Status, CreatedDate)
    SELECT seed.Id, seed.Name, seed.Name, seed.About, industry.Id, province.Id, seed.Address, seed.SizeMin, seed.SizeMax,
        seed.LogoId, seed.CoverId, seed.Slug, seed.Email, seed.FoundedYear, seed.Culture, seed.Verification, 1, @Now
    FROM @Companies seed JOIN @Industries industry ON industry.SeedKey = seed.IndustryKey JOIN @Provinces province ON province.SeedKey = seed.ProvinceKey
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Companies actual WHERE actual.Id = seed.Id);
    SET @AddedCompanies = @@ROWCOUNT;

    DECLARE @Jobs TABLE (Id uniqueidentifier PRIMARY KEY, CompanyId uniqueidentifier NOT NULL, Title nvarchar(200), Description nvarchar(max),
        Location nvarchar(200), SalaryMin decimal(18,2), SalaryMax decimal(18,2), AgeDays int, ExpiryDays int);
    INSERT @Jobs VALUES
    ('c7aaebd1-0ba4-5a12-bad4-46bdb77e03ee', '4a837a19-7363-5e3b-aa33-e69f3548d2f3', N'Backend Developer (.NET)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Bình Minh (Demo)
Vị trí: Backend Developer (.NET)
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Backend Developer (.NET) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 10–16 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 10000000, 16000000, 0, 60),
    ('1a867546-5e2b-58dd-a192-76b32c15dab7', '4a837a19-7363-5e3b-aa33-e69f3548d2f3', N'Frontend Developer (React)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Bình Minh (Demo)
Vị trí: Frontend Developer (React)
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Frontend Developer (React) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 13–20 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 13000000, 20000000, 1, 60),
    ('28658497-2426-56db-bb33-0d866f07231b', '4a837a19-7363-5e3b-aa33-e69f3548d2f3', N'DevOps Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Bình Minh (Demo)
Vị trí: DevOps Engineer
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí DevOps Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 16000000, 24000000, 2, 60),
    ('810a6bcd-32dd-5e3a-aec2-3c5e31524421', '4a837a19-7363-5e3b-aa33-e69f3548d2f3', N'QA Automation Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Bình Minh (Demo)
Vị trí: QA Automation Engineer
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí QA Automation Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 19000000, 25000000, 3, 60),
    ('620d509d-778e-5475-85b5-f5caf192ed3b', '4a837a19-7363-5e3b-aa33-e69f3548d2f3', N'Business Analyst', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Bình Minh (Demo)
Vị trí: Business Analyst
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Business Analyst trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 22000000, 29000000, 4, 60),
    ('db90f007-a8c3-5dcb-80c5-49cfdec6cccf', '14bb0e80-8e98-57ed-a3da-947ac1a7946f', N'Chuyên viên phân tích tài chính', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Bình Minh (Demo)
Vị trí: Chuyên viên phân tích tài chính
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích tài chính trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 11–17 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 11000000, 17000000, 1, 61),
    ('cd169a3e-fef3-5183-a0c5-d28ccb003ed1', '14bb0e80-8e98-57ed-a3da-947ac1a7946f', N'Chuyên viên tín dụng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Bình Minh (Demo)
Vị trí: Chuyên viên tín dụng
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tín dụng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 14000000, 21000000, 2, 61),
    ('cf11a198-f009-5950-aa3b-105947172164', '14bb0e80-8e98-57ed-a3da-947ac1a7946f', N'Chuyên viên quản trị rủi ro', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Bình Minh (Demo)
Vị trí: Chuyên viên quản trị rủi ro
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản trị rủi ro trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 17000000, 25000000, 3, 61),
    ('155ee393-9859-5399-aaf7-bd41172486e6', '14bb0e80-8e98-57ed-a3da-947ac1a7946f', N'Chuyên viên tư vấn khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Bình Minh (Demo)
Vị trí: Chuyên viên tư vấn khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn khách hàng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 20000000, 26000000, 4, 61),
    ('10361f1a-9e2b-5555-b179-0eedacea5fdf', '14bb0e80-8e98-57ed-a3da-947ac1a7946f', N'Kế toán tổng hợp', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Bình Minh (Demo)
Vị trí: Kế toán tổng hợp
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kế toán tổng hợp trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 23000000, 30000000, 5, 61),
    ('e3cc1e29-66f2-579a-b65a-36bcf6d0e229', 'b869e635-f170-55b7-b5de-ae1dbcc5e8ed', N'Chuyên viên vận hành sàn thương mại điện tử', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Bình Minh (Demo)
Vị trí: Chuyên viên vận hành sàn thương mại điện tử
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành sàn thương mại điện tử trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 12–18 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 12000000, 18000000, 2, 62),
    ('9f7c3022-8db4-585c-8a8f-8d202f9d721b', 'b869e635-f170-55b7-b5de-ae1dbcc5e8ed', N'Digital Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Bình Minh (Demo)
Vị trí: Digital Marketing Specialist
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Digital Marketing Specialist trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 15000000, 22000000, 3, 62),
    ('bbf4d347-c131-5f59-ab6e-3bedfae56b65', 'b869e635-f170-55b7-b5de-ae1dbcc5e8ed', N'Chuyên viên chăm sóc khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Bình Minh (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 18000000, 26000000, 4, 62),
    ('1c3ff788-c61a-55a0-98ca-b42af39a5164', 'b869e635-f170-55b7-b5de-ae1dbcc5e8ed', N'Chuyên viên phân tích dữ liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Bình Minh (Demo)
Vị trí: Chuyên viên phân tích dữ liệu
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích dữ liệu trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 21000000, 27000000, 5, 62),
    ('04791046-3ebf-5027-a6ed-62573ea31005', 'b869e635-f170-55b7-b5de-ae1dbcc5e8ed', N'Quản lý ngành hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Bình Minh (Demo)
Vị trí: Quản lý ngành hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý ngành hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 24000000, 31000000, 6, 62),
    ('fb5ca868-49a7-53bd-b986-7c65aed6336e', '48752bb2-64c8-5270-8ea5-bba98aed8643', N'Chuyên viên điều phối vận tải', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Bình Minh (Demo)
Vị trí: Chuyên viên điều phối vận tải
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều phối vận tải trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 13–19 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 13000000, 19000000, 3, 63),
    ('3c98173a-ba53-5a8d-bf67-c088c2c53644', '48752bb2-64c8-5270-8ea5-bba98aed8643', N'Chuyên viên xuất nhập khẩu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Bình Minh (Demo)
Vị trí: Chuyên viên xuất nhập khẩu
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên xuất nhập khẩu trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 16000000, 23000000, 4, 63),
    ('1579a0ec-198a-5ec6-8fbf-ef7187a21269', '48752bb2-64c8-5270-8ea5-bba98aed8643', N'Nhân viên quản lý kho', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Bình Minh (Demo)
Vị trí: Nhân viên quản lý kho
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên quản lý kho trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 19000000, 27000000, 5, 63),
    ('8c0ddfeb-5cdb-525b-85d6-b5ad3d139744', '48752bb2-64c8-5270-8ea5-bba98aed8643', N'Chuyên viên mua hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Bình Minh (Demo)
Vị trí: Chuyên viên mua hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên mua hàng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 22000000, 28000000, 6, 63),
    ('7763bca5-5f8a-5241-b8cc-be1e55bb301c', '48752bb2-64c8-5270-8ea5-bba98aed8643', N'Chuyên viên hoạch định chuỗi cung ứng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Bình Minh (Demo)
Vị trí: Chuyên viên hoạch định chuỗi cung ứng
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên hoạch định chuỗi cung ứng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 25000000, 32000000, 7, 63),
    ('0f4dea09-ac4a-5a1f-8d6e-86740ed8593d', '617b24e4-567c-5109-9094-b3787b1f4b48', N'Kỹ sư tự động hóa', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Bình Minh (Demo)
Vị trí: Kỹ sư tự động hóa
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư tự động hóa trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–20 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 14000000, 20000000, 4, 64),
    ('b67aa3ed-243e-578d-ae84-521875dde445', '617b24e4-567c-5109-9094-b3787b1f4b48', N'Kỹ sư cơ khí', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Bình Minh (Demo)
Vị trí: Kỹ sư cơ khí
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư cơ khí trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 17000000, 24000000, 5, 64),
    ('057e39c3-ccd8-51be-8809-fe41fc6aac5b', '617b24e4-567c-5109-9094-b3787b1f4b48', N'Kỹ sư kiểm soát chất lượng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Bình Minh (Demo)
Vị trí: Kỹ sư kiểm soát chất lượng
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư kiểm soát chất lượng trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 20000000, 28000000, 6, 64),
    ('acc4d1ad-e603-5a1a-ae7e-3aaee3242b85', '617b24e4-567c-5109-9094-b3787b1f4b48', N'Kỹ sư bảo trì', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Bình Minh (Demo)
Vị trí: Kỹ sư bảo trì
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư bảo trì trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 23000000, 29000000, 7, 64),
    ('08375d4b-2033-54c4-a0de-48d767daa9e3', '617b24e4-567c-5109-9094-b3787b1f4b48', N'Chuyên viên kế hoạch sản xuất', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Bình Minh (Demo)
Vị trí: Chuyên viên kế hoạch sản xuất
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kế hoạch sản xuất trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 26000000, 33000000, 8, 64),
    ('cd036c1b-da74-5087-a478-2ec2d4dfd838', '70cdc04e-b825-5ec6-8713-8c458bb2deb2', N'Giáo viên tiếng Anh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Bình Minh (Demo)
Vị trí: Giáo viên tiếng Anh
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Giáo viên tiếng Anh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 15000000, 21000000, 5, 65),
    ('dc966e5a-3d83-5280-b1d0-257740283ebf', '70cdc04e-b825-5ec6-8713-8c458bb2deb2', N'Chuyên viên phát triển học liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Bình Minh (Demo)
Vị trí: Chuyên viên phát triển học liệu
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phát triển học liệu trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 18000000, 25000000, 6, 65),
    ('9e403df0-ca57-51b2-aa57-cd8f58a385c6', '70cdc04e-b825-5ec6-8713-8c458bb2deb2', N'Chuyên viên tư vấn tuyển sinh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Bình Minh (Demo)
Vị trí: Chuyên viên tư vấn tuyển sinh
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn tuyển sinh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 21000000, 29000000, 7, 65),
    ('ae8ec351-07aa-5618-b1ef-5b99eb9fc68c', '70cdc04e-b825-5ec6-8713-8c458bb2deb2', N'Điều phối viên đào tạo', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Bình Minh (Demo)
Vị trí: Điều phối viên đào tạo
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều phối viên đào tạo trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 24000000, 30000000, 8, 65),
    ('75684033-6c3e-50bc-ae05-47c7c28137ce', '70cdc04e-b825-5ec6-8713-8c458bb2deb2', N'Chuyên viên công nghệ giáo dục', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Bình Minh (Demo)
Vị trí: Chuyên viên công nghệ giáo dục
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên công nghệ giáo dục trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 27000000, 34000000, 9, 65),
    ('94325952-4594-53cf-8083-7cc5c5184e0d', '3fdb6e38-85d8-5ac8-9b96-24b88c4a271c', N'Điều dưỡng viên', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Bình Minh (Demo)
Vị trí: Điều dưỡng viên
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều dưỡng viên trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 16000000, 22000000, 6, 66),
    ('a82d2cd0-fa33-5c15-9042-fbe469434ae4', '3fdb6e38-85d8-5ac8-9b96-24b88c4a271c', N'Dược sĩ', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Bình Minh (Demo)
Vị trí: Dược sĩ
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Dược sĩ trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 19000000, 26000000, 7, 66),
    ('e4bd75ba-86a1-5a5e-9613-8e2991a2c463', '3fdb6e38-85d8-5ac8-9b96-24b88c4a271c', N'Chuyên viên vận hành dịch vụ y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Bình Minh (Demo)
Vị trí: Chuyên viên vận hành dịch vụ y tế
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành dịch vụ y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 22000000, 30000000, 8, 66),
    ('8b177b77-41cc-5245-af3f-f6cb30907616', '3fdb6e38-85d8-5ac8-9b96-24b88c4a271c', N'Kỹ thuật viên xét nghiệm', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Bình Minh (Demo)
Vị trí: Kỹ thuật viên xét nghiệm
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ thuật viên xét nghiệm trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 25000000, 31000000, 9, 66),
    ('173abd85-74bc-513d-92d2-1d19911885ae', '3fdb6e38-85d8-5ac8-9b96-24b88c4a271c', N'Chuyên viên chăm sóc khách hàng y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Bình Minh (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng y tế
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 28000000, 35000000, 10, 66),
    ('d7a1214b-d4ef-59a1-ba9e-903a3ac478da', 'fdaa4d8c-0f20-5eba-83a9-894bf1b31de3', N'Chuyên viên điều hành tour', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Bình Minh (Demo)
Vị trí: Chuyên viên điều hành tour
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ngãi
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều hành tour trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ngãi', 17000000, 23000000, 7, 67),
    ('c322d911-2eff-5308-94cb-bac930317896', 'fdaa4d8c-0f20-5eba-83a9-894bf1b31de3', N'Nhân viên lễ tân', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Bình Minh (Demo)
Vị trí: Nhân viên lễ tân
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ngãi
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên lễ tân trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ngãi', 20000000, 27000000, 8, 67),
    ('dff8a6a9-6419-51c3-a74c-ee6130ab8274', 'fdaa4d8c-0f20-5eba-83a9-894bf1b31de3', N'Chuyên viên kinh doanh du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Bình Minh (Demo)
Vị trí: Chuyên viên kinh doanh du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ngãi
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kinh doanh du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ngãi', 23000000, 31000000, 9, 67),
    ('78120204-ec7f-59ae-a6d1-3afb9d67e466', 'fdaa4d8c-0f20-5eba-83a9-894bf1b31de3', N'Quản lý dịch vụ khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Bình Minh (Demo)
Vị trí: Quản lý dịch vụ khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ngãi
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý dịch vụ khách hàng trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ngãi', 26000000, 32000000, 10, 67),
    ('ce9cfd97-1661-59ce-8f5b-245fd380acc3', 'fdaa4d8c-0f20-5eba-83a9-894bf1b31de3', N'Chuyên viên marketing du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Bình Minh (Demo)
Vị trí: Chuyên viên marketing du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ngãi
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên marketing du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ngãi', 29000000, 36000000, 11, 67),
    ('1cdeb3e9-d621-57be-ab4a-aed90de34978', 'f4b041a1-d22a-5630-afde-2b5c0a1c61b3', N'Kỹ sư xây dựng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Bình Minh (Demo)
Vị trí: Kỹ sư xây dựng
Địa điểm: Khu văn phòng Demo, Tỉnh Đắk Lắk
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư xây dựng trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Đắk Lắk', 18000000, 24000000, 8, 68),
    ('c609147a-31af-5518-8ed1-7337bd425b8d', 'f4b041a1-d22a-5630-afde-2b5c0a1c61b3', N'Kiến trúc sư', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Bình Minh (Demo)
Vị trí: Kiến trúc sư
Địa điểm: Khu văn phòng Demo, Tỉnh Đắk Lắk
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kiến trúc sư trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Đắk Lắk', 21000000, 28000000, 9, 68),
    ('debfe445-e26e-589a-983c-ce92d9d58b40', 'f4b041a1-d22a-5630-afde-2b5c0a1c61b3', N'Chuyên viên quản lý dự án', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Bình Minh (Demo)
Vị trí: Chuyên viên quản lý dự án
Địa điểm: Khu văn phòng Demo, Tỉnh Đắk Lắk
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản lý dự án trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Đắk Lắk', 24000000, 32000000, 10, 68),
    ('f19a22f8-58c6-5b52-b364-aa97f58e6340', 'f4b041a1-d22a-5630-afde-2b5c0a1c61b3', N'Kỹ sư dự toán', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Bình Minh (Demo)
Vị trí: Kỹ sư dự toán
Địa điểm: Khu văn phòng Demo, Tỉnh Đắk Lắk
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư dự toán trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Đắk Lắk', 27000000, 33000000, 11, 68),
    ('5ecde55a-cdf6-56e3-9ede-5a7947940f50', 'f4b041a1-d22a-5630-afde-2b5c0a1c61b3', N'Chuyên viên tư vấn bất động sản', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Bình Minh (Demo)
Vị trí: Chuyên viên tư vấn bất động sản
Địa điểm: Khu văn phòng Demo, Tỉnh Đắk Lắk
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn bất động sản trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 30–37 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Đắk Lắk', 30000000, 37000000, 12, 68),
    ('13377b54-7b6f-5be9-b30c-8b31a40a099b', '5d96e158-3c12-5d6a-a487-b407ba52ee13', N'Graphic Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Bình Minh (Demo)
Vị trí: Graphic Designer
Địa điểm: Khu văn phòng Demo, Thành phố Hồ Chí Minh
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Graphic Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hồ Chí Minh', 19000000, 25000000, 9, 69),
    ('0d509c8f-f1fe-5270-b684-c9551f30befe', '5d96e158-3c12-5d6a-a487-b407ba52ee13', N'Content Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Bình Minh (Demo)
Vị trí: Content Marketing Specialist
Địa điểm: Khu văn phòng Demo, Thành phố Hồ Chí Minh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Content Marketing Specialist trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hồ Chí Minh', 22000000, 29000000, 10, 69),
    ('aef90417-4f58-538d-9b01-61cb8da41581', '5d96e158-3c12-5d6a-a487-b407ba52ee13', N'UI/UX Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Bình Minh (Demo)
Vị trí: UI/UX Designer
Địa điểm: Khu văn phòng Demo, Thành phố Hồ Chí Minh
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí UI/UX Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hồ Chí Minh', 25000000, 33000000, 11, 69),
    ('a2a97b8e-6207-5ee3-ada2-faa40f246b69', '5d96e158-3c12-5d6a-a487-b407ba52ee13', N'Chuyên viên truyền thông', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Bình Minh (Demo)
Vị trí: Chuyên viên truyền thông
Địa điểm: Khu văn phòng Demo, Thành phố Hồ Chí Minh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên truyền thông trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hồ Chí Minh', 28000000, 34000000, 12, 69),
    ('13b3f9f0-dad1-556c-ac45-c0e2f8e813d2', '5d96e158-3c12-5d6a-a487-b407ba52ee13', N'Video Editor', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Bình Minh (Demo)
Vị trí: Video Editor
Địa điểm: Khu văn phòng Demo, Thành phố Hồ Chí Minh
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Video Editor trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 31–38 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hồ Chí Minh', 31000000, 38000000, 13, 69),
    ('0986045f-c8c2-5ebe-8cb4-6e54df2cd5d7', 'd29659a5-b173-5586-8d9b-8d5aac6c7d28', N'Backend Developer (.NET)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Hải Đăng (Demo)
Vị trí: Backend Developer (.NET)
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Backend Developer (.NET) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 11–17 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 11000000, 17000000, 10, 70),
    ('f1daf5dc-694f-56d7-a014-e2b768ec0533', 'd29659a5-b173-5586-8d9b-8d5aac6c7d28', N'Frontend Developer (React)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Hải Đăng (Demo)
Vị trí: Frontend Developer (React)
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Frontend Developer (React) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 14000000, 21000000, 11, 70),
    ('b4a288cb-f315-5ac6-8648-422e1eccb127', 'd29659a5-b173-5586-8d9b-8d5aac6c7d28', N'DevOps Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Hải Đăng (Demo)
Vị trí: DevOps Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí DevOps Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 17000000, 25000000, 12, 70),
    ('38a49951-f7d9-55b2-b289-86a4051cd2ae', 'd29659a5-b173-5586-8d9b-8d5aac6c7d28', N'QA Automation Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Hải Đăng (Demo)
Vị trí: QA Automation Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí QA Automation Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 20000000, 26000000, 13, 70),
    ('279deec3-04ea-5219-8bee-3ad498f8b009', 'd29659a5-b173-5586-8d9b-8d5aac6c7d28', N'Business Analyst', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Hải Đăng (Demo)
Vị trí: Business Analyst
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Business Analyst trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 23000000, 30000000, 14, 70),
    ('94a51f2e-2a15-5ff7-a0e6-d63b77e207e7', 'c8156833-0c4b-5502-9cad-8ece54d27023', N'Chuyên viên phân tích tài chính', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Hải Đăng (Demo)
Vị trí: Chuyên viên phân tích tài chính
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích tài chính trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 12–18 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 12000000, 18000000, 11, 71),
    ('2dbd250c-cee6-5808-ab28-5d5ff0c663bc', 'c8156833-0c4b-5502-9cad-8ece54d27023', N'Chuyên viên tín dụng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Hải Đăng (Demo)
Vị trí: Chuyên viên tín dụng
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tín dụng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 15000000, 22000000, 12, 71),
    ('50fab70e-ba26-533f-a1f2-4df104cbdf57', 'c8156833-0c4b-5502-9cad-8ece54d27023', N'Chuyên viên quản trị rủi ro', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Hải Đăng (Demo)
Vị trí: Chuyên viên quản trị rủi ro
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản trị rủi ro trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 18000000, 26000000, 13, 71),
    ('303921ef-cfb3-5426-a11d-6a9a4a0333c1', 'c8156833-0c4b-5502-9cad-8ece54d27023', N'Chuyên viên tư vấn khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Hải Đăng (Demo)
Vị trí: Chuyên viên tư vấn khách hàng
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn khách hàng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 21000000, 27000000, 14, 71),
    ('b7c5136d-3b4d-58dd-b048-062b20b62416', 'c8156833-0c4b-5502-9cad-8ece54d27023', N'Kế toán tổng hợp', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Hải Đăng (Demo)
Vị trí: Kế toán tổng hợp
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kế toán tổng hợp trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 24000000, 31000000, 15, 71),
    ('bcb74ff6-595f-51ec-8fe9-0ac8901709e3', '2b704e8c-71e9-554e-9979-36f18ae9c930', N'Chuyên viên vận hành sàn thương mại điện tử', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Hải Đăng (Demo)
Vị trí: Chuyên viên vận hành sàn thương mại điện tử
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành sàn thương mại điện tử trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 13–19 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 13000000, 19000000, 12, 72),
    ('917af240-3cf1-542a-b3c1-05b12bac59c5', '2b704e8c-71e9-554e-9979-36f18ae9c930', N'Digital Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Hải Đăng (Demo)
Vị trí: Digital Marketing Specialist
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Digital Marketing Specialist trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 16000000, 23000000, 13, 72),
    ('351bba35-88a1-5225-ab65-78b40e91bbab', '2b704e8c-71e9-554e-9979-36f18ae9c930', N'Chuyên viên chăm sóc khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Hải Đăng (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 19000000, 27000000, 14, 72),
    ('a554ff50-5b15-5c20-b8c9-495ea759149d', '2b704e8c-71e9-554e-9979-36f18ae9c930', N'Chuyên viên phân tích dữ liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Hải Đăng (Demo)
Vị trí: Chuyên viên phân tích dữ liệu
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích dữ liệu trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 22000000, 28000000, 15, 72),
    ('312337d5-7372-527e-a271-18c14d79a7d3', '2b704e8c-71e9-554e-9979-36f18ae9c930', N'Quản lý ngành hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Hải Đăng (Demo)
Vị trí: Quản lý ngành hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý ngành hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 25000000, 32000000, 16, 72),
    ('cf41e25e-c622-554b-ad89-8734ab0b98c6', '5715cd40-e2d5-5424-9879-802a9090440e', N'Chuyên viên điều phối vận tải', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Hải Đăng (Demo)
Vị trí: Chuyên viên điều phối vận tải
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều phối vận tải trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–20 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 14000000, 20000000, 13, 73),
    ('a2fceabf-41ac-5881-8687-74ff21608bdc', '5715cd40-e2d5-5424-9879-802a9090440e', N'Chuyên viên xuất nhập khẩu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Hải Đăng (Demo)
Vị trí: Chuyên viên xuất nhập khẩu
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên xuất nhập khẩu trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 17000000, 24000000, 14, 73),
    ('406afe91-9cdc-5785-8421-3d18e7833147', '5715cd40-e2d5-5424-9879-802a9090440e', N'Nhân viên quản lý kho', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Hải Đăng (Demo)
Vị trí: Nhân viên quản lý kho
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên quản lý kho trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 20000000, 28000000, 15, 73),
    ('782a6b68-e1bf-5ca0-8a12-b3f4a2fc91e6', '5715cd40-e2d5-5424-9879-802a9090440e', N'Chuyên viên mua hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Hải Đăng (Demo)
Vị trí: Chuyên viên mua hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên mua hàng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 23000000, 29000000, 16, 73),
    ('d2bc68c2-a24e-5c73-9116-09e7dc55ebe1', '5715cd40-e2d5-5424-9879-802a9090440e', N'Chuyên viên hoạch định chuỗi cung ứng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Hải Đăng (Demo)
Vị trí: Chuyên viên hoạch định chuỗi cung ứng
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên hoạch định chuỗi cung ứng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 26000000, 33000000, 17, 73),
    ('0702ed3e-d921-55a3-a995-3ee8330b7e02', '5779faef-4869-5314-ad70-efb376b1aec9', N'Kỹ sư tự động hóa', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Hải Đăng (Demo)
Vị trí: Kỹ sư tự động hóa
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư tự động hóa trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 15000000, 21000000, 0, 74),
    ('6361a10d-1108-5eaf-a6bb-f7016bb185e3', '5779faef-4869-5314-ad70-efb376b1aec9', N'Kỹ sư cơ khí', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Hải Đăng (Demo)
Vị trí: Kỹ sư cơ khí
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư cơ khí trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 18000000, 25000000, 1, 74),
    ('f48c9e34-e7a2-5077-8bae-3e02ea0f8085', '5779faef-4869-5314-ad70-efb376b1aec9', N'Kỹ sư kiểm soát chất lượng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Hải Đăng (Demo)
Vị trí: Kỹ sư kiểm soát chất lượng
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư kiểm soát chất lượng trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 21000000, 29000000, 2, 74),
    ('72c0e936-6705-5a6d-a634-214da967ef43', '5779faef-4869-5314-ad70-efb376b1aec9', N'Kỹ sư bảo trì', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Hải Đăng (Demo)
Vị trí: Kỹ sư bảo trì
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư bảo trì trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 24000000, 30000000, 3, 74),
    ('99c4243f-7d1d-5fe0-a0ae-a196a8abd963', '5779faef-4869-5314-ad70-efb376b1aec9', N'Chuyên viên kế hoạch sản xuất', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Hải Đăng (Demo)
Vị trí: Chuyên viên kế hoạch sản xuất
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kế hoạch sản xuất trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 27000000, 34000000, 4, 74),
    ('214f875d-344a-5793-968b-c8a71862d5f1', '8bfa1442-cca1-5bc6-8dff-37063a398cd5', N'Giáo viên tiếng Anh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Hải Đăng (Demo)
Vị trí: Giáo viên tiếng Anh
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Giáo viên tiếng Anh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 16000000, 22000000, 1, 75),
    ('441e4644-2d1b-5842-955c-a194300428f5', '8bfa1442-cca1-5bc6-8dff-37063a398cd5', N'Chuyên viên phát triển học liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Hải Đăng (Demo)
Vị trí: Chuyên viên phát triển học liệu
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phát triển học liệu trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 19000000, 26000000, 2, 75),
    ('b196ba25-ba44-5d00-876d-345cc360969b', '8bfa1442-cca1-5bc6-8dff-37063a398cd5', N'Chuyên viên tư vấn tuyển sinh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Hải Đăng (Demo)
Vị trí: Chuyên viên tư vấn tuyển sinh
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn tuyển sinh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 22000000, 30000000, 3, 75),
    ('dd822276-8a3b-5e68-9ab3-dbc46c6214c7', '8bfa1442-cca1-5bc6-8dff-37063a398cd5', N'Điều phối viên đào tạo', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Hải Đăng (Demo)
Vị trí: Điều phối viên đào tạo
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều phối viên đào tạo trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 25000000, 31000000, 4, 75),
    ('f99520b5-8280-5b4d-97ec-62ac9a2627e2', '8bfa1442-cca1-5bc6-8dff-37063a398cd5', N'Chuyên viên công nghệ giáo dục', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Hải Đăng (Demo)
Vị trí: Chuyên viên công nghệ giáo dục
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên công nghệ giáo dục trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 28000000, 35000000, 5, 75),
    ('78f42d58-d3a4-5508-af81-a19ba069cf08', 'df3e7bde-a59d-5254-b642-23429cf781ad', N'Điều dưỡng viên', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Hải Đăng (Demo)
Vị trí: Điều dưỡng viên
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều dưỡng viên trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 17000000, 23000000, 2, 76),
    ('1a87f531-2fff-5158-9c71-af38d9156aa2', 'df3e7bde-a59d-5254-b642-23429cf781ad', N'Dược sĩ', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Hải Đăng (Demo)
Vị trí: Dược sĩ
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Dược sĩ trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 20000000, 27000000, 3, 76),
    ('ea741e13-039c-5f35-a630-c8d23808364d', 'df3e7bde-a59d-5254-b642-23429cf781ad', N'Chuyên viên vận hành dịch vụ y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Hải Đăng (Demo)
Vị trí: Chuyên viên vận hành dịch vụ y tế
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành dịch vụ y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 23000000, 31000000, 4, 76),
    ('c94fda1b-332f-573a-a51b-68d74920998f', 'df3e7bde-a59d-5254-b642-23429cf781ad', N'Kỹ thuật viên xét nghiệm', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Hải Đăng (Demo)
Vị trí: Kỹ thuật viên xét nghiệm
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ thuật viên xét nghiệm trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 26000000, 32000000, 5, 76),
    ('f94f32c3-22a8-55d8-8f6c-6a66cfd6fda0', 'df3e7bde-a59d-5254-b642-23429cf781ad', N'Chuyên viên chăm sóc khách hàng y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Hải Đăng (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng y tế
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 29000000, 36000000, 6, 76),
    ('176ecce7-f7ee-5640-bc0e-0f80820a9e22', 'e1bce78f-d113-5f6b-a178-7ff31a6f57eb', N'Chuyên viên điều hành tour', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Hải Đăng (Demo)
Vị trí: Chuyên viên điều hành tour
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều hành tour trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 18000000, 24000000, 3, 77),
    ('e3101b0e-694d-5bb1-ab62-1ac681a66341', 'e1bce78f-d113-5f6b-a178-7ff31a6f57eb', N'Nhân viên lễ tân', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Hải Đăng (Demo)
Vị trí: Nhân viên lễ tân
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên lễ tân trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 21000000, 28000000, 4, 77),
    ('becd4eac-f1bf-591a-9282-ea14b7da6861', 'e1bce78f-d113-5f6b-a178-7ff31a6f57eb', N'Chuyên viên kinh doanh du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Hải Đăng (Demo)
Vị trí: Chuyên viên kinh doanh du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kinh doanh du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 24000000, 32000000, 5, 77),
    ('0da21226-d171-5dbe-a69d-b3eec27235d6', 'e1bce78f-d113-5f6b-a178-7ff31a6f57eb', N'Quản lý dịch vụ khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Hải Đăng (Demo)
Vị trí: Quản lý dịch vụ khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý dịch vụ khách hàng trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 27000000, 33000000, 6, 77),
    ('ae2aee67-abf0-5560-a549-4555df5d9a5a', 'e1bce78f-d113-5f6b-a178-7ff31a6f57eb', N'Chuyên viên marketing du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Hải Đăng (Demo)
Vị trí: Chuyên viên marketing du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên marketing du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 30–37 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 30000000, 37000000, 7, 77),
    ('83f94c15-0a15-5a03-8da6-9f9259e0bc8c', '6e0be351-ca7d-51ff-bdc7-2f8eb50e4e7b', N'Kỹ sư xây dựng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Hải Đăng (Demo)
Vị trí: Kỹ sư xây dựng
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ngãi
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư xây dựng trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ngãi', 19000000, 25000000, 4, 78),
    ('1599625d-69e3-5cc3-87b5-629acb9d3c2b', '6e0be351-ca7d-51ff-bdc7-2f8eb50e4e7b', N'Kiến trúc sư', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Hải Đăng (Demo)
Vị trí: Kiến trúc sư
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ngãi
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kiến trúc sư trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ngãi', 22000000, 29000000, 5, 78),
    ('3099cb44-4cb0-5d1b-be4a-9a91ed9dea06', '6e0be351-ca7d-51ff-bdc7-2f8eb50e4e7b', N'Chuyên viên quản lý dự án', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Hải Đăng (Demo)
Vị trí: Chuyên viên quản lý dự án
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ngãi
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản lý dự án trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ngãi', 25000000, 33000000, 6, 78),
    ('0e74f66a-f418-5eed-bc12-f9d067a9e05d', '6e0be351-ca7d-51ff-bdc7-2f8eb50e4e7b', N'Kỹ sư dự toán', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Hải Đăng (Demo)
Vị trí: Kỹ sư dự toán
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ngãi
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư dự toán trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ngãi', 28000000, 34000000, 7, 78),
    ('c58d0e49-795d-57ed-81a2-147e311575f9', '6e0be351-ca7d-51ff-bdc7-2f8eb50e4e7b', N'Chuyên viên tư vấn bất động sản', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Hải Đăng (Demo)
Vị trí: Chuyên viên tư vấn bất động sản
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ngãi
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn bất động sản trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 31–38 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ngãi', 31000000, 38000000, 8, 78),
    ('56f90dae-521f-5fe6-a82b-a69f9dabfdea', 'f3539610-9992-536c-a291-cfc3a1af84f4', N'Graphic Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Hải Đăng (Demo)
Vị trí: Graphic Designer
Địa điểm: Khu văn phòng Demo, Tỉnh Đắk Lắk
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Graphic Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Đắk Lắk', 20000000, 26000000, 5, 79),
    ('4fb5594e-9484-5e4f-976c-b85faaf4be57', 'f3539610-9992-536c-a291-cfc3a1af84f4', N'Content Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Hải Đăng (Demo)
Vị trí: Content Marketing Specialist
Địa điểm: Khu văn phòng Demo, Tỉnh Đắk Lắk
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Content Marketing Specialist trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Đắk Lắk', 23000000, 30000000, 6, 79),
    ('3e9650bc-a8af-5a34-bbf2-d60754ff5fe1', 'f3539610-9992-536c-a291-cfc3a1af84f4', N'UI/UX Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Hải Đăng (Demo)
Vị trí: UI/UX Designer
Địa điểm: Khu văn phòng Demo, Tỉnh Đắk Lắk
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí UI/UX Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Đắk Lắk', 26000000, 34000000, 7, 79),
    ('ebf42b70-9804-552d-b462-cf233de6a262', 'f3539610-9992-536c-a291-cfc3a1af84f4', N'Chuyên viên truyền thông', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Hải Đăng (Demo)
Vị trí: Chuyên viên truyền thông
Địa điểm: Khu văn phòng Demo, Tỉnh Đắk Lắk
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên truyền thông trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Đắk Lắk', 29000000, 35000000, 8, 79),
    ('34212b17-9092-5689-b7f5-8bc4bb5b034f', 'f3539610-9992-536c-a291-cfc3a1af84f4', N'Video Editor', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Hải Đăng (Demo)
Vị trí: Video Editor
Địa điểm: Khu văn phòng Demo, Tỉnh Đắk Lắk
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Video Editor trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 32–39 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Đắk Lắk', 32000000, 39000000, 9, 79),
    ('0035dee4-d558-50bf-a8c4-c949002427cc', 'f0cb2b01-af76-5b3c-9a21-1f7fd1338d04', N'Backend Developer (.NET)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Sao Mai (Demo)
Vị trí: Backend Developer (.NET)
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Backend Developer (.NET) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 12–18 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 12000000, 18000000, 6, 80),
    ('22d91e9f-4312-5443-baef-3b1ae91a90c9', 'f0cb2b01-af76-5b3c-9a21-1f7fd1338d04', N'Frontend Developer (React)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Sao Mai (Demo)
Vị trí: Frontend Developer (React)
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Frontend Developer (React) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 15000000, 22000000, 7, 80),
    ('cc572a89-b8e2-5f04-acc4-7a1d7e4283a4', 'f0cb2b01-af76-5b3c-9a21-1f7fd1338d04', N'DevOps Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Sao Mai (Demo)
Vị trí: DevOps Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí DevOps Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 18000000, 26000000, 8, 80),
    ('f5726ff3-f4b6-5417-ad4f-2401ffb5bd98', 'f0cb2b01-af76-5b3c-9a21-1f7fd1338d04', N'QA Automation Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Sao Mai (Demo)
Vị trí: QA Automation Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí QA Automation Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 21000000, 27000000, 9, 80),
    ('c02401a5-b49f-52c7-a808-e5e0e11fda02', 'f0cb2b01-af76-5b3c-9a21-1f7fd1338d04', N'Business Analyst', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Sao Mai (Demo)
Vị trí: Business Analyst
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Business Analyst trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 24000000, 31000000, 10, 80),
    ('9e8f66ac-7d1a-5a3d-a821-08fd52903645', '64b09208-021e-51b3-b0be-d1a4477a17ba', N'Chuyên viên phân tích tài chính', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Sao Mai (Demo)
Vị trí: Chuyên viên phân tích tài chính
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích tài chính trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 13–19 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 13000000, 19000000, 7, 81),
    ('d508e9bf-8e86-5fa5-ae99-127eb25e9fce', '64b09208-021e-51b3-b0be-d1a4477a17ba', N'Chuyên viên tín dụng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Sao Mai (Demo)
Vị trí: Chuyên viên tín dụng
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tín dụng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 16000000, 23000000, 8, 81),
    ('3b19d492-4a6b-5bb6-a3cd-6ed535ede167', '64b09208-021e-51b3-b0be-d1a4477a17ba', N'Chuyên viên quản trị rủi ro', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Sao Mai (Demo)
Vị trí: Chuyên viên quản trị rủi ro
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản trị rủi ro trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 19000000, 27000000, 9, 81),
    ('750734cb-668f-54ce-83cc-0b3224fc0492', '64b09208-021e-51b3-b0be-d1a4477a17ba', N'Chuyên viên tư vấn khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Sao Mai (Demo)
Vị trí: Chuyên viên tư vấn khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn khách hàng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 22000000, 28000000, 10, 81),
    ('6e2fbd10-2958-55be-8dc0-5fbee8eee5c0', '64b09208-021e-51b3-b0be-d1a4477a17ba', N'Kế toán tổng hợp', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Sao Mai (Demo)
Vị trí: Kế toán tổng hợp
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kế toán tổng hợp trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 25000000, 32000000, 11, 81),
    ('dd40812a-6096-527f-81e4-37f8fb91d6e6', 'c157fd7f-84a7-5197-b55d-0c42d7509975', N'Chuyên viên vận hành sàn thương mại điện tử', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Sao Mai (Demo)
Vị trí: Chuyên viên vận hành sàn thương mại điện tử
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành sàn thương mại điện tử trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–20 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 14000000, 20000000, 8, 82),
    ('f2503691-8e2f-5f15-a2d8-532f59055931', 'c157fd7f-84a7-5197-b55d-0c42d7509975', N'Digital Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Sao Mai (Demo)
Vị trí: Digital Marketing Specialist
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Digital Marketing Specialist trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 17000000, 24000000, 9, 82),
    ('4ca9db39-0950-5d76-9798-fbb870e72d08', 'c157fd7f-84a7-5197-b55d-0c42d7509975', N'Chuyên viên chăm sóc khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Sao Mai (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 20000000, 28000000, 10, 82),
    ('238304a3-4748-5c61-b3ee-375f864cbd5f', 'c157fd7f-84a7-5197-b55d-0c42d7509975', N'Chuyên viên phân tích dữ liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Sao Mai (Demo)
Vị trí: Chuyên viên phân tích dữ liệu
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích dữ liệu trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 23000000, 29000000, 11, 82),
    ('db6a9627-d26f-5a85-8623-1a34838185af', 'c157fd7f-84a7-5197-b55d-0c42d7509975', N'Quản lý ngành hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Sao Mai (Demo)
Vị trí: Quản lý ngành hàng
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý ngành hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 26000000, 33000000, 12, 82),
    ('ad4b7ef8-7d23-50d2-9af7-c11d71ec66f0', 'd6422993-3652-5a57-9945-d1ec8ed8ee16', N'Chuyên viên điều phối vận tải', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Sao Mai (Demo)
Vị trí: Chuyên viên điều phối vận tải
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều phối vận tải trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 15000000, 21000000, 9, 83),
    ('d54caf9a-4a98-545a-acee-73e5a65b44d2', 'd6422993-3652-5a57-9945-d1ec8ed8ee16', N'Chuyên viên xuất nhập khẩu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Sao Mai (Demo)
Vị trí: Chuyên viên xuất nhập khẩu
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên xuất nhập khẩu trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 18000000, 25000000, 10, 83),
    ('c4a79371-9a06-5503-a18e-79955b935350', 'd6422993-3652-5a57-9945-d1ec8ed8ee16', N'Nhân viên quản lý kho', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Sao Mai (Demo)
Vị trí: Nhân viên quản lý kho
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên quản lý kho trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 21000000, 29000000, 11, 83),
    ('d6aefe14-f9ab-5a5d-8f57-988d8333d3bf', 'd6422993-3652-5a57-9945-d1ec8ed8ee16', N'Chuyên viên mua hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Sao Mai (Demo)
Vị trí: Chuyên viên mua hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên mua hàng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 24000000, 30000000, 12, 83),
    ('c6baf6a8-8322-5e0c-a250-1bcb1e621ab7', 'd6422993-3652-5a57-9945-d1ec8ed8ee16', N'Chuyên viên hoạch định chuỗi cung ứng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Sao Mai (Demo)
Vị trí: Chuyên viên hoạch định chuỗi cung ứng
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên hoạch định chuỗi cung ứng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 27000000, 34000000, 13, 83),
    ('7b134221-a368-50ce-95a6-f11bd9b379dc', 'fc2f34ba-b663-5394-b064-f68cb1407bf4', N'Kỹ sư tự động hóa', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Sao Mai (Demo)
Vị trí: Kỹ sư tự động hóa
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư tự động hóa trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 16000000, 22000000, 10, 84),
    ('9c295761-1f3d-5290-95b7-06b581af5b6b', 'fc2f34ba-b663-5394-b064-f68cb1407bf4', N'Kỹ sư cơ khí', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Sao Mai (Demo)
Vị trí: Kỹ sư cơ khí
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư cơ khí trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 19000000, 26000000, 11, 84),
    ('bde5854c-35bb-5aa4-85e9-3ea796e2ffde', 'fc2f34ba-b663-5394-b064-f68cb1407bf4', N'Kỹ sư kiểm soát chất lượng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Sao Mai (Demo)
Vị trí: Kỹ sư kiểm soát chất lượng
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư kiểm soát chất lượng trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 22000000, 30000000, 12, 84),
    ('3f671de1-8f06-5568-b010-ac3a6c5694e2', 'fc2f34ba-b663-5394-b064-f68cb1407bf4', N'Kỹ sư bảo trì', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Sao Mai (Demo)
Vị trí: Kỹ sư bảo trì
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư bảo trì trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 25000000, 31000000, 13, 84),
    ('8943c578-5471-50fa-9d7d-56b7722d1627', 'fc2f34ba-b663-5394-b064-f68cb1407bf4', N'Chuyên viên kế hoạch sản xuất', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Sao Mai (Demo)
Vị trí: Chuyên viên kế hoạch sản xuất
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kế hoạch sản xuất trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 28000000, 35000000, 14, 84),
    ('34957b98-c7ea-549c-8b95-e1c90515693d', 'f04a6647-a309-5d0b-a030-9090dda4e6a4', N'Giáo viên tiếng Anh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Sao Mai (Demo)
Vị trí: Giáo viên tiếng Anh
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Giáo viên tiếng Anh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 17000000, 23000000, 11, 85),
    ('e19d5558-d991-539a-a1a1-300af32c10f0', 'f04a6647-a309-5d0b-a030-9090dda4e6a4', N'Chuyên viên phát triển học liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Sao Mai (Demo)
Vị trí: Chuyên viên phát triển học liệu
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phát triển học liệu trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 20000000, 27000000, 12, 85),
    ('194f6f25-399a-5e95-8551-f02fb106fd47', 'f04a6647-a309-5d0b-a030-9090dda4e6a4', N'Chuyên viên tư vấn tuyển sinh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Sao Mai (Demo)
Vị trí: Chuyên viên tư vấn tuyển sinh
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn tuyển sinh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 23000000, 31000000, 13, 85),
    ('e6005596-db0f-5eda-882d-1b959e11164d', 'f04a6647-a309-5d0b-a030-9090dda4e6a4', N'Điều phối viên đào tạo', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Sao Mai (Demo)
Vị trí: Điều phối viên đào tạo
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều phối viên đào tạo trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 26000000, 32000000, 14, 85),
    ('b462f967-a137-505a-a8db-6249368bb3b2', 'f04a6647-a309-5d0b-a030-9090dda4e6a4', N'Chuyên viên công nghệ giáo dục', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Sao Mai (Demo)
Vị trí: Chuyên viên công nghệ giáo dục
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên công nghệ giáo dục trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 29000000, 36000000, 15, 85),
    ('cf83c214-17fe-5e0e-8bf9-d8cad7676c74', '05ded8f4-940a-5f16-9b2f-aeda74dcbd99', N'Điều dưỡng viên', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Sao Mai (Demo)
Vị trí: Điều dưỡng viên
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều dưỡng viên trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 18000000, 24000000, 12, 86),
    ('42977c71-efdc-5a6e-9fac-2fc040be736d', '05ded8f4-940a-5f16-9b2f-aeda74dcbd99', N'Dược sĩ', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Sao Mai (Demo)
Vị trí: Dược sĩ
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Dược sĩ trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 21000000, 28000000, 13, 86),
    ('40f293cf-113b-5417-8d21-be24ebe958e1', '05ded8f4-940a-5f16-9b2f-aeda74dcbd99', N'Chuyên viên vận hành dịch vụ y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Sao Mai (Demo)
Vị trí: Chuyên viên vận hành dịch vụ y tế
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành dịch vụ y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 24000000, 32000000, 14, 86),
    ('f1710ea4-a9aa-5419-84d5-93ba0c8ba420', '05ded8f4-940a-5f16-9b2f-aeda74dcbd99', N'Kỹ thuật viên xét nghiệm', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Sao Mai (Demo)
Vị trí: Kỹ thuật viên xét nghiệm
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ thuật viên xét nghiệm trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 27000000, 33000000, 15, 86),
    ('06f722d2-909b-5a27-af50-e6d65b037cbc', '05ded8f4-940a-5f16-9b2f-aeda74dcbd99', N'Chuyên viên chăm sóc khách hàng y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Sao Mai (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng y tế
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 30–37 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 30000000, 37000000, 16, 86),
    ('2468c313-911d-5cb4-865d-450de05cc1a6', '2ddc58ae-655b-5ff5-90fa-56cda5cb0e9c', N'Chuyên viên điều hành tour', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Sao Mai (Demo)
Vị trí: Chuyên viên điều hành tour
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều hành tour trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 19000000, 25000000, 13, 87),
    ('3f6004f0-a0a5-5b18-b8f6-7c5945145117', '2ddc58ae-655b-5ff5-90fa-56cda5cb0e9c', N'Nhân viên lễ tân', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Sao Mai (Demo)
Vị trí: Nhân viên lễ tân
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên lễ tân trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 22000000, 29000000, 14, 87),
    ('64694dc9-34fe-508f-8cb8-7d3ff2cecbb2', '2ddc58ae-655b-5ff5-90fa-56cda5cb0e9c', N'Chuyên viên kinh doanh du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Sao Mai (Demo)
Vị trí: Chuyên viên kinh doanh du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kinh doanh du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 25000000, 33000000, 15, 87),
    ('0f36dd80-3681-5828-a14f-f586c6acaac1', '2ddc58ae-655b-5ff5-90fa-56cda5cb0e9c', N'Quản lý dịch vụ khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Sao Mai (Demo)
Vị trí: Quản lý dịch vụ khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý dịch vụ khách hàng trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 28000000, 34000000, 16, 87),
    ('a164b855-bbba-56ba-a865-c717478eabf2', '2ddc58ae-655b-5ff5-90fa-56cda5cb0e9c', N'Chuyên viên marketing du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Sao Mai (Demo)
Vị trí: Chuyên viên marketing du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên marketing du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 31–38 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 31000000, 38000000, 17, 87),
    ('504fe497-7f03-5f3d-928b-ab79661246cf', 'd6faaaa7-72af-5a76-8a5f-4bbaa010a53f', N'Kỹ sư xây dựng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Sao Mai (Demo)
Vị trí: Kỹ sư xây dựng
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư xây dựng trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 20000000, 26000000, 0, 88),
    ('fdb24b73-7901-5894-9678-eaba793034f7', 'd6faaaa7-72af-5a76-8a5f-4bbaa010a53f', N'Kiến trúc sư', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Sao Mai (Demo)
Vị trí: Kiến trúc sư
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kiến trúc sư trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 23000000, 30000000, 1, 88),
    ('1a81b554-37c8-5b90-ad5e-f8b2b4b15f86', 'd6faaaa7-72af-5a76-8a5f-4bbaa010a53f', N'Chuyên viên quản lý dự án', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Sao Mai (Demo)
Vị trí: Chuyên viên quản lý dự án
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản lý dự án trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 26000000, 34000000, 2, 88),
    ('780e2699-d556-56c0-a2b8-4453cc74c7ec', 'd6faaaa7-72af-5a76-8a5f-4bbaa010a53f', N'Kỹ sư dự toán', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Sao Mai (Demo)
Vị trí: Kỹ sư dự toán
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư dự toán trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 29000000, 35000000, 3, 88),
    ('a25e0eda-4963-543e-ade3-2a34a1b54543', 'd6faaaa7-72af-5a76-8a5f-4bbaa010a53f', N'Chuyên viên tư vấn bất động sản', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Sao Mai (Demo)
Vị trí: Chuyên viên tư vấn bất động sản
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn bất động sản trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 32–39 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 32000000, 39000000, 4, 88),
    ('6cab9195-5a3f-5bb3-bed9-2e7459ca99d6', 'f2855ed2-3b8b-52ee-a809-7848c82dc510', N'Graphic Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Sao Mai (Demo)
Vị trí: Graphic Designer
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ngãi
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Graphic Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ngãi', 21000000, 27000000, 1, 89),
    ('07741ceb-8a7f-53cf-88a6-071852895a6c', 'f2855ed2-3b8b-52ee-a809-7848c82dc510', N'Content Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Sao Mai (Demo)
Vị trí: Content Marketing Specialist
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ngãi
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Content Marketing Specialist trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ngãi', 24000000, 31000000, 2, 89),
    ('8b8d673e-900e-57e3-854d-b4eaa585336f', 'f2855ed2-3b8b-52ee-a809-7848c82dc510', N'UI/UX Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Sao Mai (Demo)
Vị trí: UI/UX Designer
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ngãi
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí UI/UX Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ngãi', 27000000, 35000000, 3, 89),
    ('ab12e06a-b091-5af5-9627-56d433e1f0b3', 'f2855ed2-3b8b-52ee-a809-7848c82dc510', N'Chuyên viên truyền thông', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Sao Mai (Demo)
Vị trí: Chuyên viên truyền thông
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ngãi
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên truyền thông trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 30–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ngãi', 30000000, 36000000, 4, 89),
    ('e2c510ba-8742-58a5-836c-38c8a3d9170c', 'f2855ed2-3b8b-52ee-a809-7848c82dc510', N'Video Editor', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Sao Mai (Demo)
Vị trí: Video Editor
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ngãi
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Video Editor trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 33–40 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ngãi', 33000000, 40000000, 5, 89),
    ('373112e8-28fa-57ec-b6ff-9ab4d83370d4', '48bf565a-61ee-5efe-a5c8-c0f477305e82', N'Backend Developer (.NET)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Thanh Hà (Demo)
Vị trí: Backend Developer (.NET)
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Backend Developer (.NET) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 13–19 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 13000000, 19000000, 2, 60),
    ('79675b3a-6374-5ccd-94e1-82a51bf9a131', '48bf565a-61ee-5efe-a5c8-c0f477305e82', N'Frontend Developer (React)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Thanh Hà (Demo)
Vị trí: Frontend Developer (React)
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Frontend Developer (React) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 16000000, 23000000, 3, 60),
    ('283e04b9-5c70-5dfd-848e-f2e2d3f0409e', '48bf565a-61ee-5efe-a5c8-c0f477305e82', N'DevOps Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Thanh Hà (Demo)
Vị trí: DevOps Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí DevOps Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 19000000, 27000000, 4, 60),
    ('9b5b15c9-9908-5b6c-a0fe-388d774fa547', '48bf565a-61ee-5efe-a5c8-c0f477305e82', N'QA Automation Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Thanh Hà (Demo)
Vị trí: QA Automation Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí QA Automation Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 22000000, 28000000, 5, 60),
    ('63bcf310-3afc-5d75-951b-ba7a9894439c', '48bf565a-61ee-5efe-a5c8-c0f477305e82', N'Business Analyst', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Thanh Hà (Demo)
Vị trí: Business Analyst
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Business Analyst trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 25000000, 32000000, 6, 60),
    ('16cbf96a-e375-58b3-958e-cc02ebafe438', '92cf5fe8-b865-562c-9aa5-137051ae64a6', N'Chuyên viên phân tích tài chính', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Thanh Hà (Demo)
Vị trí: Chuyên viên phân tích tài chính
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích tài chính trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–20 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 14000000, 20000000, 3, 61),
    ('b2c3b81c-23b4-5122-84a2-7de04d787134', '92cf5fe8-b865-562c-9aa5-137051ae64a6', N'Chuyên viên tín dụng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Thanh Hà (Demo)
Vị trí: Chuyên viên tín dụng
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tín dụng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 17000000, 24000000, 4, 61),
    ('dc464281-5f81-504e-8f71-d327432d8f46', '92cf5fe8-b865-562c-9aa5-137051ae64a6', N'Chuyên viên quản trị rủi ro', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Thanh Hà (Demo)
Vị trí: Chuyên viên quản trị rủi ro
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản trị rủi ro trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 20000000, 28000000, 5, 61),
    ('2bc21870-3e48-5982-bd99-95310eced122', '92cf5fe8-b865-562c-9aa5-137051ae64a6', N'Chuyên viên tư vấn khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Thanh Hà (Demo)
Vị trí: Chuyên viên tư vấn khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn khách hàng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 23000000, 29000000, 6, 61),
    ('b042e922-70f4-503a-9375-89f0768b0dd2', '92cf5fe8-b865-562c-9aa5-137051ae64a6', N'Kế toán tổng hợp', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Thanh Hà (Demo)
Vị trí: Kế toán tổng hợp
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kế toán tổng hợp trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 26000000, 33000000, 7, 61),
    ('e0df29ac-40c8-5eed-bf8e-d89bc3c1064b', '97a4c0a1-2d68-5e15-b704-a846d7ae7379', N'Chuyên viên vận hành sàn thương mại điện tử', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Thanh Hà (Demo)
Vị trí: Chuyên viên vận hành sàn thương mại điện tử
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành sàn thương mại điện tử trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 15000000, 21000000, 4, 62),
    ('640af802-2c4a-5abc-a2ef-723221984e26', '97a4c0a1-2d68-5e15-b704-a846d7ae7379', N'Digital Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Thanh Hà (Demo)
Vị trí: Digital Marketing Specialist
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Digital Marketing Specialist trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 18000000, 25000000, 5, 62),
    ('3051ec97-addf-59b1-8664-c12b75e5ae17', '97a4c0a1-2d68-5e15-b704-a846d7ae7379', N'Chuyên viên chăm sóc khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Thanh Hà (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 21000000, 29000000, 6, 62),
    ('50f4ad29-89df-5fee-86ce-744ffd99e56d', '97a4c0a1-2d68-5e15-b704-a846d7ae7379', N'Chuyên viên phân tích dữ liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Thanh Hà (Demo)
Vị trí: Chuyên viên phân tích dữ liệu
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích dữ liệu trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 24000000, 30000000, 7, 62),
    ('66bcc4af-bcd6-55f7-8562-5b4960496e66', '97a4c0a1-2d68-5e15-b704-a846d7ae7379', N'Quản lý ngành hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Thanh Hà (Demo)
Vị trí: Quản lý ngành hàng
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý ngành hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 27000000, 34000000, 8, 62),
    ('900d97b1-c74b-5c5e-81cf-03a380aa152f', '7f64c4f6-dea1-572f-87e1-b2baf0652e1d', N'Chuyên viên điều phối vận tải', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Thanh Hà (Demo)
Vị trí: Chuyên viên điều phối vận tải
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều phối vận tải trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 16000000, 22000000, 5, 63),
    ('fbeadf79-1b87-5db1-8710-9d4466c8d5a6', '7f64c4f6-dea1-572f-87e1-b2baf0652e1d', N'Chuyên viên xuất nhập khẩu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Thanh Hà (Demo)
Vị trí: Chuyên viên xuất nhập khẩu
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên xuất nhập khẩu trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 19000000, 26000000, 6, 63),
    ('43ec86d4-9f03-51ba-8a98-616db022e0ae', '7f64c4f6-dea1-572f-87e1-b2baf0652e1d', N'Nhân viên quản lý kho', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Thanh Hà (Demo)
Vị trí: Nhân viên quản lý kho
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên quản lý kho trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 22000000, 30000000, 7, 63),
    ('847cab1d-2fe7-579b-92cc-277b65f7fd17', '7f64c4f6-dea1-572f-87e1-b2baf0652e1d', N'Chuyên viên mua hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Thanh Hà (Demo)
Vị trí: Chuyên viên mua hàng
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên mua hàng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 25000000, 31000000, 8, 63),
    ('f608014a-1960-50b5-9da4-2912f4f70f61', '7f64c4f6-dea1-572f-87e1-b2baf0652e1d', N'Chuyên viên hoạch định chuỗi cung ứng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Thanh Hà (Demo)
Vị trí: Chuyên viên hoạch định chuỗi cung ứng
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên hoạch định chuỗi cung ứng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 28000000, 35000000, 9, 63),
    ('3ec23e00-cc2f-5214-87e0-348274ea1e92', 'a1ec7855-c9f9-5052-975d-6db8a3eb613a', N'Kỹ sư tự động hóa', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Thanh Hà (Demo)
Vị trí: Kỹ sư tự động hóa
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư tự động hóa trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 17000000, 23000000, 6, 64),
    ('d56dfcb9-e552-5755-9506-0f656efb8561', 'a1ec7855-c9f9-5052-975d-6db8a3eb613a', N'Kỹ sư cơ khí', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Thanh Hà (Demo)
Vị trí: Kỹ sư cơ khí
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư cơ khí trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 20000000, 27000000, 7, 64),
    ('eb7021e0-ddea-5313-926c-73679950bae2', 'a1ec7855-c9f9-5052-975d-6db8a3eb613a', N'Kỹ sư kiểm soát chất lượng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Thanh Hà (Demo)
Vị trí: Kỹ sư kiểm soát chất lượng
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư kiểm soát chất lượng trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 23000000, 31000000, 8, 64),
    ('6fd98d52-bbbb-55a9-a4e7-7ff57afa1dac', 'a1ec7855-c9f9-5052-975d-6db8a3eb613a', N'Kỹ sư bảo trì', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Thanh Hà (Demo)
Vị trí: Kỹ sư bảo trì
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư bảo trì trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 26000000, 32000000, 9, 64),
    ('d23829c7-a403-51fd-85d7-610b1593e0e3', 'a1ec7855-c9f9-5052-975d-6db8a3eb613a', N'Chuyên viên kế hoạch sản xuất', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Thanh Hà (Demo)
Vị trí: Chuyên viên kế hoạch sản xuất
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kế hoạch sản xuất trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 29000000, 36000000, 10, 64),
    ('97dd6c7d-d092-5300-b7f4-a077db51d762', '6c2147a1-cebd-54e0-91d4-4c4c9695d532', N'Giáo viên tiếng Anh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Thanh Hà (Demo)
Vị trí: Giáo viên tiếng Anh
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Giáo viên tiếng Anh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 18000000, 24000000, 7, 65),
    ('01522691-c2fc-5dcc-adf5-60618ff29f44', '6c2147a1-cebd-54e0-91d4-4c4c9695d532', N'Chuyên viên phát triển học liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Thanh Hà (Demo)
Vị trí: Chuyên viên phát triển học liệu
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phát triển học liệu trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 21000000, 28000000, 8, 65),
    ('15af7bd8-2087-5c28-8bc8-e68d4c0d38f3', '6c2147a1-cebd-54e0-91d4-4c4c9695d532', N'Chuyên viên tư vấn tuyển sinh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Thanh Hà (Demo)
Vị trí: Chuyên viên tư vấn tuyển sinh
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn tuyển sinh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 24000000, 32000000, 9, 65),
    ('96973d25-5b2c-5027-b197-dcdfbca59181', '6c2147a1-cebd-54e0-91d4-4c4c9695d532', N'Điều phối viên đào tạo', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Thanh Hà (Demo)
Vị trí: Điều phối viên đào tạo
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều phối viên đào tạo trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 27000000, 33000000, 10, 65),
    ('f965778d-a4af-5ed3-8d1d-b807ec44bcd6', '6c2147a1-cebd-54e0-91d4-4c4c9695d532', N'Chuyên viên công nghệ giáo dục', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Thanh Hà (Demo)
Vị trí: Chuyên viên công nghệ giáo dục
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên công nghệ giáo dục trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 30–37 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 30000000, 37000000, 11, 65),
    ('ebb7446a-e6a9-5b47-9dac-0e36a25edec2', 'c26c54ce-7f9b-5ecd-aae4-9b2555cb78bc', N'Điều dưỡng viên', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Thanh Hà (Demo)
Vị trí: Điều dưỡng viên
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều dưỡng viên trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 19000000, 25000000, 8, 66),
    ('76d074e5-dd2a-5980-880a-22a117f77e55', 'c26c54ce-7f9b-5ecd-aae4-9b2555cb78bc', N'Dược sĩ', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Thanh Hà (Demo)
Vị trí: Dược sĩ
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Dược sĩ trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 22000000, 29000000, 9, 66),
    ('b1396b5a-769a-519e-8fc9-710d65bae0b9', 'c26c54ce-7f9b-5ecd-aae4-9b2555cb78bc', N'Chuyên viên vận hành dịch vụ y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Thanh Hà (Demo)
Vị trí: Chuyên viên vận hành dịch vụ y tế
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành dịch vụ y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 25000000, 33000000, 10, 66),
    ('7c74d8c5-3882-5467-862a-e62345948d8b', 'c26c54ce-7f9b-5ecd-aae4-9b2555cb78bc', N'Kỹ thuật viên xét nghiệm', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Thanh Hà (Demo)
Vị trí: Kỹ thuật viên xét nghiệm
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ thuật viên xét nghiệm trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 28000000, 34000000, 11, 66),
    ('d6299f80-b27b-5e6d-a53d-192884dc4712', 'c26c54ce-7f9b-5ecd-aae4-9b2555cb78bc', N'Chuyên viên chăm sóc khách hàng y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Thanh Hà (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng y tế
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 31–38 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 31000000, 38000000, 12, 66),
    ('71b1f4d3-a6e0-50c8-b2ba-aae5c16d1cd6', '8843a009-4ac8-5cb7-afcd-880abeae7eac', N'Chuyên viên điều hành tour', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Thanh Hà (Demo)
Vị trí: Chuyên viên điều hành tour
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều hành tour trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 20000000, 26000000, 9, 67),
    ('952df659-22f0-56ce-9d72-15c1a0492391', '8843a009-4ac8-5cb7-afcd-880abeae7eac', N'Nhân viên lễ tân', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Thanh Hà (Demo)
Vị trí: Nhân viên lễ tân
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên lễ tân trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 23000000, 30000000, 10, 67),
    ('cec33d74-8ecc-55ee-8650-6e6685bb5729', '8843a009-4ac8-5cb7-afcd-880abeae7eac', N'Chuyên viên kinh doanh du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Thanh Hà (Demo)
Vị trí: Chuyên viên kinh doanh du lịch
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kinh doanh du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 26000000, 34000000, 11, 67),
    ('62c62a12-8761-59dc-bf73-cfd182c9fe32', '8843a009-4ac8-5cb7-afcd-880abeae7eac', N'Quản lý dịch vụ khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Thanh Hà (Demo)
Vị trí: Quản lý dịch vụ khách hàng
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý dịch vụ khách hàng trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 29000000, 35000000, 12, 67),
    ('6ee0eeed-bd71-5e03-8a8b-af0646e2205b', '8843a009-4ac8-5cb7-afcd-880abeae7eac', N'Chuyên viên marketing du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Thanh Hà (Demo)
Vị trí: Chuyên viên marketing du lịch
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên marketing du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 32–39 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 32000000, 39000000, 13, 67),
    ('1b600aa0-b87f-5207-aa90-0822d871976e', 'f9eeea98-be44-5455-bedd-f494149db24f', N'Kỹ sư xây dựng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Thanh Hà (Demo)
Vị trí: Kỹ sư xây dựng
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư xây dựng trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 21000000, 27000000, 10, 68),
    ('a9fcd7cf-869d-5f96-9fd1-1e066b45bc3a', 'f9eeea98-be44-5455-bedd-f494149db24f', N'Kiến trúc sư', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Thanh Hà (Demo)
Vị trí: Kiến trúc sư
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kiến trúc sư trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 24000000, 31000000, 11, 68),
    ('5781098f-168a-5cbb-8c18-e32423aeea1a', 'f9eeea98-be44-5455-bedd-f494149db24f', N'Chuyên viên quản lý dự án', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Thanh Hà (Demo)
Vị trí: Chuyên viên quản lý dự án
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản lý dự án trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 27000000, 35000000, 12, 68),
    ('601e7199-22ef-55ec-b46b-02303d5f5502', 'f9eeea98-be44-5455-bedd-f494149db24f', N'Kỹ sư dự toán', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Thanh Hà (Demo)
Vị trí: Kỹ sư dự toán
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư dự toán trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 30–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 30000000, 36000000, 13, 68),
    ('5ec4498c-117f-53a8-a2a2-0f720e0c163b', 'f9eeea98-be44-5455-bedd-f494149db24f', N'Chuyên viên tư vấn bất động sản', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Thanh Hà (Demo)
Vị trí: Chuyên viên tư vấn bất động sản
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn bất động sản trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 33–40 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 33000000, 40000000, 14, 68),
    ('82e531d5-8a9d-59bf-890d-e74f74bf2b24', 'a1fb5b7b-8c05-5cfd-a137-59116fbe6f47', N'Graphic Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Thanh Hà (Demo)
Vị trí: Graphic Designer
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Graphic Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 22000000, 28000000, 11, 69),
    ('f5340415-7b0f-503d-be0b-d3f8df1cb200', 'a1fb5b7b-8c05-5cfd-a137-59116fbe6f47', N'Content Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Thanh Hà (Demo)
Vị trí: Content Marketing Specialist
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Content Marketing Specialist trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 25000000, 32000000, 12, 69),
    ('c167e705-cde7-546f-a287-6d6a726a7ad3', 'a1fb5b7b-8c05-5cfd-a137-59116fbe6f47', N'UI/UX Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Thanh Hà (Demo)
Vị trí: UI/UX Designer
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí UI/UX Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 28000000, 36000000, 13, 69),
    ('0fb1fc4b-e22f-53d4-b210-16a093ff444a', 'a1fb5b7b-8c05-5cfd-a137-59116fbe6f47', N'Chuyên viên truyền thông', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Thanh Hà (Demo)
Vị trí: Chuyên viên truyền thông
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên truyền thông trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 31–37 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 31000000, 37000000, 14, 69),
    ('0b5d4caa-8862-5204-a857-0c9d1b805a58', 'a1fb5b7b-8c05-5cfd-a137-59116fbe6f47', N'Video Editor', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Thanh Hà (Demo)
Vị trí: Video Editor
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Trị
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Video Editor trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 34–41 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Trị', 34000000, 41000000, 15, 69),
    ('8ffc2055-376c-53ba-813a-177e6e4db802', '41f52010-8697-5d78-b94e-55f2b7e46e83', N'Backend Developer (.NET)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ An Phú (Demo)
Vị trí: Backend Developer (.NET)
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Backend Developer (.NET) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 10–16 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 10000000, 16000000, 12, 70),
    ('90541727-6dc1-5774-b46c-d93f4fc3f7d2', '41f52010-8697-5d78-b94e-55f2b7e46e83', N'Frontend Developer (React)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ An Phú (Demo)
Vị trí: Frontend Developer (React)
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Frontend Developer (React) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 13–20 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 13000000, 20000000, 13, 70),
    ('1ddaf9ea-f4f0-5ade-bb07-981013141592', '41f52010-8697-5d78-b94e-55f2b7e46e83', N'DevOps Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ An Phú (Demo)
Vị trí: DevOps Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí DevOps Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 16000000, 24000000, 14, 70),
    ('54aacdef-3108-5fdf-a4e8-a131377fc054', '41f52010-8697-5d78-b94e-55f2b7e46e83', N'QA Automation Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ An Phú (Demo)
Vị trí: QA Automation Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí QA Automation Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 19000000, 25000000, 15, 70),
    ('c73f3307-2639-51a4-b220-03f91fce96aa', '41f52010-8697-5d78-b94e-55f2b7e46e83', N'Business Analyst', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ An Phú (Demo)
Vị trí: Business Analyst
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Business Analyst trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 22000000, 29000000, 16, 70),
    ('9ce6a2dd-f90f-5c22-8f20-2817f94079da', '062abf3f-fcf3-5745-89eb-dd4f64cfa7a4', N'Chuyên viên phân tích tài chính', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính An Phú (Demo)
Vị trí: Chuyên viên phân tích tài chính
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích tài chính trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 11–17 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 11000000, 17000000, 13, 71),
    ('834b3798-4c18-54fc-b51d-e52c6400867b', '062abf3f-fcf3-5745-89eb-dd4f64cfa7a4', N'Chuyên viên tín dụng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính An Phú (Demo)
Vị trí: Chuyên viên tín dụng
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tín dụng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 14000000, 21000000, 14, 71),
    ('f8a3439d-006e-5126-8dcd-6c2c768d0014', '062abf3f-fcf3-5745-89eb-dd4f64cfa7a4', N'Chuyên viên quản trị rủi ro', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính An Phú (Demo)
Vị trí: Chuyên viên quản trị rủi ro
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản trị rủi ro trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 17000000, 25000000, 15, 71),
    ('00212c94-2cba-594b-b285-57b5beb78d92', '062abf3f-fcf3-5745-89eb-dd4f64cfa7a4', N'Chuyên viên tư vấn khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính An Phú (Demo)
Vị trí: Chuyên viên tư vấn khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn khách hàng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 20000000, 26000000, 16, 71),
    ('6c75f6b3-8154-5116-8cc4-f060f43d24bc', '062abf3f-fcf3-5745-89eb-dd4f64cfa7a4', N'Kế toán tổng hợp', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính An Phú (Demo)
Vị trí: Kế toán tổng hợp
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kế toán tổng hợp trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 23000000, 30000000, 17, 71),
    ('ed1537d4-b6b3-5f9e-98ec-45ff62f46c33', 'aeae827e-47c4-57a1-a510-53d1c791682f', N'Chuyên viên vận hành sàn thương mại điện tử', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại An Phú (Demo)
Vị trí: Chuyên viên vận hành sàn thương mại điện tử
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành sàn thương mại điện tử trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 12–18 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 12000000, 18000000, 0, 72),
    ('d83b3835-1df4-52cd-ab27-80065f7e3501', 'aeae827e-47c4-57a1-a510-53d1c791682f', N'Digital Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại An Phú (Demo)
Vị trí: Digital Marketing Specialist
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Digital Marketing Specialist trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 15000000, 22000000, 1, 72),
    ('c26e120f-8c9a-5378-a85d-97f5a5d749f6', 'aeae827e-47c4-57a1-a510-53d1c791682f', N'Chuyên viên chăm sóc khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại An Phú (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 18000000, 26000000, 2, 72),
    ('a59717ba-b234-553f-8d0d-170d90d0ac11', 'aeae827e-47c4-57a1-a510-53d1c791682f', N'Chuyên viên phân tích dữ liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại An Phú (Demo)
Vị trí: Chuyên viên phân tích dữ liệu
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích dữ liệu trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 21000000, 27000000, 3, 72),
    ('10d6c23d-3a1f-5f56-8d23-65dfffc39857', 'aeae827e-47c4-57a1-a510-53d1c791682f', N'Quản lý ngành hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại An Phú (Demo)
Vị trí: Quản lý ngành hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý ngành hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 24000000, 31000000, 4, 72),
    ('93766d8c-35b6-59bd-9623-cc301aa917ef', '7d1eaff4-9d15-5ef0-8126-33282093b5c3', N'Chuyên viên điều phối vận tải', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics An Phú (Demo)
Vị trí: Chuyên viên điều phối vận tải
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều phối vận tải trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 13–19 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 13000000, 19000000, 1, 73),
    ('fbcc5fd9-5273-51cb-9d7c-912d5088e821', '7d1eaff4-9d15-5ef0-8126-33282093b5c3', N'Chuyên viên xuất nhập khẩu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics An Phú (Demo)
Vị trí: Chuyên viên xuất nhập khẩu
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên xuất nhập khẩu trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 16000000, 23000000, 2, 73),
    ('06965223-9fc2-5129-b3f5-38781bbbf715', '7d1eaff4-9d15-5ef0-8126-33282093b5c3', N'Nhân viên quản lý kho', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics An Phú (Demo)
Vị trí: Nhân viên quản lý kho
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên quản lý kho trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 19000000, 27000000, 3, 73),
    ('9cbd6bc5-845c-5561-8339-e8048ba89183', '7d1eaff4-9d15-5ef0-8126-33282093b5c3', N'Chuyên viên mua hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics An Phú (Demo)
Vị trí: Chuyên viên mua hàng
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên mua hàng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 22000000, 28000000, 4, 73),
    ('f68dd7fb-ec58-58db-a082-063e5fe29f6e', '7d1eaff4-9d15-5ef0-8126-33282093b5c3', N'Chuyên viên hoạch định chuỗi cung ứng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics An Phú (Demo)
Vị trí: Chuyên viên hoạch định chuỗi cung ứng
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên hoạch định chuỗi cung ứng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 25000000, 32000000, 5, 73),
    ('e71d438a-c818-56a0-8ff2-8503095982ac', '635c7a43-6213-5519-82ce-00591852cf8b', N'Kỹ sư tự động hóa', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất An Phú (Demo)
Vị trí: Kỹ sư tự động hóa
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư tự động hóa trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–20 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 14000000, 20000000, 2, 74),
    ('25db5883-d4ff-5057-aeff-9dc250c69549', '635c7a43-6213-5519-82ce-00591852cf8b', N'Kỹ sư cơ khí', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất An Phú (Demo)
Vị trí: Kỹ sư cơ khí
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư cơ khí trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 17000000, 24000000, 3, 74),
    ('a5b1f85d-bc3f-50df-9834-c9e2ca83ad20', '635c7a43-6213-5519-82ce-00591852cf8b', N'Kỹ sư kiểm soát chất lượng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất An Phú (Demo)
Vị trí: Kỹ sư kiểm soát chất lượng
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư kiểm soát chất lượng trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 20000000, 28000000, 4, 74),
    ('f84b2b6a-7a50-5c3e-870b-0a2f3bb2afff', '635c7a43-6213-5519-82ce-00591852cf8b', N'Kỹ sư bảo trì', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất An Phú (Demo)
Vị trí: Kỹ sư bảo trì
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư bảo trì trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 23000000, 29000000, 5, 74),
    ('f6389be1-edc8-58e0-b092-2fff599f03b2', '635c7a43-6213-5519-82ce-00591852cf8b', N'Chuyên viên kế hoạch sản xuất', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất An Phú (Demo)
Vị trí: Chuyên viên kế hoạch sản xuất
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kế hoạch sản xuất trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 26000000, 33000000, 6, 74),
    ('49ebbf64-94d8-50a6-bcf1-5ab25f9a2417', '203c8dae-265e-533c-a51d-66ec00f1ad3d', N'Giáo viên tiếng Anh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục An Phú (Demo)
Vị trí: Giáo viên tiếng Anh
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Giáo viên tiếng Anh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 15000000, 21000000, 3, 75),
    ('b6a64e68-ae1e-5da4-9c9b-ab3ec172ce7e', '203c8dae-265e-533c-a51d-66ec00f1ad3d', N'Chuyên viên phát triển học liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục An Phú (Demo)
Vị trí: Chuyên viên phát triển học liệu
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phát triển học liệu trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 18000000, 25000000, 4, 75),
    ('66656c4d-1bfc-59e0-8b7e-4f819811f7ba', '203c8dae-265e-533c-a51d-66ec00f1ad3d', N'Chuyên viên tư vấn tuyển sinh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục An Phú (Demo)
Vị trí: Chuyên viên tư vấn tuyển sinh
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn tuyển sinh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 21000000, 29000000, 5, 75),
    ('4abfbf7a-95c0-5af0-8ca1-56b469d76e16', '203c8dae-265e-533c-a51d-66ec00f1ad3d', N'Điều phối viên đào tạo', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục An Phú (Demo)
Vị trí: Điều phối viên đào tạo
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều phối viên đào tạo trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 24000000, 30000000, 6, 75),
    ('4562d024-f7ed-5152-b2bf-3e304dd80221', '203c8dae-265e-533c-a51d-66ec00f1ad3d', N'Chuyên viên công nghệ giáo dục', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục An Phú (Demo)
Vị trí: Chuyên viên công nghệ giáo dục
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên công nghệ giáo dục trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 27000000, 34000000, 7, 75),
    ('fec9b790-127d-5b43-912e-2df2a3096a63', '84155ef7-7f5a-5119-bd92-0b82718eb783', N'Điều dưỡng viên', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe An Phú (Demo)
Vị trí: Điều dưỡng viên
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều dưỡng viên trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 16000000, 22000000, 4, 76),
    ('4f4f3101-8fff-5b46-bfcc-9322e2d56b21', '84155ef7-7f5a-5119-bd92-0b82718eb783', N'Dược sĩ', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe An Phú (Demo)
Vị trí: Dược sĩ
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Dược sĩ trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 19000000, 26000000, 5, 76),
    ('b6ad1b01-cf3f-5ff2-8126-999eb3774cbe', '84155ef7-7f5a-5119-bd92-0b82718eb783', N'Chuyên viên vận hành dịch vụ y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe An Phú (Demo)
Vị trí: Chuyên viên vận hành dịch vụ y tế
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành dịch vụ y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 22000000, 30000000, 6, 76),
    ('06de9403-a025-5594-a1c8-e5d066c8ba57', '84155ef7-7f5a-5119-bd92-0b82718eb783', N'Kỹ thuật viên xét nghiệm', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe An Phú (Demo)
Vị trí: Kỹ thuật viên xét nghiệm
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ thuật viên xét nghiệm trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 25000000, 31000000, 7, 76),
    ('e08c283e-b113-5532-b011-691cae324bbf', '84155ef7-7f5a-5119-bd92-0b82718eb783', N'Chuyên viên chăm sóc khách hàng y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe An Phú (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng y tế
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 28000000, 35000000, 8, 76),
    ('cfcacce9-a651-5414-972f-c4f9bece0daa', 'bde8b5ea-5821-57ce-aaf8-de0e47994ac7', N'Chuyên viên điều hành tour', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch An Phú (Demo)
Vị trí: Chuyên viên điều hành tour
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều hành tour trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 17000000, 23000000, 5, 77),
    ('fb971021-9ca0-5c9b-839a-9ebecffe4b29', 'bde8b5ea-5821-57ce-aaf8-de0e47994ac7', N'Nhân viên lễ tân', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch An Phú (Demo)
Vị trí: Nhân viên lễ tân
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên lễ tân trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 20000000, 27000000, 6, 77),
    ('a82ea0a3-c255-5659-b1cd-fcaf904fca8d', 'bde8b5ea-5821-57ce-aaf8-de0e47994ac7', N'Chuyên viên kinh doanh du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch An Phú (Demo)
Vị trí: Chuyên viên kinh doanh du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kinh doanh du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 23000000, 31000000, 7, 77),
    ('6c8e6ffa-796f-5bcc-9f89-481c8fb8b173', 'bde8b5ea-5821-57ce-aaf8-de0e47994ac7', N'Quản lý dịch vụ khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch An Phú (Demo)
Vị trí: Quản lý dịch vụ khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý dịch vụ khách hàng trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 26000000, 32000000, 8, 77),
    ('116d9f35-fbf1-5c49-af06-a5ba7f3e47ea', 'bde8b5ea-5821-57ce-aaf8-de0e47994ac7', N'Chuyên viên marketing du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch An Phú (Demo)
Vị trí: Chuyên viên marketing du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên marketing du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 29000000, 36000000, 9, 77),
    ('ec7e2445-8cb2-53f2-a048-e1a1b456a796', '7cab1b98-2436-5ada-b0af-5d44f8ffb959', N'Kỹ sư xây dựng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng An Phú (Demo)
Vị trí: Kỹ sư xây dựng
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư xây dựng trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 18000000, 24000000, 6, 78),
    ('d7afa81b-8191-5c4d-a2d2-58f2a265a081', '7cab1b98-2436-5ada-b0af-5d44f8ffb959', N'Kiến trúc sư', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng An Phú (Demo)
Vị trí: Kiến trúc sư
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kiến trúc sư trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 21000000, 28000000, 7, 78),
    ('d78b0dc7-8595-5725-b806-2d7d04c4bfea', '7cab1b98-2436-5ada-b0af-5d44f8ffb959', N'Chuyên viên quản lý dự án', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng An Phú (Demo)
Vị trí: Chuyên viên quản lý dự án
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản lý dự án trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 24000000, 32000000, 8, 78),
    ('9b4759de-31aa-5832-b18c-3cbe6a4426cb', '7cab1b98-2436-5ada-b0af-5d44f8ffb959', N'Kỹ sư dự toán', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng An Phú (Demo)
Vị trí: Kỹ sư dự toán
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư dự toán trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 27000000, 33000000, 9, 78),
    ('16393794-b177-5e2e-9a57-297406e7c8f1', '7cab1b98-2436-5ada-b0af-5d44f8ffb959', N'Chuyên viên tư vấn bất động sản', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng An Phú (Demo)
Vị trí: Chuyên viên tư vấn bất động sản
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn bất động sản trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 30–37 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 30000000, 37000000, 10, 78),
    ('9fd2064a-8a0e-595f-930e-db9ba3dfbe49', '48a0b715-d220-5f61-8bc2-8595f64e95b9', N'Graphic Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo An Phú (Demo)
Vị trí: Graphic Designer
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Graphic Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 19000000, 25000000, 7, 79),
    ('092a1d82-05e9-5bd2-a521-91c896b57389', '48a0b715-d220-5f61-8bc2-8595f64e95b9', N'Content Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo An Phú (Demo)
Vị trí: Content Marketing Specialist
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Content Marketing Specialist trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 22000000, 29000000, 8, 79),
    ('6d60123c-1789-53db-a42f-2c6fccb558df', '48a0b715-d220-5f61-8bc2-8595f64e95b9', N'UI/UX Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo An Phú (Demo)
Vị trí: UI/UX Designer
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí UI/UX Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 25000000, 33000000, 9, 79),
    ('a3f5d0c6-c050-598a-91ed-87cfa8fe37d2', '48a0b715-d220-5f61-8bc2-8595f64e95b9', N'Chuyên viên truyền thông', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo An Phú (Demo)
Vị trí: Chuyên viên truyền thông
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên truyền thông trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 28000000, 34000000, 10, 79),
    ('3c99ef6c-a13f-5035-b60d-9bbe59280da8', '48a0b715-d220-5f61-8bc2-8595f64e95b9', N'Video Editor', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo An Phú (Demo)
Vị trí: Video Editor
Địa điểm: Khu văn phòng Demo, Tỉnh Thanh Hóa
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Video Editor trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 31–38 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thanh Hóa', 31000000, 38000000, 11, 79),
    ('286e93ac-c30d-51c2-8aa7-9495269f6338', 'f24d1d72-e77e-56bd-965d-b5d741f59baf', N'Backend Developer (.NET)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Vạn An (Demo)
Vị trí: Backend Developer (.NET)
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Backend Developer (.NET) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 11–17 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 11000000, 17000000, 8, 80),
    ('1faae1a4-d3dc-55ee-a4bd-979b1fd19633', 'f24d1d72-e77e-56bd-965d-b5d741f59baf', N'Frontend Developer (React)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Vạn An (Demo)
Vị trí: Frontend Developer (React)
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Frontend Developer (React) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 14000000, 21000000, 9, 80),
    ('fb4c51a8-0105-5956-8907-0301c41a5a11', 'f24d1d72-e77e-56bd-965d-b5d741f59baf', N'DevOps Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Vạn An (Demo)
Vị trí: DevOps Engineer
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí DevOps Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 17000000, 25000000, 10, 80),
    ('2716dbc4-61cc-59f3-bd3e-f3d73dd5b783', 'f24d1d72-e77e-56bd-965d-b5d741f59baf', N'QA Automation Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Vạn An (Demo)
Vị trí: QA Automation Engineer
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí QA Automation Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 20000000, 26000000, 11, 80),
    ('4b15b6ee-c138-5ccf-9dd1-437a1576ca1c', 'f24d1d72-e77e-56bd-965d-b5d741f59baf', N'Business Analyst', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Vạn An (Demo)
Vị trí: Business Analyst
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Business Analyst trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 23000000, 30000000, 12, 80),
    ('59b919d1-710e-553c-ab04-628ddcbbc35c', '32a8aa15-f7b7-5f43-b8c0-2f07733983af', N'Chuyên viên phân tích tài chính', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Vạn An (Demo)
Vị trí: Chuyên viên phân tích tài chính
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích tài chính trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 12–18 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 12000000, 18000000, 9, 81),
    ('157f9ea0-57f6-502f-92b4-14456887a0b8', '32a8aa15-f7b7-5f43-b8c0-2f07733983af', N'Chuyên viên tín dụng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Vạn An (Demo)
Vị trí: Chuyên viên tín dụng
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tín dụng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 15000000, 22000000, 10, 81),
    ('cb69cd3d-7dda-595e-ac5a-f946f3a75c78', '32a8aa15-f7b7-5f43-b8c0-2f07733983af', N'Chuyên viên quản trị rủi ro', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Vạn An (Demo)
Vị trí: Chuyên viên quản trị rủi ro
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản trị rủi ro trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 18000000, 26000000, 11, 81),
    ('05abd1da-0e7f-5fca-aa07-5e12044b6337', '32a8aa15-f7b7-5f43-b8c0-2f07733983af', N'Chuyên viên tư vấn khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Vạn An (Demo)
Vị trí: Chuyên viên tư vấn khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn khách hàng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 21000000, 27000000, 12, 81),
    ('f27eae43-0167-5fc5-a44d-157042a5bce4', '32a8aa15-f7b7-5f43-b8c0-2f07733983af', N'Kế toán tổng hợp', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Vạn An (Demo)
Vị trí: Kế toán tổng hợp
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kế toán tổng hợp trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 24000000, 31000000, 13, 81),
    ('1e5bfc5c-52f5-5eb9-8adf-d5d0323a20ab', 'f12d95cc-3212-549e-80f6-fb6b092316cf', N'Chuyên viên vận hành sàn thương mại điện tử', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Vạn An (Demo)
Vị trí: Chuyên viên vận hành sàn thương mại điện tử
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành sàn thương mại điện tử trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 13–19 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 13000000, 19000000, 10, 82),
    ('d7c3a744-27e0-508d-aea8-95f3509158d4', 'f12d95cc-3212-549e-80f6-fb6b092316cf', N'Digital Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Vạn An (Demo)
Vị trí: Digital Marketing Specialist
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Digital Marketing Specialist trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 16000000, 23000000, 11, 82),
    ('69b91921-493d-5b5e-acf1-2605e1b53553', 'f12d95cc-3212-549e-80f6-fb6b092316cf', N'Chuyên viên chăm sóc khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Vạn An (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 19000000, 27000000, 12, 82),
    ('2e9b3da1-e7ac-56f8-8b18-8de0f16008d1', 'f12d95cc-3212-549e-80f6-fb6b092316cf', N'Chuyên viên phân tích dữ liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Vạn An (Demo)
Vị trí: Chuyên viên phân tích dữ liệu
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích dữ liệu trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 22000000, 28000000, 13, 82),
    ('7304b9b0-489c-56d6-a21e-77f8542a08e3', 'f12d95cc-3212-549e-80f6-fb6b092316cf', N'Quản lý ngành hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Vạn An (Demo)
Vị trí: Quản lý ngành hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý ngành hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 25000000, 32000000, 14, 82),
    ('394be1ca-9918-5d75-873a-ee1dfe1b7451', '03c155ec-1d26-5907-93b6-b948daf6c1d3', N'Chuyên viên điều phối vận tải', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Vạn An (Demo)
Vị trí: Chuyên viên điều phối vận tải
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều phối vận tải trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–20 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 14000000, 20000000, 11, 83),
    ('bead8fd2-4556-5bd8-9862-734fad328915', '03c155ec-1d26-5907-93b6-b948daf6c1d3', N'Chuyên viên xuất nhập khẩu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Vạn An (Demo)
Vị trí: Chuyên viên xuất nhập khẩu
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên xuất nhập khẩu trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 17000000, 24000000, 12, 83),
    ('5361eee5-15ab-58aa-8deb-594859a615b1', '03c155ec-1d26-5907-93b6-b948daf6c1d3', N'Nhân viên quản lý kho', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Vạn An (Demo)
Vị trí: Nhân viên quản lý kho
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên quản lý kho trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 20000000, 28000000, 13, 83),
    ('1d0d05b7-fa1f-5cec-9371-6f0a9841cd45', '03c155ec-1d26-5907-93b6-b948daf6c1d3', N'Chuyên viên mua hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Vạn An (Demo)
Vị trí: Chuyên viên mua hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên mua hàng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 23000000, 29000000, 14, 83),
    ('18e9a6ee-60ff-527d-9a19-678cc728f06c', '03c155ec-1d26-5907-93b6-b948daf6c1d3', N'Chuyên viên hoạch định chuỗi cung ứng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Vạn An (Demo)
Vị trí: Chuyên viên hoạch định chuỗi cung ứng
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên hoạch định chuỗi cung ứng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 26000000, 33000000, 15, 83),
    ('b1ead523-cc47-5e86-9b98-3ac367c2f93e', 'd3c30ccb-ed8c-5392-8c9e-9eb59092e51f', N'Kỹ sư tự động hóa', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Vạn An (Demo)
Vị trí: Kỹ sư tự động hóa
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư tự động hóa trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 15000000, 21000000, 12, 84),
    ('be90d2ec-da4e-5bc7-a931-d3d345176b9c', 'd3c30ccb-ed8c-5392-8c9e-9eb59092e51f', N'Kỹ sư cơ khí', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Vạn An (Demo)
Vị trí: Kỹ sư cơ khí
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư cơ khí trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 18000000, 25000000, 13, 84),
    ('37747e07-fb06-580c-8616-5fab0c9730b6', 'd3c30ccb-ed8c-5392-8c9e-9eb59092e51f', N'Kỹ sư kiểm soát chất lượng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Vạn An (Demo)
Vị trí: Kỹ sư kiểm soát chất lượng
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư kiểm soát chất lượng trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 21000000, 29000000, 14, 84),
    ('63032545-6d99-5d08-94fb-8ae47c088825', 'd3c30ccb-ed8c-5392-8c9e-9eb59092e51f', N'Kỹ sư bảo trì', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Vạn An (Demo)
Vị trí: Kỹ sư bảo trì
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư bảo trì trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 24000000, 30000000, 15, 84),
    ('2d2f91d4-4f3f-5fce-9ab5-d74670983993', 'd3c30ccb-ed8c-5392-8c9e-9eb59092e51f', N'Chuyên viên kế hoạch sản xuất', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Vạn An (Demo)
Vị trí: Chuyên viên kế hoạch sản xuất
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kế hoạch sản xuất trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 27000000, 34000000, 16, 84),
    ('ea6240ac-2f91-5dd5-b6d4-c3ed8e70346e', '82fc2ae1-0f12-5025-9d95-c2bbb922e29e', N'Giáo viên tiếng Anh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Vạn An (Demo)
Vị trí: Giáo viên tiếng Anh
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Giáo viên tiếng Anh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 16000000, 22000000, 13, 85),
    ('9458ea6e-bfc5-5549-89d7-977de42fb9bb', '82fc2ae1-0f12-5025-9d95-c2bbb922e29e', N'Chuyên viên phát triển học liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Vạn An (Demo)
Vị trí: Chuyên viên phát triển học liệu
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phát triển học liệu trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 19000000, 26000000, 14, 85),
    ('a688448a-078f-5636-b412-4fc14ccb7858', '82fc2ae1-0f12-5025-9d95-c2bbb922e29e', N'Chuyên viên tư vấn tuyển sinh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Vạn An (Demo)
Vị trí: Chuyên viên tư vấn tuyển sinh
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn tuyển sinh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 22000000, 30000000, 15, 85),
    ('9ea3f612-6ae7-530a-a873-1dea6e1448c2', '82fc2ae1-0f12-5025-9d95-c2bbb922e29e', N'Điều phối viên đào tạo', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Vạn An (Demo)
Vị trí: Điều phối viên đào tạo
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều phối viên đào tạo trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 25000000, 31000000, 16, 85),
    ('9b38ab52-e859-52db-bef5-479122c1c2f4', '82fc2ae1-0f12-5025-9d95-c2bbb922e29e', N'Chuyên viên công nghệ giáo dục', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Vạn An (Demo)
Vị trí: Chuyên viên công nghệ giáo dục
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên công nghệ giáo dục trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 28000000, 35000000, 17, 85),
    ('8f8bb155-96de-5e25-8069-8df69973c1c2', '83a412e7-ac58-5287-aa90-c025fee82507', N'Điều dưỡng viên', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Vạn An (Demo)
Vị trí: Điều dưỡng viên
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều dưỡng viên trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 17000000, 23000000, 0, 86),
    ('303c4068-c3d5-5a56-95f2-3eb0670621ee', '83a412e7-ac58-5287-aa90-c025fee82507', N'Dược sĩ', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Vạn An (Demo)
Vị trí: Dược sĩ
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Dược sĩ trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 20000000, 27000000, 1, 86),
    ('02aa0f84-4850-5496-bad1-b8dc30a71c02', '83a412e7-ac58-5287-aa90-c025fee82507', N'Chuyên viên vận hành dịch vụ y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Vạn An (Demo)
Vị trí: Chuyên viên vận hành dịch vụ y tế
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành dịch vụ y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 23000000, 31000000, 2, 86),
    ('d89dbf4c-0f7a-5dd3-93ba-d2139bfce899', '83a412e7-ac58-5287-aa90-c025fee82507', N'Kỹ thuật viên xét nghiệm', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Vạn An (Demo)
Vị trí: Kỹ thuật viên xét nghiệm
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ thuật viên xét nghiệm trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 26000000, 32000000, 3, 86),
    ('4883cc6b-edb1-554a-9edf-3562314fc41f', '83a412e7-ac58-5287-aa90-c025fee82507', N'Chuyên viên chăm sóc khách hàng y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Vạn An (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng y tế
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 29000000, 36000000, 4, 86),
    ('081f180b-7e52-50f0-928b-e6635ad446f9', '078602d5-75dd-5a3e-a4fe-db70739cf5b7', N'Chuyên viên điều hành tour', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Vạn An (Demo)
Vị trí: Chuyên viên điều hành tour
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều hành tour trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 18000000, 24000000, 1, 87),
    ('eb179bba-7d46-5c5b-a1d5-0df174ed4736', '078602d5-75dd-5a3e-a4fe-db70739cf5b7', N'Nhân viên lễ tân', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Vạn An (Demo)
Vị trí: Nhân viên lễ tân
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên lễ tân trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 21000000, 28000000, 2, 87),
    ('c978017f-a383-57a2-8248-e9db4b2209db', '078602d5-75dd-5a3e-a4fe-db70739cf5b7', N'Chuyên viên kinh doanh du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Vạn An (Demo)
Vị trí: Chuyên viên kinh doanh du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kinh doanh du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 24000000, 32000000, 3, 87),
    ('e96635c9-468b-5592-b852-61e4c5670e93', '078602d5-75dd-5a3e-a4fe-db70739cf5b7', N'Quản lý dịch vụ khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Vạn An (Demo)
Vị trí: Quản lý dịch vụ khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý dịch vụ khách hàng trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 27000000, 33000000, 4, 87),
    ('c37dd617-89cd-503e-af5f-b6bfc5dad275', '078602d5-75dd-5a3e-a4fe-db70739cf5b7', N'Chuyên viên marketing du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Vạn An (Demo)
Vị trí: Chuyên viên marketing du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên marketing du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 30–37 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 30000000, 37000000, 5, 87),
    ('5c9c56b8-8d0d-5a01-9541-3da2cd7e9fdc', '272bee99-42e4-50d2-99fe-09a415cd0619', N'Kỹ sư xây dựng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Vạn An (Demo)
Vị trí: Kỹ sư xây dựng
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư xây dựng trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 19000000, 25000000, 2, 88),
    ('88f1e713-7021-526c-8bd8-e5f6fdd0f7e8', '272bee99-42e4-50d2-99fe-09a415cd0619', N'Kiến trúc sư', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Vạn An (Demo)
Vị trí: Kiến trúc sư
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kiến trúc sư trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 22000000, 29000000, 3, 88),
    ('938b2147-41f8-59fc-b84e-4ee88aebd9cf', '272bee99-42e4-50d2-99fe-09a415cd0619', N'Chuyên viên quản lý dự án', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Vạn An (Demo)
Vị trí: Chuyên viên quản lý dự án
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản lý dự án trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 25000000, 33000000, 4, 88),
    ('6b2e8cdc-066b-54a6-ba84-8000ff14e45e', '272bee99-42e4-50d2-99fe-09a415cd0619', N'Kỹ sư dự toán', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Vạn An (Demo)
Vị trí: Kỹ sư dự toán
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư dự toán trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 28000000, 34000000, 5, 88),
    ('ec8d9d26-4d19-553b-8b33-ae8644ebd90a', '272bee99-42e4-50d2-99fe-09a415cd0619', N'Chuyên viên tư vấn bất động sản', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Vạn An (Demo)
Vị trí: Chuyên viên tư vấn bất động sản
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn bất động sản trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 31–38 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 31000000, 38000000, 6, 88),
    ('dcf562e7-ebcd-50d6-ad6c-0e71b920c5fc', '666abe98-ecb0-5cf0-ae57-05ce8c38ae4e', N'Graphic Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Vạn An (Demo)
Vị trí: Graphic Designer
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Graphic Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 20000000, 26000000, 3, 89),
    ('404e142d-3a33-5845-ad7c-08c77c887d6d', '666abe98-ecb0-5cf0-ae57-05ce8c38ae4e', N'Content Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Vạn An (Demo)
Vị trí: Content Marketing Specialist
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Content Marketing Specialist trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 23000000, 30000000, 4, 89),
    ('833e9b32-9655-5c89-a485-8b90329ee0aa', '666abe98-ecb0-5cf0-ae57-05ce8c38ae4e', N'UI/UX Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Vạn An (Demo)
Vị trí: UI/UX Designer
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí UI/UX Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 26000000, 34000000, 5, 89),
    ('9300c3d0-c095-5862-9ed5-88b2e197f7cf', '666abe98-ecb0-5cf0-ae57-05ce8c38ae4e', N'Chuyên viên truyền thông', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Vạn An (Demo)
Vị trí: Chuyên viên truyền thông
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên truyền thông trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 29000000, 35000000, 6, 89),
    ('ce118fe9-cf3b-59fe-8aff-1adae5ddbee4', '666abe98-ecb0-5cf0-ae57-05ce8c38ae4e', N'Video Editor', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Vạn An (Demo)
Vị trí: Video Editor
Địa điểm: Khu văn phòng Demo, Thành phố Hải Phòng
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Video Editor trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 32–39 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hải Phòng', 32000000, 39000000, 7, 89),
    ('cfc323aa-2ac0-55a5-99e8-69392c2c248b', '02e2cde5-7040-5f37-9777-bd0c0d665e6a', N'Backend Developer (.NET)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Thiên Hà (Demo)
Vị trí: Backend Developer (.NET)
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Backend Developer (.NET) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 12–18 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 12000000, 18000000, 4, 60),
    ('9c5c5b5b-6ffa-5c6b-9353-8c4a013e39f0', '02e2cde5-7040-5f37-9777-bd0c0d665e6a', N'Frontend Developer (React)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Thiên Hà (Demo)
Vị trí: Frontend Developer (React)
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Frontend Developer (React) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 15000000, 22000000, 5, 60),
    ('3d048a01-750c-59b4-acbc-3a7cd2415237', '02e2cde5-7040-5f37-9777-bd0c0d665e6a', N'DevOps Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Thiên Hà (Demo)
Vị trí: DevOps Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí DevOps Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 18000000, 26000000, 6, 60),
    ('63303f27-9031-5839-ade2-df4895aaff49', '02e2cde5-7040-5f37-9777-bd0c0d665e6a', N'QA Automation Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Thiên Hà (Demo)
Vị trí: QA Automation Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí QA Automation Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 21000000, 27000000, 7, 60),
    ('48994536-8e5c-5c6f-8625-42ee20b340c4', '02e2cde5-7040-5f37-9777-bd0c0d665e6a', N'Business Analyst', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Thiên Hà (Demo)
Vị trí: Business Analyst
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Business Analyst trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 24000000, 31000000, 8, 60),
    ('96d6fd64-6228-51d5-a4a1-394f1812a65d', '13e1ac49-bdeb-5700-bb70-db51049c29a1', N'Chuyên viên phân tích tài chính', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Thiên Hà (Demo)
Vị trí: Chuyên viên phân tích tài chính
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích tài chính trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 13–19 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 13000000, 19000000, 5, 61),
    ('311ee90f-362c-57d0-9f1c-e64071e3d2ef', '13e1ac49-bdeb-5700-bb70-db51049c29a1', N'Chuyên viên tín dụng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Thiên Hà (Demo)
Vị trí: Chuyên viên tín dụng
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tín dụng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 16000000, 23000000, 6, 61),
    ('2aee1a4c-19ae-5820-b8c1-595ed63e3635', '13e1ac49-bdeb-5700-bb70-db51049c29a1', N'Chuyên viên quản trị rủi ro', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Thiên Hà (Demo)
Vị trí: Chuyên viên quản trị rủi ro
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản trị rủi ro trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 19000000, 27000000, 7, 61),
    ('fef17176-88ad-5102-97b6-16b5db84b60e', '13e1ac49-bdeb-5700-bb70-db51049c29a1', N'Chuyên viên tư vấn khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Thiên Hà (Demo)
Vị trí: Chuyên viên tư vấn khách hàng
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn khách hàng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 22000000, 28000000, 8, 61),
    ('00732d8e-0088-52cd-abdd-88430324c335', '13e1ac49-bdeb-5700-bb70-db51049c29a1', N'Kế toán tổng hợp', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Thiên Hà (Demo)
Vị trí: Kế toán tổng hợp
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kế toán tổng hợp trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 25000000, 32000000, 9, 61),
    ('f76c9411-b250-5184-92cb-ed5e3cc5a30c', '1e915b2a-fd19-54d2-a72a-744771d6fec9', N'Chuyên viên vận hành sàn thương mại điện tử', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Thiên Hà (Demo)
Vị trí: Chuyên viên vận hành sàn thương mại điện tử
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành sàn thương mại điện tử trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–20 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 14000000, 20000000, 6, 62),
    ('7dd627ef-7e8e-519d-b30f-b7cf2dd6750f', '1e915b2a-fd19-54d2-a72a-744771d6fec9', N'Digital Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Thiên Hà (Demo)
Vị trí: Digital Marketing Specialist
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Digital Marketing Specialist trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 17000000, 24000000, 7, 62),
    ('9483e975-4550-5344-9a4a-7173528fd4b0', '1e915b2a-fd19-54d2-a72a-744771d6fec9', N'Chuyên viên chăm sóc khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Thiên Hà (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 20000000, 28000000, 8, 62),
    ('00692468-6805-5a69-a8e9-d1753f8e39d6', '1e915b2a-fd19-54d2-a72a-744771d6fec9', N'Chuyên viên phân tích dữ liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Thiên Hà (Demo)
Vị trí: Chuyên viên phân tích dữ liệu
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích dữ liệu trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 23000000, 29000000, 9, 62),
    ('40f3a7bc-2c81-5a4d-bd01-ba00f100cd0b', '1e915b2a-fd19-54d2-a72a-744771d6fec9', N'Quản lý ngành hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Thiên Hà (Demo)
Vị trí: Quản lý ngành hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý ngành hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 26000000, 33000000, 10, 62),
    ('647e45bd-ad74-5f88-8240-d68499e9dc79', '1cd9db77-0efb-560b-9d01-b4b572499c5b', N'Chuyên viên điều phối vận tải', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Thiên Hà (Demo)
Vị trí: Chuyên viên điều phối vận tải
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều phối vận tải trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 15000000, 21000000, 7, 63),
    ('02022672-0581-5359-9d57-01f546efc39e', '1cd9db77-0efb-560b-9d01-b4b572499c5b', N'Chuyên viên xuất nhập khẩu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Thiên Hà (Demo)
Vị trí: Chuyên viên xuất nhập khẩu
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên xuất nhập khẩu trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 18000000, 25000000, 8, 63),
    ('eaad5675-97b4-5e21-ae1a-3532511baf5b', '1cd9db77-0efb-560b-9d01-b4b572499c5b', N'Nhân viên quản lý kho', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Thiên Hà (Demo)
Vị trí: Nhân viên quản lý kho
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên quản lý kho trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 21000000, 29000000, 9, 63),
    ('6c944805-41bc-5aaf-ac6a-170186c44614', '1cd9db77-0efb-560b-9d01-b4b572499c5b', N'Chuyên viên mua hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Thiên Hà (Demo)
Vị trí: Chuyên viên mua hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên mua hàng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 24000000, 30000000, 10, 63),
    ('49447bc7-4469-5931-bee6-704a43361615', '1cd9db77-0efb-560b-9d01-b4b572499c5b', N'Chuyên viên hoạch định chuỗi cung ứng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Thiên Hà (Demo)
Vị trí: Chuyên viên hoạch định chuỗi cung ứng
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên hoạch định chuỗi cung ứng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 27000000, 34000000, 11, 63),
    ('16b384c6-a280-5bfa-a47e-2feb2ff9ff12', '6a94f72c-6026-5e4b-b196-75ebc283a0ae', N'Kỹ sư tự động hóa', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Thiên Hà (Demo)
Vị trí: Kỹ sư tự động hóa
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư tự động hóa trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 16000000, 22000000, 8, 64),
    ('25b71ef2-419a-5649-8045-724499755707', '6a94f72c-6026-5e4b-b196-75ebc283a0ae', N'Kỹ sư cơ khí', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Thiên Hà (Demo)
Vị trí: Kỹ sư cơ khí
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư cơ khí trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 19000000, 26000000, 9, 64),
    ('499c6c0b-8471-57d2-af5d-bae7a5fac775', '6a94f72c-6026-5e4b-b196-75ebc283a0ae', N'Kỹ sư kiểm soát chất lượng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Thiên Hà (Demo)
Vị trí: Kỹ sư kiểm soát chất lượng
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư kiểm soát chất lượng trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 22000000, 30000000, 10, 64),
    ('3b563673-2cfb-5429-ab92-13ee48f620b9', '6a94f72c-6026-5e4b-b196-75ebc283a0ae', N'Kỹ sư bảo trì', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Thiên Hà (Demo)
Vị trí: Kỹ sư bảo trì
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư bảo trì trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 25000000, 31000000, 11, 64),
    ('d44f9a81-1b29-558b-80e3-ddbb1f018574', '6a94f72c-6026-5e4b-b196-75ebc283a0ae', N'Chuyên viên kế hoạch sản xuất', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Thiên Hà (Demo)
Vị trí: Chuyên viên kế hoạch sản xuất
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kế hoạch sản xuất trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 28000000, 35000000, 12, 64),
    ('627afab5-0528-5517-b39b-e0cd19188afe', 'a5b4c183-6b02-5eef-8717-caab064c27d3', N'Giáo viên tiếng Anh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Thiên Hà (Demo)
Vị trí: Giáo viên tiếng Anh
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Giáo viên tiếng Anh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 17000000, 23000000, 9, 65),
    ('8eb3d36c-aa71-5bda-a3d7-548cf49f76ea', 'a5b4c183-6b02-5eef-8717-caab064c27d3', N'Chuyên viên phát triển học liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Thiên Hà (Demo)
Vị trí: Chuyên viên phát triển học liệu
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phát triển học liệu trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 20000000, 27000000, 10, 65),
    ('74877f2b-b1fa-58f1-b235-9cb54b827059', 'a5b4c183-6b02-5eef-8717-caab064c27d3', N'Chuyên viên tư vấn tuyển sinh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Thiên Hà (Demo)
Vị trí: Chuyên viên tư vấn tuyển sinh
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn tuyển sinh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 23000000, 31000000, 11, 65),
    ('d72ce0d5-513b-59c5-a9f5-741fbfc227b4', 'a5b4c183-6b02-5eef-8717-caab064c27d3', N'Điều phối viên đào tạo', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Thiên Hà (Demo)
Vị trí: Điều phối viên đào tạo
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều phối viên đào tạo trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 26000000, 32000000, 12, 65),
    ('e965b6b7-4e79-50f0-8517-ac377d187af4', 'a5b4c183-6b02-5eef-8717-caab064c27d3', N'Chuyên viên công nghệ giáo dục', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Thiên Hà (Demo)
Vị trí: Chuyên viên công nghệ giáo dục
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên công nghệ giáo dục trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 29000000, 36000000, 13, 65),
    ('d825b1a5-3e00-5c00-9bec-f413424a8678', 'f492136a-f672-5bb7-ad96-7795bae3974e', N'Điều dưỡng viên', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Thiên Hà (Demo)
Vị trí: Điều dưỡng viên
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều dưỡng viên trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 18000000, 24000000, 10, 66),
    ('85480075-c092-505e-94c5-6854bc2d4379', 'f492136a-f672-5bb7-ad96-7795bae3974e', N'Dược sĩ', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Thiên Hà (Demo)
Vị trí: Dược sĩ
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Dược sĩ trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 21000000, 28000000, 11, 66),
    ('18bb48f6-26c8-5419-81f6-3cd2b905b35d', 'f492136a-f672-5bb7-ad96-7795bae3974e', N'Chuyên viên vận hành dịch vụ y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Thiên Hà (Demo)
Vị trí: Chuyên viên vận hành dịch vụ y tế
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành dịch vụ y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 24000000, 32000000, 12, 66),
    ('f59bde14-0007-5408-b1d2-cff7f4e8577e', 'f492136a-f672-5bb7-ad96-7795bae3974e', N'Kỹ thuật viên xét nghiệm', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Thiên Hà (Demo)
Vị trí: Kỹ thuật viên xét nghiệm
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ thuật viên xét nghiệm trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 27000000, 33000000, 13, 66),
    ('0402ea40-9b21-50b3-9007-85b1b999b4bf', 'f492136a-f672-5bb7-ad96-7795bae3974e', N'Chuyên viên chăm sóc khách hàng y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Thiên Hà (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng y tế
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 30–37 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 30000000, 37000000, 14, 66),
    ('417c493c-1366-5fc3-ad7a-399e9ba505da', '78869b06-538e-593b-b173-3e5f9e0bf389', N'Chuyên viên điều hành tour', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Thiên Hà (Demo)
Vị trí: Chuyên viên điều hành tour
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều hành tour trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 19000000, 25000000, 11, 67),
    ('2bf088fc-3d24-535f-aef8-6a4d2c015cb6', '78869b06-538e-593b-b173-3e5f9e0bf389', N'Nhân viên lễ tân', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Thiên Hà (Demo)
Vị trí: Nhân viên lễ tân
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên lễ tân trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 22000000, 29000000, 12, 67),
    ('9d8024fa-d958-5b85-b26f-5ffd4edede4f', '78869b06-538e-593b-b173-3e5f9e0bf389', N'Chuyên viên kinh doanh du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Thiên Hà (Demo)
Vị trí: Chuyên viên kinh doanh du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kinh doanh du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 25000000, 33000000, 13, 67),
    ('c346c3f8-0bdd-5363-8214-f166e018e3c9', '78869b06-538e-593b-b173-3e5f9e0bf389', N'Quản lý dịch vụ khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Thiên Hà (Demo)
Vị trí: Quản lý dịch vụ khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý dịch vụ khách hàng trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 28000000, 34000000, 14, 67),
    ('63b49b51-54b6-53cb-a3ac-6bde7584ec87', '78869b06-538e-593b-b173-3e5f9e0bf389', N'Chuyên viên marketing du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Thiên Hà (Demo)
Vị trí: Chuyên viên marketing du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên marketing du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 31–38 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 31000000, 38000000, 15, 67),
    ('5706384e-1945-5211-b0fc-736567761f32', 'c71832d4-2fdc-5414-93fd-c987ae700e3a', N'Kỹ sư xây dựng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Thiên Hà (Demo)
Vị trí: Kỹ sư xây dựng
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư xây dựng trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 20000000, 26000000, 12, 68),
    ('b4f961a0-a192-54cc-ad7e-1b7bafd8ed5f', 'c71832d4-2fdc-5414-93fd-c987ae700e3a', N'Kiến trúc sư', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Thiên Hà (Demo)
Vị trí: Kiến trúc sư
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kiến trúc sư trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 23000000, 30000000, 13, 68),
    ('810a33ea-b624-58b4-9e9f-b8344291cef5', 'c71832d4-2fdc-5414-93fd-c987ae700e3a', N'Chuyên viên quản lý dự án', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Thiên Hà (Demo)
Vị trí: Chuyên viên quản lý dự án
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản lý dự án trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 26000000, 34000000, 14, 68),
    ('c7f77b32-a216-587c-94fb-ae83417e65d6', 'c71832d4-2fdc-5414-93fd-c987ae700e3a', N'Kỹ sư dự toán', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Thiên Hà (Demo)
Vị trí: Kỹ sư dự toán
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư dự toán trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 29000000, 35000000, 15, 68),
    ('25fa61d8-3568-589d-9875-54c420ae9b60', 'c71832d4-2fdc-5414-93fd-c987ae700e3a', N'Chuyên viên tư vấn bất động sản', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Thiên Hà (Demo)
Vị trí: Chuyên viên tư vấn bất động sản
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn bất động sản trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 32–39 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 32000000, 39000000, 16, 68),
    ('3a626f2d-ad6c-5dfd-92bf-a812f9958e98', '0426a190-c63d-5bba-88bc-1f1fa871dce0', N'Graphic Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Thiên Hà (Demo)
Vị trí: Graphic Designer
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Graphic Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 21000000, 27000000, 13, 69),
    ('efe635d6-7813-5f67-a46e-40088806548e', '0426a190-c63d-5bba-88bc-1f1fa871dce0', N'Content Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Thiên Hà (Demo)
Vị trí: Content Marketing Specialist
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Content Marketing Specialist trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 24000000, 31000000, 14, 69),
    ('169c43a8-8e83-57e8-9714-e7a6d9ee838d', '0426a190-c63d-5bba-88bc-1f1fa871dce0', N'UI/UX Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Thiên Hà (Demo)
Vị trí: UI/UX Designer
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí UI/UX Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 27000000, 35000000, 15, 69),
    ('5f4c3954-7788-540a-8aee-a7389831fc0b', '0426a190-c63d-5bba-88bc-1f1fa871dce0', N'Chuyên viên truyền thông', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Thiên Hà (Demo)
Vị trí: Chuyên viên truyền thông
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên truyền thông trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 30–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 30000000, 36000000, 16, 69),
    ('2ce394d9-acda-5435-ad55-7840a9a2a920', '0426a190-c63d-5bba-88bc-1f1fa871dce0', N'Video Editor', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Thiên Hà (Demo)
Vị trí: Video Editor
Địa điểm: Khu văn phòng Demo, Tỉnh Quảng Ninh
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Video Editor trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 33–40 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Quảng Ninh', 33000000, 40000000, 17, 69),
    ('c85ec54e-9942-5fb4-b620-c9d3307bf083', '44b2fa56-c57e-5239-83f7-7a74c03d002c', N'Backend Developer (.NET)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Minh Sơn (Demo)
Vị trí: Backend Developer (.NET)
Địa điểm: Khu văn phòng Demo, Tỉnh Hưng Yên
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Backend Developer (.NET) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 13–19 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Hưng Yên', 13000000, 19000000, 0, 70),
    ('ec808654-f190-592b-bf6b-73545cd1856b', '44b2fa56-c57e-5239-83f7-7a74c03d002c', N'Frontend Developer (React)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Minh Sơn (Demo)
Vị trí: Frontend Developer (React)
Địa điểm: Khu văn phòng Demo, Tỉnh Hưng Yên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Frontend Developer (React) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Hưng Yên', 16000000, 23000000, 1, 70),
    ('64955553-4e9e-567e-bcc1-2822f58779c9', '44b2fa56-c57e-5239-83f7-7a74c03d002c', N'DevOps Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Minh Sơn (Demo)
Vị trí: DevOps Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh Hưng Yên
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí DevOps Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Hưng Yên', 19000000, 27000000, 2, 70),
    ('5c42de4a-0e3c-5fcb-986d-34a40b78c9ba', '44b2fa56-c57e-5239-83f7-7a74c03d002c', N'QA Automation Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Minh Sơn (Demo)
Vị trí: QA Automation Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh Hưng Yên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí QA Automation Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Hưng Yên', 22000000, 28000000, 3, 70),
    ('fef7aee0-8a0f-5521-aa71-3970cfb03732', '44b2fa56-c57e-5239-83f7-7a74c03d002c', N'Business Analyst', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Minh Sơn (Demo)
Vị trí: Business Analyst
Địa điểm: Khu văn phòng Demo, Tỉnh Hưng Yên
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Business Analyst trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Hưng Yên', 25000000, 32000000, 4, 70),
    ('d9fd7170-fb11-5b1b-aa33-e92251e7aeb4', '21e3b2af-9a1a-55da-8d29-577e1a92890a', N'Chuyên viên phân tích tài chính', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Minh Sơn (Demo)
Vị trí: Chuyên viên phân tích tài chính
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích tài chính trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–20 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 14000000, 20000000, 1, 71),
    ('be9aacf6-2f4e-59c5-b709-27069504d882', '21e3b2af-9a1a-55da-8d29-577e1a92890a', N'Chuyên viên tín dụng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Minh Sơn (Demo)
Vị trí: Chuyên viên tín dụng
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tín dụng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 17000000, 24000000, 2, 71),
    ('eb524841-e4ca-5194-9fe2-903b1bc42cef', '21e3b2af-9a1a-55da-8d29-577e1a92890a', N'Chuyên viên quản trị rủi ro', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Minh Sơn (Demo)
Vị trí: Chuyên viên quản trị rủi ro
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản trị rủi ro trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 20000000, 28000000, 3, 71),
    ('5bc96964-01b0-5472-8fa9-fe0778bf48ee', '21e3b2af-9a1a-55da-8d29-577e1a92890a', N'Chuyên viên tư vấn khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Minh Sơn (Demo)
Vị trí: Chuyên viên tư vấn khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn khách hàng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 23000000, 29000000, 4, 71),
    ('6cad3090-5a44-5312-9595-49f106bacfaf', '21e3b2af-9a1a-55da-8d29-577e1a92890a', N'Kế toán tổng hợp', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Minh Sơn (Demo)
Vị trí: Kế toán tổng hợp
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kế toán tổng hợp trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 26000000, 33000000, 5, 71),
    ('12d2ff14-3e8b-5629-af8f-399cfaf3a7c0', 'cada2d90-3f1a-519f-bf02-d904dbc6b8c9', N'Chuyên viên vận hành sàn thương mại điện tử', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Minh Sơn (Demo)
Vị trí: Chuyên viên vận hành sàn thương mại điện tử
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành sàn thương mại điện tử trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 15000000, 21000000, 2, 72),
    ('19ec36ec-d200-5857-bbc1-1678609b479b', 'cada2d90-3f1a-519f-bf02-d904dbc6b8c9', N'Digital Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Minh Sơn (Demo)
Vị trí: Digital Marketing Specialist
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Digital Marketing Specialist trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 18000000, 25000000, 3, 72),
    ('56f6f184-7fe3-556e-8d86-3387a0e8a51b', 'cada2d90-3f1a-519f-bf02-d904dbc6b8c9', N'Chuyên viên chăm sóc khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Minh Sơn (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 21000000, 29000000, 4, 72),
    ('08803ffd-7aac-54d4-b78c-b49b4650979d', 'cada2d90-3f1a-519f-bf02-d904dbc6b8c9', N'Chuyên viên phân tích dữ liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Minh Sơn (Demo)
Vị trí: Chuyên viên phân tích dữ liệu
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích dữ liệu trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 24000000, 30000000, 5, 72),
    ('ec8d83b2-9185-5658-ac2e-64e36ce6df32', 'cada2d90-3f1a-519f-bf02-d904dbc6b8c9', N'Quản lý ngành hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Minh Sơn (Demo)
Vị trí: Quản lý ngành hàng
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý ngành hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 27000000, 34000000, 6, 72),
    ('a635be01-7307-5644-9482-424187535bd7', '5c8bb042-3a7b-51e0-94d8-c6deb9b28311', N'Chuyên viên điều phối vận tải', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Minh Sơn (Demo)
Vị trí: Chuyên viên điều phối vận tải
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều phối vận tải trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 16000000, 22000000, 3, 73),
    ('cb52ddf7-a3e6-5dd2-909b-5563807231bf', '5c8bb042-3a7b-51e0-94d8-c6deb9b28311', N'Chuyên viên xuất nhập khẩu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Minh Sơn (Demo)
Vị trí: Chuyên viên xuất nhập khẩu
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên xuất nhập khẩu trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 19000000, 26000000, 4, 73),
    ('f443af11-746b-5a6f-81f6-201a40f4f83d', '5c8bb042-3a7b-51e0-94d8-c6deb9b28311', N'Nhân viên quản lý kho', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Minh Sơn (Demo)
Vị trí: Nhân viên quản lý kho
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên quản lý kho trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 22000000, 30000000, 5, 73),
    ('ba99be16-bcfa-5a69-97eb-6acbd375ec6c', '5c8bb042-3a7b-51e0-94d8-c6deb9b28311', N'Chuyên viên mua hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Minh Sơn (Demo)
Vị trí: Chuyên viên mua hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên mua hàng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 25000000, 31000000, 6, 73),
    ('da67ecb9-e7de-5dda-8798-7c5a806cedea', '5c8bb042-3a7b-51e0-94d8-c6deb9b28311', N'Chuyên viên hoạch định chuỗi cung ứng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Minh Sơn (Demo)
Vị trí: Chuyên viên hoạch định chuỗi cung ứng
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên hoạch định chuỗi cung ứng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 28000000, 35000000, 7, 73),
    ('90b60118-cbec-553e-b550-c8a7c9731a29', 'e1adacfe-4bf1-5324-ad95-16c61010c220', N'Kỹ sư tự động hóa', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Minh Sơn (Demo)
Vị trí: Kỹ sư tự động hóa
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư tự động hóa trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 17000000, 23000000, 4, 74),
    ('68ad1782-fa4e-5aea-b5ca-1f996f066c97', 'e1adacfe-4bf1-5324-ad95-16c61010c220', N'Kỹ sư cơ khí', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Minh Sơn (Demo)
Vị trí: Kỹ sư cơ khí
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư cơ khí trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 20000000, 27000000, 5, 74),
    ('c1c12dc9-a8ee-5deb-b415-085a7d6de3ef', 'e1adacfe-4bf1-5324-ad95-16c61010c220', N'Kỹ sư kiểm soát chất lượng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Minh Sơn (Demo)
Vị trí: Kỹ sư kiểm soát chất lượng
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư kiểm soát chất lượng trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 23000000, 31000000, 6, 74),
    ('acb95b09-9568-5ae5-b0bf-b0563ab5e4f3', 'e1adacfe-4bf1-5324-ad95-16c61010c220', N'Kỹ sư bảo trì', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Minh Sơn (Demo)
Vị trí: Kỹ sư bảo trì
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư bảo trì trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 26000000, 32000000, 7, 74),
    ('67796593-5c9d-57f9-838f-6df4062caf46', 'e1adacfe-4bf1-5324-ad95-16c61010c220', N'Chuyên viên kế hoạch sản xuất', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Minh Sơn (Demo)
Vị trí: Chuyên viên kế hoạch sản xuất
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kế hoạch sản xuất trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 29000000, 36000000, 8, 74),
    ('a25a1a50-0252-5bc2-95ed-62f1d2815621', '43a30852-8eef-5fe4-beb6-edd81897025f', N'Giáo viên tiếng Anh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Minh Sơn (Demo)
Vị trí: Giáo viên tiếng Anh
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Giáo viên tiếng Anh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 18000000, 24000000, 5, 75),
    ('757acc26-dba6-5719-8ae1-3d81138386c3', '43a30852-8eef-5fe4-beb6-edd81897025f', N'Chuyên viên phát triển học liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Minh Sơn (Demo)
Vị trí: Chuyên viên phát triển học liệu
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phát triển học liệu trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 21000000, 28000000, 6, 75),
    ('6dc8d947-15d3-535b-9614-06c92f09c34e', '43a30852-8eef-5fe4-beb6-edd81897025f', N'Chuyên viên tư vấn tuyển sinh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Minh Sơn (Demo)
Vị trí: Chuyên viên tư vấn tuyển sinh
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn tuyển sinh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 24000000, 32000000, 7, 75),
    ('f2e3938a-5bf3-52ce-aef9-a9b6fb9fd11f', '43a30852-8eef-5fe4-beb6-edd81897025f', N'Điều phối viên đào tạo', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Minh Sơn (Demo)
Vị trí: Điều phối viên đào tạo
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều phối viên đào tạo trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 27000000, 33000000, 8, 75),
    ('1ead2f61-db12-52a6-9c09-9ae6896c58b6', '43a30852-8eef-5fe4-beb6-edd81897025f', N'Chuyên viên công nghệ giáo dục', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Minh Sơn (Demo)
Vị trí: Chuyên viên công nghệ giáo dục
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên công nghệ giáo dục trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 30–37 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 30000000, 37000000, 9, 75),
    ('fbb48a82-4ff4-5390-8426-e589211005e9', '0ed91b3e-1603-5fa6-99c0-bddb536e17ac', N'Điều dưỡng viên', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Minh Sơn (Demo)
Vị trí: Điều dưỡng viên
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều dưỡng viên trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 19000000, 25000000, 6, 76),
    ('09e4889a-96e7-5db5-883e-d3220fc75e19', '0ed91b3e-1603-5fa6-99c0-bddb536e17ac', N'Dược sĩ', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Minh Sơn (Demo)
Vị trí: Dược sĩ
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Dược sĩ trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 22000000, 29000000, 7, 76),
    ('7b6782c8-3251-5183-8908-bacfbee317bf', '0ed91b3e-1603-5fa6-99c0-bddb536e17ac', N'Chuyên viên vận hành dịch vụ y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Minh Sơn (Demo)
Vị trí: Chuyên viên vận hành dịch vụ y tế
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành dịch vụ y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 25000000, 33000000, 8, 76),
    ('1fbe417e-e711-5a57-9f58-11b315e53729', '0ed91b3e-1603-5fa6-99c0-bddb536e17ac', N'Kỹ thuật viên xét nghiệm', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Minh Sơn (Demo)
Vị trí: Kỹ thuật viên xét nghiệm
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ thuật viên xét nghiệm trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 28000000, 34000000, 9, 76),
    ('7c7742a3-adbc-55d3-a732-3f8a27fff5de', '0ed91b3e-1603-5fa6-99c0-bddb536e17ac', N'Chuyên viên chăm sóc khách hàng y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Minh Sơn (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng y tế
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 31–38 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 31000000, 38000000, 10, 76),
    ('750216d1-5b11-5198-9b03-cf6e0371d76c', '0e52d5a5-da80-5394-b923-84f74c5d2921', N'Chuyên viên điều hành tour', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Minh Sơn (Demo)
Vị trí: Chuyên viên điều hành tour
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều hành tour trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 20000000, 26000000, 7, 77),
    ('9c34c9a9-3422-53ac-86b9-ea9c29b2a01d', '0e52d5a5-da80-5394-b923-84f74c5d2921', N'Nhân viên lễ tân', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Minh Sơn (Demo)
Vị trí: Nhân viên lễ tân
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên lễ tân trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 23000000, 30000000, 8, 77),
    ('a64e7f08-1dcb-54a5-a056-118eba5ab0d1', '0e52d5a5-da80-5394-b923-84f74c5d2921', N'Chuyên viên kinh doanh du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Minh Sơn (Demo)
Vị trí: Chuyên viên kinh doanh du lịch
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kinh doanh du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 26000000, 34000000, 9, 77),
    ('de4492f1-28c1-5e92-8435-c257bf37b7e7', '0e52d5a5-da80-5394-b923-84f74c5d2921', N'Quản lý dịch vụ khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Minh Sơn (Demo)
Vị trí: Quản lý dịch vụ khách hàng
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý dịch vụ khách hàng trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 29000000, 35000000, 10, 77),
    ('7faef59e-79d1-53d9-bf66-d6e88f9cfb25', '0e52d5a5-da80-5394-b923-84f74c5d2921', N'Chuyên viên marketing du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Minh Sơn (Demo)
Vị trí: Chuyên viên marketing du lịch
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên marketing du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 32–39 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 32000000, 39000000, 11, 77),
    ('ba249cd2-6b3a-541c-a364-df8c01f329ed', '9a70e94a-7836-5d01-a4b3-edd830474bcd', N'Kỹ sư xây dựng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Minh Sơn (Demo)
Vị trí: Kỹ sư xây dựng
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư xây dựng trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 21000000, 27000000, 8, 78),
    ('4b601496-5e05-55c0-8451-9dd1788b6e77', '9a70e94a-7836-5d01-a4b3-edd830474bcd', N'Kiến trúc sư', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Minh Sơn (Demo)
Vị trí: Kiến trúc sư
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kiến trúc sư trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 24000000, 31000000, 9, 78),
    ('142f1aa2-0554-5c6b-8234-612a5401a173', '9a70e94a-7836-5d01-a4b3-edd830474bcd', N'Chuyên viên quản lý dự án', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Minh Sơn (Demo)
Vị trí: Chuyên viên quản lý dự án
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản lý dự án trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 27000000, 35000000, 10, 78),
    ('d3eee8bf-6b0c-5055-8f59-c8dfad4b7fa7', '9a70e94a-7836-5d01-a4b3-edd830474bcd', N'Kỹ sư dự toán', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Minh Sơn (Demo)
Vị trí: Kỹ sư dự toán
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư dự toán trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 30–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 30000000, 36000000, 11, 78),
    ('5fc9fe0c-7cbd-51ec-9953-e9a00bd752d4', '9a70e94a-7836-5d01-a4b3-edd830474bcd', N'Chuyên viên tư vấn bất động sản', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Minh Sơn (Demo)
Vị trí: Chuyên viên tư vấn bất động sản
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn bất động sản trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 33–40 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 33000000, 40000000, 12, 78),
    ('c4543537-3ff3-5dfb-87b9-6a9ab9f8958a', 'f578cad6-ae06-5707-99f9-c6e7b3925811', N'Graphic Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Minh Sơn (Demo)
Vị trí: Graphic Designer
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Graphic Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 22000000, 28000000, 9, 79),
    ('0e5fe114-be37-52d1-bff8-957579589cde', 'f578cad6-ae06-5707-99f9-c6e7b3925811', N'Content Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Minh Sơn (Demo)
Vị trí: Content Marketing Specialist
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Content Marketing Specialist trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 25000000, 32000000, 10, 79),
    ('c1ce9fcd-cc91-5c6f-84a6-4a3acddb6b3a', 'f578cad6-ae06-5707-99f9-c6e7b3925811', N'UI/UX Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Minh Sơn (Demo)
Vị trí: UI/UX Designer
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí UI/UX Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 28000000, 36000000, 11, 79),
    ('b3d6058e-84a3-5550-bcb8-0608f04dac15', 'f578cad6-ae06-5707-99f9-c6e7b3925811', N'Chuyên viên truyền thông', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Minh Sơn (Demo)
Vị trí: Chuyên viên truyền thông
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên truyền thông trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 31–37 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 31000000, 37000000, 12, 79),
    ('8301e14c-ad62-5de4-a46a-efba1ae291dc', 'f578cad6-ae06-5707-99f9-c6e7b3925811', N'Video Editor', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Minh Sơn (Demo)
Vị trí: Video Editor
Địa điểm: Khu văn phòng Demo, Tỉnh Lào Cai
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Video Editor trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 34–41 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lào Cai', 34000000, 41000000, 13, 79),
    ('d8531217-eb81-5798-8fb4-bc1b9a0052f0', '79031059-3750-54f3-aaed-c13f19ccaa22', N'Backend Developer (.NET)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Tân Việt (Demo)
Vị trí: Backend Developer (.NET)
Địa điểm: Khu văn phòng Demo, Tỉnh Bắc Ninh
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Backend Developer (.NET) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 10–16 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Bắc Ninh', 10000000, 16000000, 10, 80),
    ('bbe383be-e86a-5877-bbe0-8713e01d7e58', '79031059-3750-54f3-aaed-c13f19ccaa22', N'Frontend Developer (React)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Tân Việt (Demo)
Vị trí: Frontend Developer (React)
Địa điểm: Khu văn phòng Demo, Tỉnh Bắc Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Frontend Developer (React) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 13–20 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Bắc Ninh', 13000000, 20000000, 11, 80),
    ('5ffda256-5d2f-5dbd-9a27-f2e949a82aea', '79031059-3750-54f3-aaed-c13f19ccaa22', N'DevOps Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Tân Việt (Demo)
Vị trí: DevOps Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh Bắc Ninh
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí DevOps Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Bắc Ninh', 16000000, 24000000, 12, 80),
    ('ff47e985-4da5-51f4-bc98-bfa3f8795180', '79031059-3750-54f3-aaed-c13f19ccaa22', N'QA Automation Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Tân Việt (Demo)
Vị trí: QA Automation Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh Bắc Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí QA Automation Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Bắc Ninh', 19000000, 25000000, 13, 80),
    ('06f48c1e-6109-5cec-827d-28e1abc0b6c5', '79031059-3750-54f3-aaed-c13f19ccaa22', N'Business Analyst', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Tân Việt (Demo)
Vị trí: Business Analyst
Địa điểm: Khu văn phòng Demo, Tỉnh Bắc Ninh
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Business Analyst trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Bắc Ninh', 22000000, 29000000, 14, 80),
    ('8c0deb7f-a6df-5859-b9e5-dd9296a54492', '31602d3c-c648-5be5-93ce-5b4b24019610', N'Chuyên viên phân tích tài chính', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Tân Việt (Demo)
Vị trí: Chuyên viên phân tích tài chính
Địa điểm: Khu văn phòng Demo, Tỉnh Hưng Yên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích tài chính trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 11–17 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Hưng Yên', 11000000, 17000000, 11, 81),
    ('84351a22-ce43-53a1-990a-1103e910b302', '31602d3c-c648-5be5-93ce-5b4b24019610', N'Chuyên viên tín dụng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Tân Việt (Demo)
Vị trí: Chuyên viên tín dụng
Địa điểm: Khu văn phòng Demo, Tỉnh Hưng Yên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tín dụng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Hưng Yên', 14000000, 21000000, 12, 81),
    ('ebd42d12-f701-59f9-9a5d-4fe7ac324909', '31602d3c-c648-5be5-93ce-5b4b24019610', N'Chuyên viên quản trị rủi ro', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Tân Việt (Demo)
Vị trí: Chuyên viên quản trị rủi ro
Địa điểm: Khu văn phòng Demo, Tỉnh Hưng Yên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản trị rủi ro trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Hưng Yên', 17000000, 25000000, 13, 81),
    ('99700675-9604-55f9-914d-c6316a7bfea5', '31602d3c-c648-5be5-93ce-5b4b24019610', N'Chuyên viên tư vấn khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Tân Việt (Demo)
Vị trí: Chuyên viên tư vấn khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Hưng Yên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn khách hàng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Hưng Yên', 20000000, 26000000, 14, 81),
    ('30a70b76-5df5-55a7-a6e5-8b49ffeb8b9f', '31602d3c-c648-5be5-93ce-5b4b24019610', N'Kế toán tổng hợp', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Tân Việt (Demo)
Vị trí: Kế toán tổng hợp
Địa điểm: Khu văn phòng Demo, Tỉnh Hưng Yên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kế toán tổng hợp trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Hưng Yên', 23000000, 30000000, 15, 81),
    ('6d8aeabf-09dc-537c-91b9-8f7372c6a487', '54f6de28-a740-5089-8e5f-5e4e170a62d4', N'Chuyên viên vận hành sàn thương mại điện tử', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Tân Việt (Demo)
Vị trí: Chuyên viên vận hành sàn thương mại điện tử
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành sàn thương mại điện tử trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 12–18 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 12000000, 18000000, 12, 82),
    ('8956189b-abac-53f6-8bed-2926583606f1', '54f6de28-a740-5089-8e5f-5e4e170a62d4', N'Digital Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Tân Việt (Demo)
Vị trí: Digital Marketing Specialist
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Digital Marketing Specialist trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 15000000, 22000000, 13, 82),
    ('e9e16918-fffb-58ce-a6f6-963c6f47510a', '54f6de28-a740-5089-8e5f-5e4e170a62d4', N'Chuyên viên chăm sóc khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Tân Việt (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 18000000, 26000000, 14, 82),
    ('65653634-85b9-5c10-830d-871f41987ae8', '54f6de28-a740-5089-8e5f-5e4e170a62d4', N'Chuyên viên phân tích dữ liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Tân Việt (Demo)
Vị trí: Chuyên viên phân tích dữ liệu
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích dữ liệu trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 21000000, 27000000, 15, 82),
    ('ffc43aeb-3418-571f-bc19-4127e07a4d45', '54f6de28-a740-5089-8e5f-5e4e170a62d4', N'Quản lý ngành hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Tân Việt (Demo)
Vị trí: Quản lý ngành hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý ngành hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 24000000, 31000000, 16, 82),
    ('8052a0cc-4d64-52ae-abcc-abd30e9cd8b7', 'ed3d579d-027b-566e-97d9-b363f38162ec', N'Chuyên viên điều phối vận tải', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Tân Việt (Demo)
Vị trí: Chuyên viên điều phối vận tải
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều phối vận tải trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 13–19 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 13000000, 19000000, 13, 83),
    ('4820a4b8-5a5f-52ca-b17f-17e4959e5129', 'ed3d579d-027b-566e-97d9-b363f38162ec', N'Chuyên viên xuất nhập khẩu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Tân Việt (Demo)
Vị trí: Chuyên viên xuất nhập khẩu
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên xuất nhập khẩu trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 16000000, 23000000, 14, 83),
    ('c46eb490-1bd8-50e8-afed-4375e763a069', 'ed3d579d-027b-566e-97d9-b363f38162ec', N'Nhân viên quản lý kho', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Tân Việt (Demo)
Vị trí: Nhân viên quản lý kho
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên quản lý kho trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 19000000, 27000000, 15, 83),
    ('d6ae2eb2-2b60-523b-8c8f-8aa6c0a201b4', 'ed3d579d-027b-566e-97d9-b363f38162ec', N'Chuyên viên mua hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Tân Việt (Demo)
Vị trí: Chuyên viên mua hàng
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên mua hàng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 22000000, 28000000, 16, 83),
    ('61fc753d-b28a-5262-bb3c-a9ddbafded8c', 'ed3d579d-027b-566e-97d9-b363f38162ec', N'Chuyên viên hoạch định chuỗi cung ứng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Tân Việt (Demo)
Vị trí: Chuyên viên hoạch định chuỗi cung ứng
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên hoạch định chuỗi cung ứng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 25000000, 32000000, 17, 83),
    ('feb6272b-77ae-5528-b620-ab21977de479', '7ec29f01-9a06-554b-bfd3-1bb40f7350c3', N'Kỹ sư tự động hóa', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Tân Việt (Demo)
Vị trí: Kỹ sư tự động hóa
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư tự động hóa trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–20 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 14000000, 20000000, 0, 84),
    ('0c8d39ab-0ccf-5017-8bd1-7e2c67dd2d1e', '7ec29f01-9a06-554b-bfd3-1bb40f7350c3', N'Kỹ sư cơ khí', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Tân Việt (Demo)
Vị trí: Kỹ sư cơ khí
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư cơ khí trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 17000000, 24000000, 1, 84),
    ('ae726137-d451-585c-a2eb-df898683fa79', '7ec29f01-9a06-554b-bfd3-1bb40f7350c3', N'Kỹ sư kiểm soát chất lượng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Tân Việt (Demo)
Vị trí: Kỹ sư kiểm soát chất lượng
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư kiểm soát chất lượng trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 20000000, 28000000, 2, 84),
    ('327d271e-c8de-5828-8bfc-f114deb3e612', '7ec29f01-9a06-554b-bfd3-1bb40f7350c3', N'Kỹ sư bảo trì', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Tân Việt (Demo)
Vị trí: Kỹ sư bảo trì
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư bảo trì trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 23000000, 29000000, 3, 84),
    ('c33e092a-1616-5906-81a1-1aeba74576f3', '7ec29f01-9a06-554b-bfd3-1bb40f7350c3', N'Chuyên viên kế hoạch sản xuất', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Tân Việt (Demo)
Vị trí: Chuyên viên kế hoạch sản xuất
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kế hoạch sản xuất trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 26000000, 33000000, 4, 84),
    ('7f509d6a-cd6e-5e89-a2ee-3636eff9bb16', '16d99124-eff5-54cf-b295-d8a7b4f01a69', N'Giáo viên tiếng Anh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Tân Việt (Demo)
Vị trí: Giáo viên tiếng Anh
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Giáo viên tiếng Anh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 15000000, 21000000, 1, 85),
    ('e5e2c9e7-543d-5530-b0fb-485b528bb71b', '16d99124-eff5-54cf-b295-d8a7b4f01a69', N'Chuyên viên phát triển học liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Tân Việt (Demo)
Vị trí: Chuyên viên phát triển học liệu
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phát triển học liệu trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 18000000, 25000000, 2, 85),
    ('c095e9a0-cc31-5432-9782-47b6ef44d960', '16d99124-eff5-54cf-b295-d8a7b4f01a69', N'Chuyên viên tư vấn tuyển sinh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Tân Việt (Demo)
Vị trí: Chuyên viên tư vấn tuyển sinh
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn tuyển sinh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 21000000, 29000000, 3, 85),
    ('c59bed89-7d89-595a-a46b-540d6988067b', '16d99124-eff5-54cf-b295-d8a7b4f01a69', N'Điều phối viên đào tạo', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Tân Việt (Demo)
Vị trí: Điều phối viên đào tạo
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều phối viên đào tạo trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 24000000, 30000000, 4, 85),
    ('5936dc3d-73e7-55d7-b3cf-15f4eb500713', '16d99124-eff5-54cf-b295-d8a7b4f01a69', N'Chuyên viên công nghệ giáo dục', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Tân Việt (Demo)
Vị trí: Chuyên viên công nghệ giáo dục
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên công nghệ giáo dục trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 27000000, 34000000, 5, 85),
    ('dc0cd26f-84bd-5057-b498-c24f17f09de7', 'a50cb7d2-3dc3-554f-9495-e73298d1be2c', N'Điều dưỡng viên', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Tân Việt (Demo)
Vị trí: Điều dưỡng viên
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều dưỡng viên trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 16000000, 22000000, 2, 86),
    ('8aa1eeaf-71c0-5fdf-a725-e42c7c613317', 'a50cb7d2-3dc3-554f-9495-e73298d1be2c', N'Dược sĩ', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Tân Việt (Demo)
Vị trí: Dược sĩ
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Dược sĩ trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 19000000, 26000000, 3, 86),
    ('652fe61a-caf1-5484-b726-c0e96aacb6a3', 'a50cb7d2-3dc3-554f-9495-e73298d1be2c', N'Chuyên viên vận hành dịch vụ y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Tân Việt (Demo)
Vị trí: Chuyên viên vận hành dịch vụ y tế
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành dịch vụ y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 22000000, 30000000, 4, 86),
    ('82505da0-fbab-5fd5-a6c6-4cb8af89b4e4', 'a50cb7d2-3dc3-554f-9495-e73298d1be2c', N'Kỹ thuật viên xét nghiệm', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Tân Việt (Demo)
Vị trí: Kỹ thuật viên xét nghiệm
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ thuật viên xét nghiệm trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 25000000, 31000000, 5, 86),
    ('22bf776a-3bbf-58e2-ae98-78671340a09c', 'a50cb7d2-3dc3-554f-9495-e73298d1be2c', N'Chuyên viên chăm sóc khách hàng y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Tân Việt (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng y tế
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 28000000, 35000000, 6, 86),
    ('530244a3-6025-57e2-945d-599ddf83ce21', '4e2cd592-87bd-56c8-893b-318c85005b3f', N'Chuyên viên điều hành tour', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Tân Việt (Demo)
Vị trí: Chuyên viên điều hành tour
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều hành tour trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 17000000, 23000000, 3, 87),
    ('7195f893-a1c2-52e3-8a58-b662962a5ec6', '4e2cd592-87bd-56c8-893b-318c85005b3f', N'Nhân viên lễ tân', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Tân Việt (Demo)
Vị trí: Nhân viên lễ tân
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên lễ tân trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 20000000, 27000000, 4, 87),
    ('5da7c3ce-1744-51a6-a630-8ad1eea620e9', '4e2cd592-87bd-56c8-893b-318c85005b3f', N'Chuyên viên kinh doanh du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Tân Việt (Demo)
Vị trí: Chuyên viên kinh doanh du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kinh doanh du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 23000000, 31000000, 5, 87),
    ('be390824-5a62-55f5-a4e8-35edf2ffb3a8', '4e2cd592-87bd-56c8-893b-318c85005b3f', N'Quản lý dịch vụ khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Tân Việt (Demo)
Vị trí: Quản lý dịch vụ khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý dịch vụ khách hàng trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 26000000, 32000000, 6, 87),
    ('df12f7b6-823c-525e-b825-b82254a6f01b', '4e2cd592-87bd-56c8-893b-318c85005b3f', N'Chuyên viên marketing du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Tân Việt (Demo)
Vị trí: Chuyên viên marketing du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên marketing du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 29000000, 36000000, 7, 87),
    ('8e7d32f3-d747-5948-bd3b-a83823d88028', 'fc3cfce6-06a0-5453-ba31-dee1626da3cb', N'Kỹ sư xây dựng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Tân Việt (Demo)
Vị trí: Kỹ sư xây dựng
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư xây dựng trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 18000000, 24000000, 4, 88),
    ('7c37cf8f-89bf-5354-b5ad-d08043338172', 'fc3cfce6-06a0-5453-ba31-dee1626da3cb', N'Kiến trúc sư', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Tân Việt (Demo)
Vị trí: Kiến trúc sư
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kiến trúc sư trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 21000000, 28000000, 5, 88),
    ('b253f209-56c4-5a50-9a76-076aeea5e622', 'fc3cfce6-06a0-5453-ba31-dee1626da3cb', N'Chuyên viên quản lý dự án', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Tân Việt (Demo)
Vị trí: Chuyên viên quản lý dự án
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản lý dự án trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 24000000, 32000000, 6, 88),
    ('ce320782-b355-56e8-8afc-252396874564', 'fc3cfce6-06a0-5453-ba31-dee1626da3cb', N'Kỹ sư dự toán', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Tân Việt (Demo)
Vị trí: Kỹ sư dự toán
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư dự toán trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 27000000, 33000000, 7, 88),
    ('8da6ba99-4cb5-5c52-a112-59f9148e8c49', 'fc3cfce6-06a0-5453-ba31-dee1626da3cb', N'Chuyên viên tư vấn bất động sản', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Tân Việt (Demo)
Vị trí: Chuyên viên tư vấn bất động sản
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn bất động sản trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 30–37 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 30000000, 37000000, 8, 88),
    ('37da1e59-5740-51f9-a052-582e748e2cbf', 'b35c57ab-1da0-5df1-b038-34cb54aed01a', N'Graphic Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Tân Việt (Demo)
Vị trí: Graphic Designer
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Graphic Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 19000000, 25000000, 5, 89),
    ('62147ddf-2ead-56fe-807f-939b480c6292', 'b35c57ab-1da0-5df1-b038-34cb54aed01a', N'Content Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Tân Việt (Demo)
Vị trí: Content Marketing Specialist
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Content Marketing Specialist trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 22000000, 29000000, 6, 89),
    ('64438fcc-4547-50cc-b985-af6c4e6e6abe', 'b35c57ab-1da0-5df1-b038-34cb54aed01a', N'UI/UX Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Tân Việt (Demo)
Vị trí: UI/UX Designer
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí UI/UX Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 25000000, 33000000, 7, 89),
    ('c39b59c2-8593-54d4-90b2-c00f4501e2c6', 'b35c57ab-1da0-5df1-b038-34cb54aed01a', N'Chuyên viên truyền thông', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Tân Việt (Demo)
Vị trí: Chuyên viên truyền thông
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên truyền thông trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 28000000, 34000000, 8, 89),
    ('b6fa7020-9ee0-54f1-99ef-feafc6823caf', 'b35c57ab-1da0-5df1-b038-34cb54aed01a', N'Video Editor', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Tân Việt (Demo)
Vị trí: Video Editor
Địa điểm: Khu văn phòng Demo, Tỉnh Điện Biên
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Video Editor trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 31–38 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Điện Biên', 31000000, 38000000, 9, 89),
    ('7ae6af84-bb31-526c-8e33-0d13c31379fd', '4a0da68e-ebdf-5715-a2ee-a777a4c46b5f', N'Backend Developer (.NET)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Đông Phong (Demo)
Vị trí: Backend Developer (.NET)
Địa điểm: Khu văn phòng Demo, Tỉnh Thái Nguyên
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Backend Developer (.NET) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 11–17 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thái Nguyên', 11000000, 17000000, 6, 60),
    ('07ab8a21-c3ba-57bc-9b94-c646b607c054', '4a0da68e-ebdf-5715-a2ee-a777a4c46b5f', N'Frontend Developer (React)', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Đông Phong (Demo)
Vị trí: Frontend Developer (React)
Địa điểm: Khu văn phòng Demo, Tỉnh Thái Nguyên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Frontend Developer (React) trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thái Nguyên', 14000000, 21000000, 7, 60),
    ('06112ae3-5aca-538f-b6b6-7573f627bdc5', '4a0da68e-ebdf-5715-a2ee-a777a4c46b5f', N'DevOps Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Đông Phong (Demo)
Vị trí: DevOps Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh Thái Nguyên
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí DevOps Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thái Nguyên', 17000000, 25000000, 8, 60),
    ('d042ee86-1511-53cc-9931-65baa39286a7', '4a0da68e-ebdf-5715-a2ee-a777a4c46b5f', N'QA Automation Engineer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Đông Phong (Demo)
Vị trí: QA Automation Engineer
Địa điểm: Khu văn phòng Demo, Tỉnh Thái Nguyên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí QA Automation Engineer trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thái Nguyên', 20000000, 26000000, 9, 60),
    ('bb4f68f1-715d-50a6-b498-c8b21f7120ea', '4a0da68e-ebdf-5715-a2ee-a777a4c46b5f', N'Business Analyst', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Công nghệ Đông Phong (Demo)
Vị trí: Business Analyst
Địa điểm: Khu văn phòng Demo, Tỉnh Thái Nguyên
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Business Analyst trong lĩnh vực công nghệ thông tin.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Thái Nguyên', 23000000, 30000000, 10, 60),
    ('d5874ba1-c20a-54aa-8ec3-895b00cdf2f8', '8370ed33-18e7-5cb9-aea7-ca98c8db2313', N'Chuyên viên phân tích tài chính', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Đông Phong (Demo)
Vị trí: Chuyên viên phân tích tài chính
Địa điểm: Khu văn phòng Demo, Tỉnh Bắc Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích tài chính trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 12–18 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Bắc Ninh', 12000000, 18000000, 7, 61),
    ('def7a164-8646-5f6e-9a4f-3affeb1b4cc0', '8370ed33-18e7-5cb9-aea7-ca98c8db2313', N'Chuyên viên tín dụng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Đông Phong (Demo)
Vị trí: Chuyên viên tín dụng
Địa điểm: Khu văn phòng Demo, Tỉnh Bắc Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tín dụng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Bắc Ninh', 15000000, 22000000, 8, 61),
    ('14b5c4cd-de8b-5cf4-af39-74be8919ea90', '8370ed33-18e7-5cb9-aea7-ca98c8db2313', N'Chuyên viên quản trị rủi ro', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Đông Phong (Demo)
Vị trí: Chuyên viên quản trị rủi ro
Địa điểm: Khu văn phòng Demo, Tỉnh Bắc Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản trị rủi ro trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Bắc Ninh', 18000000, 26000000, 9, 61),
    ('71421148-890f-5bec-87de-f52e82a251e7', '8370ed33-18e7-5cb9-aea7-ca98c8db2313', N'Chuyên viên tư vấn khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Đông Phong (Demo)
Vị trí: Chuyên viên tư vấn khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Bắc Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn khách hàng trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Bắc Ninh', 21000000, 27000000, 10, 61),
    ('0ae69bf4-b098-56f2-93b7-d5e25eb7d783', '8370ed33-18e7-5cb9-aea7-ca98c8db2313', N'Kế toán tổng hợp', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Tài chính Đông Phong (Demo)
Vị trí: Kế toán tổng hợp
Địa điểm: Khu văn phòng Demo, Tỉnh Bắc Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kế toán tổng hợp trong lĩnh vực ngân hàng & tài chính.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Bắc Ninh', 24000000, 31000000, 11, 61),
    ('9b0acfd1-848c-5119-9e68-6fcee8d15341', '76841e48-1916-5c2e-a94a-dc98dee018a9', N'Chuyên viên vận hành sàn thương mại điện tử', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Đông Phong (Demo)
Vị trí: Chuyên viên vận hành sàn thương mại điện tử
Địa điểm: Khu văn phòng Demo, Tỉnh Hưng Yên
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành sàn thương mại điện tử trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 13–19 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Hưng Yên', 13000000, 19000000, 8, 62),
    ('8313a00b-5b45-50a3-9f9f-85a60b66d661', '76841e48-1916-5c2e-a94a-dc98dee018a9', N'Digital Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Đông Phong (Demo)
Vị trí: Digital Marketing Specialist
Địa điểm: Khu văn phòng Demo, Tỉnh Hưng Yên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Digital Marketing Specialist trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Hưng Yên', 16000000, 23000000, 9, 62),
    ('bd241d6f-0247-510e-9d09-311d297751c4', '76841e48-1916-5c2e-a94a-dc98dee018a9', N'Chuyên viên chăm sóc khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Đông Phong (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Hưng Yên
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Hưng Yên', 19000000, 27000000, 10, 62),
    ('e6a88c51-dfc3-5e7a-87fa-778a2ace2047', '76841e48-1916-5c2e-a94a-dc98dee018a9', N'Chuyên viên phân tích dữ liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Đông Phong (Demo)
Vị trí: Chuyên viên phân tích dữ liệu
Địa điểm: Khu văn phòng Demo, Tỉnh Hưng Yên
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phân tích dữ liệu trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Hưng Yên', 22000000, 28000000, 11, 62),
    ('ed544c7e-5ae3-59c9-a932-73672bf9e76b', '76841e48-1916-5c2e-a94a-dc98dee018a9', N'Quản lý ngành hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Thương mại Đông Phong (Demo)
Vị trí: Quản lý ngành hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Hưng Yên
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý ngành hàng trong lĩnh vực thương mại điện tử.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Hưng Yên', 25000000, 32000000, 12, 62),
    ('82069ad4-f2ad-58f9-983f-b14da046211a', '3f470166-5e17-59da-8b3e-3ae731ee7254', N'Chuyên viên điều phối vận tải', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Đông Phong (Demo)
Vị trí: Chuyên viên điều phối vận tải
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều phối vận tải trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 14–20 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 14000000, 20000000, 9, 63),
    ('98f5b53d-7169-5432-b017-3247176a56c6', '3f470166-5e17-59da-8b3e-3ae731ee7254', N'Chuyên viên xuất nhập khẩu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Đông Phong (Demo)
Vị trí: Chuyên viên xuất nhập khẩu
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên xuất nhập khẩu trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 17000000, 24000000, 10, 63),
    ('b610f068-fd24-5222-acbd-0bbacd265a1e', '3f470166-5e17-59da-8b3e-3ae731ee7254', N'Nhân viên quản lý kho', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Đông Phong (Demo)
Vị trí: Nhân viên quản lý kho
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên quản lý kho trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 20000000, 28000000, 11, 63),
    ('6c679f04-7989-5334-82b3-dad7d2ddb01f', '3f470166-5e17-59da-8b3e-3ae731ee7254', N'Chuyên viên mua hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Đông Phong (Demo)
Vị trí: Chuyên viên mua hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên mua hàng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 23000000, 29000000, 12, 63),
    ('42fcaae2-6152-5a69-ad66-0cc1736933cf', '3f470166-5e17-59da-8b3e-3ae731ee7254', N'Chuyên viên hoạch định chuỗi cung ứng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Logistics Đông Phong (Demo)
Vị trí: Chuyên viên hoạch định chuỗi cung ứng
Địa điểm: Khu văn phòng Demo, Tỉnh Nghệ An
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên hoạch định chuỗi cung ứng trong lĩnh vực logistics & chuỗi cung ứng.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Nghệ An', 26000000, 33000000, 13, 63),
    ('882dc3a4-b741-5acd-9b94-ba43a2cafd25', '5c8c91f5-50a3-553e-b9b5-760e0fa45762', N'Kỹ sư tự động hóa', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Đông Phong (Demo)
Vị trí: Kỹ sư tự động hóa
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư tự động hóa trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 15–21 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 15000000, 21000000, 10, 64),
    ('df55e26b-d0de-5e60-986b-c2a38c106a2b', '5c8c91f5-50a3-553e-b9b5-760e0fa45762', N'Kỹ sư cơ khí', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Đông Phong (Demo)
Vị trí: Kỹ sư cơ khí
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư cơ khí trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 18000000, 25000000, 11, 64),
    ('d413f24f-2266-5adb-9c72-f6739d2680f9', '5c8c91f5-50a3-553e-b9b5-760e0fa45762', N'Kỹ sư kiểm soát chất lượng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Đông Phong (Demo)
Vị trí: Kỹ sư kiểm soát chất lượng
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư kiểm soát chất lượng trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 21000000, 29000000, 12, 64),
    ('bb5878bb-aa8a-5abd-8d1f-051afb3a0f26', '5c8c91f5-50a3-553e-b9b5-760e0fa45762', N'Kỹ sư bảo trì', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Đông Phong (Demo)
Vị trí: Kỹ sư bảo trì
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư bảo trì trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 24000000, 30000000, 13, 64),
    ('4e7258f9-13e3-50a0-a070-4a82df4a06c8', '5c8c91f5-50a3-553e-b9b5-760e0fa45762', N'Chuyên viên kế hoạch sản xuất', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sản xuất Đông Phong (Demo)
Vị trí: Chuyên viên kế hoạch sản xuất
Địa điểm: Khu văn phòng Demo, Thành phố Huế
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kế hoạch sản xuất trong lĩnh vực sản xuất & kỹ thuật.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Huế', 27000000, 34000000, 14, 64),
    ('fa0cf739-4fdc-549e-9fbc-9853f0345d12', 'e22151d1-bc72-57b3-8b3a-ed22cc2c73e8', N'Giáo viên tiếng Anh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Đông Phong (Demo)
Vị trí: Giáo viên tiếng Anh
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Giáo viên tiếng Anh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 16–22 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 16000000, 22000000, 11, 65),
    ('6e6024c5-efb7-5b85-80e4-df4befaa8acb', 'e22151d1-bc72-57b3-8b3a-ed22cc2c73e8', N'Chuyên viên phát triển học liệu', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Đông Phong (Demo)
Vị trí: Chuyên viên phát triển học liệu
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên phát triển học liệu trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 19000000, 26000000, 12, 65),
    ('18d06632-ec27-5708-942f-a4d1231f1a5b', 'e22151d1-bc72-57b3-8b3a-ed22cc2c73e8', N'Chuyên viên tư vấn tuyển sinh', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Đông Phong (Demo)
Vị trí: Chuyên viên tư vấn tuyển sinh
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn tuyển sinh trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 22000000, 30000000, 13, 65),
    ('62b05a9d-7673-57ea-a1b8-4c47c294db67', 'e22151d1-bc72-57b3-8b3a-ed22cc2c73e8', N'Điều phối viên đào tạo', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Đông Phong (Demo)
Vị trí: Điều phối viên đào tạo
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều phối viên đào tạo trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 25000000, 31000000, 14, 65),
    ('df4c4b6b-d20b-52ef-a1da-b5dc6a0f7642', 'e22151d1-bc72-57b3-8b3a-ed22cc2c73e8', N'Chuyên viên công nghệ giáo dục', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Giáo dục Đông Phong (Demo)
Vị trí: Chuyên viên công nghệ giáo dục
Địa điểm: Khu văn phòng Demo, Tỉnh Gia Lai
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên công nghệ giáo dục trong lĩnh vực giáo dục & đào tạo.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Gia Lai', 28000000, 35000000, 15, 65),
    ('a6c9eefc-e282-5528-a6b7-067df91a729d', '48a22bc5-be81-531d-933d-557a40f16e85', N'Điều dưỡng viên', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Đông Phong (Demo)
Vị trí: Điều dưỡng viên
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Điều dưỡng viên trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 17–23 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 17000000, 23000000, 12, 66),
    ('189d0aa8-90f8-5db9-863a-09d0d87977d5', '48a22bc5-be81-531d-933d-557a40f16e85', N'Dược sĩ', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Đông Phong (Demo)
Vị trí: Dược sĩ
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Dược sĩ trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–27 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 20000000, 27000000, 13, 66),
    ('1f672a68-41dc-5ad2-a1dc-8249298388b7', '48a22bc5-be81-531d-933d-557a40f16e85', N'Chuyên viên vận hành dịch vụ y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Đông Phong (Demo)
Vị trí: Chuyên viên vận hành dịch vụ y tế
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên vận hành dịch vụ y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–31 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 23000000, 31000000, 14, 66),
    ('0f7e182f-a1b3-536d-be1e-9c065a0519eb', '48a22bc5-be81-531d-933d-557a40f16e85', N'Kỹ thuật viên xét nghiệm', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Đông Phong (Demo)
Vị trí: Kỹ thuật viên xét nghiệm
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ thuật viên xét nghiệm trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 26000000, 32000000, 15, 66),
    ('344c9407-a4ed-5d7d-84c6-d213584492bc', '48a22bc5-be81-531d-933d-557a40f16e85', N'Chuyên viên chăm sóc khách hàng y tế', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sức khỏe Đông Phong (Demo)
Vị trí: Chuyên viên chăm sóc khách hàng y tế
Địa điểm: Khu văn phòng Demo, Tỉnh Lâm Đồng
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên chăm sóc khách hàng y tế trong lĩnh vực y tế & chăm sóc sức khỏe.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–36 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Lâm Đồng', 29000000, 36000000, 16, 66),
    ('3905bbcc-d3fb-517a-99ed-a6f09c6e4b51', '73b886b4-db23-5559-b243-765b1bc1bdcf', N'Chuyên viên điều hành tour', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Đông Phong (Demo)
Vị trí: Chuyên viên điều hành tour
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên điều hành tour trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 18–24 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 18000000, 24000000, 13, 67),
    ('c8bb3ce8-2945-5427-bb60-6d69f7869c12', '73b886b4-db23-5559-b243-765b1bc1bdcf', N'Nhân viên lễ tân', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Đông Phong (Demo)
Vị trí: Nhân viên lễ tân
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Nhân viên lễ tân trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 21–28 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 21000000, 28000000, 14, 67),
    ('3a637963-f3f7-5c2b-8f3b-b196433fdce0', '73b886b4-db23-5559-b243-765b1bc1bdcf', N'Chuyên viên kinh doanh du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Đông Phong (Demo)
Vị trí: Chuyên viên kinh doanh du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên kinh doanh du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 24–32 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 24000000, 32000000, 15, 67),
    ('adeea550-53d0-5456-a4fe-277dadadb3d5', '73b886b4-db23-5559-b243-765b1bc1bdcf', N'Quản lý dịch vụ khách hàng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Đông Phong (Demo)
Vị trí: Quản lý dịch vụ khách hàng
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Quản lý dịch vụ khách hàng trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 27–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 27000000, 33000000, 16, 67),
    ('9014f353-8d76-5ecc-a711-0f7c7ddc239d', '73b886b4-db23-5559-b243-765b1bc1bdcf', N'Chuyên viên marketing du lịch', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Du lịch Đông Phong (Demo)
Vị trí: Chuyên viên marketing du lịch
Địa điểm: Khu văn phòng Demo, Tỉnh Tây Ninh
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên marketing du lịch trong lĩnh vực du lịch & khách sạn.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 30–37 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh Tây Ninh', 30000000, 37000000, 17, 67),
    ('18851499-5516-5893-b55d-4f3e60800cb4', '29691523-762c-5517-8dad-a455d88fd4ff', N'Kỹ sư xây dựng', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Đông Phong (Demo)
Vị trí: Kỹ sư xây dựng
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư xây dựng trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 19–25 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 19000000, 25000000, 0, 68),
    ('70a96d9d-7f4b-5f7d-8e0d-c0b921b38a29', '29691523-762c-5517-8dad-a455d88fd4ff', N'Kiến trúc sư', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Đông Phong (Demo)
Vị trí: Kiến trúc sư
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kiến trúc sư trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 22–29 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 22000000, 29000000, 1, 68),
    ('012b859f-977b-528e-87a6-cc8c6c9b4145', '29691523-762c-5517-8dad-a455d88fd4ff', N'Chuyên viên quản lý dự án', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Đông Phong (Demo)
Vị trí: Chuyên viên quản lý dự án
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên quản lý dự án trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 25–33 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 25000000, 33000000, 2, 68),
    ('0cb5f600-fd9a-5e7e-8048-50771dc1bd72', '29691523-762c-5517-8dad-a455d88fd4ff', N'Kỹ sư dự toán', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Đông Phong (Demo)
Vị trí: Kỹ sư dự toán
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Kỹ sư dự toán trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 28–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 28000000, 34000000, 3, 68),
    ('cc2ed3c0-1105-500f-a5dc-832dc32bea7a', '29691523-762c-5517-8dad-a455d88fd4ff', N'Chuyên viên tư vấn bất động sản', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Xây dựng Đông Phong (Demo)
Vị trí: Chuyên viên tư vấn bất động sản
Địa điểm: Khu văn phòng Demo, Tỉnh An Giang
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên tư vấn bất động sản trong lĩnh vực xây dựng & bất động sản.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 31–38 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Tỉnh An Giang', 31000000, 38000000, 4, 68),
    ('ad9b9453-1e50-503e-8957-077699a3aeab', '11674ab5-3cf2-550a-8311-c9c5ba1f60fa', N'Graphic Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Đông Phong (Demo)
Vị trí: Graphic Designer
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Graphic Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 20–26 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 20000000, 26000000, 1, 69),
    ('95a383b1-43cd-52b6-bc38-a99d42aba48b', '11674ab5-3cf2-550a-8311-c9c5ba1f60fa', N'Content Marketing Specialist', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Đông Phong (Demo)
Vị trí: Content Marketing Specialist
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Content Marketing Specialist trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 23–30 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 23000000, 30000000, 2, 69),
    ('dac3990d-a159-5903-92df-1354b5da62b6', '11674ab5-3cf2-550a-8311-c9c5ba1f60fa', N'UI/UX Designer', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Đông Phong (Demo)
Vị trí: UI/UX Designer
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí UI/UX Designer trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 3 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 26–34 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 26000000, 34000000, 3, 69),
    ('30ee921d-d583-5417-9628-92d0316d5457', '11674ab5-3cf2-550a-8311-c9c5ba1f60fa', N'Chuyên viên truyền thông', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Đông Phong (Demo)
Vị trí: Chuyên viên truyền thông
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Làm việc tại văn phòng · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Chuyên viên truyền thông trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 1 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 29–35 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 29000000, 35000000, 4, 69),
    ('072ab286-d0a1-563e-82aa-300fbe7e91c6', '11674ab5-3cf2-550a-8311-c9c5ba1f60fa', N'Video Editor', N'VỊ TRÍ DEMO — KHÔNG PHẢI TIN TUYỂN DỤNG THỰC TẾ

Doanh nghiệp: Công ty Sáng tạo Đông Phong (Demo)
Vị trí: Video Editor
Địa điểm: Khu văn phòng Demo, Thành phố Hà Nội
Hình thức: Hybrid · Toàn thời gian

MÔ TẢ CÔNG VIỆC
- Thực hiện các nhiệm vụ chuyên môn của vị trí Video Editor trong lĩnh vực truyền thông & thiết kế.
- Phối hợp với các bộ phận liên quan để triển khai dự án và cải tiến quy trình.
- Theo dõi chất lượng công việc, báo cáo kết quả và đề xuất giải pháp.

YÊU CẦU
- Kinh nghiệm từ 2 năm trong lĩnh vực liên quan.
- Có kỹ năng giao tiếp, làm việc nhóm và chủ động giải quyết vấn đề.
- Thành thạo các công cụ chuyên môn và có tinh thần học hỏi.

QUYỀN LỢI MINH HỌA
- Thu nhập 32–39 triệu VND/tháng tùy năng lực.
- Bảo hiểm theo quy định, nghỉ phép và hoạt động đào tạo nội bộ.
- Lộ trình phát triển nghề nghiệp và đánh giá hiệu quả định kỳ.

Đây là dữ liệu thử nghiệm. Không gửi hồ sơ hoặc thông tin cá nhân đến địa chỉ demo.', N'Thành phố Hà Nội', 32000000, 39000000, 5, 69);
    INSERT dbo.Jobs (Id, CompanyId, Title, Description, Location, SalaryMin, SalaryMax, CreatedAt, ExpiresAt, IsClosed)
    SELECT Id, CompanyId, Title, Description, Location, SalaryMin, SalaryMax, DATEADD(day, -AgeDays, @Now), DATEADD(day, ExpiryDays, @Now), 0
    FROM @Jobs seed WHERE NOT EXISTS (SELECT 1 FROM dbo.Jobs actual WHERE actual.Id = seed.Id);
    SET @AddedJobs = @@ROWCOUNT;

    IF (SELECT COUNT(*) FROM dbo.Companies c JOIN @Companies s ON c.Id = s.Id) <> 100 THROW 51002, 'Expected 100 seeded companies.', 1;
    IF (SELECT COUNT(*) FROM dbo.Jobs j JOIN @Jobs s ON j.Id = s.Id) <> 500 THROW 51003, 'Expected 500 seeded job posts.', 1;
    IF EXISTS (SELECT 1 FROM @Companies c LEFT JOIN dbo.Jobs j ON j.CompanyId = c.Id GROUP BY c.Id HAVING COUNT(j.Id) < 5)
        THROW 51004, 'Each demo company must have at least five jobs.', 1;
    COMMIT TRANSACTION;
    SELECT @AddedCompanies AS InsertedCompanies, @AddedJobs AS InsertedJobs,
        (SELECT COUNT(*) FROM dbo.Companies c JOIN @Companies s ON c.Id = s.Id) AS SeededCompanies,
        (SELECT COUNT(*) FROM dbo.Jobs j JOIN @Jobs s ON j.Id = s.Id) AS SeededJobs;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
