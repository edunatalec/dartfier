import 'dart:async';

import 'package:dartfier/dartfier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StreamSignal', () {
    test('starts loading before the stream emits', () {
      final StreamController<int> controller = StreamController<int>();
      addTearDown(controller.close);
      final StreamSignal<int> signal = StreamSignal(controller.stream);

      expect(signal.value, const AsyncLoading<int>());

      signal.dispose();
    });

    test('publishes data for every event', () async {
      final StreamController<int> controller = StreamController<int>();
      addTearDown(controller.close);
      final StreamSignal<int> signal = StreamSignal(controller.stream);

      controller.add(1);
      await pumpEventQueue();

      expect(signal.value, const AsyncData<int>(1));

      controller.add(2);
      await pumpEventQueue();

      expect(signal.value, const AsyncData<int>(2));

      signal.dispose();
    });

    test('publishes the error with previous data and stack trace', () async {
      final StreamController<int> controller = StreamController<int>();
      addTearDown(controller.close);
      final StreamSignal<int> signal = StreamSignal(controller.stream);

      controller.add(1);
      await pumpEventQueue();

      controller.addError(StateError('boom'), StackTrace.current);
      await pumpEventQueue();

      final AsyncError<int> error = signal.value as AsyncError<int>;

      expect(error.error, isA<StateError>());
      expect(error.previous, 1);
      expect(error.stackTrace, isNotNull);

      signal.dispose();
    });

    test('keeps listening after an error', () async {
      final StreamController<int> controller = StreamController<int>();
      addTearDown(controller.close);
      final StreamSignal<int> signal = StreamSignal(controller.stream);

      controller.addError(StateError('boom'));
      await pumpEventQueue();

      expect(signal.value, isA<AsyncError<int>>());

      controller.add(7);
      await pumpEventQueue();

      expect(signal.value, const AsyncData<int>(7));

      signal.dispose();
    });

    test('keeps the last value when the stream closes', () async {
      final StreamController<int> controller = StreamController<int>();
      addTearDown(controller.close);
      final StreamSignal<int> signal = StreamSignal(controller.stream);

      controller.add(3);
      await controller.close();
      await pumpEventQueue();

      expect(signal.value, const AsyncData<int>(3));

      signal.dispose();
    });

    test('does not notify when the stream repeats a value', () async {
      final StreamController<int> controller = StreamController<int>();
      addTearDown(controller.close);
      final StreamSignal<int> signal = StreamSignal(controller.stream);

      controller.add(1);
      await pumpEventQueue();

      int notifications = 0;
      signal.addListener(() => notifications++);

      controller.add(1);
      await pumpEventQueue();

      expect(notifications, 0);

      controller.add(2);
      await pumpEventQueue();

      expect(notifications, 1);

      signal.dispose();
    });

    test('cancels the subscription on dispose', () async {
      final StreamController<int> controller = StreamController<int>();
      addTearDown(controller.close);
      final StreamSignal<int> signal = StreamSignal(controller.stream);

      signal.dispose();
      await pumpEventQueue();

      expect(controller.hasListener, isFalse);
    });

    test('ignores an event arriving after dispose', () async {
      final StreamController<int> controller =
          StreamController<int>.broadcast();
      addTearDown(controller.close);
      final StreamSignal<int> signal = StreamSignal(controller.stream);

      signal.dispose();
      controller.add(9);
      await pumpEventQueue();

      expect(signal.value, const AsyncLoading<int>());
    });

    test('composes with Computed', () async {
      final StreamController<int> controller = StreamController<int>();
      addTearDown(controller.close);
      final StreamSignal<int> signal = StreamSignal(controller.stream);
      final Computed<int> doubled = Computed(
        () => (signal.value.valueOrNull ?? 0) * 2,
      );

      expect(doubled.value, 0);

      controller.add(21);
      await pumpEventQueue();

      expect(doubled.value, 42);

      signal.dispose();
    });
  });
}
