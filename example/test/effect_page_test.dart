import 'package:example/pages/effect_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EffectPage ticks without rescheduling its effect', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: EffectPage()));

    expect(find.textContaining('started 1000ms timer'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('tick 1 (period 1000ms)'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('tick 2 (period 1000ms)'), findsOneWidget);
    expect(find.textContaining('started 1000ms timer'), findsOneWidget);
    expect(find.textContaining('cleanup: cancelled'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
