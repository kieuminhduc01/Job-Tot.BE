# Đăng ký và đăng nhập ứng viên

Backend cung cấp API cho hai form đăng ký/đăng nhập. Repository này chưa có mã frontend.
Đăng nhập Google, LinkedIn, Facebook và quên mật khẩu chưa được triển khai; cần cấu hình
OAuth và dịch vụ gửi email/SMS trước khi nối các nút tương ứng.

## Chạy lần đầu

Dừng API đang chạy trước khi build/migration để tránh khóa DLL:

```powershell
dotnet tool restore
dotnet ef database update --project src/JobTot.Infrastructure --startup-project src/JobTot.Api
dotnet run --project src/JobTot.Api --launch-profile http
```

Migration `AddCandidateAuthentication` cho phép `Account.Email` null khi đăng ký bằng
số điện thoại và tạo unique index cho `Account.Phone`. Nếu database đã có số điện thoại
trùng, cần xử lý dữ liệu trùng trước khi áp dụng; migration không xóa tài khoản.
Không rollback migration khi đã có tài khoản chỉ dùng số điện thoại mà chưa bổ sung email.

## API và dữ liệu

Prefix: `/api/candidate/auth`.

| Method | Path | Kết quả |
|---|---|---|
| GET | `/csrf` | `{ "token": "...", "headerName": "X-CSRF-TOKEN" }` và cookie CSRF |
| POST | `/register` | 201, tạo Account và CandidateProfile cùng transaction, tự đăng nhập |
| POST | `/login` | 200, đăng nhập ứng viên |
| GET | `/me` | 200, thông tin ứng viên; 401 nếu chưa đăng nhập hoặc tài khoản không khả dụng |
| POST | `/logout` | 204, xóa cookie đăng nhập trên trình duyệt hiện tại |

Đăng ký:

```json
{
  "fullName": "Nguyễn Văn A",
  "emailOrPhone": "ungvien@example.com",
  "password": "matkhau123",
  "confirmPassword": "matkhau123"
}
```

Đăng nhập:

```json
{
  "emailOrPhone": "ungvien@example.com",
  "password": "matkhau123",
  "rememberMe": true
}
```

`emailOrPhone` nhận email hoặc số di động Việt Nam, ví dụ `0912345678`, `+84912345678`.
Email được trim và chuyển về chữ thường. Số điện thoại lưu dạng `+84…`, bỏ khoảng trắng,
dấu chấm, gạch ngang và ngoặc. Một tài khoản đăng ký bằng email đăng nhập bằng email đó;
tài khoản đăng ký bằng số điện thoại đăng nhập bằng số đó. Chưa có API liên kết thêm email/số điện thoại.
Họ tên bắt buộc, tối đa 200 ký tự; mật khẩu 8–128 ký tự và xác nhận phải khớp.
Mật khẩu được băm bằng ASP.NET Core Identity PasswordHasher, không lưu hoặc trả mật khẩu rõ.
Email/số điện thoại chưa được xác minh quyền sở hữu; `EmailVerifiedAt` vẫn null.

Đăng ký/đăng nhập trả:

```json
{
  "account": {
    "id": "<account-guid>",
    "candidateProfileId": "<profile-guid>",
    "fullName": "Nguyễn Văn A",
    "email": "ungvien@example.com",
    "phone": null,
    "accountType": "Candidate"
  },
  "expiresAt": "<UTC timestamp>"
}
```

`/me` trả trực tiếp đối tượng `account`. Không có password hash trong response.

## Kết nối frontend

Xác thực dùng cookie `JobTot.Candidate` có HttpOnly, không dùng token trong localStorage.
Mọi request gửi `credentials: "include"`. Các request POST cần header `X-CSRF-TOKEN`
và cookie CSRF từ `/csrf`. Lấy token mới sau khi trạng thái đăng nhập thay đổi;
helper dưới đây lấy mới trước mỗi POST để xử lý việc đó tự động.

