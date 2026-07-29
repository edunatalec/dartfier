import 'dart:async';

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

  /// Completes with the first value that satisfies [condition].
  ///
  /// The current value is checked first, with [peek]: when it already
  /// satisfies [condition] the future completes with it and no subscription
  /// is created — so awaiting inside a tracked scope never subscribes that
  /// scope to the signal. Otherwise the future completes with the first
  /// change that satisfies [condition], and the subscription is cancelled
  /// right after. Changes are observed through [listen], so a burst of
  /// synchronous writes completes the future with the value at the end of the
  /// burst, not with the intermediate one that first satisfied it.
  ///
  /// ```dart
  /// final AsyncSignal<int> total = AsyncSignal();
  ///
  /// unawaited(total.run(fetchTotal));
  /// final AsyncValue<int> loaded = await total.when((v) => v is AsyncData);
  /// ```
  ///
  /// A [condition] that throws on the initial check propagates synchronously;
  /// one that throws on a change completes the future with that error and
  /// cancels the subscription. There is no built-in timeout: if the signal is
  /// disposed — or simply never satisfies [condition] — the future never
  /// completes, so guard the call with [Future.timeout] when that matters.
  Future<T> when(bool Function(T value) condition) {
    final T current = peek();

    if (condition(current)) return Future<T>.value(current);

    final Completer<T> completer = Completer<T>();
    late final Effect subscription;

    subscription = listen((T previous, T next) {
      final bool satisfied;

      try {
        satisfied = condition(next);
      } catch (error, stackTrace) {
        subscription.dispose();
        completer.completeError(error, stackTrace);

        return;
      }

      if (!satisfied) return;

      subscription.dispose();
      completer.complete(next);
    });

    return completer.future;
  }
}
