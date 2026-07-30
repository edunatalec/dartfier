import 'dart:async';

import 'async_value.dart';
import 'readonly_signal.dart';

/// A [Signal] holding the [AsyncValue] of a [Stream].
///
/// The subscription opens on creation, so the signal starts [AsyncLoading]
/// and moves to [AsyncData] on the first event. An error becomes
/// [AsyncError] carrying the data from before it, and the subscription stays
/// open — a later event publishes data again.
///
/// ```dart
/// final StreamSignal<int> ticks = StreamSignal(source);
///
/// Observer((context) => Text('${ticks.value.valueOrNull ?? 0}'));
///
/// ticks.dispose(); // cancels the subscription
/// ```
///
/// Closing the stream leaves the last state in place: a finished stream does
/// not invalidate what it produced, and there is no done state to move to.
///
/// The equality guard of [Signal] still applies, so a stream repeating a
/// value it already published notifies nobody. That makes it a fit for state
/// arriving over time — a location, a connectivity status, a Firestore
/// document — and a poor one for a sequence of events, where two identical
/// payloads are two distinct facts. Keep those on the [Stream].
///
/// Tracking stays fully synchronous: events arrive outside the reactive graph
/// and write their outcome into the signal.
base class StreamSignal<T> extends Signal<AsyncValue<T>> {
  /// Subscribes to [source] and publishes its events.
  ///
  /// Disposing the signal cancels the subscription — the owner of the signal
  /// owns it, exactly as with a [Signal].
  StreamSignal(Stream<T> source) : super(AsyncLoading<T>()) {
    _subscription = source.listen(_onData, onError: _onError);
  }

  late final StreamSubscription<T> _subscription;

  void _onData(T data) => value = AsyncData<T>(data);

  void _onError(Object error, StackTrace stackTrace) {
    value = AsyncError<T>(
      error,
      stackTrace: stackTrace,
      previous: peek().valueOrNull,
    );
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());

    super.dispose();
  }
}
