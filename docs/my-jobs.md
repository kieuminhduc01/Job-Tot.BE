# Việc làm của tôi

Frontend: `/my-jobs` mặc định mở tab đã lưu; `/saved-jobs` chuyển tới `/my-jobs?tab=saved`.
Các tab: `saved`, `applied`, `companies`, `interviews`, `hired`. `companies` là “NTD Quan Tâm bạn”,
giữ URL cũ để liên kết đang có vẫn hoạt động. Frontend lấy 6 mục/trang cho tab này,
4 mục/trang cho tab `applied` và `hired`, 3 mục/trang cho `saved` và `interviews`.
Header, footer, kho CV, cẩm nang và tiện ích dùng nguyên các component chung của trang công ty.

## API yêu cầu tài khoản ứng viên

- `GET /api/candidate/saved-jobs`: ID việc làm đã lưu của tài khoản hiện tại.
- `PUT /api/candidate/saved-jobs/{jobId}`: lưu; idempotent, kể cả hai lần lưu đồng thời.
- `DELETE /api/candidate/saved-jobs/{jobId}`: bỏ lưu; idempotent.
- `GET /api/candidate/my-jobs?tab=saved&page=1&pageSize=3`: hồ sơ, số liệu, dữ liệu tab,
  hạn nộp và việc làm gợi ý. PageSize giới hạn 1–50; page >= 1; chỉ chấp nhận năm tab trên.
- `PUT /api/candidate/my-jobs/status`: `{ readyStatus: "looking"|"considering"|"paused" }`,
  đồng bộ trạng thái vào CandidateProfile và JSON hồ sơ. Dashboard trả `readyStatus`;
  `openToWork` chỉ đúng khi trạng thái là `looking`.
- `PUT /api/candidate/my-jobs/availability` giữ tương thích: `{ openToWork: true|false }`, đồng bộ trạng thái
  `looking`/`paused` vào CandidateProfile và JSON hồ sơ.
- `PUT /api/candidate/interviews/{id}/confirm`: xác nhận lịch của chính ứng viên, lưu
  `InterviewStatus = confirmed`; gọi lại không thay đổi dữ liệu. Trả 404 cho lịch người khác,
  409 nếu lịch đã hủy, kết thúc hoặc không còn chờ xác nhận. CancellationToken được truyền đến EF.

## Nguồn dữ liệu

- Bảng mới `CandidateSavedJobs` liên kết trực tiếp ứng viên và `Jobs`, unique index trên CandidateId/JobId.
  Bảng `SavedJob` cũ liên kết RecruitmentCampaign được giữ nguyên vì hai loại ID khác nhau.
- Ứng tuyển đọc từ `CandidateJobSubmissions` và `Application` của chiến dịch tuyển dụng; số hồ sơ đã xem đếm `ReviewedAt` khác null.
  `ReviewedAt` dành cho luồng nhà tuyển dụng cập nhật khi xem hồ sơ; không tự tăng số lượt xem.
  Tab `applied` trả `applications` với ID, tên CV snapshot, HR liên hệ và `progress`
  (`currentStep`, `label`, `completed`, `stopped`), cùng danh sách `jobs` theo đúng thứ tự
  ngày nộp giảm dần. Phân trang và lọc theo tài khoản diễn ra tại database; tin đóng/hết hạn
  vẫn được giữ trong lịch sử, công ty ngừng hoạt động bị loại khỏi danh sách.
  Trạng thái thống nhất: Mới ứng tuyển (1), Đang phỏng vấn (2), Đã gửi offer (3),
  Đã nhận việc (4), Không phù hợp (5). ReviewedAt không tự chuyển trạng thái xử lý.
  Nhận việc và không phù hợp là hai kết quả riêng; nhận việc không tô sáng không phù hợp.
  Tab `hired` lọc trạng thái hired/Hired từ cả hai nguồn; `stats.hired` đếm số đã nhận việc.
  Hồ sơ chiến dịch đọc trực tiếp ApplicationStatus để phản ánh thay đổi của nhà tuyển dụng.
  ID chiến dịch khác ID Jobs; `applications.detailUrl` dẫn tới công ty cho hồ sơ chiến dịch.
  withdrawn/cancelled/canceled vẫn giữ thông tin rút hoặc hủy hồ sơ.
  `accepted` không đồng nghĩa đã nhận việc. Tải tab không ghi ReviewedAt hay thay đổi trạng thái.
  `nextInterview` là lịch sắp bắt đầu gần nhất của chính ứng viên, không phụ thuộc trang
  danh sách ứng tuyển; loại lịch đã hủy/kết thúc và dữ liệu công ty/chiến dịch ngừng hoạt động.
  Jobs và RecruitmentCampaign có ID độc lập, nên không ghép lịch vào đơn ứng tuyển bằng
  tên công ty/tên vị trí và không dùng lịch khác để tự nâng bước phỏng vấn.
  Giao diện có 4 thẻ/trang, thanh tiến trình, email HR (hoặc liên kết chi tiết khi thiếu email),
  sidebar lịch gần nhất và gợi ý việc làm. Cẩm nang/tiện ích dùng component chung.
