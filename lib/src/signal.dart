part of 'readonly_signal.dart';

/// A reactive value built on [ChangeNotifier].
///
/// {@category Core}
///
/// Reading [value] inside a tracked scope — an [Observer] builder, a
/// [Computed] function or an [Effect] body — automatically subscribes the
/// reader. Writing notifies listeners, unless the new value is judged equal.
///
/// ```dart
/// final Signal<int> count = Signal(0);
/// final Computed<int> doubled = Computed(() => count.value * 2);
///
/// count.value = 5;
/// print(doubled.value); // 10
/// ```
///
/// [Signal] implements [ReadonlySignal] — expose it as such to hand readers
/// listening without writing — and [ValueListenable], so it also works with
/// [ValueListenableBuilder], [Listenable.merge] and any Flutter API that
/// accepts a [Listenable].
///
/// Disposing is the owner's job: whoever creates the signal calls [dispose],
/// after which writes are ignored.
///
/// See also:
///
///  * [Computed], which derives a value from other reactive values.
///  * [batch], which groups several writes into a single notification.
///  * [AsyncSignal], a signal holding the state of asynchronous work.
base class Signal<T> extends ChangeNotifier
    implements ReadonlySignal<T>, ReactiveSource {
  /// Creates a signal holding [initial].
  ///
  /// When `equals` is provided it replaces `==` in the write guard: a write
  /// whose new value is judged equal to the current one does not notify.
  ///
  /// ```dart
  /// final Signal<List<int>> items = Signal([1, 2], equals: listEquals);
  ///
  /// items.value = [1, 2]; // equal by listEquals — listeners not notified
  /// ```
  Signal(T initial, {bool Function(T previous, T next)? equals})
    : _equals = equals,
      _value = initial {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  final bool Function(T previous, T next)? _equals;

  final Set<ReactiveNode> _dependents = <ReactiveNode>{};

  bool _disposed = false;

  T _value;

  @override
  T get value {
    Tracker.reportRead(this);

    return _value;
  }

  /// Sets the current value and notifies listeners.
  ///
  /// The write is ignored when the signal is disposed or when the new value
  /// is judged equal to the current one (by `equals`, falling back to `==`).
  ///
  /// Inside a [batch] the guard covers the group: the notification carries the
  /// value the signal held when the batch first wrote to it, so a batch that
  /// moves the value and puts it back notifies nobody.
  set value(T newValue) {
    if (_disposed || _isEqual(_value, newValue)) return;

    final T previous = _value;
    _value = newValue;

    Propagation.run(() {
      for (final ReactiveNode dependent in _dependents.toList()) {
        dependent.markStale();
      }

      Propagation.emit(this, () => _notify(previous));
    });
  }

  void _notify(T previous) {
    if (_disposed || _isEqual(previous, _value)) return;

    notifyListeners();
  }

  /// Derives the next value from the current one and writes it.
  ///
  /// The current value is read with [peek], so calling it inside a tracked
  /// scope does not subscribe that scope to this signal. The write goes
  /// through [value], keeping the equality guard — a [transform] returning a
  /// value judged equal does not notify — and the no-op after [dispose].
  ///
  /// ```dart
  /// final Signal<int> count = Signal(0);
  ///
  /// count.update((int current) => current + 1);
  /// print(count.value); // 1
  /// ```
  void update(T Function(T current) transform) => value = transform(peek());

  /// Reads the current value without registering a dependency.
  ///
  /// Use it inside a tracked scope to consult a value the scope should not
  /// react to.
  ///
  /// ```dart
  /// final Signal<String> route = Signal('home');
  /// final Signal<int> page = Signal(1);
  ///
  /// final Effect logger = Effect(
  ///   (_) => debugPrint('${route.value} (page ${page.peek()})'),
  /// );
  /// ```
  @override
  T peek() => _value;

  @override
  void addDependent(ReactiveNode dependent) => _dependents.add(dependent);

  @override
  void removeDependent(ReactiveNode dependent) => _dependents.remove(dependent);

  @override
  void dispose() {
    _disposed = true;
    _dependents.clear();

    super.dispose();
  }

  bool _isEqual(T previous, T next) {
    final bool Function(T previous, T next)? equals = _equals;

    return equals != null ? equals(previous, next) : previous == next;
  }
}
