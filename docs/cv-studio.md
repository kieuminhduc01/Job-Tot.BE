# CV Studio

## Các màn hình

- `/cv-templates`: danh sách, tìm kiếm, lọc danh mục, sắp xếp và phân trang mẫu đã xuất bản.
- `/cv-templates/:id`: xem trước; “Dùng mẫu này” tạo một CV riêng theo tài khoản ứng viên.
- `/my-cvs`: danh sách CV online đã lưu, chỉnh sửa hoặc xóa.
- `/my-cvs/:id/edit`: sửa nội dung trực tiếp, màu, font, cỡ chữ, lề, ảnh PNG/JPG tối đa 200 KB, bố cục một cột/hai cột/sidebar/Bento; sắp xếp, ẩn, thêm và xóa mục. Tự lưu sau 900 ms ngừng nhập; các lần lưu được thực hiện tuần tự.
- `/admin/cv-templates`: đăng nhập quản trị và quản lý mẫu.
- `/admin/cv-templates/new`, `/admin/cv-templates/:id/edit`: thiết kế mẫu bằng cùng trình chỉnh sửa; lưu nháp, xuất bản hoặc ẩn.

Header, footer, breadcrumb và CareerResources dùng cùng component với trang danh sách công ty. Các lối vào Mẫu CV và Tạo CV Online đã dẫn tới tính năng thật.

## Database

Migration `20261004041652_AddOnlineCvStudio` thêm cấu hình vào `CvTemplate`, `OnlineDocumentJson` và `DocumentVersion` vào `CandidateCv`, cùng 9 mẫu khởi đầu có thể chỉnh sửa qua admin. Migration đã được áp dụng trên SQL Express cục bộ `Server=.\SQLEXPRESS;Database=JobTot` trong phiên triển khai.

Với database khác, kiểm tra đúng connection string rồi chạy từ `BE/JobTot`:

```powershell
dotnet ef database update --project src/JobTot.Infrastructure --startup-project src/JobTot.Api --configuration CvVerification --no-build
```

Khởi động lại API Debug đang chạy để nạp code mới. Không chạy thêm một API nền và không build đè cấu hình Debug đang chạy.

## Cấp tài khoản admin lần đầu

Tài khoản đã có `AccountType=Admin`, `AccountStatus=Active` và mật khẩu băm theo `AccountPasswordHasher` có thể đăng nhập. Không cho phép đăng ký công khai tự cấp quyền admin.

Nếu chưa có admin, sau khi build cấu hình CvVerification và áp dụng migration, chạy lệnh một lần sau. Lệnh hỏi email và mật khẩu; không có mật khẩu mặc định. Nó tạo tài khoản mới, từ chối nếu email đã tồn tại và kết thúc ngay, không mở API nền.

```powershell
$env:JOBTOT_ADMIN_EMAIL = Read-Host 'Email admin mới'
$adminSecurePassword = Read-Host 'Mật khẩu admin (ít nhất 12 ký tự)' -AsSecureString
$adminPasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminSecurePassword)
try {
    $env:JOBTOT_ADMIN_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($adminPasswordPointer)
    dotnet run --project src/JobTot.Api --configuration CvVerification --no-build -- --create-cv-admin
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($adminPasswordPointer)
    Remove-Item Env:JOBTOT_ADMIN_PASSWORD
    Remove-Item Env:JOBTOT_ADMIN_EMAIL
}
```

`dotnet run` ở đây chỉ chạy tác vụ cấp tài khoản rồi kết thúc trước `app.Run`, dùng appsettings/launch profile của dự án. Kiểm tra connection string cho đúng database trước khi chạy. Admin dùng token riêng trong sessionStorage, hiệu lực 2 giờ, khác audience/scheme với ứng viên; backend kiểm tra tài khoản, quyền và phiên còn hoạt động trên từng request. Đăng xuất thu hồi phiên.

## Lưu và xuất PDF

CV online lưu cấu trúc JSON, không nhận HTML tùy ý. Bộ dựng hiển thị văn bản qua React và kiểm tra layout, font, màu, kích thước, số mục và ảnh ở backend. CV ứng viên là bản sao độc lập; cập nhật/ẩn mẫu không làm thay đổi CV đã tạo.

Lưu dùng GUID phiên bản với EF concurrency token. Request mang phiên bản cũ nhận 409; giao diện giữ bản đang chỉnh sửa và yêu cầu tải bản mới nhất. Khi mất mạng/lưu lỗi, người dùng có thể thử lại; rời trang có thay đổi chưa lưu sẽ được nhắc.

“In / Lưu PDF” mở hộp thoại in của trình duyệt. Chọn **Save as PDF**, khổ A4 và tắt header/footer của trình duyệt. Đây là xuất PDF qua trình duyệt, không phải dịch vụ xuất PDF server. CSS in chỉ hiển thị CV, giữ font, màu, bố cục và lề đã chọn.

PDF upload cũ vẫn lưu trong `ContentJson` và tải qua API profile cũ. CV online dùng `OnlineDocumentJson` riêng; trang profile dẫn đến editor thay vì gọi tải PDF cũ. Khi ứng tuyển, có thể chọn CV online; hồ sơ ứng tuyển chụp lại JSON lúc nộp, không bị thay đổi khi ứng viên sửa hoặc xóa CV sau đó.

Không gán điểm ATS, lượt dùng, đánh giá hay thống kê giả. Chưa triển khai viết CV bằng AI hoặc nhập nội dung tự động từ PDF.

## Kiểm tra

```powershell
dotnet test tests/JobTot.Domain.Tests/JobTot.Domain.Tests.csproj -c CvVerification --no-restore --disable-build-servers -m:1 --filter "FullyQualifiedName~CvStudioTests|FullyQualifiedName~CandidateProfileTests|FullyQualifiedName~RequestCancellationTests"
```

Tại FE: `npm run check`, `npx playwright test tests/cv-studio.spec.js`.

Kiểm thử SQL chỉ đọc: đặt `JOBTOT_VERIFY_SQL=1`, chạy test `CvStudioReadsSeededTemplatesAndDocumentsOnMigratedSqlServer`. Test dùng host in-process được dispose; không khởi động API ngoài.
