import 'package:app_iot/src/features/bluetooth/data/parsers/json_line_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JsonLineParser ghép chunk theo newline và parse an toàn', () {
    final parser = JsonLineParser();

    final first = parser.append('{"ok":true,"action":"ping"}\n{"ok":');
    final second = parser.append(
      'true,"action":"wifi_status","status":{"interface":"wlan0","state":"connected","connection":"Home","ip":"192.168.1.50"}}\n',
    );

    expect(first, hasLength(1));
    expect(first.first['action'], 'ping');

    expect(second, hasLength(1));
    expect(second.first['action'], 'wifi_status');
    expect(parser.pendingBuffer, isEmpty);
  });

  test(
    'JsonLineParser giữ được escape unicode khi chunk bị cắt giữa chuỗi',
    () {
      final parser = JsonLineParser();

      final first = parser.append(
        '{"ok":true,"action":"scan_wifi","networks":[{"ssid":"\\ud83d',
      );
      final second = parser.append(
        '\\ude43","signal":52,"security":"WPA1 WPA2"}]}\n',
      );

      expect(first, isEmpty);
      expect(second, hasLength(1));
      expect(second.first['action'], 'scan_wifi');
    },
  );
}
