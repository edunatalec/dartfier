/// @docImport 'package:dartfier/dartfier.dart';
library;

import 'tracker.dart';

/// Groups several writes into a single atomic update.
///
/// {@category Utilities}
///
/// Writes that belong together often pass through states that are not valid on
/// their own. Outside a batch, every write notifies immediately, so a listener
/// can observe that half-applied state:
///
/// ```dart
/// final Signal<String> first = Signal('A');
/// final Signal<String> second = Signal('B');
/// final Computed<String> pair = Computed(() => '${first.value}${second.value}');
///
/// pair.addListener(() => print(pair.value));
///
/// final String held = first.peek();
/// first.value = second.peek();
/// second.value = held;
/// // prints BB, then BA — BB never existed logically
/// ```
///
/// Inside a batch, listeners are notified once, at the end, with the final
/// value:
///
/// ```dart
/// batch(() {
///   final String held = first.peek();
///   first.value = second.peek();
///   second.value = held;
/// });
/// // prints BA
/// ```
///
/// Reads stay current while the batch runs — staleness still propagates per
/// write — so `pair.value` read inside [run] already reflects the writes made
/// so far. Only the notifications are held back.
///
/// A [Computed] reconciles once per batch instead of once per write, so this
/// is also how a burst of related writes avoids recomputing repeatedly:
///
/// ```dart
/// final Signal<String> query = Signal('');
/// final Signal<String?> category = Signal<String?>('books');
/// final Signal<bool> inStock = Signal(true);
///
/// batch(() {
///   query.value = '';
///   category.value = null;
///   inStock.value = false;
/// });
/// ```
///
/// Batches nest: only the outermost one flushes. The value returned by [run]
/// is returned unchanged, and pending notifications are still delivered when
/// [run] throws.
///
/// See also:
///
///  * [Signal.update], which derives one write from the current value.
T batch<T>(T Function() run) => Propagation.batch(run);
