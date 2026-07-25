import 'package:flutter/foundation.dart';

import 'tracker.dart';

/// A reactive value built on [ChangeNotifier].
///
/// Reading [value] inside a tracked scope — an `Observer` builder, a
/// `Computed` function or an `Effect` body — automatically subscribes the
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
/// [Signal] implements [ValueListenable], so it also works with
/// [ValueListenableBuilder], [Listenable.merge] and any Flutter API that
/// accepts a [Listenable].
class Signal<T> extends ChangeNotifier implements ValueListenable<T> {
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
  Signal(T initial, {this._equals}) : _value = initial {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  final bool Function(T previous, T next)? _equals;

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
  set value(T newValue) {
    if (_disposed || _isEqual(_value, newValue)) return;

    _value = newValue;
    notifyListeners();
  }

  /// Reads the current value without registering a dependency.
  ///
  /// Use it inside a tracked scope to consult a value the scope should not
  /// react to.
  ///
  /// ```dart
  /// final Effect logger = Effect(
  ///   (_) => debugPrint('${tracked.value} (page ${page.peek()})'),
  /// );
  /// ```
  T peek() => _value;

  @override
  void dispose() {
    _disposed = true;

    super.dispose();
  }

  bool _isEqual(T previous, T next) {
    final bool Function(T previous, T next)? equals = _equals;

    return equals != null ? equals(previous, next) : previous == next;
  }
}
