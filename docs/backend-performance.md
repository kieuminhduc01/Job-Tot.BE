# Tối ưu hiệu năng backend — 15/10/2026

Đã rà soát các repository, service, controller, xác thực, cấu hình EF Core và model/index
trong BE. Các thay đổi tập trung vào số lượt gọi SQL, lượng dữ liệu được đọc, truy vấn
phân trang và CPU khi tính mức phù hợp ứng viên. Không thay đổi hợp đồng JSON của API.

## Những chỗ đã sửa

| Luồng | Nguyên nhân | Thay đổi |
| --- | --- | --- |
| Bộ lọc việc làm | 11 SELECT nối tiếp để tính các bộ đếm trên cùng tập việc làm | Một aggregation có điều kiện và một bộ đếm công ty: còn 2 SELECT |
| Dashboard ứng viên | Tải hoạt động hồ sơ không sử dụng; mỗi badge chạy một SELECT; hydration gọi lại API tìm kiếm kèm COUNT | Dùng hồ sơ tóm tắt; gộp 5 badge vào một SELECT; lấy chi tiết từ danh sách ID đã phân trang và dùng dictionary để giữ thứ tự |
| Hồ sơ/CV | Include toàn bộ CV, cả file base64 và tài liệu JSON khi chỉ cần metadata | SELECT riêng ID, tiêu đề, cờ mặc định và trạng thái online; tải nội dung chỉ khi thực sự đọc/tải CV |
| Chọn CV mặc định/tải CV lên | Đọc lại file của các CV cũ để đổi cờ | Projection metadata và concurrency version, chỉ UPDATE cờ; giải phóng CV mặc định cũ trước INSERT trong transaction |
| Lượt xem hồ sơ | Tải tất cả lượt xem rồi Distinct/Take trong RAM | COUNT riêng, GROUP BY công ty, MAX thời gian và TOP(5) tại SQL |
| Danh bạ công ty | Tải toàn bộ tiêu đề tuyển dụng của công ty trong trang rồi chỉ hiển thị 3 | Hai ROW_NUMBER tại SQL, chỉ trả tối đa 3 tiêu đề khác nhau/công ty; parameter hóa ID qua OPENJSON |
| Metadata công ty | Tải một dòng mỗi công ty tuyển dụng chỉ để đếm/tính tổng | Aggregate trả một dòng; bỏ truy vấn phụ khi trang kết quả rỗng |
| Nhà tuyển dụng | Tải toàn bộ Company cho kiểm tra membership; import tải cả CV snapshot | Chỉ SELECT trường cần dùng; import bỏ payload CV |
| Chiến dịch/ứng viên | Include nhiều collection làm nhân số dòng và lặp JSON lớn | Split query tại các luồng cần thiết; GET dùng AsNoTracking và chỉ lấy skill đang hoạt động |
| Thống kê chiến dịch | 4 SELECT cho tổng ứng tuyển và đã tuyển | 2 aggregation có điều kiện |
| Khám phá ứng viên | Chuẩn hóa cùng kỹ năng/chức danh cho từng cặp; sort toàn bộ chiến dịch để lấy một kết quả | Chuẩn bị dữ liệu chuẩn hóa theo request; duyệt lấy kết quả tốt nhất; lọc keyword một lần mỗi hồ sơ |
| Header/chat | Tải Company, logo và cover đầy đủ; đếm unread bằng DISTINCT qua mọi message | Projection trường cần dùng; chọn recruiter đầu tiên mỗi tài khoản tại SQL; đếm conversation bằng EXISTS |
| Logging | Ghi console mỗi lệnh SQL ở mức Information | Mặc định category `Microsoft.EntityFrameworkCore.Database.Command` là Warning |

Thứ tự tiêu đề công ty vẫn là `CreatedAt DESC, Id ASC`. Việc loại tiêu đề trùng giữ
so sánh ordinal của .NET bằng binary collation và DATALENGTH, bao gồm khác hoa/thường,
Unicode và khoảng trắng cuối. Truy vấn raw SQL này chỉ dùng cho SQL Server, cùng provider
của ứng dụng. Các giá trị ID được truyền bằng parameter.

Các truy vấn dùng cho cập nhật vẫn giữ tracking. Kiểm tra quyền truy cập và điều kiện
ẩn thông tin liên hệ của ứng viên trong talent pool được giữ nguyên. Không cache hồ sơ
hoặc kết quả phân quyền giữa các request.

## Index

Migration: `20261015011931_AddReadQueryPerformanceIndexes`.

| Bảng | Khóa index theo thứ tự |
| --- | --- |
| CandidateJobSubmissions | CandidateId, AppliedAt DESC, Id; INCLUDE JobId, Status, ReviewedAt, CvTitle |
| CandidateSavedJobs | CandidateId, SavedAt DESC, JobId |
| Application | CandidateId, Status, AppliedAt DESC, Id; INCLUDE CampaignId, ApplicationStatus |
| Application | CampaignId, Status, AppliedAt DESC, Id; INCLUDE CandidateId, ApplicationStatus, Source |
| RecruitmentCampaign | CompanyId, Status, CreatedDate DESC, Id; INCLUDE CampaignStatus |
| RecruiterProfile | AccountId, Status, JoinedAt, Id; INCLUDE CompanyId |
| Jobs | CompanyId, IsClosed, CreatedAt DESC, Id; INCLUDE ExpiresAt, Title |

