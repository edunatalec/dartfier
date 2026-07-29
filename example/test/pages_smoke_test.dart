import 'package:example/main.dart';
import 'package:example/pages/async_signal_page.dart';
import 'package:example/pages/computed_page.dart';
import 'package:example/pages/effect_page.dart';
import 'package:example/pages/listen_when_page.dart';
import 'package:example/pages/observer_page.dart';
import 'package:example/pages/readonly_signal_page.dart';
import 'package:example/pages/signal_page.dart';
import 'package:example/pages/untracked_peek_page.dart';
import 'package:example/pages/value_listenable_page.dart';
import 'package:example/recipes/cart/cart_page.dart';
import 'package:example/recipes/gated_action/gated_action_page.dart';
import 'package:example/recipes/search/search_page.dart';
import 'package:example/recipes/session/session_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _pages = <Widget>[
  SignalPage(),
  ComputedPage(),
  ReadonlySignalPage(),
  EffectPage(),
  ObserverPage(),
  AsyncSignalPage(),
  ListenWhenPage(),
  UntrackedPeekPage(),
  ValueListenablePage(),
  SessionPage(),
  SearchPage(),
  CartPage(),
  GatedActionPage(),
];

void main() {
  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('home lists the API tour and the recipes', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('API TOUR'), findsOneWidget);
    expect(find.text('Signal'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Session events'), 100);

    expect(find.text('REAL-WORLD RECIPES'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Action with a prerequisite'),
      100,
    );

    expect(find.text('Action with a prerequisite'), findsOneWidget);
  });

  testWidgets('every page builds and disposes without throwing', (
    tester,
  ) async {
    for (final Widget page in _pages) {
      await pumpPage(tester, page);
    }
  });

  testWidgets('every page lays out on a phone-sized screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final Widget page in _pages) {
      await pumpPage(tester, page);
    }
  });
}
