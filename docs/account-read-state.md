# Trạng thái đọc theo tài khoản

Migration: `20261012095438_AddAccountReadState`. Migration chỉ tạo bảng mới và index, không chạy cập nhật database tự động.

Tại `BE/JobTot`, dừng API đang debug rồi chạy:

```powershell
dotnet ef database update --project src/JobTot.Infrastructure --startup-project src/JobTot.Api
```

Hoặc Package Manager Console trong Visual Studio:

```powershell
Update-Database -Project JobTot.Infrastructure -StartupProject JobTot.Api
```

- `AccountNotificationReads`: khóa `(AccountId, NotificationId)`, thời điểm `ReadAt`.
- `AccountMessageReads`: khóa `(AccountId, MessageId)`, thời điểm `ReadAt`; MessageId có FK tới ChatMessages.
- `PUT /api/{candidate|employer}/header/read`: `{ ids: [...] }`, tối đa 100 ID/lần. Chỉ ghi cho tài khoản đang đăng nhập.
- `PUT /api/{candidate|employer}/messages/{conversationId}/read`: `{ messageIds: [...] }`, tối đa 100 ID/lần; kiểm tra quyền thành viên, chỉ đánh dấu tin nhận thuộc cuộc trò chuyện đó.
- Header trả `notifications[].isRead` và `unreadConversationCount`. Bộ đếm tin nhắn đếm số cuộc trò chuyện có tin chưa đọc, không bị giới hạn bởi danh sách 50 tin header.
- Đánh dấu đọc idempotent; khóa ghép ngăn tạo trùng. Không có thao tác đánh dấu chưa đọc hoặc làm lùi trạng thái.
- Frontend bỏ localStorage cho trạng thái đọc. Bấm icon tin nhắn không đánh dấu đã đọc; mở hội thoại khi tab đang hiển thị mới gửi ID tin nhận đã tải.
- Thiết bị khác cập nhật khi tải lại, quay lại cửa sổ/tab hoặc qua polling header mỗi 30 giây; chưa dùng push thời gian thực.
- Trạng thái localStorage cũ không tự nhập lên server; thông báo/tin cũ chưa có receipt sẽ được coi là chưa đọc.
