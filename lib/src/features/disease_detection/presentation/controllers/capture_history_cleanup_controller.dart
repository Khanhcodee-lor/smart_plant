import 'package:app_iot/src/core/services/firebase/firebase_firestore_service.dart';
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
  const CaptureHistoryCleanupService(this._firestore);

  final FirebaseFirestoreService _firestore;

  Future<CaptureHistoryCleanupResult> deleteAll(String plantId) async {
    final normalizedPlantId = plantId.trim();
    if (normalizedPlantId.isEmpty) {
      throw ArgumentError('Plant id must not be empty.');
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
      return CaptureHistoryCleanupService(firestore);
    });

final captureHistoryCleanupInFlightProvider = StateProvider.autoDispose
    .family<bool, String>((ref, plantId) => false);
