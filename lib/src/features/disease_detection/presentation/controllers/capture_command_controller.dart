import 'package:app_iot/src/core/services/firebase/firebase_realtime_database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlantCaptureCommandService {
  const PlantCaptureCommandService(this._database);

  final FirebaseRealtimeDatabaseService _database;

  Future<String> requestCapture(String plantId) async {
    final normalizedPlantId = plantId.trim();
    if (normalizedPlantId.isEmpty) {
      throw ArgumentError('Plant id must not be empty.');
    }

    final now = DateTime.now().toUtc();
    final requestId = buildPlantCaptureRequestId(now);
    final path = buildPlantCaptureCommandPath(normalizedPlantId);
    await _database.setData(
      path,
      buildPlantCaptureRequestOnlyPayload(now: now, requestId: requestId),
    );
    return requestId;
  }
}

String buildPlantCaptureCommandPath(String plantId) {
  return 'plants/${plantId.trim()}/commands/capture';
}

String buildPlantCaptureRequestId(DateTime now) {
  return 'manual_${now.millisecondsSinceEpoch}_${now.microsecondsSinceEpoch.remainder(1000000).toRadixString(16)}';
}

Map<String, dynamic> buildPlantCaptureCommandPayload({
  required DateTime now,
  String? requestId,
  int status = 1,
}) {
  return {
    'status': status,
    'request_id': requestId ?? buildPlantCaptureRequestId(now),
    'timestamp': now.millisecondsSinceEpoch / 1000,
  };
}

Map<String, dynamic> buildPlantCaptureRequestOnlyPayload({
  required DateTime now,
  String? requestId,
}) {
  return {
    'request_id': requestId ?? buildPlantCaptureRequestId(now),
    'timestamp': now.millisecondsSinceEpoch / 1000,
  };
}

final plantCaptureCommandServiceProvider = Provider<PlantCaptureCommandService>(
  (ref) {
    final database = ref.watch(firebaseRealtimeDatabaseServiceProvider);
    return PlantCaptureCommandService(database);
  },
);

final plantCaptureCommandInFlightProvider = StateProvider.autoDispose
    .family<bool, String>((ref, plantId) => false);

final plantCaptureSnapshotRefreshKeyProvider = StateProvider.autoDispose
    .family<String, String>((ref, plantId) => '');
