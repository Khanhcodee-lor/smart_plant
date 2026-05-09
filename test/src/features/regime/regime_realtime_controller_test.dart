import 'package:app_iot/src/features/regime/presentation/controllers/regime_realtime_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse realtime sensor and pump control data', () {
    final data = RegimeRealtimeData.fromDatabase({
      'sensor': {
        'air': {'humidity': 67, 'temperature_c': 28.1},
        'soil': {'moisture_percent': 42.5},
        'updated_at': '2026-05-08T11:20:00Z',
      },
      'control': {
        'pump': {
          'mode': 'auto',
          'command': 'auto',
          'enabled': true,
          'updated_at': '2026-05-08T11:21:00Z',
        },
      },
    });

    expect(data.temperature, 28.1);
    expect(data.humidity, 67);
    expect(data.soilMoisture, 42.5);
    expect(data.updatedAt, '2026-05-08T11:20:00Z');
    expect(data.pump.isAutomatic, isTrue);
    expect(data.pump.displayLabel, 'Bơm tự động');
  });

  test('build pump control path under realtime plant node', () {
    expect(buildPumpControlPath('tomato_001'), 'plant/tomato_001/control/pump');
  });

  test('build automatic pump payload', () {
    final payload = buildPumpControlPayload(
      action: PumpControlAction.automatic,
      now: DateTime.utc(2026, 5, 8, 11, 20),
    );

    expect(payload['mode'], 'auto');
    expect(payload['command'], 'auto');
    expect(payload['enabled'], isTrue);
    expect(payload['manual_override'], isFalse);
    expect(payload['updated_by'], 'app');
  });

  test('build manual off pump payload', () {
    final payload = buildPumpControlPayload(
      action: PumpControlAction.manualOff,
      now: DateTime.utc(2026, 5, 8, 11, 20),
    );

    expect(payload['mode'], 'manual');
    expect(payload['command'], 'off');
    expect(payload['enabled'], isFalse);
    expect(payload['manual_override'], isTrue);
    expect(payload['updated_by'], 'app');
  });
}
