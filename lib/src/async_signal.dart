import 'async_value.dart';
import 'readonly_signal.dart';

/// A [Signal] holding the [AsyncValue] of an asynchronous operation.
///
/// The signal starts [AsyncIdle]. [run] executes a fetcher and publishes
/// [AsyncLoading], then [AsyncData] or [AsyncError], with latest-wins
/// semantics: starting a new run drops the outcome of any older one still in
/// flight. While a run is in flight the state carries the previous data, so
/// UIs can keep showing it.
///
/// ```dart
/// final AsyncSignal<int> total = AsyncSignal();
///
/// await total.run(() async => 42);
/// print(total.value); // AsyncData<int>(42)
/// ```
///
/// Tracking stays fully synchronous: the fetcher runs outside the reactive
/// graph and writes its outcome back into the signal.
base class AsyncSignal<T> extends Signal<AsyncValue<T>> {
  /// Creates the signal in the [AsyncIdle] state.
  AsyncSignal() : super(AsyncIdle<T>());

  int _generation = 0;

  /// Runs [fetcher] and publishes loading, then data or error.
  ///
  /// Latest wins: if another [run] starts before this one completes, the
  /// older outcome — success or failure — is dropped silently. Completions
  /// arriving after `dispose` are ignored.
  ///
  /// A rerun that republishes a loading state equal to the current one
  /// (same previous data) is swallowed by the equality guard and does not
  /// notify listeners.
  Future<void> run(Future<T> Function() fetcher) async {
    final int generation = ++_generation;
    value = AsyncLoading<T>(previous: peek().valueOrNull);

    try {
      final T result = await fetcher();

      if (generation != _generation) return;

      value = AsyncData<T>(result);
    } catch (error, stackTrace) {
      if (generation != _generation) return;

      value = AsyncError<T>(
        error,
        stackTrace: stackTrace,
        previous: peek().valueOrNull,
      );
    }
  }
}
