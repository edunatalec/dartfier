import 'package:flutter/foundation.dart';

import 'tracker.dart';

class Signal<T> extends ChangeNotifier implements ValueListenable<T> {
  Signal(T initial) : _value = initial {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  bool _disposed = false;

  T _value;

  @override
  T get value {
    Tracker.reportRead(this);

    return _value;
  }

  set value(T newValue) {
    if (_disposed || _value == newValue) return;

    _value = newValue;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;

    super.dispose();
  }
}
