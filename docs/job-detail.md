# Chi tiết việc làm dành cho ứng viên

Trang `/jobs/:id` đọc `GET /api/jobs/{id}` và thông tin doanh nghiệp từ API danh sách công ty.
Tiêu đề và nút ứng tuyển trên trang chủ, danh sách việc làm và chi tiết công ty dẫn tới trang này.
`#job-application` cuộn tới form ứng tuyển; chuyển sang vị trí khác cuộn lên đầu trang.
Header, footer và ba phần tài nguyên dùng nguyên component chung với trang danh sách công ty.

## Nội dung tuyển dụng

`POST /api/jobs` và `PUT /api/jobs/{id}` nhận thêm:

- `requirements`: yêu cầu ứng viên, mỗi ý một dòng (tối đa 10.000 ký tự).
- `hiringProcess`: mỗi vòng một dòng, định dạng `Tiêu đề|Mô tả` (tối đa 4.000 ký tự).
- `vacancies`: số lượng tuyển (1–10.000).
- `genderRequirement`, `ageRequirement`: thông tin do nhà tuyển dụng cung cấp.
- `recruiterName`, `recruiterTitle`, `recruiterEmail`: người phụ trách tuyển dụng; email được kiểm tra định dạng.

Phúc lợi tiếp tục dùng `benefits`, phân cách bằng `|` hoặc xuống dòng. Nội dung thiếu được thông báo
là chưa cập nhật, không tự thêm thông tin HR, tuổi, giới tính hoặc quy trình cho tin thực tế.

## Ứng tuyển

- `GET /api/candidate/jobs/{id}/application`: trạng thái hồ sơ đã gửi của người đăng nhập, null/204 nếu chưa gửi.
- `POST /api/candidate/jobs/{id}/application`: `{ cvId, fullName, phone, coverLetter }`.
- Cả hai endpoint yêu cầu bearer token theo policy ứng viên hiện có.
- Danh sách CV lấy từ `GET /api/candidate/profile`; tải PDF mới dùng `POST /api/candidate/profile/cvs`.
  Giữ giới hạn PDF tối đa 5 MB và kiểm tra nội dung PDF của API hồ sơ.
- CV phải thuộc ứng viên, đang hoạt động và có nội dung. Tin phải chưa đóng, chưa hết hạn, công ty đang hoạt động.
- Mỗi ứng viên gửi một hồ sơ cho một tin; unique index chặn cả gửi trùng đồng thời, trả 409.
- `CandidateJobSubmissions` liên kết trực tiếp `Jobs`, ứng viên và CV; lưu bản sao nội dung CV tại thời điểm gửi,
  họ tên, điện thoại, thư giới thiệu, thời điểm và trạng thái `submitted`. API phản hồi không chứa nội dung CV.
- Đăng nhập/đăng ký từ form quay lại vị trí đang ứng tuyển; đường dẫn quay lại chỉ chấp nhận trang chi tiết việc làm nội bộ.
- Chức năng liên hệ HR mở email nếu nhà tuyển dụng cung cấp email; không giả lập chat hoặc gửi email tự động.

## Database và kiểm tra

Áp dụng migration `AddCandidateJobDetailsAndSubmissions` bằng `dotnet ef database update`.
Seed tùy chọn `scripts/seed-job-candidate-details.sql` chỉ điền trường còn trống trên 500 tin Demo gốc.
Yêu cầu được trích từ mô tả Demo; quy trình minh họa có nhãn Demo. Không sửa hồ sơ đã gửi.
Generator `scripts/generate-company-directory-seed.py` tạo lại seed.

Kiểm thử backend bao gồm nội dung chi tiết, CV người khác, dữ liệu không hợp lệ, tin đóng/hết hạn,
tin của công ty ngừng hoạt động, hồ sơ trùng và trạng thái sau khi gửi.
`JOBTOT_VERIFY_SQL=1` bật kiểm thử đọc API qua SQL Server phát triển bằng WebApplicationFactory,
không khởi chạy tiến trình API riêng.
Frontend: `npx playwright test tests/job-detail.spec.js tests/jobs.spec.js tests/home.spec.js`.
