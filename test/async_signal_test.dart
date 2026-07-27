import 'dart:async';

import 'package:dartfier/dartfier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AsyncSignal', () {
    test('starts idle with no data', () {
      final AsyncSignal<int> signal = AsyncSignal();

      expect(signal.value, const AsyncIdle<int>());
      expect(signal.value.valueOrNull, isNull);
    });

    test('publishes loading then data on the first run', () async {
      final AsyncSignal<int> signal = AsyncSignal();
      int notifications = 0;
      signal.addListener(() => notifications++);

      final Completer<int> gate = Completer<int>();
      final Future<void> flight = signal.run(() => gate.future);

      expect(signal.value, const AsyncLoading<int>());
      expect(notifications, 1);

      gate.complete(42);
      await flight;

      expect(signal.value, const AsyncData<int>(42));
      expect(notifications, 2);
    });

    test('keeps previous data while reloading', () async {
      final AsyncSignal<int> signal = AsyncSignal();
      await signal.run(() async => 1);

      final Completer<int> gate = Completer<int>();
      final Future<void> reload = signal.run(() => gate.future);

      expect(signal.value, const AsyncLoading<int>(previous: 1));
      expect(signal.value.valueOrNull, 1);

      gate.complete(2);
      await reload;

      expect(signal.value, const AsyncData<int>(2));
    });

    test('publishes the error with previous data and stack trace', () async {
      final AsyncSignal<int> signal = AsyncSignal();
      await signal.run(() async => 1);

      await signal.run(() async => throw StateError('boom'));

      final AsyncValue<int> state = signal.value;
      expect(state, isA<AsyncError<int>>());

      final AsyncError<int> error = state as AsyncError<int>;
      expect(error.error, isA<StateError>());
      expect(error.previous, 1);
      expect(error.stackTrace, isNotNull);
    });

    test('drops a stale success when a newer run starts', () async {
      final AsyncSignal<int> signal = AsyncSignal();
      final Completer<int> first = Completer<int>();
      final Completer<int> second = Completer<int>();

      final Future<void> firstRun = signal.run(() => first.future);
      final Future<void> secondRun = signal.run(() => second.future);

      second.complete(2);
      await secondRun;

      expect(signal.value, const AsyncData<int>(2));

      first.complete(1);
      await firstRun;

      expect(signal.value, const AsyncData<int>(2));
    });

    test('drops a stale failure silently', () async {
      final AsyncSignal<int> signal = AsyncSignal();
      final Completer<int> first = Completer<int>();

      final Future<void> failing = signal.run(() => first.future);
      final Future<void> winning = signal.run(() async => 7);
      await winning;

      first.completeError(StateError('stale'));
      await failing;

      expect(signal.value, const AsyncData<int>(7));
    });

    test('keeps the error when a stale success arrives later', () async {
      final AsyncSignal<int> signal = AsyncSignal();
      final Completer<int> slow = Completer<int>();

      final Future<void> slowRun = signal.run(() => slow.future);
      await signal.run(() async => throw StateError('boom'));

      expect(signal.value, isA<AsyncError<int>>());

      slow.complete(1);
      await slowRun;

      expect(signal.value, isA<AsyncError<int>>());
    });

    test('carries previous data through consecutive errors', () async {
      final AsyncSignal<int> signal = AsyncSignal();
      await signal.run(() async => 1);
      await signal.run(() async => throw StateError('first'));
      await signal.run(() async => throw StateError('second'));

      final AsyncError<int> error = signal.value as AsyncError<int>;

      expect(error.previous, 1);
    });

    test(
      'does not renotify when a rerun republishes an equal loading state',
      () async {
        final AsyncSignal<int> signal = AsyncSignal();
        final Completer<int> first = Completer<int>();
        final Completer<int> second = Completer<int>();

        final Future<void> firstRun = signal.run(() => first.future);
        int notifications = 0;
        signal.addListener(() => notifications++);

        final Future<void> secondRun = signal.run(() => second.future);

        expect(notifications, 0);

        second.complete(2);
        await secondRun;
        first.complete(1);
        await firstRun;

        expect(notifications, 1);
        expect(signal.value, const AsyncData<int>(2));
      },
    );

    test('ignores a completion arriving after dispose', () async {
      final AsyncSignal<int> signal = AsyncSignal();
      final Completer<int> gate = Completer<int>();
      final Future<void> flight = signal.run(() => gate.future);

      signal.dispose();
      gate.complete(5);
      await flight;

      expect(signal.value.isLoading, isTrue);
    });

    test('composes with Computed', () async {
      final AsyncSignal<int> signal = AsyncSignal();
      final Computed<int> doubled = Computed(
        () => (signal.value.valueOrNull ?? 0) * 2,
      );

      expect(doubled.value, 0);

      await signal.run(() async => 21);

      expect(doubled.value, 42);
    });
  });
}
