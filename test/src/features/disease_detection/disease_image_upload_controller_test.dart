import 'package:app_iot/src/features/disease_detection/presentation/controllers/disease_image_upload_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse upload response with annotated image and disease list', () {
    final result = debugParseDiseaseImageUploadResult(
      {
        'data': {
          'annotated_frame_storage_path': 'detections/uploaded.jpg',
          'timestamp': '2026-05-11T03:50:00.000000Z',
          'disease_list_unique_top': [
            {
              'class_en': 'Tomato septoria leaf spot',
              'highest_confidence': 0.367,
            },
          ],
        },
      },
      fallbackSnapshotUrl: '/local/old.jpg',
      fallbackTime: '2026-05-11 10:49:00',
    );

    expect(result.snapshotUrl, 'detections/uploaded.jpg');
    expect(result.hasServerSnapshot, isTrue);
    expect(result.latestDetection?.diseaseClass, 'Tomato septoria leaf spot');
    expect(result.latestDetection?.confidence, 0.367);
    expect(result.latestDetection?.snapshotUrl, 'detections/uploaded.jpg');
  });

  test(
    'parse upload response uses selected phone image when server cannot detect',
    () {
      final result = debugParseDiseaseImageUploadResult(
        {'ok': true},
        fallbackSnapshotUrl: '/data/user/0/app/cache/upload.jpg',
        fallbackTime: '2026-05-11 10:50:00',
      );

      expect(result.snapshotUrl, '/data/user/0/app/cache/upload.jpg');
      expect(result.hasServerSnapshot, isFalse);
      expect(result.capturedAt, '2026-05-11 10:50:00');
      expect(result.detections, isEmpty);
    },
  );

  test('parse upload response with detection list under data', () {
    final result = debugParseDiseaseImageUploadResult(
      {
        'data': [
          {'class': 'Tomato healthy', 'confidence': 99},
        ],
      },
      fallbackSnapshotUrl: '/local/upload.jpg',
      fallbackTime: '2026-05-11 10:50:00',
    );

    expect(result.latestDetection?.diseaseClass, 'Tomato healthy');
    expect(result.latestDetection?.confidence, 0.99);
    expect(result.latestDetection?.snapshotUrl, '/local/upload.jpg');
    expect(result.snapshotUrl, '/local/upload.jpg');
    expect(result.hasServerSnapshot, isFalse);
  });

  test(
    'parse upload response does not treat raw image url as processed image',
    () {
      final result = debugParseDiseaseImageUploadResult(
        {
          'data': {
            'image_url': 'https://example.com/raw-upload.jpg',
            'timestamp': '2026-05-11T05:05:41.000000Z',
            'disease_list_unique_top': [
              {
                'class_en': 'Tomato leaf bacterial spot',
                'highest_confidence': 0.61,
              },
            ],
          },
        },
        fallbackSnapshotUrl: '/local/upload.jpg',
        fallbackTime: '2026-05-11 12:05:39',
      );

      expect(result.snapshotUrl, '/local/upload.jpg');
      expect(result.hasServerSnapshot, isFalse);
      expect(result.latestDetection?.snapshotUrl, '/local/upload.jpg');
    },
  );
}
