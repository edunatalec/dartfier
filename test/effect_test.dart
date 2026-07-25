import 'package:dartfier/dartfier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Effect', () {
    test('runs immediately on creation', () {
      final Signal<int> count = Signal(1);
      final List<int> log = <int>[];

      Effect((_) => log.add(count.value));

      expect(log, [1]);
    });

    test('reruns when a dependency changes', () async {
      final Signal<int> count = Signal(1);
      final List<int> log = <int>[];
      Effect((_) => log.add(count.value));

      count.value = 2;
      await pumpEventQueue();

      expect(log, [1, 2]);
    });

    test('coalesces synchronous writes into one rerun', () async {
      final Signal<int> a = Signal(1);
      final Signal<int> b = Signal(10);
      final List<String> log = <String>[];
      Effect((_) => log.add('${a.value}:${b.value}'));

      a.value = 2;
      a.value = 3;
      b.value = 20;
      await pumpEventQueue();

      expect(log, ['1:10', '3:20']);
    });

    test('reads a consistent diamond after coalescing', () async {
      final Signal<int> base = Signal(1);
      final Computed<int> left = Computed(() => base.value + 1);
      final Computed<int> right = Computed(() => base.value * 10);
      final List<String> log = <String>[];
      Effect((_) => log.add('${left.value}:${right.value}'));

      base.value = 2;
      await pumpEventQueue();

      expect(log, ['2:10', '3:20']);
    });

    test('retracks conditional dependencies', () async {
      final Signal<bool> flag = Signal(true);
      final Signal<int> a = Signal(1);
      final Signal<int> b = Signal(2);
      final List<int> log = <int>[];
      Effect((_) => log.add(flag.value ? a.value : b.value));

      flag.value = false;
      await pumpEventQueue();

      expect(log, [1, 2]);

      a.value = 99;
      await pumpEventQueue();

      expect(log, [1, 2]);

      b.value = 3;
      await pumpEventQueue();

      expect(log, [1, 2, 3]);
    });

    test('stops rerunning after dispose', () async {
      final Signal<int> count = Signal(1);
      final List<int> log = <int>[];
      final Effect effect = Effect((_) => log.add(count.value));

      effect.dispose();
      count.value = 2;
      await pumpEventQueue();

      expect(log, [1]);
    });

    test('does not rerun when disposed after being scheduled', () async {
      final Signal<int> count = Signal(1);
      final List<int> log = <int>[];
      final Effect effect = Effect((_) => log.add(count.value));

      count.value = 2;
      effect.dispose();
      await pumpEventQueue();

      expect(log, [1]);
    });

    test('propagates an exception thrown by the first run', () {
      expect(() => Effect((_) => throw StateError('boom')), throwsStateError);
    });

    test(
      'ignores a write to its own dependency during the first run',
      () async {
        final Signal<int> count = Signal(1);
        final List<int> log = <int>[];

        Effect((_) {
          log.add(count.value);

          if (count.value < 10) count.value = 99;
        });

        await pumpEventQueue();

        expect(log, [1]);
        expect(count.value, 99);
      },
    );

    test(
      'keeps rescheduling when a rerun writes to its own dependency',
      () async {
        final Signal<int> count = Signal(0);
        final List<int> log = <int>[];
        final Effect effect = Effect((_) {
          log.add(count.value);

          if (count.value > 0 && count.value < 4) {
            count.value = count.value + 1;
          }
        });

        count.value = 1;
        await pumpEventQueue();

        expect(log, [0, 1, 2, 3, 4]);

        effect.dispose();
      },
    );

    test('runs cleanup before each rerun', () async {
      final Signal<int> count = Signal(1);
      final List<String> log = <String>[];
      Effect((onCleanup) {
        final int seen = count.value;
        log.add('run:$seen');
        onCleanup(() => log.add('cleanup:$seen'));
      });

      count.value = 2;
      await pumpEventQueue();

      expect(log, ['run:1', 'cleanup:1', 'run:2']);
    });

    test('runs cleanup on dispose', () {
      final Signal<int> count = Signal(1);
      final List<String> log = <String>[];
      final Effect effect = Effect((onCleanup) {
        log.add('run:${count.value}');
        onCleanup(() => log.add('cleanup'));
      });

      effect.dispose();

      expect(log, ['run:1', 'cleanup']);
    });

    test('runs cleanups only once when disposed twice', () {
      final List<String> log = <String>[];
      final Effect effect = Effect((onCleanup) {
        log.add('run');
        onCleanup(() => log.add('cleanup'));
      });

      effect.dispose();
      effect.dispose();

      expect(log, ['run', 'cleanup']);
    });

    test('runs cleanups in reverse registration order', () async {
      final Signal<int> count = Signal(1);
      final List<String> log = <String>[];
      Effect((onCleanup) {
        count.value;
        onCleanup(() => log.add('first'));
        onCleanup(() => log.add('second'));
      });

      count.value = 2;
      await pumpEventQueue();

      expect(log, ['second', 'first']);
    });

    test('cleanup reads do not register dependencies', () async {
      final Signal<int> tracked = Signal(1);
      final Signal<int> aux = Signal(0);
      final List<int> log = <int>[];
      Effect((onCleanup) {
        log.add(tracked.value);
        onCleanup(() => aux.value);
      });

      tracked.value = 2;
      await pumpEventQueue();

      expect(log, [1, 2]);

      aux.value = 9;
      await pumpEventQueue();

      expect(log, [1, 2]);
    });
  });
}
