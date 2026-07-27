part of 'readonly_signal.dart';

/// A derived reactive value with automatic dependency tracking.
///
/// The computation is lazy: it runs on the first read and is cached until a
/// dependency notifies. Dependencies are rediscovered on every recomputation,
/// so conditional reads subscribe to exactly what the last run read.
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
base class Computed<T> extends ChangeNotifier implements ReadonlySignal<T> {
  /// Creates a computed value derived by the given function.
  ///
  /// When `equals` is provided, a recomputation whose result is judged equal
  /// to the previous value keeps the previous object, preserving identity
  /// for downstream `==` checks.
  ///
  /// ```dart
  /// final Computed<List<Chapter>> visible = Computed(
  ///   () => filter(chapters.value, query.value),
  ///   equals: listEquals,
  /// );
  /// ```
  Computed(this._compute, {this._equals}) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  final T Function() _compute;

  final bool Function(T previous, T next)? _equals;

  late final DependencyBag _dependencies = DependencyBag(_onDependencyChanged);

  bool _disposed = false;
  bool _dirty = true;
  bool _computing = false;
  bool _hasValue = false;

  late T _value;

  @override
  T get value {
    Tracker.reportRead(this);

    if (_dirty) _recompute();

    return _value;
  }

  /// Reads the current value without registering a dependency.
  ///
  /// Still recomputes if the cached value is stale.
  ///
  /// ```dart
  /// final Computed<int> shifted = Computed(() => doubled.peek() + 1);
  /// ```
  @override
  T peek() {
    if (_dirty) _recompute();

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

      if (!_hasValue || !_isEqual(_value, next)) _value = next;

      _hasValue = true;
    } finally {
      _computing = false;
    }

    _dirty = false;
  }

  void _onDependencyChanged() {
    if (_dirty) return;

    _dirty = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _dependencies.dispose();

    super.dispose();
  }

  bool _isEqual(T previous, T next) {
    final bool Function(T previous, T next)? equals = _equals;

    return equals != null ? equals(previous, next) : previous == next;
  }
}
