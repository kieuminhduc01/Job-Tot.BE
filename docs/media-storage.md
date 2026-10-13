# Avatar trên backend

Ảnh avatar mới được ghi vào `src/JobTot.Api/wwwroot/uploads/avatars/{guid}.png`
(hoặc `.jpg`). `CandidateProfile.DetailsJson.AvatarUrl` chỉ lưu URL tương đối
`/uploads/avatars/{guid}.png`. API phục vụ công khai riêng thư mục avatar này.
Các thư mục khác không tự động được công khai.

Upload vẫn yêu cầu phiên ứng viên, kiểm tra định dạng PNG/JPG và giới hạn 2 MB.
Server tạo tên file, không dùng tên do trình duyệt cung cấp. Đổi/xóa avatar cập nhật
database trước, rồi xóa file avatar cũ theo đường dẫn đã kiểm tra.
Cancellation hoặc database failure được chuyển lên middleware; không trả thành công giả.
Nếu ghi database thất bại sau khi đã ghi file, file mới có thể còn lại (không xóa vì
transaction có thể đã commit trong thời điểm cancellation). Có thể cần dọn file không
còn được tham chiếu khi vận hành.

`Media:AvatarDirectory` cho phép cấu hình thư mục storage khác. Khi triển khai, thư mục
này cần được giữ qua các lần publish/redeploy và được backup cùng database.
Frontend dùng `VITE_API_BASE_URL` để tải ảnh từ backend khi hai ứng dụng khác origin;
Vite đã có proxy `/uploads/avatars` cho môi trường phát triển.

## Chuyển avatar cũ

Avatar Base64 cũ vẫn hiển thị được. Để chuyển ảnh cũ sang file backend, chạy lệnh một
lần sau khi sao lưu, trong thời gian không có thao tác sửa hồ sơ:

```powershell
dotnet run --project src/JobTot.Api --configuration MediaMigration -- --migrate-avatars
```

Lệnh đọc avatar PNG/JPG Base64 từ hồ sơ, ghi file và cập nhật URL, rồi thoát.
Có thể chạy lại: hồ sơ đã chuyển không bị xử lý thêm. Không cần migration schema.
Không build đè cấu hình Debug khi API đang chạy. Lệnh này chưa tự động chạy trên
database của người dùng.

PDF CV và ảnh nhúng trong CV online vẫn dùng cơ chế lưu hiện có. CV được tải qua
API có phân quyền; không đưa PDF CV vào thư mục public avatar. Chuyển các tài liệu
này sang file cần bảo toàn snapshot hồ sơ ứng tuyển và cơ chế kiểm tra quyền tải.

## Company logos and covers

Files: `src/JobTot.Api/wwwroot/uploads/companies/logos` and `covers`.
The API exposes `/uploads/companies/...`. `Media:CompanyDirectory` can override the storage root.
Persist and back up this directory across deployments; when overriding it, copy bundled seed SVGs there too.
Seed SVGs use stable UUID filenames; user uploads use random UUID filenames and PNG/JPEG extensions.
Upload endpoint: `POST /api/employer/company/images/logo` or `/cover`, multipart `file` and `revision`.
Requires employer authentication and the existing company edit permission. Company selection comes from membership.
Maximum 5 MB; PNG/JPEG MIME and signatures are checked. SVG upload is rejected; bundled SVGs are trusted assets.
The company media FK and brand URL are updated together in a transaction with revision conflict detection.
The profile PUT cannot assign an arbitrary logo/cover URL. Cancellation and database failures propagate normally.
Old media/files are retained because another record or snapshot may reference them. Failed writes may leave an
unreferenced file. Clean these only after checking database references and a retention interval.
The UI asks users to save pending profile edits before selecting an image.
Vite proxies `/uploads/companies`; deployed frontend resolves URLs using `VITE_API_BASE_URL`.
`SQL/seed-demo.sql` updates legacy company image URLs before inserting demo data, within the same transaction.
New `SQL/seed-demo.sql` already uses the new paths. No EF schema change is required.
