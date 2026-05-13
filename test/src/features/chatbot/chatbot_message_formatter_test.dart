import 'package:app_iot/src/features/chatbot/presentation/utils/chatbot_message_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('format assistant markdown into plain readable text', () {
    const input = '''
### I. Nguyên nhân gây bệnh Mốc Sương trên Cà Chua

Nguyên nhân chính là **_Phytophthora infestans_**.

**Điều kiện lý tưởng**
* **Thời tiết:** Mát mẻ
* **Lây lan:** Qua gió

---

[Xem thêm](https://example.com)
''';

    final output = formatAssistantMessageForDisplay(input);

    expect(output, contains('I. Nguyên nhân gây bệnh Mốc Sương trên Cà Chua'));
    expect(output, contains('Nguyên nhân chính là Phytophthora infestans.'));
    expect(output, contains('Điều kiện lý tưởng'));
    expect(output, contains('• Thời tiết: Mát mẻ'));
    expect(output, contains('• Lây lan: Qua gió'));
    expect(output, isNot(contains('###')));
    expect(output, isNot(contains('**')));
    expect(output, isNot(contains('---')));
    expect(output, isNot(contains('[Xem thêm]')));
  });
}
