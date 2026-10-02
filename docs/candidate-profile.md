# Hồ sơ cá nhân ứng viên

Frontend: `/profile`. Unauthenticated visitors are redirected to `/login`. The page only loads the signed-in candidate’s data.

Áp dụng migration từ thư mục `BE/JobTot`:

```powershell
dotnet ef database update --project src/JobTot.Infrastructure --startup-project src/JobTot.Api
```

| Phương thức | URL | Chức năng |
| --- | --- | --- |
| GET | `/api/candidate/profile` | Đọc hồ sơ và danh sách CV |
| PUT | `/api/candidate/profile` | Lưu hồ sơ, kinh nghiệm, kỹ năng, học vấn, chứng chỉ, dự án, tiêu chí tìm việc |
| POST | `/api/candidate/profile/cvs` | Upload PDF qua multipart field `file`, tối đa 5 MB |
| GET | `/api/candidate/profile/cvs/{id}` | Tải CV thuộc tài khoản hiện tại |

All endpoints require `Authorization: Bearer <accessToken>` and the CandidateOnly policy. The account ID comes from the validated JWT; the client cannot select another account. No CSRF header is required. PUT nhận đầy đủ document (không phải PATCH); trả về hồ sơ sau khi lưu. Các trường lương dùng VND/tháng, `birthDate` dạng `yyyy-MM-dd` hoặc null, `readyStatus` là `looking`, `considering`, `paused`.

Danh sách `experiences`, `skills`, `education`, `certificates`, `projects` gồm các object với `title`, `organization`, `period`, `description`, `tags` (chuỗi công nghệ phân cách dấu phẩy). Email/số điện thoại lấy từ tài khoản, không chỉnh sửa qua API hồ sơ.

Thông tin bổ sung lưu trong `CandidateProfile.DetailsJson`; các trường hiện có (headline, summary, birthDate, salary, readyStatus) đồng bộ khi lưu. CV lưu base64 trong `CandidateCv.ContentJson`, phù hợp bản triển khai ban đầu; có thể chuyển sang object storage khi lượng CV lớn. CV mới nhất được đánh dấu chính. Không phục vụ CV bằng URL public.

Ảnh bài viết sử dụng vùng ảnh của thiết kế tham chiếu. Cẩm nang/công cụ tái sử dụng thông báo tính năng hiện có. Điểm ATS, lượt xem và lời mời chỉ xuất hiện dưới dạng dữ liệu mẫu; tài khoản thực không được hiển thị số liệu giả. Chưa có tích hợp phân tích ATS, thống kê lượt xem, xác minh chứng chỉ hoặc thay ảnh đại diện.
