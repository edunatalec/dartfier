/// @docImport 'package:dartfier/dartfier.dart';
library;

import 'tracker.dart';

/// Runs [run] with dependency tracking suspended and returns its result.
///
/// {@category Utilities}
///
/// Signals and computeds read inside the block do not become dependencies of
/// the current tracked scope. Use it to consult auxiliary state inside an
/// [Observer], [Computed] or [Effect] without subscribing to it.
///
/// ```dart
/// final Signal<int> tracked = Signal(0);
/// final Signal<int> verbosity = Signal(1);
///
/// final Effect logger = Effect(
///   (_) => print('${tracked.value} @ ${untracked(() => verbosity.value)}'),
/// );
/// ```
///
/// See also:
///
///  * [ReadonlySignal.peek], which does the same for a single value.
T untracked<T>(T Function() run) => Tracker.untracked(run);
