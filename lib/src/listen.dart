import 'effect.dart';
import 'readonly_signal.dart';
import 'untracked.dart';

/// Side-effect subscriptions on any [ReadonlySignal].
///
/// Available on [Signal], [Computed] and `AsyncSignal` alike: they all are
/// [ReadonlySignal]s underneath.
extension ReadonlySignalSubscriptions<T> on ReadonlySignal<T> {
  /// Calls [onChange] with the previous and the next value on every change.
  ///
  /// The subscription is an [Effect], so it inherits its guarantees. Reruns
  /// are coalesced through the microtask queue: a burst of synchronous writes
  /// produces a single call, carrying the value from before the burst and the
  /// value after it. A subscription on a [Computed] therefore never observes
  /// the inconsistent intermediate state a raw [Listenable.addListener] would
  /// see in the middle of a diamond, and a recomputation that lands on an
  /// equal value does not call [onChange] at all.
  ///
  /// The callback does not run on creation — the first run only captures the
  /// current value — and its reads are untracked, so consulting other signals
  /// inside it does not subscribe the subscription to them.
  ///
  /// ```dart
  /// final Signal<int> count = Signal(0);
  /// final Effect subscription = count.listen(
  ///   (int previous, int next) => debugPrint('$previous -> $next'),
  /// );
  ///
  /// count.value = 1; // prints '0 -> 1' on the next microtask
  /// subscription.dispose();
  /// ```
  ///
  /// Disposing the returned [Effect] is the caller's job. Listening to a lazy
  /// [Computed] forces its first computation and keeps it eager, since it now
  /// recomputes on every notification. Writing to the listened signal from
  /// [onChange] retriggers the subscription and hits the effect's self-write
  /// guard — a [StateError] after 100 consecutive reruns.
  Effect listen(void Function(T previous, T next) onChange) {
    late T previous;
    bool first = true;

    return Effect((_) {
      final T next = value;

      if (first) {
        first = false;
        previous = next;

        return;
      }

      if (next == previous) return;

      final T before = previous;
      previous = next;

      untracked(() => onChange(before, next));
    });
  }
}
