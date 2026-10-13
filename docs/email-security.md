# Xác thực email và khôi phục bằng mật khẩu tạm

Cả tài khoản ứng viên và nhà tuyển dụng mới phải xác thực email trước khi tạo tài khoản. Đăng ký mới chỉ dùng email; tài khoản cũ đăng nhập bằng số điện thoại vẫn hoạt động.

- Mã OTP 6 chữ số, hiệu lực 10 phút, tối đa 5 lần nhập sai, gửi lại cách ít nhất 60 giây.
- Bảng `AccountEmailChallenges` lưu hash mã/mật khẩu tạm, vai trò, email, thời hạn, số lần thử và trạng thái sử dụng. Không lưu mật khẩu/mã dạng plaintext.
- Quên mật khẩu gửi mật khẩu tạm ngẫu nhiên, hiệu lực 30 phút. Mật khẩu hiện tại được giữ đến khi người dùng xác nhận đổi mật khẩu mới.
- Đăng nhập bằng mật khẩu tạm chỉ trả ticket đổi mật khẩu (HTTP 428), không cấp access/refresh token. Sau khi đặt mật khẩu mới, frontend đăng nhập lại bằng mật khẩu mới.
- Challenge dùng một lần, có concurrency token; ticket đổi mật khẩu gắn với hash mật khẩu hiện tại. Tài khoản cũ không bị khóa bởi migration.
- SMTP gửi thất bại trả lỗi, không hiển thị thành công giả. Request recovery dùng thông báo chung cho email không tồn tại.

## Gmail SMTP

Bật xác minh 2 bước cho tài khoản Gmail và tạo App Password. Gmail SMTP dùng `smtp.gmail.com`, cổng 587, TLS/STARTTLS. Xem https://support.google.com/mail/answer/7104828 và https://support.google.com/accounts/answer/185833.

Project API đã có `UserSecretsId=jobtot-api`. Từ thư mục `BE/JobTot`, cấu hình locally (thay các placeholder; không commit secret):

```powershell
dotnet user-secrets set "PasswordRecovery:Smtp:From" "YOUR_GMAIL@gmail.com" --project src/JobTot.Api
dotnet user-secrets set "PasswordRecovery:Smtp:Username" "YOUR_GMAIL@gmail.com" --project src/JobTot.Api
dotnet user-secrets set "PasswordRecovery:Smtp:Password" "GMAIL_APP_PASSWORD" --project src/JobTot.Api
```

Host/port/SSL đã có trong appsettings. Production dùng cấu hình môi trường `PasswordRecovery__Smtp__From`, `PasswordRecovery__Smtp__Username`, `PasswordRecovery__Smtp__Password` và lưu Data Protection key ring bền vững/shared khi chạy nhiều instance.

## Database

Migration `AddAccountEmailChallenges`. Dừng debug API trước khi chạy:

```powershell
dotnet ef database update --project src/JobTot.Infrastructure --startup-project src/JobTot.Api
```

Không có mật khẩu Gmail trong repository. Chưa cập nhật database hay gửi email thật trong quá trình kiểm thử.

API: POST `/api/{candidate|employer}/auth/email/request` ({email}), `/email/verify` ({email,challengeId,code}), `/email/change-temporary-password` ({token,password,confirmPassword}). Registration thêm `emailVerificationToken` lấy sau bước verify.
