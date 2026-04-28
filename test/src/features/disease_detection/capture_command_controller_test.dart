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
}
