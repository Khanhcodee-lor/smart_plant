import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('widget test harness smoke test', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('IoT Plant Doctor'))),
    );

    expect(find.text('IoT Plant Doctor'), findsOneWidget);
  });
}
