import 'package:dartfier/dartfier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('untracked', () {
    test('reads inside the block do not register dependencies', () {
      final Signal<int> tracked = Signal(1);
      final Signal<int> ignored = Signal(10);
      final Computed<int> sum = Computed(
        () => tracked.value + untracked(() => ignored.value),
      );

      expect(sum.value, 11);

      int notifications = 0;
      sum.addListener(() => notifications++);

      ignored.value = 20;

      expect(notifications, 0);

      tracked.value = 2;

      expect(notifications, 1);
      expect(sum.value, 22);
    });

    test('restores tracking when the block throws', () {
      final Signal<int> a = Signal(1);
      final Computed<int> resilient = Computed(() {
        try {
          untracked(() => throw StateError('boom'));
        } on StateError {
          a.peek();
        }

        return a.value;
      });

      expect(resilient.value, 1);

      int notifications = 0;
      resilient.addListener(() => notifications++);

      a.value = 5;

      expect(notifications, 1);
      expect(resilient.value, 5);
    });

    test('does not rerun an effect for reads inside the block', () async {
      final Signal<int> tracked = Signal(1);
      final Signal<int> ignored = Signal(0);
      final List<int> log = <int>[];

      Effect(() => log.add(tracked.value + untracked(() => ignored.value)));

      ignored.value = 100;
      await pumpEventQueue();

      expect(log, [1]);

      tracked.value = 2;
      await pumpEventQueue();

      expect(log, [1, 102]);
    });
  });

  group('peek', () {
    test('Signal.peek reads without registering a dependency', () {
      final Signal<int> tracked = Signal(1);
      final Signal<int> peeked = Signal(10);
      final Computed<int> sum = Computed(() => tracked.value + peeked.peek());

      expect(sum.value, 11);

      int notifications = 0;
      sum.addListener(() => notifications++);

      peeked.value = 20;

      expect(notifications, 0);
    });

    test('Computed.peek reads without registering and still recomputes', () {
      final Signal<int> count = Signal(1);
      final Computed<int> doubled = Computed(() => count.value * 2);
      final Computed<int> shifted = Computed(() => doubled.peek() + 1);

      expect(shifted.value, 3);

      int notifications = 0;
      shifted.addListener(() => notifications++);

      count.value = 5;

      expect(notifications, 0);
      expect(doubled.peek(), 10);
    });
  });
}
