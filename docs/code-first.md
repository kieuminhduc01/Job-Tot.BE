# Database code first theo ERD JobTot

Model nằm trong `src/JobTot.Domain/Entities`, cấu hình EF Core nằm trong
`src/JobTot.Infrastructure/Persistence/ErdModelConfiguration.cs`. `RecruitmentDbContext`
đã đăng ký tất cả 32 entity trong ERD. Migration `AddErdModels` nối tiếp `InitialCreate`.

## Tạo database

Chạy từ thư mục gốc repository, sau khi cấu hình SQL Server:

```powershell
$env:ConnectionStrings__SqlServer = 'Server=(localdb)\MSSQLLocalDB;Database=JobTot;Trusted_Connection=True;TrustServerCertificate=True'
dotnet tool restore
dotnet ef database update --project src/JobTot.Infrastructure --startup-project src/JobTot.Api
```

Database mới sẽ được tạo và áp dụng cả hai migration. Với database đã chạy
`InitialCreate`, EF chỉ áp dụng migration còn thiếu. Không dùng `EnsureCreated`
chung với migrations. Không xóa migration cũ trên database đã triển khai.

Sau khi thay đổi model:

```powershell
dotnet ef migrations add TenThayDoi --project src/JobTot.Infrastructure --startup-project src/JobTot.Api --output-dir Persistence/Migrations
dotnet ef migrations script --idempotent --project src/JobTot.Infrastructure --startup-project src/JobTot.Api --output migration.sql
dotnet ef database update --project src/JobTot.Infrastructure --startup-project src/JobTot.Api
```

## Quy ước và giả định

ERD chỉ ghi tên cột và PK/FK; không chỉ định kiểu dữ liệu, nullable, độ dài hay
giá trị trạng thái. Các lựa chọn sau là giả định triển khai, có thể điều chỉnh:

- PK/FK dùng `Guid` / SQL `uniqueidentifier`; PK khởi tạo trong C#.
- Ngày sinh và ngày bắt đầu/kết thúc dùng `DateOnly?`; thời điểm dùng
  `DateTimeOffset`, lưu UTC theo quy ước của ứng dụng.
- Lương và điểm dùng `decimal(18,2)`. Cờ dùng `bool`; số lượng dùng `int`.
- Trạng thái nghiệp vụ, loại tài khoản, loại media dùng chuỗi, chưa áp đặt enum
  vì ERD chưa định nghĩa đầy đủ các giá trị hợp lệ. Media.Type dự kiến Image/Video.
- `Status` audit dùng enum `EntityStatus`: `Active = 1`, `Inactive = 2`, `Deleted = 3`; mặc định `Active`. EF Core lưu dưới dạng `int`, giữ nguyên schema database. Chưa có cơ chế soft delete/query filter.
- Chuỗi thông thường dài tối đa 200; email 320, điện thoại 32, URL 2048,
  password hash 1024, provider subject 256; nội dung dài dùng `nvarchar(max)`.
- Trường mô tả và tùy chọn cho phép null. Company.IndustryId và
  HeadOfficeProvinceId cho phép null để hỗ trợ công ty hiện có và API cũ.
  LogoFileId, CoverFileId, CandidateProfile.ProvinceId, CandidateCv.CvTemplateId,
  Application.CvId và StageId cũng cho phép null. Các FK nghiệp vụ còn lại bắt buộc.
- CreatedAccountId và UpdatedAccountId là FK nullable đến Account, bao gồm
  chính bảng Account, để có thể tạo tài khoản đầu tiên hoặc bản ghi hệ thống.
  CreatedDate khởi tạo UTC và có SQL default. Tầng nghiệp vụ phải gán người
  thực hiện, UpdatedDate và UpdatedAccountId khi cập nhật; chưa tích hợp đăng nhập.
- Tất cả FK mới dùng NoAction. Phải xử lý bản ghi phụ trước khi xóa bản ghi cha.

## Quan hệ và điểm cần phân biệt

- Account–CandidateProfile là 1–0..1. Account–RecruiterProfile là 1–n theo ERD.
  Các FK nghiệp vụ có navigation hai chiều; FK audit có navigation về Account.
- Các bảng nối vẫn có Id riêng theo ERD, kèm unique index trên cặp FK:
  CandidateSkill, CampaignSkill, CampaignBenefit, CompanyIndustry, CompanyMedia,
  TalentPoolTag, SavedJob và FollowedCompany.
- ExternalLogin có unique Provider + ProviderSubject; Account.Email là unique.
  Mỗi ứng viên có tối đa một CandidateCv.IsDefault = true, bằng filtered unique index.
- Giữ cả Company.IndustryId (ngành chính) và CompanyIndustry (danh sách ngành)
  vì ERD có cả hai. Tầng nghiệp vụ quyết định quy tắc đồng bộ hai trường hợp này.
- Bổ sung FK từ các cột có trong ERD dù đường nối bị thiếu: Company.IndustryId,
  RecruitmentCampaign.IndustryId, InterviewFeedback.RecruiterId.
  LogoFileId/CoverFileId được giả định tham chiếu Media. CvTemplate.CategoryId
  tham chiếu CvCategory; CompanyMedia.MediaId tham chiếu Media.
- Entity C# `JobApplication` ánh xạ bảng `Application`, tránh trùng tên namespace
  `JobTot.Application`.
- Giữ bảng `Companies` và `Jobs` để tương thích API hiện có. Company.Name ánh xạ
  cột DisplayName; Company.Description ánh xạ cột About. Migration đổi tên cột,
  giữ dữ liệu. DisplayName/About trên C# là alias NotMapped; trong truy vấn LINQ
  dùng Name/Description. About vẫn giới hạn 4000 ký tự như API cũ.
- `Jobs` là model cũ, không đồng bộ tự động với `RecruitmentCampaign`. Database
  cuối cùng có 33 bảng nghiệp vụ: 32 bảng ERD và Jobs. Endpoint hiện tại vẫn dùng
  Jobs; API cho các module ERD mới chưa thuộc phần triển khai model này.
- FK kiểm tra bản ghi tham chiếu tồn tại. Những quy tắc như CV phải thuộc ứng viên,
  stage phải thuộc campaign, recruiter phải thuộc công ty và khoảng lương/ngày
  hợp lệ cần validation nghiệp vụ bổ sung.

## Kiểm tra

`dotnet test` kiểm tra các quy tắc JobPost hiện có và metadata của toàn bộ ERD:
PK, FK audit, không có FK ngầm, NoAction, quan hệ một-một, unique index bảng nối
và khả năng sinh SQL Server DDL. Kiểm tra này không kết nối SQL Server.