Sáu index đơn có cùng cột đầu được thay bằng index ghép tương ứng. Không đưa file CV,
DetailsJson hoặc mô tả dài vào INCLUDE. Index cần thêm dung lượng và công việc khi ghi;
nên tiếp tục kiểm tra execution plan và index usage với tải thực tế.

Đã áp dụng migration vào `.\SQLEXPRESS`, database `JobTot` cục bộ. Với môi trường khác:

```powershell
dotnet ef database update AddReadQueryPerformanceIndexes `
  --project src/JobTot.Infrastructure --startup-project src/JobTot.Api --configuration Release
```

Hoàn tác riêng migration này về phiên bản trước (khôi phục 6 index đơn):

```powershell
dotnet ef database update 20261013003007_AddAccountEmailChallenges `
  --project src/JobTot.Infrastructure --startup-project src/JobTot.Api --configuration Release
```

## Kết quả kiểm chứng cục bộ

Database hiện có khoảng 1.003 jobs, 1.003 campaigns, 4.003 applications, 4.003 submissions,
4.001 saved jobs và 503 candidate profiles. Các con số dưới đây là số đo trên dữ liệu
cục bộ, không phải cam kết latency hoặc khả năng chịu tải cho production.

| Kiểm tra | Trước | Sau |
| --- | ---: | ---: |
| Bộ lọc việc làm: lượt SELECT | 11 | 2 |
| Bộ lọc việc làm: trung vị 5 lần đo sau warm-up, cùng database sau khi áp dụng index | 22,14 ms | 8,64 ms |
| Hồ sơ dùng cho dashboard: lượt SELECT | 5 | 2 |
| Việc đã lưu: logical reads của truy vấn trang đại diện | 18 | 2 |
| Hồ sơ ứng tuyển: logical reads của truy vấn trang đại diện | 26 | 2 |
| Chiến dịch: logical reads của truy vấn trang đại diện | 22 | 2 |
| Matching: 20.000 cặp ứng viên/chiến dịch giả lập, chỉ phần CPU | 244 ms | 18 ms |

Ba phép đo logical reads dùng cùng truy vấn và cùng dữ liệu; fingerprint kết quả trước/sau
giống nhau. Migration đã được chạy thử trong transaction và rollback toàn bộ trước khi
áp dụng chính thức. Không dùng physical reads để so tốc độ vì trạng thái cache khác nhau.

Đã kiểm tra:

- Build Release thành công, 0 warning và 0 error.
- 195 assertion với SQL Server thật: số bộ lọc so với thuật toán cũ, trường hợp rỗng,
  phân trang, 5 tab dashboard trên 3 ứng viên, CV metadata, avatar/header và tiêu đề công ty.
- 58 lượt gọi controller đọc thành công: campaign, candidate/talent, discovery,
  header và chat; có serialize response để thực thi các projection trì hoãn.
- 20.000 cặp matching cho cùng điểm, lý do và danh sách kỹ năng với thuật toán cũ.
- Chọn CV mặc định và upload trong transaction bắt buộc rollback: hash tài liệu,
  version và dữ liệu lưu sau kiểm tra không đổi; giữ đúng một CV mặc định khi upload.
- EF model khớp migration snapshot; script migration chạy được trên SQL Server.

Các harness kiểm chứng được giữ ngoài repository tại thư mục `.verification` và
`.tmp-jobtot-performance` của workspace, không đưa lại bộ test đã xóa vào source BE.
Đây là kiểm tra hồi quy và đo cục bộ; chưa chạy load test nhiều người dùng đồng thời.

## Những giới hạn cần tiếp tục đo khi dữ liệu tăng

- Talent discovery vẫn cần xét toàn bộ hồ sơ được phép hiển thị để giữ đúng xếp hạng
  và thống kê toàn cục. Muốn giảm tiếp I/O cần lưu các trường summary/skill đã chuẩn hóa
  thành dữ liệu truy vấn được hoặc thiết kế lại phần tìm kiếm; không thêm Take tùy ý
  trước khi tính điểm vì sẽ mất kết quả.
- Tìm kiếm `Contains` trên mô tả/tên thường không tận dụng được B-tree để tìm substring.
  Chỉ thêm index không giải quyết được mọi truy vấn này. Cần đánh giá full-text search
  cùng yêu cầu tiếng Việt và ngữ nghĩa tìm kiếm trước khi thay đổi.
- Các API vẫn hỗ trợ số trang theo OFFSET để tương thích frontend. Trang rất sâu sẽ
  tốn chi phí; nếu tải thực tế tập trung vào lịch sử dài, cân nhắc cursor pagination.
- Hồ sơ cũ chứa avatar base64 và các tài liệu JSON lớn vẫn có thể gây I/O đáng kể tại
  nơi cần đọc đầy đủ. Có sẵn luồng migration avatar riêng; đợt này không tự chuyển file.

Để xem SQL trong thời gian chẩn đoán, tạm đặt
`Logging__LogLevel__Microsoft.EntityFrameworkCore.Database.Command=Information`.
Ghi lại số request, số SELECT, p50/p95 và logical reads; tắt log chi tiết sau khi đo.
Hướng dẫn nền: [EF Core efficient querying](https://learn.microsoft.com/en-us/ef/core/performance/efficient-querying)
và [performance diagnosis](https://learn.microsoft.com/en-us/ef/core/performance/performance-diagnosis).
