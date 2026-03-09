import 'package:freezed_annotation/freezed_annotation.dart';

part 'plant.freezed.dart';

@freezed
class DetectionItem with _$DetectionItem {
  const factory DetectionItem({
    required String diseaseClass,
    required double confidence,
    required String time,
    @Default('') String snapshotUrl,
  }) = _DetectionItem;
}

@freezed
class Plant with _$Plant {
  const factory Plant({
    required String id,
    required String name,
    required String status,
    required String imageUrl,
    required String videoUrl,
    required DetectionItem? latestDetection,
    required List<DetectionItem> history,
  }) = _Plant;

  // Custom mapper từ Realtime Database JSON Object
  factory Plant.fromRealtimeDb(String id, Map<dynamic, dynamic> data) {
    // Thông tin cơ bản
    final info = data['info'] as Map<dynamic, dynamic>? ?? {};
    final stringName = info['name']?.toString() ?? 'Cây không xác định';
    final stringImage = info['image']?.toString() ?? '';

    // Stream video
    final streamData = data['stream'] as Map<dynamic, dynamic>? ?? {};
    final videoUrl = streamData['video_url']?.toString() ?? '';

    // Detections
    final detections = data['detections'] as Map<dynamic, dynamic>? ?? {};
    final latestData = detections['latest'] as Map<dynamic, dynamic>?;
    
    DetectionItem? latestDetection;
    if (latestData != null) {
      latestDetection = DetectionItem(
        diseaseClass: latestData['class']?.toString() ?? 'Unknown',
        confidence: (latestData['confidence'] as num?)?.toDouble() ?? 0.0,
        time: latestData['time']?.toString() ?? '',
      );
    }

    final diseaseClass = latestData?['class']?.toString();
    final stringStatus = (diseaseClass != null && diseaseClass != 'Healthy')
        ? diseaseClass
        : 'Hãy đến thăm khu vườn của bạn';

    // History
    final historyData = detections['history'] as Map<dynamic, dynamic>? ?? {};
    final List<DetectionItem> historyList = [];
    historyData.forEach((key, value) {
      if (value is Map) {
         historyList.add(DetectionItem(
            diseaseClass: value['class']?.toString() ?? 'Unknown',
            confidence: (value['confidence'] as num?)?.toDouble() ?? 0.0,
            time: value['time']?.toString() ?? '',
            snapshotUrl: value['snapshot']?.toString() ?? '',
         ));
      }
    });

    // Sort lịch sử theo thời gian mới nhất (cơ bản dựa trên chuỗi time)
    historyList.sort((a, b) => b.time.compareTo(a.time));

    return Plant(
      id: id,
      name: stringName,
      status: stringStatus,
      imageUrl: stringImage,
      videoUrl: videoUrl,
      latestDetection: latestDetection,
      history: historyList,
    );
  }
}

