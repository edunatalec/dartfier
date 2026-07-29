import 'dart:async';

import 'package:dartfier/dartfier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('when', () {
    test('completes with the current value when already satisfied', () async {
      final Signal<int> count = Signal(5);

      final Future<int> satisfied = count.when((int value) => value > 3);

      count.value = 10;

      expect(await satisfied, 5);
    });

    test('completes on the first change that satisfies it', () async {
      final Signal<int> count = Signal(0);
      final Future<int> reached = count.when((int value) => value >= 3);

      count.value = 1;
      await pumpEventQueue();

      count.value = 3;
      await pumpEventQueue();

      count.value = 4;

      expect(await reached, 3);

      count.value = 5;
      await pumpEventQueue();

      expect(count.value, 5);
    });

    test('completes with the final value of a synchronous burst', () async {
      final Signal<int> count = Signal(0);
      final Future<int> reached = count.when((int value) => value >= 3);

      count.value = 3;
      count.value = 4;

      expect(await reached, 4);
    });

    test('does not complete while the condition is unsatisfied', () async {
      final Signal<int> count = Signal(0);
      final Future<int> pending = count.when((int value) => value > 10);
      int? resolved;
      unawaited(pending.then((int value) => resolved = value));

      count.value = 1;
      await pumpEventQueue();

      expect(resolved, isNull);

      count.value = 11;
      await pumpEventQueue();

      expect(resolved, 11);
    });

    test('completes with the error thrown by the condition', () async {
      final Signal<int> count = Signal(0);
      final Future<int> failing = count.when((int value) {
        if (value > 1) throw StateError('boom');

        return false;
      });

      count.value = 2;

      await expectLater(failing, throwsStateError);
    });

    test('does not subscribe the surrounding effect', () async {
      final Signal<int> count = Signal(0);
      final Signal<int> other = Signal(0);
      final List<int> log = <int>[];

      Effect((_) {
        log.add(other.value);
        unawaited(count.when((int value) => value > 100));
      });

      count.value = 1;
      await pumpEventQueue();

      expect(log, [0]);

      other.value = 1;
      await pumpEventQueue();

      expect(log, [0, 1]);
    });
  });
}
