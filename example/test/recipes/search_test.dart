import 'package:example/recipes/search/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SearchPage: a burst of keystrokes fires a single fetch', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchPage()));

    await tester.enterText(find.byType(TextField), 'm');
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'ma');
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'man');
    await tester.pump();

    expect(find.text('fetches: 0'), findsOneWidget);
    expect(find.text('Type to search'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('fetches: 1'), findsOneWidget);
    expect(find.text('Searching…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('fetches: 1'), findsOneWidget);
    expect(find.text('3 matches'), findsOneWidget);
    expect(find.text('Mango'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('SearchPage: the previous matches stay through the refetch', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchPage()));

    await tester.enterText(find.byType(TextField), 'man');
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('3 matches'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'pea');
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('Searching… (still showing 3 from the last query)'),
      findsOneWidget,
    );
    expect(find.text('Mango'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('2 matches'), findsOneWidget);
    expect(find.text('Peach'), findsOneWidget);
    expect(find.text('Mango'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
