import 'package:flutter/foundation.dart';

import 'tracker.dart';

class Computed<T> extends ChangeNotifier implements ValueListenable<T> {
  Computed(this._compute) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  final T Function() _compute;

  late final DependencyBag _dependencies = DependencyBag(_onDependencyChanged);

  bool _disposed = false;
  bool _dirty = true;
  bool _computing = false;

  late T _value;

  @override
  T get value {
    Tracker.reportRead(this);

    if (_dirty) _recompute();

    return _value;
  }

  void _recompute() {
    if (_computing) {
      throw StateError('Computed dependency cycle detected');
    }

    _computing = true;

    try {
      _value = _disposed
          ? Tracker.collect(<Listenable>{}, _compute)
          : _dependencies.track(_compute);
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
}
