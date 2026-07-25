import 'dart:async';

import 'tracker.dart';

/// A cleanup callback registered by an [Effect] run.
typedef EffectCleanup = void Function();

/// A reactive side effect with automatic dependency tracking.
///
/// The body runs synchronously on creation and reruns whenever a value it
/// read changes. Reruns are coalesced through the microtask queue: a burst of
/// synchronous writes produces a single rerun that reads consistent state.
///
/// The body receives a cleanup registrar. Registered cleanups run in reverse
/// order before the next rerun and on [dispose] — use them to release
/// resources opened by the previous run.
///
/// ```dart
/// final Effect ticker = Effect((onCleanup) {
///   final Timer timer = Timer.periodic(period.value, onTick);
///   onCleanup(timer.cancel);
/// });
///
/// ticker.dispose(); // cancels the last timer
/// ```
///
/// The body must be synchronous — reads after an `await` are not tracked.
/// An effect must not write to a signal it reads: from the first rerun on,
/// that reschedules forever.
class Effect {
  /// Creates the effect and runs its body immediately.
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

  /// Stops the effect: runs pending cleanups and cancels any scheduled rerun.
  ///
  /// Calling it more than once is a no-op.
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
