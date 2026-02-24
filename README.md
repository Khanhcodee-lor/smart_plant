# 🌿 Plant Smart - IoT Plant Doctor (Flutter App)

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-%23000000.svg?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-%23FFCA28.svg?style=for-the-badge&logo=firebase&logoColor=black)

**Plant Smart** là ứng dụng di động đóng vai trò là trung tâm điều khiển và giám sát cho hệ thống IoT nông nghiệp thông minh. Ứng dụng cho phép người dùng theo dõi tình trạng môi trường, điều khiển thiết bị tưới tiêu tự động và nhận cảnh báo sớm về các loại bệnh trên cây trồng thông qua tích hợp AI.

---

## 🏗 Kiến trúc hệ thống tổng thể (System Architecture)

Dự án này là giao diện tương tác người dùng (Frontend) của một hệ thống sinh thái IoT hoàn chỉnh bao gồm:

1. **Edge Devices (Phần cứng thu thập):** Sử dụng **ESP32** tích hợp module Camera để thu thập hình ảnh cây trồng và các cảm biến đo thông số môi trường (nhiệt độ, độ ẩm đất, ánh sáng).
2. **Local Server & AI Processing:** Sử dụng **Raspberry Pi** chạy backend bằng **Python** để xử lý ảnh. AI model được deploy trên Raspberry Pi sẽ phân tích hình ảnh từ ESP32 gửi về để phát hiện và phân loại bệnh/sâu hại.
3. **Cloud & Backend:** **Firebase** đóng vai trò là cầu nối lưu trữ dữ liệu môi trường, kết quả chuẩn đoán từ AI và đồng bộ thời gian thực đến ứng dụng di động.
4. **Mobile App (Repository này):** Ứng dụng **Flutter** hiển thị dữ liệu realtime, cung cấp dashboard điều khiển thiết bị (máy bơm, đèn sưởi) và cảnh báo đẩy (Push Notifications) khi phát hiện bệnh.

---

## 📱 Các tính năng chính (Key Features)

* 🔐 **Xác thực:** Đăng nhập an toàn qua Google Sign-In (Firebase Auth).
* 🌤 **Thời tiết thời gian thực:** Tích hợp OpenWeatherMap API & tự động định vị (Geolocator) để gợi ý chăm sóc.
* 📊 **Dashboard Giám sát:** Theo dõi biểu đồ nhiệt độ, độ ẩm đất và ánh sáng theo thời gian thực.
* ⚙️ **Điều khiển IoT (Chế độ hoạt động):** Chuyển đổi linh hoạt giữa chế độ **Tự động** (dựa trên ngưỡng cảm biến) và **Lịch trình** (hẹn giờ bật/tắt máy bơm).
* 🦠 **Bác sĩ Cây trồng (AI Detection):** Nhận luồng dữ liệu (stream) và lịch sử cảnh báo sâu bệnh (Late blight, leaf curl...) từ hệ thống AI gửi lên Firebase.
* 🔔 **Cảnh báo thông minh:** Tích hợp Firebase Cloud Messaging (FCM) để push notification khi phát hiện thông số nguy hiểm.

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

---

## 📁 Cấu trúc thư mục (Folder Structure)

Project được tổ chức theo tính năng (Feature-first) kết hợp Clean Architecture để dễ dàng mở rộng và maintain trong môi trường doanh nghiệp:

```text
lib/
├── src/
│   ├── core/                   # Cốt lõi ứng dụng (Constants, Error handling, Router, Utilities)
│   │   ├── services/firebase/  # Tích hợp Firebase Services đóng gói độc lập
│   │   └── views/              # BaseView tối ưu UI logic
│   │
│   ├── features/               # Phân chia theo từng tính năng
│   │   ├── auth/               # Đăng nhập, quản lý phiên user
│   │   ├── home/               # Dashboard tổng quan, API thời tiết
│   │   ├── regime/             # Điều khiển thiết bị, lịch trình, biểu đồ cảm biến
│   │   ├── support/            # Khám phá, hỗ trợ thiết bị IoT
│   │   └── profile/            # Cài đặt, liên kết third-party (Google Home, Alexa)
│   │       │
│   │       ├── data/           # Data layer (Repositories Impl, Data Sources)
│   │       ├── domain/         # Domain layer (Entities, Repositories interface)
│   │       └── presentation/   # Presentation layer (Controllers/Providers, Widgets, Views)
│   │
│   ├── shared/                 # Widgets, Animations dùng chung toàn app
│   └── app.dart                # Khởi tạo MaterialApp, Theme





