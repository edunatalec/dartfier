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

/// Something a derived node can read and be invalidated by.
///
/// Implemented by both `Signal` and `Computed`. A bag created with an owner
/// links to these through [addDependent] instead of [Listenable.addListener],
/// which separates the staleness cascade from the notifications outside
/// listeners receive.
abstract interface class ReactiveSource implements Listenable {
  /// Registers [dependent] to be marked stale when this source changes.
  void addDependent(ReactiveNode dependent);

  /// Stops cascading staleness to [dependent].
  void removeDependent(ReactiveNode dependent);
}

/// A derived node that propagates staleness before any value is compared.
///
/// Only [Computed] implements it: a node is both a source for whoever reads it
/// and a dependent of whatever it reads.
abstract interface class ReactiveNode implements ReactiveSource {
  /// Marks the node stale: a source it reads directly changed.
  void markStale();

  /// Marks the node possibly stale: a derived value it reads may have
  /// changed, which is only known once that value settles.
  void markMaybeStale();

  /// Resolves the node, recomputing only if a dependency really changed.
  void settle();

  /// Whether the last [settle] produced a different value.
  bool get changed;

  /// Recomputes when stale and notifies listeners only if the value changed.
  void reconcile();
}

/// Splits a write into staleness first, notifications last.
///
/// A write marks the whole reachable graph stale before anything recomputes,
/// so every value compared during [_flush] is read against fully current
/// state. Without the split, a node could recompute while a sibling still
/// holds a stale cache and cut off a notification on an inconsistent result.
///
/// Notifications always run untracked. A listener that reads a reactive value
/// would otherwise report that read to whatever tracked scope happened to
/// trigger the write — an effect body, a builder — subscribing it to a value
/// it never read.
abstract final class Propagation {
  static int _depth = 0;

  static int _batches = 0;

  static final List<ReactiveNode> _pending = <ReactiveNode>[];

  static final Set<ReactiveNode> _scheduled = <ReactiveNode>{};

  static final List<VoidCallback> _notifications = <VoidCallback>[];

  static final Set<ReactiveSource> _notified = <ReactiveSource>{};

  /// Runs [write] as the staleness phase, then reconciles what it marked.
  ///
  /// Reentrant: a write performed by a listener during reconciliation joins
  /// the phase in progress instead of starting a nested one.
  static void run(VoidCallback write) {
    _depth += 1;

    try {
      write();
    } finally {
      _depth -= 1;
    }

    if (_depth == 0) _flush();
  }

  /// Groups every write in [run] into a single atomic update.
  ///
  /// Staleness still propagates per write, so reads inside [run] stay current;
  /// only the notifications outside listeners receive are held back to the end.
  static T batch<T>(T Function() run) {
    _batches += 1;
    _depth += 1;

    try {
      return run();
    } finally {
      _batches -= 1;
      _depth -= 1;

      if (_batches == 0) _notified.clear();

      if (_depth == 0) _flush();
    }
  }

  /// Emits [notify] for [source], or defers it to the end of a batch.
  ///
  /// A source that writes repeatedly inside one batch notifies once. The
  /// dedupe lasts as long as the batch does: a listener that opens its own
  /// batch while the propagation runs notifies again.
  static void emit(ReactiveSource source, VoidCallback notify) {
    if (_batches == 0) {
      Tracker.untracked(notify);

      return;
    }

    if (_notified.add(source)) _notifications.add(notify);
  }

  /// Schedules [node] to be reconciled at the end of the current phase.
  ///
  /// Scheduling the same node twice before it reconciles is a no-op; a node
  /// invalidated again *by* the reconciliation is scheduled anew.
  static void schedule(ReactiveNode node) {
    if (_scheduled.add(node)) _pending.add(node);
  }

  static const int _maxRounds = 100;

  static void _flush() {
    _depth += 1;

    try {
      Tracker.untracked(_drain);
    } finally {
      _notifications.clear();
      _pending.clear();
      _scheduled.clear();
      _depth -= 1;
    }
  }

  static void _drain() {
    int notified = 0;
    int reconciled = 0;
    int rounds = 0;

    while (notified < _notifications.length || reconciled < _pending.length) {
      rounds += 1;

      if (rounds > _maxRounds) {
        throw StateError(
          'Propagation did not settle after $_maxRounds rounds: a listener '
          'writes to a value it is notified about, so every round schedules '
          'another one. Move the write out of the listener, or read the '
          'value with peek().',
        );
      }

      final int notifyEnd = _notifications.length;
      final int reconcileEnd = _pending.length;

      while (notified < notifyEnd) {
        _notifications[notified]();
        notified += 1;
      }

      while (reconciled < reconcileEnd) {
        final ReactiveNode node = _pending[reconciled];

        reconciled += 1;
        _scheduled.remove(node);
        node.reconcile();
      }
    }
  }
}

/// The dependency set of one tracked owner (a computed, effect or observer).
///
/// Each [track] run rediscovers the dependencies and diffs subscriptions:
/// new reads are subscribed, dropped reads are unsubscribed. With an [owner],
/// dependencies that are themselves [ReactiveNode]s link through the staleness
/// cascade; everything else subscribes as a plain listener.
class DependencyBag {
  /// Creates a bag that invokes [_onDependencyChanged] when any tracked
  /// dependency notifies.
  DependencyBag(this._onDependencyChanged, {ReactiveNode? owner})
    : _owner = owner;

  final VoidCallback _onDependencyChanged;

  final ReactiveNode? _owner;

  Set<Listenable> _dependencies = const {};

  /// Whether the last [track] run registered at least one dependency.
  bool get hasDependencies => _dependencies.isNotEmpty;

  /// The tracked dependencies that are themselves derived nodes.
  Iterable<ReactiveNode> get reactiveDependencies =>
      _dependencies.whereType<ReactiveNode>();

  /// Runs [run] under tracking and swaps subscriptions to what it read.
  T track<T>(T Function() run) {
    final Set<Listenable> reads = <Listenable>{};
    final T result = Tracker.collect(reads, run);

    _swap(reads);

    return result;
  }

  void _swap(Set<Listenable> next) {
    for (final Listenable dependency in _dependencies) {
      if (!next.contains(dependency)) _detach(dependency);
    }

    for (final Listenable dependency in next) {
      if (!_dependencies.contains(dependency)) _attach(dependency);
    }

    _dependencies = next;
  }

  void _attach(Listenable dependency) {
    final ReactiveNode? owner = _owner;

    if (owner != null && dependency is ReactiveSource) {
      dependency.addDependent(owner);

      return;
    }

    dependency.addListener(_onDependencyChanged);
  }

  void _detach(Listenable dependency) {
    final ReactiveNode? owner = _owner;

    if (owner != null && dependency is ReactiveSource) {
      dependency.removeDependent(owner);

      return;
    }

    dependency.removeListener(_onDependencyChanged);
  }

  /// Unsubscribes from every tracked dependency.
  void dispose() {
    for (final Listenable dependency in _dependencies) {
      _detach(dependency);
    }

    _dependencies = const {};
  }
}