```javascript
const API = "http://localhost:5049/api/candidate/auth";

async function authRequest(path, body) {
  const options = { credentials: "include" };
  if (body !== undefined) {
    const csrfResponse = await fetch(`${API}/csrf`, options);
    if (!csrfResponse.ok) throw new Error("Không lấy được mã xác thực yêu cầu.");
    const csrf = await csrfResponse.json();
    options.method = "POST";
    options.headers = {
      "Content-Type": "application/json",
      [csrf.headerName]: csrf.token,
    };
    options.body = JSON.stringify(body);
  }
  const response = await fetch(`${API}${path}`, options);
  if (response.status === 204) return;
  const data = await response.json();
  if (!response.ok) {
    const error = new Error(data.detail || data.title || "Yêu cầu không thành công.");
    error.status = response.status;
    error.errors = data.errors; // Lỗi validation theo trường để hiển thị trên form.
    throw error;
  }
  return data;
}

// Gọi từ sự kiện submit form; hiển thị lỗi trong catch và tắt loading trong finally.
const register = (form) => authRequest("/register", form);
const login = (form) => authRequest("/login", form);
const getCurrentCandidate = () => authRequest("/me");
const logout = () => authRequest("/logout", {});
```

Không chọn ghi nhớ: cookie phiên trình duyệt, ticket hết hạn sau 8 giờ.
Chọn ghi nhớ: cookie tồn tại tối đa 30 ngày. Không gia hạn tự động.
Đăng ký tự đăng nhập bằng cookie phiên. Đăng xuất xóa cookie của trình duyệt hiện tại;
chưa có chức năng thu hồi tất cả phiên trên các thiết bị khác.
Mỗi request xác thực kiểm tra lại trạng thái Account và CandidateProfile trong database.
Tài khoản khác loại `Candidate`, bị khóa, inactive hoặc deleted không được dùng API ứng viên.

Development cho phép CORS từ `http://localhost:3000` và `http://localhost:5173`.
Đổi `Cors:AllowedOrigins` nếu frontend dùng cổng khác. Dùng cùng scheme/hostname khi phát triển
(ví dụ cả frontend lẫn API đều dùng HTTP localhost). Cookie SameSite=Lax phù hợp same-site;
khi triển khai nên dùng cùng site qua reverse proxy hoặc các subdomain cùng site, cùng HTTPS.
Production cookie luôn Secure; cấu hình origin chính xác và lưu Data Protection keys bền vững
khi chạy container hoặc nhiều instance để các instance đọc được cùng cookie.

## Thử bằng Swagger

1. Mở `http://localhost:5049/swagger`.
2. Gọi `GET /api/candidate/auth/csrf`, copy `token` trong response.
3. Gọi register/login, điền token vào ô header `X-CSRF-TOKEN` và điền JSON body.
4. Gọi `/me`; trình duyệt tự gửi cookie đã nhận.
5. Lấy token mới từ `/csrf` trước khi gọi `/logout`.

## Lỗi và kiểm thử

| HTTP | Ý nghĩa |
|---|---|
| 400 | Dữ liệu sai hoặc thiếu/sai CSRF token |
| 401 | Sai thông tin đăng nhập, tài khoản không khả dụng, hoặc chưa đăng nhập |
| 403 | Không có quyền ứng viên |
| 409 | Email hoặc số điện thoại đã đăng ký |
| 429 | Quá 10 request đăng ký/đăng nhập trong 1 phút trên một IP |

Giới hạn request nằm trong bộ nhớ từng API instance. Nếu chạy nhiều instance hoặc sau proxy,
cần cấu hình trusted proxy/forwarded headers và giới hạn tập trung tại gateway.
Các API công ty/tin tuyển dụng cũ chưa được gắn quyền nhà tuyển dụng trong thay đổi này.

```powershell
dotnet test tests/JobTot.Domain.Tests/JobTot.Domain.Tests.csproj
```

Kiểm thử HTTP dùng WebApplicationFactory với EF InMemory, không thay đổi database JobTot.
Chúng kiểm tra cookie, CSRF, validation, tài khoản trùng, đăng nhập, vai trò/trạng thái,
ghi nhớ đăng nhập, đăng xuất và rate limiting. Kiểm thử model SQL Server xác nhận unique index;
InMemory không kiểm chứng unique constraint hay transaction thực tế của SQL Server.

Tham khảo cơ chế framework:
[Cookie authentication](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/cookie?view=aspnetcore-9.0),
[CSRF protection](https://learn.microsoft.com/en-us/aspnet/core/security/anti-request-forgery?view=aspnetcore-9.0).
