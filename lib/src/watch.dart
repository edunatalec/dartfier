/// @docImport 'package:dartfier/dartfier.dart';
library;

import 'effect.dart';
import 'untracked.dart';

/// A side effect on an auto-tracked expression, skipping the first run.
///
/// {@category Utilities}
///
/// [track] runs under dependency tracking, so it may read as many reactive
/// values as it needs and the watcher rediscovers them on every run. Whenever
/// its result changes, [onChange] receives the previous and the next value.
///
/// The first run only captures the current value — [onChange] is not called on
/// creation. This is the difference from [Effect], whose body runs
/// immediately: use a [Watch] to react to a *transition*, and an [Effect] to
/// keep something in sync with the current state.
///
/// ```dart
/// final Signal<String> user = Signal('ana');
/// final Signal<bool> premium = Signal(false);
///
/// final Watch<(String, bool)> watcher = Watch(
///   () => (user.value, premium.value),
///   (previous, next) => debugPrint('$previous -> $next'),
/// );
///
/// user.value = 'bruno'; // prints '(ana, false) -> (bruno, false)'
/// watcher.dispose();
/// ```
///
/// A record is the idiomatic way to track several values at once: records
/// compare structurally, so the callback runs when any component changes and
/// stays silent when the group returns to what it was.
///
/// Reruns inherit the guarantees of [Effect] — coalesced through the microtask
/// queue, so a burst of synchronous writes produces a single call carrying the
/// value from before the burst. [track] must be synchronous, and [onChange]
/// runs untracked: reading other signals inside it subscribes nobody.
///
/// Results are compared with `==` unless [equals] is given. A [track] that
/// returns a collection needs one, since a `List` compares by identity:
///
/// ```dart
/// final Signal<int> threshold = Signal(2);
/// final Signal<List<int>> numbers = Signal(const [1, 2, 3]);
///
/// final Watch<List<int>> selected = Watch(
///   () => numbers.value.where((int n) => n > threshold.value).toList(),
///   (List<int> previous, List<int> next) => debugPrint('$next'),
///   equals: listEquals,
/// );
/// ```
///
/// Disposing the watcher is the caller's job, like every other reactive node.
///
/// See also:
///
///  * [Effect], which runs immediately and reacts to the current state.
///  * [ReadonlySignalSubscriptions.listen], the same job scoped to a single
///    signal.
///  * [untracked], to read a value inside [track] without depending on it.
class Watch<T> {
  /// Creates the watcher and captures the current value of [track].
  ///
  /// [onChange] is not called until [track] produces a different result.
  Watch(
    T Function() track,
    void Function(T previous, T next) onChange, {
    bool Function(T previous, T next)? equals,
  }) {
    late T previous;
    bool first = true;

    _effect = Effect((_) {
      final T next = track();

      if (first) {
        first = false;
        previous = next;

        return;
      }

      final bool unchanged = equals != null
          ? equals(previous, next)
          : previous == next;

      if (unchanged) return;

      final T before = previous;
      previous = next;

      untracked(() => onChange(before, next));
    });
  }

  late final Effect _effect;

  /// Stops the watcher: no further change calls `onChange`.
  ///
  /// Calling it more than once is a no-op.
  void dispose() => _effect.dispose();
}
