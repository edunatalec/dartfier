import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reentrancy', () {
    test('skips a computed a listener disposed during the flush', () {
      final Signal<int> count = Signal(1);
      final Computed<int> doubled = Computed(() => count.value * 2);
      final Computed<int> tripled = Computed(() => count.value * 3);
      final Computed<int> quadrupled = Computed(() => count.value * 4);
      doubled.value;
      tripled.value;
      quadrupled.value;

      doubled.addListener(tripled.dispose);
      tripled.addListener(() {});

      int notifications = 0;
      quadrupled.addListener(() => notifications++);

      count.value = 2;

      expect(notifications, 1);
      expect(quadrupled.value, 8);
    });

    test('drops the pending notification of a signal disposed mid-flush', () {
      final Signal<int> first = Signal(0);
      final Signal<int> second = Signal(0);

      first.addListener(second.dispose);
      second.addListener(() {});

      batch(() {
        first.value = 1;
        second.value = 1;
      });

      expect(second.value, 1);
    });

    test('notifies once per batch for a source two of them write', () {
      final Signal<int> first = Signal(0);
      final Signal<int> second = Signal(0);
      final Signal<int> total = Signal(0);

      first.addListener(() => batch(() => total.value = total.peek() + 1));
      second.addListener(() => batch(() => total.value = total.peek() + 1));

      int notifications = 0;
      total.addListener(() => notifications++);

      batch(() {
        first.value = 1;
        second.value = 1;
      });

      expect(total.value, 2);
      expect(notifications, 2);
    });

    test('notifies immediately for a write made after the batch closed', () {
      final Signal<int> count = Signal(0);
      final Signal<String> mirror = Signal('');

      count.addListener(() => mirror.value = 'saw ${count.peek()}');

      final List<String> seen = <String>[];
      mirror.addListener(() => seen.add(mirror.peek()));

      batch(() {
        count.value = 1;
        count.value = 2;
      });

      expect(seen, <String>['saw 2']);
    });

    test('keeps the flush consistent when a compute opens a batch', () {
      final Signal<int> count = Signal(1);
      final Signal<int> audit = Signal(0);
      final Computed<int> doubled = Computed(() {
        batch(() => audit.value = audit.peek() + 1);

        return count.value * 2;
      });
      doubled.value;

      int notifications = 0;
      doubled.addListener(() => notifications++);

      count.value = 5;

      expect(doubled.value, 10);
      expect(notifications, 1);
      expect(audit.value, 2);
    });

    test('keeps a listener read out of the effect dependencies', () async {
      final Signal<int> trigger = Signal(1);
      final Signal<int> target = Signal(0);
      final Signal<int> unrelated = Signal(0);

      final List<int> seen = <int>[];
      target.addListener(() => seen.add(unrelated.value));

      int runs = 0;
      final Effect effect = Effect((_) {
        runs++;
        target.value = trigger.value;
      });

      expect(runs, 1);

      unrelated.value = 99;
      await pumpEventQueue();

      expect(runs, 1);

      effect.dispose();
    });

    test('recovers the propagation state after a batch flush throws', () {
      final Signal<int> count = Signal(1);
      final Computed<int> failing = Computed<int>(
        () => count.value == 2 ? throw StateError('boom') : count.value * 10,
      );
      failing.value;
      failing.addListener(() {});

      expect(() => batch(() => count.value = 2), throwsStateError);

      final Signal<int> other = Signal(0);
      int notifications = 0;
      other.addListener(() => notifications++);

      batch(() {
        count.value = 3;
        other.value = 1;
      });

      expect(notifications, 1);
      expect(failing.value, 30);
    });

    test(
      'cancels a rerun of an effect a listener disposed mid-flush',
      () async {
        final Signal<int> count = Signal(0);
        final List<int> log = <int>[];

        final Effect effect = Effect((_) => log.add(count.value));
        count.addListener(effect.dispose);

        count.value = 1;
        await pumpEventQueue();

        expect(log, <int>[0]);
      },
    );

    testWidgets('stops rebuilding an observer removed from the tree', (
      WidgetTester tester,
    ) async {
      final Signal<int> count = Signal(0);

      int builds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Observer((_) {
            builds++;

            return Text('${count.value}');
          }),
        ),
      );

      expect(builds, 1);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      count.value = 1;
      await tester.pump();

      expect(builds, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
