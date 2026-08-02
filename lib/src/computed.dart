part of 'readonly_signal.dart';

/// A derived reactive value with automatic dependency tracking.
///
/// {@category Core}
///
/// The computation is lazy: it runs on the first read and is cached until a
/// dependency changes. Dependencies are rediscovered on every recomputation,
/// so conditional reads subscribe to exactly what the last run read.
///
/// Listeners are notified only when the recomputed value actually differs —
/// a dependency that changes without moving the result stays silent, and the
/// cascade stops here. A computed nobody listens to is not recomputed by a
/// write at all: it stays stale until read.
///
/// ```dart
/// final Signal<int> count = Signal(1);
/// final Computed<int> doubled = Computed(() => count.value * 2);
///
/// print(doubled.value); // 2
/// count.value = 5;
/// print(doubled.value); // 10
/// ```
///
/// The compute function must be synchronous — an `await` breaks tracking.
/// A dependency cycle throws a [StateError] on read.
///
/// [Computed] implements [ReadonlySignal] — expose it as such to hand
/// readers listening without writing.
///
/// Disposing is the owner's job: whoever creates the computed calls [dispose],
/// after which it stops tracking and keeps its last value. Until then it stays
/// registered as a dependent of every source it read — the source holds the
/// reference, not the other way around, so a computed created in a `State` and
/// left undisposed keeps that closure reachable through a signal that outlives
/// the screen.
///
/// See also:
///
///  * [Signal], the writable value a computation usually reads from.
///  * [untracked], to read a value inside the computation without depending
///    on it.
///  * [AsyncSignal], for derivations that need to await.
base class Computed<T> extends ChangeNotifier
    implements ReadonlySignal<T>, ReactiveNode {
  /// Creates a computed value derived by the given function.
  ///
  /// When `equals` is provided, a recomputation whose result is judged equal
  /// to the previous value keeps the previous object, preserving identity
  /// for downstream `==` checks.
  ///
  /// ```dart
  /// final Signal<List<String>> chapters = Signal(<String>['one', 'two']);
  /// final Signal<String> query = Signal('');
  ///
  /// final Computed<List<String>> visible = Computed(
  ///   () => chapters.value
  ///       .where((String chapter) => chapter.contains(query.value))
  ///       .toList(),
  ///   equals: listEquals,
  /// );
  /// ```
  Computed(this._compute, {bool Function(T previous, T next)? equals})
    : _equals = equals {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  final T Function() _compute;

  final bool Function(T previous, T next)? _equals;

  late final DependencyBag _dependencies = DependencyBag(
    markStale,
    owner: this,
  );

  final Set<ReactiveNode> _dependents = <ReactiveNode>{};

  bool _disposed = false;
  bool _computing = false;
  bool _hasValue = false;
  bool _changed = false;

  _Freshness _freshness = _Freshness.stale;

  late T _value;

  @override
  T get value {
    Tracker.reportRead(this);

    settle();

    return _value;
  }

  /// Reads the current value without registering a dependency.
  ///
  /// Still recomputes if the cached value is stale.
  ///
  /// ```dart
  /// final Signal<int> count = Signal(1);
  /// final Computed<int> doubled = Computed(() => count.value * 2);
  ///
  /// final Computed<int> shifted = Computed(() => doubled.peek() + 1);
  /// ```
  @override
  T peek() {
    settle();

    return _value;
  }

  void _recompute() {
    if (_computing) {
      throw StateError('Computed dependency cycle detected');
    }

    _computing = true;

    try {
      final T next = _disposed
          ? Tracker.collect(<Listenable>{}, _compute)
          : _dependencies.track(_compute);

      _changed = !_hasValue || !isEqual(_value, next, equals: _equals);

      if (_changed) _value = next;

      _hasValue = true;
    } finally {
      _computing = false;
    }

    _freshness = _Freshness.clean;
  }

  @override
  void markStale() => _invalidate(_Freshness.stale);

  @override
  void markMaybeStale() => _invalidate(_Freshness.maybeStale);

  void _invalidate(_Freshness next) {
    if (hasListeners) Propagation.schedule(this);

    if (_freshness.index >= next.index) return;

    final bool wasClean = _freshness == _Freshness.clean;
    _freshness = next;

    if (!wasClean) return;

    for (final ReactiveNode dependent in _dependents.toList()) {
      dependent.markMaybeStale();
    }
  }

  @override
  bool get changed => _changed;

  @override
  void settle() {
    if (_freshness == _Freshness.maybeStale) _askDependencies();

    if (_freshness == _Freshness.stale) _recompute();
  }

  void _askDependencies() {
    for (final ReactiveNode dependency in _dependencies.reactiveDependencies) {
      dependency.settle();

      if (!dependency.changed) continue;

      _freshness = _Freshness.stale;

      return;
    }

    _freshness = _Freshness.clean;
    _changed = false;
  }

  @override
  void reconcile() {
    if (_disposed || _freshness == _Freshness.clean || !hasListeners) return;

    settle();

    if (_changed) notifyListeners();
  }

  /// Subscribes [listener] and forces the first computation.
  ///
  /// A lazy [Computed] has no dependencies until it runs once, so a listener
  /// added before any read would never be called. Listening therefore settles
  /// the value and keeps the computed eager, exactly like
  /// [ReadonlySignalSubscriptions.listen] does.
  @override
  void addListener(VoidCallback listener) {
    if (!_disposed) settle();

    super.addListener(listener);
  }

  @override
  void addDependent(ReactiveNode dependent) => _dependents.add(dependent);

  @override
  void removeDependent(ReactiveNode dependent) => _dependents.remove(dependent);

  @override
  void dispose() {
    _disposed = true;
    _dependents.clear();
    _dependencies.dispose();

    super.dispose();
  }
}

enum _Freshness { clean, maybeStale, stale }
