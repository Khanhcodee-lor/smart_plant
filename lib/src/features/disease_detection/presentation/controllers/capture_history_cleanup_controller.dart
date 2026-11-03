import 'package:app_iot/src/core/services/firebase/firebase_firestore_service.dart';
import 'package:app_iot/src/core/services/firebase/firebase_realtime_database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CaptureHistoryCleanupResult {
  const CaptureHistoryCleanupResult({
    required this.deletedDocuments,
    required this.clearedParentDocuments,
  });

  final int deletedDocuments;
  final int clearedParentDocuments;
}

class CaptureHistoryCleanupService {
  const CaptureHistoryCleanupService(this._firestore, [this._realtimeDatabase]);

  final FirebaseFirestoreService _firestore;
  final FirebaseRealtimeDatabaseService? _realtimeDatabase;

  Future<CaptureHistoryCleanupResult> deleteAll(String plantId) async {
    final normalizedPlantId = plantId.trim();
    if (normalizedPlantId.isEmpty) {
      throw ArgumentError('Plant id must not be empty.');
    }

    if (_realtimeDatabase != null) {
      for (final path in [
        'plants/$normalizedPlantId/plant_captures',
        'plant/$normalizedPlantId/plant_captures',
        'plants/$normalizedPlantId/latest_disease',
        'plant/$normalizedPlantId/latest_disease',
        'plants/$normalizedPlantId/diseaseDetection',
        'plant/$normalizedPlantId/diseaseDetection',
        'plants/$normalizedPlantId/detections',
        'plant/$normalizedPlantId/detections',
        'plants/$normalizedPlantId/detection',
        'plant/$normalizedPlantId/detection',
        'plants/$normalizedPlantId/latest_snapshot_url',
        'plant/$normalizedPlantId/latest_snapshot_url',
        'plants/$normalizedPlantId/latest_captured_at',
        'plant/$normalizedPlantId/latest_captured_at',
      ]) {
        try {
          await _realtimeDatabase.deleteData(path);
        } catch (_) {}
      }
    }

    var deletedDocuments = 0;
    for (final path in captureHistoryCollectionPaths(normalizedPlantId)) {
      try {
        deletedDocuments += await _firestore.deleteCollectionDocuments(path);
      } on FirebaseException catch (error) {
        if (!_canIgnoreCleanupPathError(error)) {
          rethrow;
        }
      }
    }

    var clearedParentDocuments = 0;
    for (final path in captureHistoryParentDocumentPaths(normalizedPlantId)) {
      try {
        await _firestore.updateData(path, clearLatestDetectionFields());
        clearedParentDocuments += 1;
      } on FirebaseException catch (error) {
        if (!_canIgnoreCleanupPathError(error)) {
          rethrow;
        }
      }
    }

    return CaptureHistoryCleanupResult(
      deletedDocuments: deletedDocuments,
      clearedParentDocuments: clearedParentDocuments,
    );
  }
}

List<String> captureHistoryCollectionPaths(String plantId) {
  final normalized = plantId.trim();
  return [
    'plant/$normalized/plant_captures',
    'plants/$normalized/plant_captures',
    'plant/$normalized/detections',
    'plants/$normalized/detections',
    'plant/$normalized/detection',
    'plants/$normalized/detection',
    'plant/$normalized/disease_detections',
    'plants/$normalized/disease_detections',
    'plant/$normalized/diseaseDetections',
    'plants/$normalized/diseaseDetections',
  ];
}

List<String> captureHistoryParentDocumentPaths(String plantId) {
  final normalized = plantId.trim();
  return ['plant/$normalized', 'plants/$normalized'];
}

Map<String, dynamic> clearLatestDetectionFields() {
  final delete = FieldValue.delete();
  return {
    'latest_detection_at': delete,
    'latestDetectionAt': delete,
    'latest_detected_at': delete,
    'latest_detection_id': delete,
    'latestDetectionId': delete,
    'latest_detection_path': delete,
    'latestDetectionPath': delete,
    'latest_diseases': delete,
    'latestDiseases': delete,
    'latest_objects': delete,
    'latestObjects': delete,
    'detected_objects': delete,
    'detectedObjects': delete,
    'latest_total_objects': delete,
    'latestTotalObjects': delete,
    'latest_snapshot_path': delete,
    'latest_snapshot_url': delete,
    'latest_annotated_frame_storage_path': delete,
    'latest_annotated_frame_url': delete,
    'annotated_frame_storage_path': delete,
    'annotatedFrameStoragePath': delete,
    'annotated_frame_url': delete,
    'annotatedFrameUrl': delete,
    'annotated_image_url': delete,
    'annotatedImageUrl': delete,
    'processed_frame_storage_path': delete,
    'processedFrameStoragePath': delete,
    'processed_frame_url': delete,
    'processedFrameUrl': delete,
    'processed_image_url': delete,
    'processedImageUrl': delete,
    'output_frame_storage_path': delete,
    'outputFrameStoragePath': delete,
    'output_frame_url': delete,
    'outputFrameUrl': delete,
    'output_image_url': delete,
    'outputImageUrl': delete,
    'result_frame_storage_path': delete,
    'resultFrameStoragePath': delete,
    'result_frame_url': delete,
    'resultFrameUrl': delete,
    'result_image_url': delete,
    'resultImageUrl': delete,
    'snapshot': delete,
    'snapshotUrl': delete,
    'detections': delete,
    'diseaseDetection': delete,
    'detection': delete,
    'latest': delete,
    'latestDetection': delete,
    'currentDetection': delete,
    'history': delete,
    'detectionHistory': delete,
  };
}

bool _canIgnoreCleanupPathError(FirebaseException error) {
  return error.code == 'not-found' || error.code == 'permission-denied';
}

final captureHistoryCleanupServiceProvider =
    Provider<CaptureHistoryCleanupService>((ref) {
      final firestore = ref.watch(firebaseFirestoreServiceProvider);
      final database = ref.watch(firebaseRealtimeDatabaseServiceProvider);
      return CaptureHistoryCleanupService(firestore, database);
    });

final captureHistoryCleanupInFlightProvider = StateProvider.autoDispose
    .family<bool, String>((ref, plantId) => false);
