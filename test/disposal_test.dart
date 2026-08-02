import 'dart:async';

import 'package:dartfier/dartfier.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  group('disposal', () {
    testWidgets('a late write after the page is gone changes nothing', (
      tester,
    ) async {
      final Signal<int> count = Signal(0);
      final Computed<int> doubled = Computed(() => count.value * 2);

      await tester.pumpWidget(host(Observer((_) => Text('${doubled.value}'))));

      expect(find.text('0'), findsOneWidget);

      await tester.pumpWidget(host(const SizedBox()));

      doubled.dispose();
      count.dispose();

      expect(() => count.value = 5, returnsNormally);
      expect(() => count.update((int current) => current + 1), returnsNormally);
      expect(count.value, 0);
      expect(doubled.value, 0);

      await tester.pump();
    });

    testWidgets('an async callback resolving after dispose is harmless', (
      tester,
    ) async {
      final Signal<int> count = Signal(0);
      final Completer<int> request = Completer<int>();

      unawaited(request.future.then((int value) => count.value = value));

      await tester.pumpWidget(host(Observer((_) => Text('${count.value}'))));
      await tester.pumpWidget(host(const SizedBox()));

      count.dispose();
      request.complete(7);
      await tester.pump();

      expect(count.value, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an AsyncSignal run landing after dispose is dropped', (
      tester,
    ) async {
      final AsyncSignal<int> total = AsyncSignal<int>();
      final Completer<int> request = Completer<int>();

      await tester.pumpWidget(
        host(Observer((_) => Text('${total.value.valueOrNull ?? '—'}'))),
      );

      unawaited(total.run(() => request.future));
      await tester.pumpWidget(host(const SizedBox()));

      total.dispose();
      request.complete(42);
      await tester.pump();

      expect(total.peek().valueOrNull, isNull);
      expect(tester.takeException(), isNull);
    });

    test('a write to a disposed signal leaves its dependents alone', () {
      final Signal<int> count = Signal(1);
      final Computed<int> doubled = Computed(() => count.value * 2);

      int notifications = 0;
      doubled.addListener(() => notifications++);

      count.dispose();
      count.value = 10;

      expect(notifications, 0);
      expect(doubled.value, 2);
    });

    test('disposing twice is a no-op for every primitive', () {
      final Signal<int> count = Signal(0);
      final Computed<int> doubled = Computed(() => count.value * 2);
      final Effect effect = Effect((_) => doubled.value);
      final Watch<int> watcher = Watch(() => count.value, (_, _) {});

      doubled.value;

      expect(() {
        watcher.dispose();
        watcher.dispose();
        effect.dispose();
        effect.dispose();
        doubled.dispose();
        count.dispose();
      }, returnsNormally);
    });
  });
}
