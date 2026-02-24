# Firebase Services

Thư mục này chứa các dịch vụ được đóng gói để tương tác với Firebase.

## 1. FirebaseAuthService
Dùng để quản lý xác thực người dùng.
- `authStateChanges`: Stream theo dõi trạng thái đăng nhập.
- `currentUser`: Lấy user hiện tại.
- `signInWithEmail(email, password)`: Đăng nhập.
- `signUpWithEmail(email, password)`: Đăng ký.
- `signOut()`: Đăng xuất.
- `sendPasswordResetEmail(email)`: Quên mật khẩu.

## 2. FirebaseFirestoreService
Dùng để quản lý Cloud Firestore Database.
- `collectionStream(path)`: Lấy dữ liệu danh sách theo thời gian thực.
- `documentStream(path)`: Lấy dữ liệu 1 document theo thời gian thực.
- `setData(path, data)`: Ghi hoặc cập nhật dữ liệu.
- `addDocument(path, data)`: Thêm mới dữ liệu vào collection.
- `deleteData(path)`: Xóa dữ liệu.

## 3. FirebaseStorageService
Dùng để quản lý tệp tin (Hình ảnh, Video...).
- `uploadFile(path, file)`: Tải tệp lên và trả về URL.
- `deleteFile(path)`: Xóa tệp.
- `getDownloadUrl(path)`: Lấy link tải tệp.

## 4. FirebaseMessagingService
Dùng cho thông báo đẩy (Push Notifications).
- `init()`: Khởi tạo, xin quyền và cấu hình handler.
- `getToken()`: Lấy FCM Token của thiết bị.
- `subscribeToTopic(topic)`: Đăng ký nhận tin theo chủ đề.
- `unsubscribeFromTopic(topic)`: Hủy nhận tin theo chủ đề.

## 5. FirebaseRemoteConfigService
Dùng để cấu hình ứng dụng từ xa mà không cần cập nhật app.
- `init()`: Khởi tạo và fetch dữ liệu mới nhất.
- `getString(key)`, `getBool(key)`, `getInt(key)`: Lấy giá trị cấu hình theo kiểu dữ liệu.

## 6. FirebaseAnalyticsService
Dùng để theo dõi hành vi người dùng và phân tích dữ liệu.
- `logEvent(name, parameters)`: Ghi lại một sự kiện tùy chỉnh.
- `setUserId(id)`: Gán ID cho người dùng để theo dõi xuyên suốt.
- `setCurrentScreen(screenName)`: Ghi lại sự kiện xem màn hình.

## 7. FirebaseCrashlyticsService
Dùng để ghi lại lỗi và crash ứng dụng tự động.
- `init()`: Khởi tạo bắt lỗi toàn cục (Fatal/Non-fatal).
- `log(message)`: Thêm log vào báo cáo lỗi.
- `recordError(error, stack)`: Ghi lại một lỗi cụ thể một cách thủ công.

## 8. FirebaseDynamicLinksService
Dùng để tạo và xử lý các liên kết thông minh (Deep Links).
- `init(onLinkSuccess)`: Lắng nghe và xử lý link khi app mở từ bên ngoài.
- `createShortLink(path)`: Tạo một đường dẫn ngắn để chia sẻ tính năng trong app.
