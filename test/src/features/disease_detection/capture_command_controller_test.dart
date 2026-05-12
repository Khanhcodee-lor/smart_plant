import 'package:app_iot/src/core/services/firebase/firebase_realtime_database_service.dart';
import 'package:app_iot/src/features/disease_detection/presentation/controllers/capture_command_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('build capture command path under plants root', () {
    expect(
      buildPlantCaptureCommandPath('tomato_001'),
      'plants/tomato_001/commands/capture',
    );
  });

  test('build capture payload writes status request id and timestamp', () {
    final now = DateTime.utc(2026, 4, 28, 0, 53, 18, 349, 940);
    final payload = buildPlantCaptureCommandPayload(
      now: now,
      requestId: 'manual_test_request',
    );

    expect(payload['status'], 1);
    expect(payload['request_id'], 'manual_test_request');
    expect(payload['timestamp'], now.millisecondsSinceEpoch / 1000);
  });

  test('build request-only capture payload omits status', () {
    final now = DateTime.utc(2026, 4, 28, 0, 53, 18, 349, 940);
    final payload = buildPlantCaptureRequestOnlyPayload(
      now: now,
      requestId: 'manual_test_request',
    );

    expect(payload.containsKey('status'), isFalse);
    expect(payload['request_id'], 'manual_test_request');
    expect(payload['timestamp'], now.millisecondsSinceEpoch / 1000);
  });

  test('request capture overwrites command node without status', () async {
    final database = _FakeRealtimeDatabaseService();
    final service = PlantCaptureCommandService(database);

    final requestId = await service.requestCapture(' tomato_001 ');

    expect(database.sets, hasLength(1));
    expect(database.updates, isEmpty);
    expect(database.sets[0].path, 'plants/tomato_001/commands/capture');
    expect(database.sets[0].data, isA<Map<String, dynamic>>());
    final data = database.sets[0].data as Map<String, dynamic>;
    expect(data.containsKey('status'), isFalse);
    expect(requestId, startsWith('manual_'));
    expect(data['request_id'], requestId);
  });
}

class _FakeRealtimeDatabaseService implements FirebaseRealtimeDatabaseService {
  final updates = <_DatabaseUpdate>[];
  final sets = <_DatabaseSet>[];

  @override
  Future<dynamic> getData(String path) async => null;

  @override
  Future<void> setData(String path, Object? data) async {
    sets.add(_DatabaseSet(path, data));
  }

  @override
  Future<void> updateData(String path, Map<String, dynamic> data) async {
    updates.add(_DatabaseUpdate(path, Map<String, dynamic>.from(data)));
  }
}

class _DatabaseUpdate {
  const _DatabaseUpdate(this.path, this.data);

  final String path;
  final Map<String, dynamic> data;
}

class _DatabaseSet {
  const _DatabaseSet(this.path, this.data);

  final String path;
  final Object? data;
}
