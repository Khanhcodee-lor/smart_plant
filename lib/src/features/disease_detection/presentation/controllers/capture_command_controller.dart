import 'package:app_iot/src/core/services/firebase/firebase_realtime_database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlantCaptureCommandService {
  const PlantCaptureCommandService(this._database);

  final FirebaseRealtimeDatabaseService _database;

  Future<void> requestCapture(String plantId) async {
    final normalizedPlantId = plantId.trim();
    if (normalizedPlantId.isEmpty) {
      throw ArgumentError('Plant id must not be empty.');
    }

    final now = DateTime.now().toUtc();
    await _database.updateData(
      buildPlantCaptureCommandPath(normalizedPlantId),
      buildPlantCaptureCommandPayload(now: now),
    );
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
}) {
  return {
    'status': 1,
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

final plantCaptureCommandInFlightProvider =
    StateProvider.autoDispose.family<bool, String>((ref, plantId) => false);
