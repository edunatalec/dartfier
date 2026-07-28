import 'package:example/main.dart';
import 'package:example/pages/async_signal_page.dart';
import 'package:example/pages/computed_page.dart';
import 'package:example/pages/effect_page.dart';
import 'package:example/pages/observer_page.dart';
import 'package:example/pages/readonly_signal_page.dart';
import 'package:example/pages/signal_page.dart';
import 'package:example/pages/untracked_peek_page.dart';
import 'package:example/pages/value_listenable_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('home lists every example page', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Signal'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('ValueListenable interop'), 100);

    expect(find.text('ValueListenable interop'), findsOneWidget);
  });

  testWidgets('every page builds and disposes without throwing', (
    tester,
  ) async {
    const pages = <Widget>[
      SignalPage(),
      ComputedPage(),
      ReadonlySignalPage(),
      EffectPage(),
      ObserverPage(),
      AsyncSignalPage(),
      UntrackedPeekPage(),
      ValueListenablePage(),
    ];

    for (final Widget page in pages) {
      await pumpPage(tester, page);
    }
  });
}
