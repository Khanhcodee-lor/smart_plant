# 🌿 Plant Smart - IoT Plant Doctor (Flutter App)

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-%23000000.svg?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-%23FFCA28.svg?style=for-the-badge&logo=firebase&logoColor=black)

**Plant Smart** là ứng dụng di động đóng vai trò là trung tâm điều khiển và giám sát cho hệ thống IoT nông nghiệp thông minh. Ứng dụng cho phép người dùng theo dõi tình trạng môi trường, điều khiển thiết bị tưới tiêu tự động và nhận cảnh báo sớm về các loại bệnh trên cây trồng thông qua tích hợp AI.

## 🧾 Báo cáo dự án (Project Report)

### ✅ Mục tiêu
* Xây dựng ứng dụng giám sát và điều khiển vườn cây thông minh trên nền tảng di động.
* Hiển thị dữ liệu cảm biến, trạng thái thiết bị và lịch sử hoạt động theo thời gian thực.
* Hỗ trợ phát hiện sớm bệnh cây và cung cấp cảnh báo/khuyến nghị chăm sóc.
* Đảm bảo giao diện thân thiện, dễ sử dụng cho người dùng phổ thông.

---

## 📱 Các tính năng chính (Key Features)

* 🔐 **Đăng nhập & hồ sơ:** Xác thực Google và quản lý thông tin người dùng.
* 🏡 **Trang chủ khu vườn:** Tổng quan khu vườn, cây trồng và trạng thái hiện tại.
* 🌡 **Giám sát môi trường:** Nhiệt độ, độ ẩm không khí, độ ẩm đất cập nhật realtime.
* 💧 **Điều khiển thiết bị:** Bật/tắt bơm thủ công hoặc tự động theo ngưỡng/lịch trình.
* 🧪 **Chẩn đoán bệnh cây:** Ảnh chụp, lịch sử lần chụp, kết quả phân tích và cảnh báo.
* 📡 **Cấu hình thiết bị:** Ghép nối và cấu hình Raspberry Pi qua BLE.
* 💬 **Hỗ trợ người dùng:** Trung tâm hỗ trợ và trợ lý AI tư vấn.

## 🖼 Hình ảnh các màn hình (Screenshots)

<table>
  <tr>
    <td align="center">
      <img src="assets/screen/z7819933467133_aa3455a9271f6b2e2174176e08375e79.jpg" width="240" alt="Login" />
      <br />
      <sub>Đăng nhập</sub>
    </td>
    <td align="center">
      <img src="assets/screen/z7819933474818_7bca74ae742f4be93c07b9cf8b459f6f.jpg" width="240" alt="Home" />
      <br />
      <sub>Trang chủ khu vườn</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="assets/screen/z7819933478898_9111537c359199e180c7994be46a0895.jpg" width="240" alt="Control" />
      <br />
      <sub>Chế độ &amp; điều khiển bơm</sub>
    </td>
    <td align="center">
      <img src="assets/screen/z7819933544261_225024e663c983a36909dbcceb06ee8b.jpg" width="240" alt="Diagnosis overview" />
      <br />
      <sub>Chẩn đoán bệnh (tổng quan)</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="assets/screen/z7819933494714_957c713040bd0b41ed3827ff273811fb.jpg" width="240" alt="Capture detail" />
      <br />
      <sub>Chi tiết lần chụp</sub>
    </td>
    <td align="center">
      <img src="assets/screen/z7819933521588_9b7d80528b92f0bcc9c7fc58d4168798.jpg" width="240" alt="AI assistant" />
      <br />
      <sub>Trợ lý AI (mở)</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="assets/screen/z7819933547141_1782abf3bca355173fbfc0ed3ef9b005.jpg" width="240" alt="AI chat" />
      <br />
      <sub>Trợ lý AI (hội thoại)</sub>
    </td>
    <td align="center">
      <img src="assets/screen/z7819933485795_27a53df7d586f227cbced5d591bfa6ab.jpg" width="240" alt="Support" />
      <br />
      <sub>Trung tâm hỗ trợ</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="assets/screen/z7819933481096_e93e0a574bd85287d800c85799011850.jpg" width="240" alt="Profile" />
      <br />
      <sub>Hồ sơ người dùng</sub>
    </td>
    <td align="center">
      <img src="assets/screen/z7819945249825_e511b4c441cc72d56cda4e42a0680616.jpg" width="240" alt="BLE setup" />
      <br />
      <sub>Cấu hình Pi qua BLE</sub>
    </td>
  </tr>
</table>

---

## 🛠 Công nghệ & Thư viện sử dụng (Tech Stack)

Dự án chú trọng áp dụng các best practices của hệ sinh thái Flutter:

* **Framework:** Flutter (Dart)
* **Architecture:** Tách biệt rõ ràng theo chuẩn **Clean Architecture** (Domain, Data, Presentation).
* **State Management:** **Riverpod** (`riverpod_annotation`, `flutter_riverpod`) xử lý reactive state tối ưu.
* **Routing:** **GoRouter** quản lý điều hướng và deep linking.
* **Networking & API:** `Dio` thao tác REST API (thời tiết) và Firebase SDK.
* **Data Modeling:** `Freezed` & `JsonSerializable` tạo immutable state và parse JSON an toàn.
* **UI/UX:**
  * `flutter_screenutil` - Responsive UI mọi kích thước màn hình.
  * `fl_chart` - Vẽ biểu đồ dữ liệu môi trường.
  * `lottie` & `flutter_svg` - Animation và icon vector.
* **Firebase Suite:** Khai thác toàn diện hệ sinh thái Firebase (Auth, Firestore, Storage, Messaging, Crashlytics, Analytics, Remote Config, Performance).





