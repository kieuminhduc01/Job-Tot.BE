# Danh sách việc làm

Trang `/jobs` sử dụng API thật, gồm tìm kiếm, bộ lọc và phân trang 6 tin/trang.
Header, footer, kho CV, cẩm nang và tiện ích sử dụng cùng component với `/companies`.

## API

- `GET /api/jobs`: `keyword`, `provinceId`, `industryId`, `companyId`, `verifiedOnly`, `salaryBand`,
  `experienceLevels`, `positionLevels`, `employmentTypes`, `jobIds`, `page`, `pageSize`.
  Mảng dùng khóa lặp lại: `experienceLevels=none&experienceLevels=1-3`.
- `GET /api/jobs/filters`: tổng tin/doanh nghiệp và các lựa chọn bộ lọc kèm số lượng từ database.
- `GET /api/jobs/{id}`: chi tiết và mô tả việc làm.
- `POST /api/jobs`, `PUT /api/jobs/{id}`: lưu cả các trường mở rộng bên dưới.

Kết quả danh sách trả `items`, `totalCount`, `page`, `pageSize`. Chỉ mặc định lấy tin chưa đóng,
chưa hết hạn từ doanh nghiệp đang hoạt động. Sắp xếp ngày đăng giảm dần rồi ID để phân trang ổn định.
Tìm kiếm từ khóa trên tiêu đề, mô tả và tên doanh nghiệp. Ngành nghề bao gồm ngành chính và ngành phụ.
Các lựa chọn trong cùng một nhóm được kết hợp OR; các nhóm được kết hợp AND.

Địa điểm chọn từ danh mục `Province` đang hoạt động qua `/api/companies/filters`.
Dropdown gửi `provinceId` (GUID), backend lọc trực tiếp `Jobs.ProvinceId`, không dùng chuỗi địa chỉ
và không dùng tỉnh/thành trụ sở công ty để suy đoán nơi làm việc. Link cũ có `location=<tên tỉnh>`
được frontend chuyển sang ID danh mục; API vẫn hỗ trợ tên chính xác/tên bỏ tiền tố để tương thích.
Khi tạo/cập nhật tin có địa chỉ quận/huyện chi tiết, gửi `provinceId` riêng cùng `location` hiển thị.
Province không tồn tại hoặc không hoạt động bị từ chối khi ghi tin.

Mức lương tháng: `under-10`, `10-15`, `15-20`, `20-30`, `over-30`, `negotiable`.
Lọc theo khoảng giao nhau với mức lương tin đăng; một tin có khoảng rộng có thể xuất hiện trong nhiều nhóm.
Tin lương theo giờ/ngày không được tính vào nhóm lương tháng. Thỏa thuận là cả hai mức lương đều null.
Số lượng cạnh bộ lọc là số tin đang mở trong toàn bộ danh mục, không phụ thuộc bộ lọc hiện chọn.

Các trường mở rộng:

| Trường | Giá trị |
| --- | --- |
| `provinceId` | GUID trong bảng `Province`, hoặc null nếu tin cũ chưa xác định tỉnh/thành |
| `experienceLevel` | `none`, `under-1`, `1-3`, `3-5`, `over-5`, hoặc null |
| `positionLevel` | `intern`, `employee`, `supervisor`, `manager`, `director`, hoặc null |
| `employmentType` | `full-time`, `part-time`, `internship`, `remote`, `flexible`, hoặc null |
| `salaryPeriod` | `monthly` (mặc định), `daily`, `hourly` |
| `workSchedule` | Văn bản tối đa 200 ký tự |
| `salaryNote` | Phụ chú lương tối đa 200 ký tự, ví dụ `Tips` |
| `benefits` | Văn bản tối đa 1000 ký tự, các thẻ ngăn cách bằng `\|` |

DTO danh sách bổ sung tên/logo doanh nghiệp, trạng thái xác thực, ngành nghề và các trường trên.
Tin cũ giữ các trường kinh nghiệm/cấp bậc/hình thức null để không tự suy đoán thông tin.
Lỗi tham số trả 400; lỗi tải trên frontend có nút thử lại. Bộ lọc được lưu trong URL và giữ khi tải lại trang.

## Migration và dữ liệu phát triển

```powershell
dotnet ef database update --project src/JobTot.Infrastructure --startup-project src/JobTot.Api
sqlcmd -S '.\SQLEXPRESS' -d JobTot -E -C -b -f 65001 -i scripts/seed-job-directory-details.sql
```

Migration `AddJobDirectoryDetails` bổ sung cột và mặc định lương tháng, không xóa dữ liệu cũ.
Migration `AddJobProvince` bổ sung khóa ngoại tới `Province`, chỉ gán tin cũ khi địa điểm
khớp đúng một tên tỉnh/thành đang hoạt động. Địa chỉ chưa xác định được giữ null.
Migration `BackfillJobProvinceAliases` nhận thêm tên rút gọn (Hà Nội, TP. Hồ Chí Minh...),
chỉ liên kết khi tìm được duy nhất một tỉnh/thành đang hoạt động trong danh mục.
Seed tùy chọn chỉ bổ sung thông tin còn trống cho 500 tin Demo đã có, dựa trên ID cố định và nội dung demo.
Không thay đổi lương, mô tả, ngày hết hạn hoặc thông tin đã chỉnh sửa. Generator chung tạo lại seed này.

Lưu việc làm dùng API theo tài khoản ứng viên; khách dùng localStorage. `/saved-jobs` chuyển tới
tab đã lưu của `/my-jobs`. Xem [Việc làm của tôi](my-jobs.md) cho API và nguồn số liệu.
Nút tiêu đề mở mô tả. Luồng nộp hồ sơ của nút “Ứng tuyển ngay” vẫn sử dụng thông báo dịch vụ hiện có,
chưa triển khai xử lý hồ sơ ứng tuyển trong phạm vi trang danh sách.
