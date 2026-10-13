# TaskCanceledException khi debug backend

## Try/catch tại repository, service và controller

Các hàm trong repository, service, controller, token service và password recovery
được bọc `try/catch`. Hàm trả Task trực tiếp được chuyển sang `async/await` để
catch bao phủ cả lỗi xảy ra sau khi bắt đầu tác vụ bất đồng bộ.

- `OperationCanceledException` (bao gồm `TaskCanceledException`) được chuyển tiếp bằng
  `throw;`. Middleware chỉ xử lý như client disconnect khi `RequestAborted` đã hủy.
- Các exception khác được thêm tên lớp/hàm vào `Exception.Data["JobTot.Operations"]`
  rồi chuyển tiếp bằng `throw;`, giữ nguyên exception và stack trace. Handler ghi
  chuỗi thao tác vào log lỗi 500 một lần ở biên HTTP; không ghi mật khẩu/token vào metadata.
- Các catch chuyên biệt sẵn có cho concurrency, refresh-token replay và lỗi nghiệp vụ
  vẫn được giữ nguyên trong logic của hàm.

Try/catch không ngăn Visual Studio dừng trước catch khi bật Break When Thrown.
Không trả null, danh sách rỗng hay Unauthorized chỉ vì truy vấn bị hủy hoặc database lỗi.
Xem phần Exception Settings bên dưới để điều chỉnh điểm dừng debugger.

## Hồ sơ ứng viên: CandidateProfileRepository.GetAsync → CandidateProfileController.Get

GET `/api/candidate/profile` giữ CancellationToken đến truy vấn EF. Effect tải hồ sơ
đã hoãn khởi động bằng timer zero-delay, hủy timer trước khi abort và bỏ qua kết quả
của request đã hủy. Test frontend kiểm tra mỗi lần mở trang chỉ gửi một GET trong StrictMode.

Frontend dùng `readResponseJson` để đọc response trong các module API: chỉ bỏ qua
SyntaxError của body rỗng/không phải JSON; AbortError và lỗi kết nối tiếp tục được ném.
Không dùng `.json().catch(() => null)` vì nó có thể biến request bị hủy thành kết quả rỗng.

Nếu Visual Studio dừng tại `BufferedDataReader.InitializeAsync`, kiểm tra
`HttpContext.RequestAborted.IsCancellationRequested` ở controller/middleware và nhấn F5.
Nếu token đã hủy, middleware xử lý ngắt kết nối; debugger vẫn có thể dừng trước catch.
Thiết lập Exception Settings ở phần dưới áp dụng cho tất cả endpoint có cùng hiện tượng.

## Avatar và thông báo: AccountHeaderController.Get

Request header hiện thuộc provider của phiên đăng nhập, tồn tại qua chuyển trang.
Chuyển giữa các trang dùng header không còn hủy rồi tải lại request header đang chạy.
Polling vẫn giới hạn một request đang chạy; đăng xuất, đổi tài khoản hoặc đóng ứng dụng
vẫn hủy request đúng cách. Timer startup được hủy trước AbortController trong cleanup.

TaskCanceledException tại truy vấn avatar không giống lỗi sai mật khẩu hoặc đăng ký trùng:
EF dùng exception để báo truy vấn đang bị hủy. Middleware chung đã bắt nó khi RequestAborted
được hủy; không cần catch riêng từng controller và không được trả hồ sơ rỗng thay thế.
Debugger first-chance dừng trước middleware catch. Cần thiết lập Exception Settings như
phần dưới; sửa code không thể ngăn debugger dừng trước catch của EF.

## Bộ lọc doanh nghiệp: MetadataAsync → CompaniesController.Filters

API `/api/companies/filters` giữ CancellationToken từ request đến từng truy vấn EF.
Phần thống kê đã giảm từ bốn truy vấn xuống hai; truy vấn không bắt cancellation để trả dữ liệu rỗng.
Kiểm thử bao phủ dữ liệu thực, database rỗng và token đã bị hủy.

Các effect tải danh sách theo dõi doanh nghiệp và khôi phục phiên đăng nhập dùng timer
zero-delay có cleanup trước khi abort. Vì vậy StrictMode không gửi request đầu hai lần.
ESLint có quy tắc `request-lifecycle/safe-fetch-effect` kiểm tra mẫu cleanup của các effect gọi API;
chạy `npm run check` và `npm run test:request-lifecycle` trong FE để kiểm tra khi sửa code.

Không thể bảo đảm một request không bao giờ bị hủy: chuyển trang, đóng tab hoặc mất kết nối
đều là lý do hợp lệ. Mục tiêu là không gửi request thừa và xử lý đúng cancellation,
không biến nó thành lỗi 500, cũng không che lỗi database khác. Cách tắt debugger dừng
trước catch được mô tả trong phần Visual Studio bên dưới.

Khi Vite tải lại một trang hoặc cập nhật component, React chạy cleanup của effect.
Frontend gọi `AbortController.abort()` để hủy request cũ. API nhận `RequestAborted` và
truyền CancellationToken vào EF Core. Nếu SQL đang mở kết nối hoặc đọc dữ liệu,
EF/SqlClient có thể ném TaskCanceledException hoặc OperationCanceledException.

