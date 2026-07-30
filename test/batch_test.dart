import 'package:dartfier/dartfier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('batch', () {
    test('hides the intermediate state of a swap', () {
      final Signal<String> first = Signal('A');
      final Signal<String> second = Signal('B');
      final Computed<String> pair = Computed(
        () => '${first.value}${second.value}',
      );

      final List<String> seen = <String>[];
      pair.addListener(() => seen.add(pair.value));
      pair.value;

      batch(() {
        final String held = first.peek();
        first.value = second.peek();
        second.value = held;
      });

      expect(seen, <String>['BA']);
    });

    test('notifies a signal listener once for repeated writes', () {
      final Signal<int> count = Signal(0);

      final List<int> seen = <int>[];
      count.addListener(() => seen.add(count.value));

      batch(() {
        count.value = 1;
        count.value = 2;
        count.value = 3;
      });

      expect(seen, <int>[3]);
    });

    test('stays silent when the batch leaves the value unchanged', () {
      final Signal<int> count = Signal(1);

      int notifications = 0;
      count.addListener(() => notifications++);

      batch(() {
        count.value = 2;
        count.value = 1;
      });

      expect(notifications, 0);
      expect(count.value, 1);
    });

    test('reconciles a computed once for several writes', () {
      final Signal<String> query = Signal('shoes');
      final Signal<bool> inStock = Signal(true);

      int runs = 0;
      final Computed<String> label = Computed(() {
        runs++;

        return '${query.value}:${inStock.value}';
      });

      int notifications = 0;
      label.addListener(() => notifications++);
      label.value;
      runs = 0;

      batch(() {
        query.value = 'boots';
        inStock.value = false;
      });

      expect(runs, 1);
      expect(notifications, 1);
      expect(label.value, 'boots:false');
    });

    test('reads inside the batch see the writes made so far', () {
      final Signal<int> count = Signal(1);
      final Computed<int> doubled = Computed(() => count.value * 2);
      doubled.value;

      final List<int> readings = <int>[];

      batch(() {
        count.value = 5;
        readings.add(doubled.value);

        count.value = 10;
        readings.add(doubled.value);
      });

      expect(readings, <int>[10, 20]);
    });

    test('only the outermost batch flushes', () {
      final Signal<int> count = Signal(0);

      int notifications = 0;
      count.addListener(() => notifications++);

      batch(() {
        count.value = 1;

        batch(() {
          count.value = 2;
        });

        expect(notifications, 0);

        count.value = 3;
      });

      expect(notifications, 1);
      expect(count.value, 3);
    });

    test('returns the value produced by the body', () {
      final Signal<int> count = Signal(1);

      final int result = batch(() {
        count.value = 4;

        return count.value * 10;
      });

      expect(result, 40);
    });

    test('delivers pending notifications when the body throws', () {
      final Signal<int> count = Signal(0);

      int notifications = 0;
      count.addListener(() => notifications++);

      expect(
        () => batch(() {
          count.value = 7;

          throw StateError('boom');
        }),
        throwsStateError,
      );

      expect(notifications, 1);
      expect(count.value, 7);
    });

    test(
      'delivers both notifications when the body throws after two writes',
      () {
        final Signal<int> first = Signal(0);
        final Signal<int> second = Signal(0);
        final Computed<String> pair = Computed(
          () => '${first.value}${second.value}',
        );
        pair.value;

        final List<String> seen = <String>[];
        pair.addListener(() => seen.add(pair.value));

        expect(
          () => batch(() {
            first.value = 1;
            second.value = 2;

            throw StateError('boom');
          }),
          throwsStateError,
        );

        expect(seen, <String>['12']);
        expect(pair.value, '12');
      },
    );

    test('starts a sibling batch from a clean state', () {
      final Signal<int> count = Signal(0);

      final List<int> seen = <int>[];
      count.addListener(() => seen.add(count.peek()));

      batch(() {
        count.value = 1;
        count.value = 2;
      });

      batch(() {
        count.value = 3;
        count.value = 4;
      });

      expect(seen, <int>[2, 4]);
    });

    test('leaves writes outside a batch notifying immediately', () {
      final Signal<int> count = Signal(0);

      final List<int> seen = <int>[];
      count.addListener(() => seen.add(count.value));

      count.value = 1;
      count.value = 2;

      expect(seen, <int>[1, 2]);
    });
  });
}
