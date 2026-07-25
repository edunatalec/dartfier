import 'package:flutter/foundation.dart';

import 'tracker.dart';

class Signal<T> extends ChangeNotifier implements ValueListenable<T> {
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

  set value(T newValue) {
    if (_disposed || _isEqual(_value, newValue)) return;

    _value = newValue;
    notifyListeners();
  }

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
