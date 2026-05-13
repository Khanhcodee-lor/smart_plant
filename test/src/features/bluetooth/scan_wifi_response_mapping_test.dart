import 'package:app_iot/src/features/bluetooth/domain/models/pi_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PiResponse map đúng response scan_wifi', () {
    final response = PiResponse.fromJson({
      'ok': true,
      'action': 'scan_wifi',
      'networks': [
        {'ssid': 'Home', 'signal': 78, 'security': 'WPA2'},
        {'ssid': 'Guest', 'signal': 42, 'security': 'Open'},
      ],
    });

    expect(response.ok, isTrue);
    expect(response.action, 'scan_wifi');
    expect(response.networks, hasLength(2));
    expect(response.networks.first.ssid, 'Home');
    expect(response.networks.first.signal, 78);
    expect(response.networks.first.security, 'WPA2');
    expect(response.networks.last.requiresPassword, isFalse);
  });
}
