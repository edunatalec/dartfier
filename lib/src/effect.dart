import 'dart:async';

import 'tracker.dart';

typedef EffectCleanup = void Function();

class Effect {
  Effect(this._run) {
    _execute();
  }

  final void Function(void Function(EffectCleanup cleanup) onCleanup) _run;

  late final DependencyBag _dependencies = DependencyBag(_onDependencyChanged);

  final List<EffectCleanup> _cleanups = <EffectCleanup>[];

  bool _disposed = false;
  bool _scheduled = false;

  void _execute() {
    _runCleanups();
    _dependencies.track(() => _run(_cleanups.add));
  }

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
    if (_disposed) return;

    _disposed = true;
    _runCleanups();
    _dependencies.dispose();
  }

  void _runCleanups() {
    final List<EffectCleanup> pending = List<EffectCleanup>.of(
      _cleanups.reversed,
    );
    _cleanups.clear();

    for (final EffectCleanup cleanup in pending) {
      Tracker.untracked(cleanup);
    }
  }
}
