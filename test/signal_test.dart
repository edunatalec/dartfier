import 'package:dartfier/dartfier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Signal', () {
    test('holds the initial value', () {
      final Signal<int> count = Signal(0);

      expect(count.value, 0);
    });

    test('notifies listeners when the value changes', () {
      final Signal<int> count = Signal(0);
      int notifications = 0;
      count.addListener(() => notifications++);

      count.value = 1;

      expect(count.value, 1);
      expect(notifications, 1);
    });

    test('does not notify when the new value is equal', () {
      final Signal<int> count = Signal(0);
      int notifications = 0;
      count.addListener(() => notifications++);

      count.value = 0;

      expect(notifications, 0);
    });

    test('ignores writes after dispose', () {
      final Signal<int> count = Signal(0);
      count.dispose();

      count.value = 1;

      expect(count.value, 0);
    });

    test('does not notify when equals judges the new value equal', () {
      final Signal<List<int>> items = Signal(<int>[1, 2], equals: listEquals);
      int notifications = 0;
      items.addListener(() => notifications++);

      items.value = <int>[1, 2];

      expect(notifications, 0);

      items.value = <int>[1, 2, 3];

      expect(notifications, 1);
    });

    test('leaves a dependent computed frozen on its last value', () {
      final Signal<int> count = Signal(1);
      final Computed<int> doubled = Computed(() => count.value * 2);
      doubled.value;

      count.dispose();
      doubled.dispose();

      expect(doubled.value, 2);
    });

    test('implements ValueListenable for interop', () {
      final Signal<int> count = Signal(7);

      expect(count, isA<ValueListenable<int>>());
    });
  });

  group('Signal.update', () {
    test('applies the transform and notifies listeners', () {
      final Signal<int> count = Signal(1);
      int notifications = 0;
      count.addListener(() => notifications++);

      count.update((int current) => current + 1);

      expect(count.value, 2);
      expect(notifications, 1);
    });

    test('does not notify when the transform returns an equal value', () {
      final Signal<int> count = Signal(1);
      int notifications = 0;
      count.addListener(() => notifications++);

      count.update((int current) => current);

      expect(count.value, 1);
      expect(notifications, 0);
    });

    test('does not subscribe the surrounding effect', () async {
      final Signal<int> tracked = Signal(0);
      final Signal<int> target = Signal(0);
      final List<int> log = <int>[];

      Effect((_) {
        log.add(tracked.value);
        target.update((int current) => current + 1);
      });

      expect(log, [0]);
      expect(target.value, 1);

      target.value = 100;
      await pumpEventQueue();

      expect(log, [0]);

      tracked.value = 1;
      await pumpEventQueue();

      expect(log, [0, 1]);
      expect(target.value, 101);
    });
  });
}
