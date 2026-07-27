import 'package:flutter/foundation.dart';

import 'tracker.dart';

part 'computed.dart';
part 'signal.dart';

/// A read-only view of a reactive value.
///
/// [Signal] and [Computed] implement this interface — and only this package
/// can, so a [ReadonlySignal] is always one of them underneath, never a
/// foreign notifier: reading [value] inside a tracked scope — an `Observer`
/// builder, a `Computed` function or an `Effect` body — automatically
/// subscribes the reader. Expose a value through it to hand consumers
/// reading and listening without writing.
///
/// ```dart
/// final Signal<int> count = Signal(1);
/// final ReadonlySignal<int> view = count;
///
/// print(view.value); // 1
/// ```
///
/// [ReadonlySignal] implements [ValueListenable], so it also works with
/// [ValueListenableBuilder], [Listenable.merge] and any Flutter API that
/// accepts a [Listenable].
abstract final class ReadonlySignal<T> implements ValueListenable<T> {
  /// Reads the current value without registering a dependency.
  ///
  /// ```dart
  /// final ReadonlySignal<int> view = Signal(1);
  ///
  /// print(view.peek()); // 1
  /// ```
  T peek();
}
