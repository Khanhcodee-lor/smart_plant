import 'package:app_iot/src/core/services/firebase/firebase_firestore_service.dart';
import 'package:app_iot/src/features/disease_detection/presentation/controllers/plant_detections_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const nestedDataDiseaseClass =
      'L\u00E1 c\u00E0 chua b\u1EC7nh m\u1ED1c s\u01B0\u01A1ng';
  const detectionPayload = {
    'annotated_frame_storage_path': 'detections/20260419_115826_579585.jpg',
    'timestamp': '2026-04-19T11:58:26.577067',
    'disease_list_unique_top': [
      {
        'class': 'Lá cà chua bệnh mốc sương',
        'class_en': 'Tomato leaf late blight',
        'count': 2,
        'highest_confidence': 0.2603909373283386,
        'leaf_ratio_percent': 66.66666666666666,
      },
      {
        'class': 'Lá cà chua bệnh mốc lá',
        'class_en': 'Tomato mold leaf',
        'count': 1,
        'highest_confidence': 0.21429243683815002,
        'leaf_ratio_percent': 33.33333333333333,
      },
    ],
  };

  test('parse Firestore collection document with disease list', () {
    final parsed = debugParsePlantDetectionsCollection([
      const FirestoreDocumentData(
        id: 'DBt0mU8Lh6tN47Ga3kZv',
        path: 'plants/tomato/detections/DBt0mU8Lh6tN47Ga3kZv',
        data: detectionPayload,
      ),
    ]);

    expect(parsed.latestDetection?.diseaseClass, 'Lá cà chua bệnh mốc sương');
    expect(
      parsed.latestDetection?.confidence,
      closeTo(0.2603909373283386, 0.000001),
    );
    expect(
      parsed.latestDetection?.snapshotUrl,
      'detections/20260419_115826_579585.jpg',
    );
    expect(
      parsed.latestDetection?.sourceDocumentPath,
      'plants/tomato/detections/DBt0mU8Lh6tN47Ga3kZv',
    );
    expect(parsed.latestDetections.map((item) => item.diseaseClass), [
      'Lá cà chua bệnh mốc sương',
      'Lá cà chua bệnh mốc lá',
    ]);
  });

  test('parse document field detection containing id maps', () {
    final parsed = debugParsePlantDetectionsDocument({
      'detection': {'DBt0mU8Lh6tN47Ga3kZv': detectionPayload},
    });

    expect(parsed.latestDetection?.diseaseClass, 'Lá cà chua bệnh mốc sương');
    expect(parsed.latestDetections, hasLength(2));
    expect(parsed.latestDetections.last.diseaseClass, 'Lá cà chua bệnh mốc lá');
  });

  test('parse singular all_classes_detected array inside detection id map', () {
    final parsed = debugParsePlantDetectionsDocument({
      'detections': {
        'DBt0mU8Lh6tN47Ga3kZv': {
          'all_classes_detected': [
            'Lá cà chua bệnh mốc lá',
            'Lá cà chua bệnh mốc sương',
          ],
          'timestamp': '2026-04-19T11:58:26.577067',
        },
      },
    });

    expect(parsed.latestDetections.map((item) => item.diseaseClass), [
      'Lá cà chua bệnh mốc lá',
      'Lá cà chua bệnh mốc sương',
    ]);
  });

  test(
    'merge parent latest image metadata into detection subcollection items',
    () {
      final parent = debugParsePlantDetectionsDocument({
        'annotated_frame_storage_path': 'detections/parent_latest.jpg',
        'latest_detection_at': '2026-04-19T12:58:49.000000',
      });
      final collection = debugParsePlantDetectionsCollection([
        const FirestoreDocumentData(
          id: 'DBt0mU8Lh6tN47Ga3kZv',
          data: {
            'disease_list_unique_top': [
              {
                'class': 'LÃ¡ cÃ  chua bá»‡nh má»‘c sÆ°Æ¡ng',
                'highest_confidence': 0.2603909373283386,
              },
            ],
          },
        ),
      ]);

      final merged = debugMergePlantDetections(parent, collection);

      expect(merged.latestSnapshotUrl, 'detections/parent_latest.jpg');
      expect(merged.latestCapturedAt, '2026-04-19 12:58:49');
      expect(
        merged.latestDetection?.snapshotUrl,
        'detections/parent_latest.jpg',
      );
      expect(merged.latestDetection?.time, '2026-04-19 12:58:49');
    },
  );

  test('merge detections by path drops data from cleared paths', () {
    final firstPath = debugParsePlantDetectionsCollection([
      const FirestoreDocumentData(
        id: 'old',
        path: 'plants/tomato/detections/old',
        data: {
          'class': 'Tomato leaf early blight',
          'confidence': 0.7,
          'timestamp': '2026-04-19T10:00:00.000000',
        },
      ),
    ]);
    final secondPath = debugParsePlantDetectionsCollection([
      const FirestoreDocumentData(
        id: 'new',
        path: 'plants/tomato/detections/new',
        data: {
          'class': 'Tomato leaf late blight',
          'confidence': 0.8,
          'timestamp': '2026-04-19T11:00:00.000000',
        },
      ),
    ]);

    final merged = debugMergePlantDetectionsByPath({
      'plants/tomato/detections/old': firstPath,
      'plants/tomato/detections/new': secondPath,
    });
    final afterOldPathCleared = debugMergePlantDetectionsByPath({
      'plants/tomato/detections/old': const PlantDetectionsData(),
      'plants/tomato/detections/new': secondPath,
    });

    expect(
      merged.history.map((item) => item.diseaseClass),
      contains('Tomato leaf early blight'),
    );
    expect(
      afterOldPathCleared.history.map((item) => item.diseaseClass),
      isNot(contains('Tomato leaf early blight')),
    );
    expect(
      afterOldPathCleared.latestDetection?.diseaseClass,
      'Tomato leaf late blight',
    );
  });

  test('parse Firestore collection document nested under data field', () {
    final parsed = debugParsePlantDetectionsCollection([
      const FirestoreDocumentData(
        id: 'DBt0mU8Lh6tN47Ga3kZv',
        data: {'data': detectionPayload},
      ),
    ]);

    expect(parsed.latestDetection?.diseaseClass, nestedDataDiseaseClass);
    expect(parsed.latestDetections, hasLength(2));
    expect(
      parsed.latestDetection?.snapshotUrl,
      'detections/20260419_115826_579585.jpg',
    );
  });

  test('parse document field detection id maps nested under data field', () {
    final parsed = debugParsePlantDetectionsDocument({
      'detection': {
        'DBt0mU8Lh6tN47Ga3kZv': {'data': detectionPayload},
      },
    });

    expect(parsed.latestDetection?.diseaseClass, nestedDataDiseaseClass);
    expect(parsed.latestDetections, hasLength(2));
    expect(
      parsed.latestDetection?.snapshotUrl,
      'detections/20260419_115826_579585.jpg',
    );
  });
}
