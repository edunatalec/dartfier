/// @docImport 'package:flutter/foundation.dart';
///
/// Fine-grained reactivity for Flutter, built entirely on [ChangeNotifier].
///
/// A [Signal] holds a value, a [Computed] derives one, an [Effect] runs a side
/// effect and an [Observer] rebuilds a widget. Reading `.value` inside a
/// *tracked scope* — an [Observer] builder, a [Computed] function or an
/// [Effect] body — subscribes the reader to that value, so dependencies are
/// discovered on every run instead of declared up front.
///
/// ```dart
/// final Signal<int> count = Signal(0);
/// final Computed<int> doubled = Computed(() => count.value * 2);
///
/// count.value = 5;
/// print(doubled.value); // 10
/// ```
///
/// A write settles in two phases: it first marks the reachable graph stale,
/// waking nobody, and only then does each stale node recompute and notify —
/// and only if its value actually changed. Reads are therefore always
/// consistent, even in a diamond, and a derivation that lands on an equal
/// value stops the cascade there.
///
/// Every reactive value is a [ChangeNotifier] implementing [ValueListenable],
/// so `ValueListenableBuilder`, `Listenable.merge` and any Flutter API taking
/// a `Listenable` work without an adapter.
///
/// See also:
///
///  * [Signal], the writable reactive value.
///  * [Computed], a lazy value derived from other reactive values.
///  * [ReadonlySignal], the read-only supertype of both.
///  * [Effect], a side effect that reruns when what it read changes.
///  * [Watch], a side effect on a tracked expression, skipping the first run.
///  * [Observer], the widget that rebuilds on the values its builder reads.
///  * [AsyncSignal], which brings asynchronous work into the graph.
///  * [batch], which groups several writes into a single notification.
library;

export 'src/async_signal.dart';
export 'src/async_value.dart';
export 'src/batch.dart';
export 'src/effect.dart';
export 'src/listen.dart';
export 'src/observer.dart';
export 'src/readonly_signal.dart';
export 'src/untracked.dart';
export 'src/watch.dart';
