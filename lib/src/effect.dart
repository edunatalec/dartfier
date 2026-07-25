import 'dart:async';

import 'tracker.dart';

class Effect {
  Effect(this._run) {
    _execute();
  }

  final void Function() _run;

  late final DependencyBag _dependencies = DependencyBag(_onDependencyChanged);

  bool _disposed = false;
  bool _scheduled = false;

  void _execute() => _dependencies.track(_run);

  void _onDependencyChanged() {
    if (_disposed || _scheduled) return;

    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;

      if (_disposed) return;

      _execute();
    });
  }

  void dispose() {
    _disposed = true;
    _dependencies.dispose();
  }
}
