# JobTot – API tuyển dụng

Code base ASP.NET Core 9, Entity Framework Core 9, SQL Server và LINQ theo Clean Architecture.

## Cấu trúc và chiều phụ thuộc

```text
src/
  JobTot.Domain/           Entity, quy tắc nghiệp vụ; không phụ thuộc framework
  JobTot.Application/      Use case, DTO, validation, interface repository → Domain
  JobTot.Infrastructure/   EF Core, SQL Server, LINQ, migration → Application
  JobTot.Api/              Controller, DI, HTTP, xử lý lỗi → Application + Infrastructure
tests/
  JobTot.Domain.Tests/     Kiểm tra quy tắc nghiệp vụ
```

Controller gọi `RecruitmentService`; service sử dụng `IRecruitmentRepository`.
Infrastructure thực thi interface bằng EF Core. LINQ được dịch sang SQL trước khi phân trang;
truy vấn danh sách dùng `AsNoTracking` và projection DTO. Không đưa `IQueryable` ra khỏi Infrastructure.
DbContext quản lý transaction cho mỗi `SaveChangesAsync`; không bọc thêm generic repository/Unit of Work.

## Chạy trên máy

Yêu cầu .NET SDK 9 và SQL Server hoặc SQL Server LocalDB. Cấu hình mặc định dùng
`(localdb)\MSSQLLocalDB`, database `JobTot`, Windows Authentication.

```powershell
dotnet restore
dotnet tool restore
dotnet ef database update --project src/JobTot.Infrastructure --startup-project src/JobTot.Api
dotnet run --project src/JobTot.Api --launch-profile https
```

Xem cổng trong `src/JobTot.Api/Properties/launchSettings.json` hoặc log lúc chạy.
Swagger UI: `https://localhost:7026/swagger` với profile https, hoặc
`http://localhost:5049/swagger` với profile http. Chọn endpoint rồi nhấn **Try it out** để thử API.
Swagger UI chỉ bật trong Development.
Trong Development, HTTP không tự chuyển sang HTTPS để Swagger và OpenAPI luôn cùng origin.
Ngoài Development, ứng dụng vẫn bật chuyển hướng HTTPS.
OpenAPI JSON: `/openapi/v1.json` (Development). Import URL này vào Postman hoặc dùng file
`src/JobTot.Api/JobTot.Api.http`.
`/health` chỉ kiểm tra ứng dụng đang chạy, không kiểm tra kết nối database.

Nếu dùng SQL Server riêng, đặt connection string qua biến môi trường trước khi chạy migration/API:

```powershell
$env:ConnectionStrings__SqlServer = 'Server=localhost;Database=JobTot;Trusted_Connection=True;Encrypt=True;TrustServerCertificate=True'
```

`TrustServerCertificate=True` phục vụ local development. Khi triển khai, dùng chứng chỉ hợp lệ,
`TrustServerCertificate=False` và secret store/biến môi trường; không commit mật khẩu database.
Ứng dụng không tự động chạy migration khi khởi động.

## API hiện có

| Method | Endpoint | Chức năng |
|---|---|---|
| GET | `/api/companies?page=1&pageSize=20` | Danh sách công ty |
| GET | `/api/companies/{id}` | Chi tiết công ty |
| POST | `/api/companies` | Tạo công ty |
| GET | `/api/jobs?keyword=developer&location=Hanoi&page=1&pageSize=20` | Tìm tin tuyển dụng |
| GET | `/api/jobs/{id}` | Chi tiết tin |
| POST | `/api/jobs` | Tạo tin cho công ty có sẵn |
| PUT | `/api/jobs/{id}` | Cập nhật tin |
| POST | `/api/jobs/{id}/close` | Đóng tin, không xóa lịch sử |

Danh sách tin mặc định loại tin đã đóng/hết hạn. `includeClosed=true` bao gồm cả hai nhóm;
`companyId` lọc theo công ty. `pageSize` tối đa 100. Danh sách sắp xếp mới nhất trước, có khóa
phụ ID để phân trang ổn định. Tìm kiếm phân biệt hoa/thường và dấu theo collation SQL Server.
Lương mặc định theo VND/tháng, cho phép null khi thỏa thuận. Thời gian dùng `DateTimeOffset`.
Tin đã đóng không được chỉnh sửa. SQL Server rowversion phát hiện cập nhật đồng thời trong
mỗi request; chưa có ETag để phát hiện dữ liệu cũ từ client giữa nhiều request.

Lỗi trả về Problem Details: 400 dữ liệu sai, 404 không tồn tại, 409 xung đột, 500 lỗi hệ thống
(không trả stack trace). Lỗi validation trường dữ liệu có `errors`.

## Kiểm tra và thay đổi schema

Đã kiểm tra khi tạo code base: build thành công không cảnh báo; 5 domain test thành công;
HTTP `/health` trả 200, OpenAPI xuất đủ endpoint, dữ liệu sai/phân trang sai trả 400.
Chưa áp dụng migration hoặc kiểm tra truy vấn trên SQL Server thật trong môi trường này.

```powershell
dotnet build
dotnet test
dotnet ef migrations add TenThayDoi --project src/JobTot.Infrastructure --startup-project src/JobTot.Api --output-dir Persistence/Migrations
dotnet ef migrations script --idempotent --project src/JobTot.Infrastructure --startup-project src/JobTot.Api --output migration.sql
```

## Phạm vi và bước phát triển tiếp

Đây là nền tảng chạy local, chưa phải hệ thống tuyển dụng hoàn chỉnh. Chưa có đăng nhập,
phân quyền hoặc kiểm tra quyền sở hữu công ty: hiện mọi người gọi API đều có thể tạo/sửa/đóng tin.
Cần bổ sung ASP.NET Core Identity/JWT, vai trò Admin/Employer/Candidate và quyền sở hữu
trước khi mở API ra Internet. Các module ứng viên, CV, ứng tuyển, email và upload file chưa triển khai.

Chọn .NET 9 để phù hợp SDK đang có trên máy. .NET 9 hết hỗ trợ ngày 10/11/2026;
nên nâng lên .NET 10 LTS trước khi triển khai dài hạn (cập nhật SDK, TargetFramework, EF Core,
OpenAPI và dotnet-ef cùng major, rồi kiểm tra lại migration).
Tham khảo: https://dotnet.microsoft.com/en-us/platform/support/policy
"# Job-Tot.BE" 
