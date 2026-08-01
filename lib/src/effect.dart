/// @docImport 'package:dartfier/dartfier.dart';
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'tracker.dart';

/// A cleanup callback registered by an [Effect] run.
///
/// {@category Utilities}
typedef EffectCleanup = void Function();

/// A reactive side effect with automatic dependency tracking.
///
/// {@category Utilities}
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
/// final Signal<Duration> period = Signal(const Duration(seconds: 1));
///
/// final Effect ticker = Effect((onCleanup) {
///   final Timer timer = Timer.periodic(
///     period.value,
///     (_) => debugPrint('tick'),
///   );
///
///   onCleanup(timer.cancel);
/// });
///
/// ticker.dispose(); // cancels the last timer
/// ```
///
/// The body must be synchronous — reads after an `await` are not tracked.
/// An effect must not write to a signal it reads — consult it with
/// [ReadonlySignal.peek] instead. During the first run such a write is
/// ignored; from the first rerun on, every self-write schedules another
/// rerun, and after 100 consecutive self-triggered reruns the effect assumes
/// it will never stabilize, disposes itself and throws a [StateError]. A
/// self-write that converges before that — a state machine settling in a few
/// steps — keeps working.
///
/// See also:
///
///  * [ReadonlySignalSubscriptions.listen], an effect that also receives the
///    previous value.
///  * [Watch], which skips the first run and reacts only to a change.
///  * [Observer], which does the same job for a widget subtree.
///  * [untracked], to read a value inside the body without depending on it.
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

  int _selfTriggeredReruns = 0;

  static const int _maxSelfTriggeredReruns = 100;

  void _execute() {
    _runCleanups();
    _dependencies.track(() => _run(_cleanups.add));
  }

  void _onDependencyChanged() {
    if (_disposed || _scheduled) return;

    _scheduled = true;
    scheduleMicrotask(_rerun);
  }

  void _rerun() {
    _scheduled = false;

    if (_disposed) return;

    _execute();

    if (!_scheduled) {
      _selfTriggeredReruns = 0;

      return;
    }

    _selfTriggeredReruns += 1;

    if (_selfTriggeredReruns < _maxSelfTriggeredReruns) return;

    dispose();

    throw StateError(
      'Effect did not stabilize after $_maxSelfTriggeredReruns consecutive '
      'self-triggered reruns: the body (or a cleanup) writes to a signal the '
      'effect reads. The effect has been disposed.',
    );
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
      try {
        Tracker.untracked(cleanup);
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'dartfier',
            context: ErrorDescription('running an Effect cleanup'),
          ),
        );
      }
    }
  }
}
