import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Plant.fromFirestore does not create Unknown detection from image metadata only',
    () {
      final plant = Plant.fromFirestore('all', {
        'annotated_frame_storage_path': 'detections/latest.jpg',
        'latest_detection_at': '2026-04-19T12:58:49.000000',
      });

      expect(plant.latestDetection, isNull);
      expect(plant.status.toLowerCase(), isNot(contains('unknown')));
    },
  );

  test('Plant.fromFirestore reads disease list at document root', () {
    final plant = Plant.fromFirestore('all', {
      'disease_list_unique_top': [
        {
          'class': 'Tomato leaf late blight',
          'highest_confidence': 0.2603909373283386,
        },
      ],
      'timestamp': '2026-04-19T11:58:26.577067',
    });

    expect(plant.latestDetection?.diseaseClass, 'Tomato leaf late blight');
    expect(
      plant.latestDetection?.confidence,
      closeTo(0.2603909373283386, 0.000001),
    );
  });

  test('Plant.fromFirestore reads root all_classes_detected payload', () {
    final plant = Plant.fromFirestore('tomato_001', {
      'all_classes_detected': ['Lá cà chua bệnh mốc sương'],
      'all_classes_detected_en': ['Tomato leaf late blight'],
      'annotated_frame_url': 'https://example.com/detections/latest.jpg',
      'annotated_frame_local_saved_at': '2026-04-28T00:53:18.349940',
    });

    expect(plant.latestDetection, isNotNull);
    expect(plant.latestDetection?.diseaseClass, 'Tomato leaf late blight');
    expect(
      plant.latestDetection?.snapshotUrl,
      'https://example.com/detections/latest.jpg',
    );
    expect(plant.latestDetection?.time, '2026-04-28 00:53:18');
  });
}
