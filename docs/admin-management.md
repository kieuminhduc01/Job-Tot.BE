# Quản trị nền tảng

Mở frontend tại `/admin` (chuyển đến `/admin/companies`) và đăng nhập bằng tài khoản
`Admin`. Phiên admin dùng chung với quản lý mẫu CV tại `/admin/cv-templates`, tách
biệt với phiên ứng viên/nhà tuyển dụng, có thời hạn hai giờ và được kiểm tra ở mỗi API.

## Chức năng

- `/admin/companies`: tìm kiếm theo tên, tên pháp lý, mã số thuế/email; xem thông tin;
  đặt trạng thái xác minh Pending/Verified/Rejected; active/inactive công ty.
  Duyệt Verified yêu cầu tên pháp lý, mã số thuế, email và địa chỉ đã được điền.
  Đây là kiểm duyệt thủ công bởi admin, không kết nối hệ thống xác minh pháp lý bên ngoài.
- `/admin/users`: tìm kiếm theo tên/email/điện thoại; active/inactive tài khoản;
  đặt mật khẩu mới dài 12–128 ký tự bằng password hasher hiện có.
  Không trả password hash trong API danh sách. Đổi mật khẩu hoặc inactive người dùng
  thu hồi toàn bộ refresh session; kích hoạt lại không phục hồi session đã thu hồi.
  Admin không thể inactive chính tài khoản đang sử dụng. Đổi mật khẩu chính mình
  yêu cầu đăng nhập lại.
- `/admin/industries`: tạo, đổi tên và active/inactive nhóm ngành. Không xóa quan hệ
  công ty/campaign hiện có. Ngành inactive bị loại khỏi danh mục đang hoạt động.
  Tên được trim và kiểm tra trùng với nhóm ngành chưa bị xóa.

Các danh sách có tìm kiếm, lọc trạng thái và phân trang 20 dòng. Frontend có timer
startup cancellable, cleanup timer trước khi abort và bỏ qua kết quả request đã hủy,
để mỗi request ban đầu chạy một lần trong React StrictMode.

## API

Tất cả endpoint dưới đây yêu cầu `AdminAuthentication.Policy` và Bearer token admin.
Endpoint đăng nhập/đăng xuất hiện có ở `/api/admin/auth/login` và `/api/admin/auth/logout`.

| Method | Path | Nội dung |
| --- | --- | --- |
| GET | `/api/admin/auth/me` | Tài khoản admin hiện tại |
| GET | `/api/admin/companies` | Danh sách công ty |
| PUT | `/api/admin/companies/{id}/verification` | `{ "verificationStatus": "Verified" }` |
| PUT | `/api/admin/companies/{id}/status` | `{ "active": false }` |
| GET | `/api/admin/users` | Danh sách tài khoản |
| PUT | `/api/admin/users/{id}/password` | `{ "password": "mật khẩu mới" }` |
| PUT | `/api/admin/users/{id}/status` | `{ "active": false }` |
| GET | `/api/admin/industries` | Danh sách nhóm ngành |
| POST | `/api/admin/industries` | `{ "name": "Tên nhóm ngành" }` |
| PUT | `/api/admin/industries/{id}` | `{ "name": "Tên mới" }` |
| PUT | `/api/admin/industries/{id}/status` | `{ "active": false }` |

Query danh sách: `page` (1–1.000.000), `size` (1–100), `keyword` (tối đa 200 ký tự),
`status` (Active/Inactive). Response: `{ items, total, page, size }`.
Mọi cập nhật ghi UpdatedAccountId/UpdatedDate. Inactive công ty ẩn công ty và việc làm
khỏi các API công khai và làm membership của nhà tuyển dụng không còn hoạt động.
Không thay schema, không cần migration cho các chức năng này.

## Cấp tài khoản admin đầu tiên

Dùng tài khoản admin hiện có, hoặc đặt `JOBTOT_ADMIN_EMAIL` và `JOBTOT_ADMIN_PASSWORD`
(tối thiểu 12 ký tự) trong môi trường của một tiến trình provisioning riêng:

```powershell
dotnet run --project src/JobTot.Api --configuration AdminProvisioning -- --create-admin
```

Lệnh chạy một lần rồi thoát, không khởi chạy web server. Alias cũ `--create-cv-admin`
vẫn dùng được. Lệnh từ chối nếu email đã tồn tại; không nâng quyền tài khoản có sẵn.
Không dùng password mặc định hoặc ghi password vào mã nguồn. Không build đè Debug
khi API do người dùng chạy còn hoạt động.

## Kiểm thử

```powershell
dotnet test tests/JobTot.Domain.Tests/JobTot.Domain.Tests.csproj --configuration AdminVerification --no-restore --filter FullyQualifiedName~AdminManagementTests
```

Frontend: `npm run check` và `npm run test:e2e -- tests/admin.spec.js tests/cv-studio.spec.js`.
HTTP tests dùng EF InMemory để kiểm tra quyền, persistence, invalidation session và
cancellation; không thay thế kiểm thử integration SQL Server.