- NTD quan tâm đọc từ `EmployerCandidateInterest` của chính ứng viên, do nhà tuyển dụng
  bấm Quan tâm trong trang tìm nhân tài. Một mục ứng với một công ty; bỏ quan tâm sẽ xóa mục.
  Sắp xếp theo `InterestedAt` mới nhất, phân trang tại database, loại công ty ngừng hoạt động.
  Thẻ ghi nhà tuyển dụng quan tâm hồ sơ, HR thực hiện thao tác và thời điểm quan tâm.
  Không suy diễn vị trí tuyển dụng vì thao tác quan tâm không gắn với một việc cụ thể.
  `ReviewedAt` chỉ dùng cho số hồ sơ đã xem, không dùng để đưa công ty vào tab này.
- Lịch phỏng vấn đọc từ `Interview` của hồ sơ chiến dịch thuộc ứng viên, chưa kết thúc, chưa hủy.
  Bổ sung thông tin công ty, vòng phỏng vấn và HR phụ trách chiến dịch; nội dung chuẩn bị
  lấy từ yêu cầu tuyển dụng, không suy diễn HR phụ trách thành hội đồng phỏng vấn.
  Thẻ đã xác nhận trong 24 giờ tới có dải cam và đếm ngược, thẻ chờ xác nhận có hành động
  ghi vào API, thẻ trực tiếp hiển thị địa điểm. Liên kết trực tuyến chỉ chấp nhận HTTP/HTTPS;
  nhắn HR mở email khi có email liên hệ.
  CalendarMonth (`YYYY-MM`) và TimeZoneOffsetMinutes cho phép lấy `interviewCalendar`
  của cả tháng, gồm lịch ngoài trang hiện tại. InterviewDate (`YYYY-MM-DD`) lọc danh sách
  theo ngày trong múi giờ client; số lịch trên tab vẫn là tổng lịch sắp tới.
  Lịch chỉ đánh dấu những buổi thực được trả về, không tạo mốc hẹn mẫu. Tháng không có
  lịch vẫn hiển thị lưới ngày. Tải lịch dùng cùng effect timer/AbortController với dashboard.
  Mỗi Interview hiện có một khung giờ; chưa có bảng khung giờ thay thế, hạn phản hồi,
  ghi chú riêng hoặc danh sách hội đồng. Giao diện dùng khung giờ thực để xác nhận.
- Hạn nộp đọc từ tin đã lưu còn tuyển trong 7 ngày tới, sắp xếp hạn gần nhất.
- Gợi ý lấy tin đang tuyển theo ProvinceId ưu tiên của hồ sơ (hoặc tỉnh/thành địa chỉ nếu chưa có ưu tiên).
  Nếu chưa chọn địa điểm thì lấy các tin mới nhất. Không gọi dịch vụ AI hoặc giả lập số liệu AI.
- Không hiển thị tin thuộc công ty ngừng hoạt động. Tin đã lưu đóng/hết hạn vẫn có thể xem và bỏ lưu,
  nút ứng tuyển đổi thành liên kết xem chi tiết.

## Frontend

Cụm “TRẠNG THÁI TÌM VIỆC” được chuyển từ `/profile` sang `/my-jobs`, thay công tắc
“Bật tìm việc chủ động”, với ba lựa chọn Tìm việc, Cân nhắc, Tạm khóa.

Provider lưu việc làm dùng chung ở cấp ứng dụng, đồng bộ bookmark giữa trang chủ, danh sách,
chi tiết và trang cá nhân. Đã đăng nhập dùng API theo tài khoản; khách tiếp tục lưu tạm localStorage.
Danh sách guest không được tự gán vào bất kỳ tài khoản nào khi đăng nhập. Trang cá nhân yêu cầu đăng nhập.
Toast thành công chỉ hiện sau khi mutation API thành công; thất bại giữ nguyên dữ liệu.
Request GET dùng timer/AbortController để tránh request trùng dưới StrictMode.
Quá trình chuyển tài khoản không hiển thị ID đã lưu của tài khoản trước.

Áp dụng migration `AddCandidateSavedJobs` trước khi chạy backend mới.
Kiểm thử: CandidateJobsTests; SqlJobDetailTests với `JOBTOT_VERIFY_SQL=1`;
frontend `tests/my-jobs.spec.js` và hồi quy các màn hình dùng bookmark.
