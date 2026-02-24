// mock_iot_data.dart
// Dữ liệu giả cho app IoT cây trồng
// Camera nhận biết sâu bệnh + Máy bơm + Đèn sưởi

// =======================
// 📷 CAMERA – SÂU BỆNH
// =======================
class PestDetection {
  final String id;
  final String cameraName;
  final String pestName;
  final double confidence; // %
  final String imageUrl;
  final DateTime detectedAt;
  final PestStatus status;

  PestDetection({
    required this.id,
    required this.cameraName,
    required this.pestName,
    required this.confidence,
    required this.imageUrl,
    required this.detectedAt,
    required this.status,
  });
}

enum PestStatus { normal, warning, danger }

final List<PestDetection> mockPestDetections = [
  PestDetection(
    id: 'pd_01',
    cameraName: 'Camera Vườn Cà Chua',
    pestName: 'Rệp lá',
    confidence: 92.4,
    imageUrl: 'https://example.com/images/aphid.jpg',
    detectedAt: DateTime.now().subtract(const Duration(minutes: 12)),
    status: PestStatus.warning,
  ),
  PestDetection(
    id: 'pd_02',
    cameraName: 'Camera Nhà Kính',
    pestName: 'Sâu ăn lá',
    confidence: 88.1,
    imageUrl: 'https://example.com/images/caterpillar.jpg',
    detectedAt: DateTime.now().subtract(const Duration(hours: 1)),
    status: PestStatus.danger,
  ),
  PestDetection(
    id: 'pd_03',
    cameraName: 'Camera Vườn Rau',
    pestName: 'Không phát hiện',
    confidence: 0,
    imageUrl: 'https://example.com/images/normal.jpg',
    detectedAt: DateTime.now().subtract(const Duration(hours: 3)),
    status: PestStatus.normal,
  ),
];

// =======================
// 💧 MÁY BƠM NƯỚC
// =======================
class WaterPump {
  final String id;
  final String name;
  final bool isOn;
  final bool autoMode;
  final int waterFlow; // lít/giờ
  final DateTime lastActive;

  WaterPump({
    required this.id,
    required this.name,
    required this.isOn,
    required this.autoMode,
    required this.waterFlow,
    required this.lastActive,
  });
}

final WaterPump mockWaterPump = WaterPump(
  id: 'pump_01',
  name: 'Máy bơm tưới chính',
  isOn: true,
  autoMode: true,
  waterFlow: 120,
  lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
);

// =======================
// 🔥 ĐÈN SƯỞI
// =======================
class HeatingLamp {
  final String id;
  final String name;
  final bool isOn;
  final bool autoMode;
  final double temperature; // °C
  final DateTime lastUpdated;

  HeatingLamp({
    required this.id,
    required this.name,
    required this.isOn,
    required this.autoMode,
    required this.temperature,
    required this.lastUpdated,
  });
}

final HeatingLamp mockHeatingLamp = HeatingLamp(
  id: 'lamp_01',
  name: 'Đèn sưởi nhà kính',
  isOn: false,
  autoMode: true,
  temperature: 22.6,
  lastUpdated: DateTime.now().subtract(const Duration(minutes: 15)),
);

// =======================
// 📊 DASHBOARD GỘP
// =======================
class IoTDashboardData {
  final List<PestDetection> pestDetections;
  final WaterPump waterPump;
  final HeatingLamp heatingLamp;

  IoTDashboardData({
    required this.pestDetections,
    required this.waterPump,
    required this.heatingLamp,
  });
}

final IoTDashboardData mockDashboardData = IoTDashboardData(
  pestDetections: mockPestDetections,
  waterPump: mockWaterPump,
  heatingLamp: mockHeatingLamp,
);
