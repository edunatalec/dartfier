import 'package:example/recipes/session/session_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'SessionPage: the Effect fires on creation, the listen does not',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SessionPage()));
      await tester.pump();

      expect(find.textContaining('current: signedOut'), findsOneWidget);
      expect(find.text('No transition yet'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('SessionPage: the listen carries previous → next', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SessionPage()));
    await tester.pump();

    await tester.tap(find.text('Sign in as ana'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('signedOut → signedIn(ana)'), findsOneWidget);
    expect(find.text('Welcome, ana'), findsOneWidget);

    await tester.tap(find.text('Switch to bruno'));
    await tester.pump();
    await tester.pump();

    expect(
      find.textContaining('signedIn(ana) → signedIn(bruno)'),
      findsOneWidget,
    );
    expect(
      find.text('Switched from ana to bruno — dropping ana cache'),
      findsOneWidget,
    );
    expect(find.textContaining('current: signedIn(bruno)'), findsOneWidget);

    await tester.tap(find.text('Expire'));
    await tester.pump();
    await tester.pump();

    expect(
      find.textContaining('signedIn(bruno) → expired(bruno)'),
      findsOneWidget,
    );
    expect(find.text('Session expired — sign in again'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('SessionPage: signing out reacts once, on the transition', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SessionPage()));
    await tester.pump();

    await tester.tap(find.text('Sign in as ana'));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Sign out'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Signed out — back to login'), findsOneWidget);
    expect(find.textContaining('signedIn(ana) → signedOut'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('signedOut → signedOut'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
