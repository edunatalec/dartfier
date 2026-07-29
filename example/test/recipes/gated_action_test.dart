import 'package:example/recipes/gated_action/gated_action_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GatedActionPage: an already loaded profile resolves at once', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GatedActionPage()));

    await tester.tap(find.text('Load profile'));
    await tester.pump(const Duration(milliseconds: 1300));

    expect(find.textContaining('profile: Ana Ribeiro'), findsOneWidget);

    await tester.tap(find.text('Share profile'));
    await tester.pump();

    expect(
      find.textContaining('already loaded, when resolves immediately'),
      findsOneWidget,
    );
    expect(find.textContaining('shared @ana'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('GatedActionPage: sharing mid-flight waits for the profile', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GatedActionPage()));

    await tester.tap(find.text('Load profile'));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Share profile'));
    await tester.pump();

    expect(
      find.textContaining('share tapped — awaiting the profile'),
      findsOneWidget,
    );
    expect(find.textContaining('shared @ana'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.textContaining('shared @ana'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('GatedActionPage: an error never satisfies the condition', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GatedActionPage()));

    await tester.tap(find.text('Break the backend'));
    await tester.pump(const Duration(milliseconds: 1300));

    expect(find.textContaining('profile: failed'), findsOneWidget);

    await tester.tap(find.text('Share profile'));
    await tester.pump(const Duration(seconds: 2));

    expect(find.textContaining('gave up'), findsNothing);

    await tester.pump(const Duration(seconds: 2));

    expect(
      find.textContaining('gave up after 3s — nothing shared'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
