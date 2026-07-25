import 'package:flutter/foundation.dart';

import 'tracker.dart';

class Computed<T> extends ChangeNotifier implements ValueListenable<T> {
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
