import 'tracker.dart';

/// Runs [run] with dependency tracking suspended and returns its result.
///
/// Signals and computeds read inside the block do not become dependencies of
/// the current tracked scope. Use it to consult auxiliary state inside an
/// `Observer`, `Computed` or `Effect` without subscribing to it.
///
/// ```dart
/// final Effect logger = Effect(
///   (_) => log(tracked.value, untracked(() => verbosity.value)),
/// );
/// ```
T untracked<T>(T Function() run) => Tracker.untracked(run);
