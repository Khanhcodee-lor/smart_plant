/// Cấu hình API key cho các dịch vụ Google Cloud.
///
/// Hướng dẫn lấy API key cho Speech-to-Text:
/// 1. Truy cập https://console.cloud.google.com
/// 2. Chọn project Firebase của bạn
/// 3. Vào "APIs & Services" → "Library"
/// 4. Tìm "Cloud Speech-to-Text API" → Enable
/// 5. Vào "APIs & Services" → "Credentials" → "Create Credentials" → "API key"
/// 6. Copy API key và dán vào biến bên dưới
class ApiConfig {
  /// API key dùng cho Google Cloud Speech-to-Text.
  /// Thay thế chuỗi rỗng bằng API key thật của bạn.
  static const String googleSpeechApiKey = 'AIzaSyAw73OX13VanB3SrmbTPjRKQ3AFXupZIV4';
}