`RequestCancellationMiddleware` trong pipeline bắt cancellation khi
`HttpContext.RequestAborted.IsCancellationRequested` là true, trả trạng thái 499
khi response chưa bắt đầu và không ghi JSON vào kết nối đã đóng.
Các cancellation không đến từ việc client ngắt kết nối vẫn được chuyển tiếp để điều tra.

## Hủy request trong xác thực JWT

`OnTokenValidated` bắt OperationCanceledException (bao gồm TaskCanceledException) chỉ khi
RequestAborted đã bị hủy, rồi trả NoResult. Một chốt cancellation sau UseAuthentication
dừng pipeline trước UseAuthorization để không phát sinh challenge 401 hay chạy controller
trên kết nối đã đóng. Middleware cũng bỏ qua request đã hủy trước khi bắt đầu xử lý.

ValidateAsync dùng một truy vấn lấy PasswordStamp/PasswordHash và kiểm tra phiên đăng nhập,
tài khoản, vai trò và trạng thái hồ sơ. Không tải DetailsJson/avatar để xác thực JWT.
GetAsync của repository xác thực cũng chỉ lấy các trường tài khoản cần thiết và ID/trạng thái hồ sơ.
Không cache phiên đăng nhập: logout, đổi mật khẩu, khóa tài khoản vẫn có hiệu lực ở request kế tiếp.

Stack trace cancellation tự nó không chứng minh SQL timeout. Nếu RequestAborted là false,
exception vẫn được chuyển tiếp; cần log và trạng thái request để xác định nguyên nhân.

Nếu stack trace vẫn hiện `CandidateTokens.ValidateAsync → CandidateAuthService.GetActiveAsync`,
phiên chạy chưa khớp code hiện tại: `ValidateAsync` đã truy vấn trực tiếp các trường xác thực,
không gọi `GetActiveAsync`. Dừng phiên Debug bằng Visual Studio, build lại rồi F5 để nạp
assembly/PDB mới. Không build đè executable Debug khi API còn chạy.

## Visual Studio dừng ở Exception Helper

Debugger có thể dừng trước khi catch chạy, dù ứng dụng có middleware xử lý.
.NET 9 cũng hỗ trợ dừng tại ranh giới async khi exception được chuyển về framework.
Nếu F5 cho phép ứng dụng tiếp tục và request mới vẫn tải dữ liệu bình thường:

1. Mở **Debug → Windows → Exception Settings** (`Ctrl+Alt+E`).
2. Tìm `System.Threading.Tasks.TaskCanceledException` và `System.OperationCanceledException`.
   Nếu chưa có mục riêng, dùng nút **+** để thêm đúng tên vào Common Language Runtime Exceptions.
3. Bỏ **Break When Thrown** cho hai loại exception này.
4. Nếu vẫn dừng vì **user-unhandled**, chọn **Continue When Unhandled in User Code**
   trong menu chuột phải của từng exception. Exception Helper cũng có tùy chọn
   **Break when this exception type is user-unhandled**; bỏ chọn nó cho loại cancellation đó.

Cấu hình này nằm trong thiết lập Visual Studio của solution, không thuộc appsettings hay launchSettings.

Tài liệu Microsoft:
- [Manage exceptions with the debugger](https://learn.microsoft.com/en-us/visualstudio/debugger/managing-exceptions-with-the-debugger?view=vs-2022)
- [Async user-unhandled exceptions in .NET 9](https://devblogs.microsoft.com/visualstudio/break-for-async-user-unhandled-exceptions-in-the-visual-studio-debugger/)

## API thực sự thất bại

### Dashboard my-jobs: CandidateJobsRepository.Candidate → DashboardAsync

Stack trace ở truy vấn `SingleOrDefaultAsync` cũng có thể là client hủy request
trong lúc EF đang đọc dữ liệu. Kiểm tra `HttpContext.RequestAborted.IsCancellationRequested`
khi debugger dừng: true là nhánh middleware xử lý 499; false cần điều tra lỗi thực.
Nhấn F5 để middleware chạy tiếp; catch không ngăn debugger dừng ở first-chance.

Dashboard chỉ truy vấn ID ứng viên trước khi tải hồ sơ, tránh đọc DetailsJson/avatar
hai lần. Frontend lấy avatar từ dashboard (backend dùng cùng profile repository
với trang profile), không gửi thêm GET profile. Effect dashboard vẫn dùng timer
có cleanup và AbortController để StrictMode không khởi chạy request đầu hai lần.
Điều hướng, reload hoặc HMR vẫn có thể hủy request hợp lệ; không bỏ cancellation token.

Nếu request mới vẫn trả 500/timeout sau khi nhấn F5, hoặc RequestAborted chưa bị hủy,
đây không chỉ là thiết lập debugger. Kiểm tra request trong Network và log API/SQL
để xác định lỗi kết nối, timeout hoặc cancellation token khác.
Không loại CancellationToken khỏi truy vấn và không chuyển tất cả cancellation thành kết quả rỗng.

Kiểm tra middleware mà không build lại hoặc khởi chạy thêm backend:

```powershell
dotnet test tests/JobTot.Domain.Tests/JobTot.Domain.Tests.csproj --configuration ProvinceVerification --no-restore --filter "FullyQualifiedName~RequestCancellationTests|FullyQualifiedName~JwtCancellationTests|FullyQualifiedName~CandidateAuthTests"
```
