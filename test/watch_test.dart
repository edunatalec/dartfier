import 'package:dartfier/dartfier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Watch', () {
    test('does not fire on creation', () async {
      final Signal<int> count = Signal(1);
      final List<String> log = <String>[];

      Watch(
        () => count.value,
        (int previous, int next) => log.add('$previous:$next'),
      );
      await pumpEventQueue();

      expect(log, isEmpty);
    });

    test('fires with the previous and the next value', () async {
      final Signal<int> count = Signal(1);
      final List<String> log = <String>[];
      Watch(
        () => count.value,
        (int previous, int next) => log.add('$previous:$next'),
      );

      count.value = 2;
      await pumpEventQueue();

      expect(log, ['1:2']);

      count.value = 5;
      await pumpEventQueue();

      expect(log, ['1:2', '2:5']);
    });

    test('tracks every value the expression reads', () async {
      final Signal<String> user = Signal('ana');
      final Signal<bool> premium = Signal(false);
      final List<(String, bool)> log = <(String, bool)>[];
      Watch(
        () => (user.value, premium.value),
        ((String, bool) previous, (String, bool) next) => log.add(next),
      );

      user.value = 'bruno';
      await pumpEventQueue();

      premium.value = true;
      await pumpEventQueue();

      expect(log, [('bruno', false), ('bruno', true)]);
    });

    test('rediscovers dependencies on every run', () async {
      final Signal<bool> useLeft = Signal(true);
      final Signal<int> left = Signal(1);
      final Signal<int> right = Signal(100);
      final List<int> log = <int>[];
      Watch(
        () => useLeft.value ? left.value : right.value,
        (int previous, int next) => log.add(next),
      );

      right.value = 200;
      await pumpEventQueue();

      expect(log, isEmpty);

      useLeft.value = false;
      await pumpEventQueue();

      expect(log, [200]);

      left.value = 2;
      await pumpEventQueue();

      expect(log, [200]);
    });

    test('coalesces a synchronous burst into one call', () async {
      final Signal<int> count = Signal(1);
      final List<String> log = <String>[];
      Watch(
        () => count.value,
        (int previous, int next) => log.add('$previous:$next'),
      );

      count.value = 2;
      count.value = 3;
      count.value = 4;
      await pumpEventQueue();

      expect(log, ['1:4']);
    });

    test('stays silent when the expression lands on an equal record', () async {
      final Signal<String> user = Signal('ana');
      final Signal<bool> premium = Signal(false);
      final List<(String, bool)> log = <(String, bool)>[];
      Watch(
        () => (user.value, premium.value),
        ((String, bool) previous, (String, bool) next) => log.add(next),
      );

      user.value = 'bruno';
      user.value = 'ana';
      await pumpEventQueue();

      expect(log, isEmpty);
    });

    test('compares results with a custom equals', () async {
      final Signal<int> threshold = Signal(0);
      final Signal<List<int>> numbers = Signal(const [1, 2, 3]);
      final List<List<int>> log = <List<int>>[];
      Watch(
        () => numbers.value.where((int n) => n > threshold.value).toList(),
        (List<int> previous, List<int> next) => log.add(next),
        equals: listEquals,
      );

      numbers.value = [1, 2, 3];
      await pumpEventQueue();

      expect(log, isEmpty);

      threshold.value = 2;
      await pumpEventQueue();

      expect(log, [
        [3],
      ]);
    });

    test('stops watching after dispose', () async {
      final Signal<int> count = Signal(1);
      final List<int> log = <int>[];
      final Watch<int> watcher = Watch(
        () => count.value,
        (int previous, int next) => log.add(next),
      );

      count.value = 2;
      await pumpEventQueue();

      watcher.dispose();
      count.value = 3;
      await pumpEventQueue();

      expect(log, [2]);
    });

    test('reads inside the callback do not become dependencies', () async {
      final Signal<int> tracked = Signal(1);
      final Signal<int> consulted = Signal(10);
      final List<String> log = <String>[];
      Watch(
        () => tracked.value,
        (int previous, int next) => log.add('$next:${consulted.value}'),
      );

      tracked.value = 2;
      await pumpEventQueue();

      consulted.value = 20;
      await pumpEventQueue();

      expect(log, ['2:10']);
    });
  });
}
