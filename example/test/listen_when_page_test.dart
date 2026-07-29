import 'package:example/pages/listen_when_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ListenWhenPage logs changes, not notifications', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ListenWhenPage()));

    expect(find.text('No change logged yet'), findsOneWidget);

    await tester.tap(find.text('+1'));
    await tester.pump();

    expect(find.textContaining('count: 0 → 1'), findsOneWidget);
    expect(find.textContaining('parity: even → odd'), findsOneWidget);

    await tester.tap(find.text('Skip 2'));
    await tester.pump();

    expect(find.textContaining('count: 1 → 3'), findsOneWidget);
    expect(find.textContaining('parity:'), findsOneWidget);

    await tester.tap(find.text('Burst +3'));
    await tester.pump();

    expect(find.textContaining('count: 3 → 6'), findsOneWidget);
    expect(find.textContaining('count: 4 →'), findsNothing);
    expect(find.textContaining('count: 5 →'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ListenWhenPage awaits AsyncData through when', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ListenWhenPage()));

    await tester.ensureVisible(find.text('Fetch and await AsyncData'));
    await tester.pump();

    await tester.tap(find.text('Fetch and await AsyncData'));
    await tester.pump();

    expect(find.textContaining('run started'), findsOneWidget);
    expect(find.textContaining('when completed'), findsNothing);

    await tester.pump(const Duration(milliseconds: 900));

    expect(find.textContaining('when completed with 42'), findsOneWidget);
    expect(find.text('total: 42'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
