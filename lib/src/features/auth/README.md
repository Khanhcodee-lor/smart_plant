
---

## 🏛 Domain Layer (Cốt lõi)

*Không phụ thuộc Flutter, Firebase hay thư viện ngoài.*

- **AppUser**  
  Đại diện cho người dùng trong hệ thống (Freezed, immutable).

- **AuthRepository**  
  Interface khai báo các chức năng xác thực (đăng nhập, đăng xuất…).  
  Chỉ mô tả *cần làm gì*, không quan tâm *làm như thế nào*.

---

## ⚙️ Data Layer (Dữ liệu)

*Xử lý việc giao tiếp với Firebase / Google.*

- **FirebaseAuthService**  
  Làm việc trực tiếp với Firebase Auth & Google Sign-In, trả về dữ liệu thô.

- **AuthRepositoryImpl**  
  Triển khai `AuthRepository`, chuyển dữ liệu Firebase sang `AppUser`.  
  Ẩn toàn bộ chi tiết kỹ thuật khỏi Domain và UI.

---

## 📱 Presentation Layer (UI)

*Quản lý giao diện và trạng thái.*

- **AuthController**  
  Quản lý trạng thái đăng nhập bằng Riverpod (`AsyncNotifier`): loading / success / error.

- **LoginScreen**  
  Hiển thị giao diện đăng nhập và lắng nghe trạng thái từ `AuthController`.

---

## 🔄 Luồng đăng nhập Google

1. Người dùng bấm **Đăng nhập bằng Google**
2. UI gọi `AuthController`
3. Controller gọi `AuthRepository`
4. Repository sử dụng `FirebaseAuthService`
5. Firebase trả dữ liệu người dùng
6. Mapping thành `AppUser`
7. UI cập nhật trạng thái

---

## ✅ Lợi ích

- Code rõ ràng, dễ đọc
- Dễ mở rộng thêm phương thức đăng nhập
- Dễ test và bảo trì
- Phù hợp cho đồ án và dự án thực tế