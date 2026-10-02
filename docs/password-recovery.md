# Khôi phục mật khẩu

`POST /api/candidate/auth/forgot-password` nhận `{ "email": "candidate@example.com" }`.
`POST /api/candidate/auth/reset-password` nhận `{ "token": "...", "password": "...", "confirmPassword": "..." }`.
Both endpoints accept anonymous JSON requests and are rate limited; no cookie or CSRF token is required.

Email có liên kết `/reset-password#token=...`, hết hạn sau 30 phút. Token được mã hóa bằng Data Protection,
gắn với mật khẩu hiện tại và không thể dùng lại sau khi đổi mật khẩu. Cập nhật mật khẩu có điều kiện trong database
để hai yêu cầu đồng thời không sử dụng cùng token thành công. Các phiên đăng nhập cũ bị từ chối ở request tiếp theo.
Phản hồi yêu cầu khôi phục không tiết lộ email có tồn tại hay không.

## Cấu hình gửi email

Cấu hình các khóa sau qua biến môi trường hoặc user-secrets; không commit mật khẩu SMTP:

| Biến môi trường | Ví dụ |
| --- | --- |
| `PasswordRecovery__FrontendUrl` | `http://localhost:5173` (production dùng HTTPS) |
| `PasswordRecovery__Smtp__Host` | máy chủ SMTP của bạn |
| `PasswordRecovery__Smtp__Port` | `587` |
| `PasswordRecovery__Smtp__EnableSsl` | `true` (STARTTLS) |
| `PasswordRecovery__Smtp__From` | địa chỉ gửi được nhà cung cấp cho phép |
| `PasswordRecovery__Smtp__Username` | tài khoản SMTP |
| `PasswordRecovery__Smtp__Password` | mật khẩu ứng dụng / SMTP secret |

Khởi động lại API sau khi cấu hình. Khi chưa cấu hình, API trả lỗi thay vì báo đã gửi email.
SmtpClient dùng STARTTLS, không dùng cổng SMTPS 465. Production cần lưu Data Protection keys bền vững
và chia sẻ giữa các API instance. Tài khoản chỉ đăng ký bằng số điện thoại chưa có email không dùng được luồng này.

Kiểm tra thực tế: gửi yêu cầu từ form, mở liên kết trong email, đặt mật khẩu mới, thử đăng nhập với mật khẩu mới,
rồi mở lại liên kết đã dùng để xác nhận bị từ chối. Không có migration schema mới.
