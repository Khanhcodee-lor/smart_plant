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

  test('prefer processed Firestore image and Vietnamese disease name', () {
    final parsed = debugParsePlantDetectionsCollection([
      const FirestoreDocumentData(
        id: 'new',
        path: 'plants/tomato_001/detections/new',
        data: {
          'class_name': 'La ca chua benh moc suong',
          'class_name_en': 'Tomato leaf late blight',
          'confidence': 0.42,
          'captured_at': '2026-05-11T12:00:00',
          'image': 'detections/pi_original.jpg',
          'processed_frame_storage_path': 'detections/pi_processed.jpg',
        },
      ),
    ]);

    expect(parsed.latestDetection?.diseaseClass, 'La ca chua benh moc suong');
    expect(parsed.latestDetection?.snapshotUrl, 'detections/pi_processed.jpg');
    expect(parsed.latestCapturedAt, '2026-05-11 12:00:00');
  });

  test('captured_at decides newest Firestore detection before confidence', () {
    final parsed = debugParsePlantDetectionsCollection([
      const FirestoreDocumentData(
        id: 'old',
        path: 'plants/tomato_001/detections/old',
        data: {
          'class_name': 'Old disease',
          'confidence': 0.99,
          'captured_at': '2026-05-11T10:00:00',
        },
      ),
      const FirestoreDocumentData(
        id: 'new',
        path: 'plants/tomato_001/detections/new',
        data: {
          'class_name': 'New disease',
          'confidence': 0.1,
          'captured_at': '2026-05-11T13:00:00',
        },
      ),
    ]);

    expect(parsed.latestDetection?.diseaseClass, 'New disease');
    expect(parsed.latestCapturedAt, '2026-05-11 13:00:00');
  });

  test('latest objects expose multiple unique diseases before top summary', () {
    final parsed = debugParsePlantDetectionsDocument({
      'latest_detection_at': '2026-05-11T14:05:35',
      'latest_diseases': ['Lá cà chua bệnh mốc lá'],
      'latest_objects': [
        {'class': 'Lá cà chua bệnh mốc lá', 'confidence': 0.29},
        {'class': 'Lá cà chua bệnh đốm vi khuẩn', 'confidence': 0.67},
        {'class': 'Lá cà chua bệnh đốm vi khuẩn', 'confidence': 0.81},
      ],
    });

    expect(parsed.latestDetections.map((item) => item.diseaseClass), [
      'Lá cà chua bệnh đốm vi khuẩn',
      'Lá cà chua bệnh mốc lá',
    ]);
    expect(parsed.latestDetections.first.confidence, 0.81);
  });

  test(
    'snapshot-only Firestore result is data and does not invent old disease',
    () {
      final parsed = debugParsePlantDetectionsDocument({
        'processed_frame_storage_path': 'detections/no_detection_processed.jpg',
        'captured_at': '2026-05-11T14:00:00',
      });

      expect(parsed.hasAnyData, isTrue);
      expect(parsed.latestDetection, isNull);
      expect(parsed.latestSnapshotUrl, 'detections/no_detection_processed.jpg');
      expect(parsed.latestCapturedAt, '2026-05-11 14:00:00');
    },
  );

  test(
    'new snapshot-only collection document replaces old disease on latest UI',
    () {
      final parsed = debugParsePlantDetectionsCollection([
        const FirestoreDocumentData(
          id: 'old',
          path: 'plant/tomato_001/detections/old',
          data: {
            'class_name': 'Old disease',
            'confidence': 0.91,
            'annotated_frame_local_saved_at': '2026-05-11T10:00:00',
            'annotated_frame_storage_path': 'detections/old.jpg',
          },
        ),
        const FirestoreDocumentData(
          id: 'new',
          path: 'plant/tomato_001/detections/new',
          data: {
            'latest_total_objects': 0,
            'all_classes_detected': <String>[],
            'all_classes_detected_en': <String>[],
            'annotated_frame_local_saved_at': '2026-05-11T13:11:17',
            'annotated_frame_storage_path': 'detections/new_processed.jpg',
          },
        ),
      ]);

      expect(
        parsed.latestDetection?.diseaseClass,
        'Kh\u00f4ng ph\u00e1t hi\u1ec7n b\u1ec7nh',
      );
      expect(parsed.latestDetections, hasLength(1));
      expect(parsed.latestSnapshotUrl, 'detections/new_processed.jpg');
      expect(parsed.latestCapturedAt, '2026-05-11 13:11:17');
      expect(
        parsed.history.map((item) => item.diseaseClass),
        contains('Old disease'),
      );
      expect(parsed.history, hasLength(2));
    },
  );

  test('history keeps each Pi capture document including no-disease docs', () {
    final parsed = debugParsePlantDetectionsCollection([
      const FirestoreDocumentData(
        id: 'first',
        path: 'plant/tomato_001/detections/first',
        data: {
          'annotated_frame_local_saved_at': '2026-05-11T10:00:00',
          'annotated_frame_storage_path': 'detections/first.jpg',
          'latest_total_objects': 0,
          'all_classes_detected': <String>[],
        },
      ),
      const FirestoreDocumentData(
        id: 'second',
        path: 'plant/tomato_001/detections/second',
        data: {
          'class_name': 'Tomato septoria leaf spot',
          'confidence': 0.87,
          'annotated_frame_local_saved_at': '2026-05-11T11:00:00',
          'annotated_frame_storage_path': 'detections/second.jpg',
        },
      ),
      const FirestoreDocumentData(
        id: 'third',
        path: 'plant/tomato_001/detections/third',
        data: {
          'annotated_frame_local_saved_at': '2026-05-11T12:00:00',
          'annotated_frame_storage_path': 'detections/third.jpg',
          'latest_total_objects': 0,
          'all_classes_detected': <String>[],
        },
      ),
    ]);

    expect(parsed.history, hasLength(3));
    expect(
      parsed.latestDetection?.diseaseClass,
      'Kh\u00f4ng ph\u00e1t hi\u1ec7n b\u1ec7nh',
    );
    expect(parsed.latestSnapshotUrl, 'detections/third.jpg');
  });

  test(
    'parent no-disease latest metadata wins over old collection disease',
    () {
      final parent = debugParsePlantDetectionsDocument({
        'latest_detection_at': '2026-05-11T13:11:17',
        'latest_total_objects': 0,
        'latest_diseases': <String>[],
        'latest_objects': <String>[],
      });
      final collection = debugParsePlantDetectionsCollection([
        const FirestoreDocumentData(
          id: 'old',
          path: 'plant/tomato_001/detections/old',
          data: {
            'class_name': 'Old disease',
            'confidence': 0.91,
            'annotated_frame_local_saved_at': '2026-05-11T10:00:00',
            'annotated_frame_storage_path': 'detections/old.jpg',
          },
        ),
      ]);

      final merged = debugMergePlantDetections(parent, collection);

      expect(merged.latestDetection, isNull);
      expect(merged.latestDetections, isEmpty);
      expect(merged.latestCapturedAt, '2026-05-11 13:11:17');
      expect(
        merged.history.map((item) => item.diseaseClass),
        contains('Old disease'),
      );
    },
  );

  test('parse Firestore latest and history node', () {
    final parsed = debugParsePlantDetectionsDocument({
      'latest': {
        'class': 'Tomato leaf bacterial spot',
        'confidence': 0.91,
        'time': '2026-05-11 13:20:00',
        'snapshot': 'detections/pi_latest.jpg',
      },
      'history': {
        '-old': {
          'class': 'Tomato leaf late blight',
          'confidence': 0.72,
          'time': '2026-05-11 12:20:00',
          'snapshot': 'detections/pi_old.jpg',
        },
      },
    });

    expect(parsed.latestDetection?.diseaseClass, 'Tomato leaf bacterial spot');
    expect(parsed.latestDetection?.snapshotUrl, 'detections/pi_latest.jpg');
    expect(parsed.latestCapturedAt, '2026-05-11 13:20:00');
    expect(
      parsed.history.map((item) => item.diseaseClass),
      contains('Tomato leaf late blight'),
    );
  });

  test('same timestamp metadata prefers collection snapshot over parent', () {
    final parent = debugParsePlantDetectionsDocument({
      'latest_detection_at': '2026-05-11T13:11:17',
      'latest_total_objects': 0,
      'latest_diseases': <String>[],
      'latest_objects': <String>[],
    });
    final collection = debugParsePlantDetectionsCollection([
      const FirestoreDocumentData(
        id: 'latest',
        path: 'plant/tomato_001/detections/latest',
        data: {
          'annotated_frame_local_saved_at': '2026-05-11T13:11:17',
          'annotated_frame_storage_path': 'detections/latest.jpg',
          'latest_total_objects': 0,
          'all_classes_detected': <String>[],
        },
      ),
    ]);

    final merged = debugMergePlantDetections(parent, collection);

    expect(merged.latestSnapshotUrl, 'detections/latest.jpg');
    expect(merged.latestCapturedAt, '2026-05-11 13:11:17');
  });

  test('parse Firestore full plant node containing detections latest', () {
    final parsed = debugParsePlantDetectionsDocument({
      'detections': {
        'latest': {
          'class': 'Tomato leaf bacterial spot',
          'confidence': 0.91,
          'time': '2026-05-11 13:20:00',
          'snapshot': 'detections/pi_latest.jpg',
        },
      },
    });

    expect(parsed.latestDetection?.diseaseClass, 'Tomato leaf bacterial spot');
    expect(parsed.latestSnapshotUrl, 'detections/pi_latest.jpg');
  });
}
