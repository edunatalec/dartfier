import 'package:dartfier/dartfier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Computed', () {
    test('computes lazily on first read', () {
      final Signal<int> count = Signal(1);
      int computations = 0;
      final Computed<int> doubled = Computed(() {
        computations++;

        return count.value * 2;
      });

      expect(computations, 0);
      expect(doubled.value, 2);
      expect(computations, 1);
    });

    test('caches the value between reads', () {
      final Signal<int> count = Signal(1);
      int computations = 0;
      final Computed<int> doubled = Computed(() {
        computations++;

        return count.value * 2;
      });

      doubled.value;
      doubled.value;

      expect(computations, 1);
    });

    test('recomputes after a dependency changes', () {
      final Signal<int> count = Signal(1);
      final Computed<int> doubled = Computed(() => count.value * 2);

      expect(doubled.value, 2);

      count.value = 5;

      expect(doubled.value, 10);
    });

    test('notifies listeners when a dependency changes', () {
      final Signal<int> count = Signal(1);
      final Computed<int> doubled = Computed(() => count.value * 2);
      doubled.value;

      int notifications = 0;
      doubled.addListener(() => notifications++);

      count.value = 2;

      expect(notifications, 1);
    });

    test('notifies once per change without an intervening read', () {
      final Signal<int> count = Signal(1);
      final Computed<int> doubled = Computed(() => count.value * 2);
      doubled.value;

      int notifications = 0;
      doubled.addListener(() => notifications++);

      count.value = 2;
      count.value = 3;

      expect(notifications, 2);
      expect(doubled.value, 6);
    });

    test('notifies once through a diamond and reads consistently', () {
      final Signal<int> base = Signal(1);
      final Computed<int> left = Computed(() => base.value + 1);
      final Computed<int> right = Computed(() => base.value * 10);
      final Computed<String> merged = Computed(
        () => '${left.value}:${right.value}',
      );

      expect(merged.value, '2:10');

      int notifications = 0;
      merged.addListener(() => notifications++);

      base.value = 2;

      expect(notifications, 1);
      expect(merged.value, '3:20');
    });

    test('retracks conditional dependencies', () {
      final Signal<bool> flag = Signal(true);
      final Signal<int> a = Signal(1);
      final Signal<int> b = Signal(2);
      final Computed<int> picked = Computed(
        () => flag.value ? a.value : b.value,
      );

      expect(picked.value, 1);

      flag.value = false;

      expect(picked.value, 2);

      int notifications = 0;
      picked.addListener(() => notifications++);

      a.value = 99;

      expect(notifications, 0);

      b.value = 3;

      expect(notifications, 1);
      expect(picked.value, 3);
    });

    test('supports chained computeds', () {
      final Signal<int> count = Signal(1);
      final Computed<int> doubled = Computed(() => count.value * 2);
      final Computed<String> label = Computed(() => 'total: ${doubled.value}');

      expect(label.value, 'total: 2');

      count.value = 3;

      expect(label.value, 'total: 6');
    });

    test('throws on a dependency cycle', () {
      late final Computed<int> cyclic;
      cyclic = Computed(() => cyclic.value + 1);

      expect(() => cyclic.value, throwsStateError);
    });

    test('stops reacting after dispose', () {
      final Signal<int> count = Signal(1);
      final Computed<int> doubled = Computed(() => count.value * 2);
      doubled.value;

      int notifications = 0;
      doubled.addListener(() => notifications++);
      doubled.dispose();

      count.value = 5;

      expect(notifications, 0);
    });

    test('does not notify when the recomputed value is unchanged', () {
      final Signal<int> count = Signal(1);
      final Computed<bool> odd = Computed(() => count.value.isOdd);
      odd.value;

      int notifications = 0;
      odd.addListener(() => notifications++);

      count.value = 3;

      expect(notifications, 0);
      expect(odd.value, true);
    });

    test('a stable link cuts the chain short', () {
      final Signal<int> count = Signal(1);
      final Computed<bool> odd = Computed(() => count.value.isOdd);

      int runs = 0;
      final Computed<String> label = Computed(() {
        runs++;

        return odd.value ? 'odd' : 'even';
      });

      int notifications = 0;
      label.addListener(() => notifications++);
      label.value;

      expect(runs, 1);

      count.value = 3;

      expect(runs, 1);
      expect(notifications, 0);

      count.value = 4;

      expect(runs, 2);
      expect(notifications, 1);
      expect(label.value, 'even');
    });

    test('does not recompute on a write while nobody listens', () {
      final Signal<int> count = Signal(1);

      int runs = 0;
      final Computed<int> doubled = Computed(() {
        runs++;

        return count.value * 2;
      });
      doubled.value;

      expect(runs, 1);

      count.value = 5;

      expect(runs, 1);
      expect(doubled.value, 10);
      expect(runs, 2);
    });

    test('keeps reconciling after a sibling compute throws', () {
      final Signal<int> count = Signal(1);
      final Computed<int> failing = Computed<int>(
        () => count.value == 2 ? throw StateError('boom') : count.value,
      );
      final Computed<int> healthy = Computed(() => count.value * 2);
      failing.value;
      healthy.value;

      int notifications = 0;
      failing.addListener(() {});
      healthy.addListener(() => notifications++);

      expect(() => count.value = 2, throwsStateError);

      count.value = 3;

      expect(notifications, greaterThan(0));
      expect(healthy.value, 6);
    });

    test('settles a write performed by a listener during reconciliation', () {
      final Signal<int> count = Signal(1);
      final Signal<String> mirror = Signal('');
      final Computed<int> doubled = Computed(() => count.value * 2);
      doubled.value;

      doubled.addListener(() => mirror.value = 'saw ${doubled.value}');

      final List<String> seen = <String>[];
      mirror.addListener(() => seen.add(mirror.value));

      count.value = 5;

      expect(seen, <String>['saw 10']);
      expect(mirror.value, 'saw 10');
    });

    test('notifies a listener added after an unread write', () {
      final Signal<int> count = Signal(1);
      final Computed<int> doubled = Computed(() => count.value * 2);
      doubled.value;

      count.value = 2;

      int notifications = 0;
      doubled.addListener(() => notifications++);

      count.value = 3;

      expect(notifications, 1);
      expect(doubled.value, 6);
    });

    test(
      'recomputes once without resubscribing when read dirty after dispose',
      () {
        final Signal<int> count = Signal(1);
        final Computed<int> doubled = Computed(() => count.value * 2);
        doubled.value;

        count.value = 2;
        doubled.dispose();

        expect(doubled.value, 4);

        count.value = 5;

        expect(doubled.value, 4);
      },
    );

    test('stays frozen when disposed while clean', () {
      final Signal<int> count = Signal(1);
      final Computed<int> doubled = Computed(() => count.value * 2);

      expect(doubled.value, 2);

      doubled.dispose();
      count.value = 10;

      expect(doubled.value, 2);
    });

    test('propagates a compute exception and retries on the next read', () {
      final Signal<bool> explode = Signal(true);
      final Computed<int> risky = Computed(() {
        if (explode.value) throw StateError('boom');

        return 42;
      });

      expect(() => risky.value, throwsStateError);

      explode.value = false;

      expect(risky.value, 42);
    });

    test(
      'keeps the previous value identity when equals judges results equal',
      () {
        final Signal<int> count = Signal(1);
        final Computed<List<int>> parity = Computed(
          () => <int>[if (count.value.isOdd) 1 else 0],
          equals: listEquals,
        );
        final List<int> first = parity.value;

        count.value = 3;

        expect(identical(parity.value, first), isTrue);

        count.value = 2;

        expect(identical(parity.value, first), isFalse);
      },
    );

    test('does not leak the tracking scope when a compute throws', () {
      final Signal<int> count = Signal(1);
      final Computed<int> risky = Computed(() => throw StateError('boom'));
      final Computed<int> outer = Computed(() {
        try {
          risky.value;
        } on StateError {
          count.value;
        }

        return count.value;
      });

      expect(outer.value, 1);

      count.value = 2;

      expect(outer.value, 2);
    });
  });
}
