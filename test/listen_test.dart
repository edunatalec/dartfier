import 'dart:async';

import 'package:dartfier/dartfier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('listen', () {
    test('does not fire on creation', () async {
      final Signal<int> count = Signal(1);
      final List<String> log = <String>[];

      count.listen((int previous, int next) => log.add('$previous:$next'));
      await pumpEventQueue();

      expect(log, isEmpty);
    });

    test('fires with the previous and the next value', () async {
      final Signal<int> count = Signal(1);
      final List<String> log = <String>[];
      count.listen((int previous, int next) => log.add('$previous:$next'));

      count.value = 2;
      await pumpEventQueue();

      expect(log, ['1:2']);

      count.value = 5;
      await pumpEventQueue();

      expect(log, ['1:2', '2:5']);
    });

    test('coalesces a synchronous burst into one callback', () async {
      final Signal<int> count = Signal(1);
      final List<String> log = <String>[];
      count.listen((int previous, int next) => log.add('$previous:$next'));

      count.value = 2;
      count.value = 3;
      count.value = 4;
      await pumpEventQueue();

      expect(log, ['1:4']);
    });

    test('reads a consistent diamond in a single callback', () async {
      final Signal<int> base = Signal(1);
      final Computed<int> left = Computed(() => base.value + 1);
      final Computed<int> right = Computed(() => base.value * 10);
      final Computed<String> pair = Computed(
        () => '${left.value}:${right.value}',
      );
      final List<String> log = <String>[];
      pair.listen(
        (String previous, String next) => log.add('$previous -> $next'),
      );

      base.value = 2;
      await pumpEventQueue();

      expect(log, ['2:10 -> 3:20']);
    });

    test(
      'does not fire when a computed recomputes to an equal value',
      () async {
        final Signal<int> count = Signal(0);
        final Computed<bool> isEven = Computed(() => count.value.isEven);
        final List<String> log = <String>[];
        isEven.listen((bool previous, bool next) => log.add('$previous:$next'));

        count.value = 2;
        await pumpEventQueue();

        expect(log, isEmpty);

        count.value = 3;
        await pumpEventQueue();

        expect(log, ['true:false']);
      },
    );

    test('stops listening after dispose', () async {
      final Signal<int> count = Signal(1);
      final List<String> log = <String>[];
      final Effect subscription = count.listen(
        (int previous, int next) => log.add('$previous:$next'),
      );

      subscription.dispose();
      count.value = 2;
      await pumpEventQueue();

      expect(log, isEmpty);
    });

    test('reads inside the callback do not become dependencies', () async {
      final Signal<int> count = Signal(1);
      final Signal<int> aux = Signal(10);
      final List<String> log = <String>[];
      count.listen((int previous, int next) => log.add('$next:${aux.value}'));

      count.value = 2;
      await pumpEventQueue();

      expect(log, ['2:10']);

      aux.value = 20;
      await pumpEventQueue();

      expect(log, ['2:10']);
    });

    test(
      'throws when the callback writes to the signal it listens to',
      () async {
        final Signal<int> count = Signal(0);
        final List<Object> errors = <Object>[];

        runZonedGuarded(() {
          count.listen((int previous, int next) => count.value = next + 1);

          count.value = 1;
        }, (Object error, StackTrace stack) => errors.add(error));

        await pumpEventQueue();

        expect(errors.single, isA<StateError>());
      },
    );
  });
}
