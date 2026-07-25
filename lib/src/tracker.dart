import 'package:flutter/foundation.dart';

/// The global read-tracking scope.
///
/// While a tracked scope runs, every reactive getter reports its read here;
/// the scope's owner then subscribes to exactly what was read.
abstract final class Tracker {
  static Set<Listenable>? _reads;

  /// Runs [run] collecting every reported read into [reads].
  ///
  /// The previous scope is restored afterwards, so nested computations
  /// subscribe one level down instead of leaking reads to the outer scope.
  static T collect<T>(Set<Listenable> reads, T Function() run) {
    final Set<Listenable>? previous = _reads;
    _reads = reads;

    try {
      return run();
    } finally {
      _reads = previous;
    }
  }

  /// Registers [source] as a dependency of the current scope, if any.
  static void reportRead(Listenable source) => _reads?.add(source);

  /// Runs [run] with tracking suspended, restoring the previous scope even
  /// when [run] throws.
  static T untracked<T>(T Function() run) {
    final Set<Listenable>? previous = _reads;
    _reads = null;

    try {
      return run();
    } finally {
      _reads = previous;
    }
  }
}

/// The dependency set of one tracked owner (a computed, effect or observer).
///
/// Each [track] run rediscovers the dependencies and diffs subscriptions:
/// new reads are subscribed, dropped reads are unsubscribed.
class DependencyBag {
  /// Creates a bag that invokes [_onDependencyChanged] when any tracked
  /// dependency notifies.
  DependencyBag(this._onDependencyChanged);

  final VoidCallback _onDependencyChanged;

  Set<Listenable> _dependencies = const {};

  /// Whether the last [track] run registered at least one dependency.
  bool get hasDependencies => _dependencies.isNotEmpty;

  /// Runs [run] under tracking and swaps subscriptions to what it read.
  T track<T>(T Function() run) {
    final Set<Listenable> reads = <Listenable>{};
    final T result = Tracker.collect(reads, run);

    _swap(reads);

    return result;
  }

  void _swap(Set<Listenable> next) {
    for (final Listenable dependency in _dependencies) {
      if (!next.contains(dependency)) {
        dependency.removeListener(_onDependencyChanged);
      }
    }

    for (final Listenable dependency in next) {
      if (!_dependencies.contains(dependency)) {
        dependency.addListener(_onDependencyChanged);
      }
    }

    _dependencies = next;
  }

  /// Unsubscribes from every tracked dependency.
  void dispose() {
    for (final Listenable dependency in _dependencies) {
      dependency.removeListener(_onDependencyChanged);
    }

    _dependencies = const {};
  }
}
