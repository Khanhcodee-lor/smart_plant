/// mock_sensors_data.dart
/// Dữ liệu giả cho cảm biến IoT – dùng code UI

class MockSensorsData {
  /// ===== NHIỆT ĐỘ =====
  static const Map<String, dynamic> temperature = {
    "value": 28.5,
    "unit": "°C",
    "status": "normal", // normal | warning | danger
    "time": "2026-01-26 19:05:10",
    "min": 18.0,
    "max": 35.0,
  };

  /// ===== ĐỘ ẨM ĐẤT =====
  static const Map<String, dynamic> soilMoisture = {
    "value": 45,
    "unit": "%",
    "status": "low", // low | normal | high
    "time": "2026-01-26 19:05:10",
    "min": 40,
    "max": 70,
  };

  /// ===== CƯỜNG ĐỘ ÁNH SÁNG =====
  static const Map<String, dynamic> lightIntensity = {
    "value": 820,
    "unit": "lux",
    "status": "good", // low | good | high
    "time": "2026-01-26 19:05:10",
    "min": 300,
    "max": 1200,
  };
}
