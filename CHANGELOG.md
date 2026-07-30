# Changelog

## [0.1.0] - 2026-07-30

### Added

- `Signal<T>` — reactive value on `ChangeNotifier` implementing `ValueListenable`, with an equality write guard and custom `equals`.
- `Computed<T>` — lazy derived value with automatic dependency tracking, cycle detection and identity-preserving `equals`. A write settles in two phases — staleness across the graph first, notifications last — so a recomputation landing on an equal value notifies nobody and stops the cascade there, while a `Computed` without listeners is never recomputed by a write.
- `ReadonlySignal<T>` — read-only supertype of `Signal` and `Computed`: reading and listening without writing. The interface is `abstract final` and the concrete classes are `base` — implementing them externally is a compile error (extending stays possible; the subclass must be marked `base`, `final` or `sealed`), so a `ReadonlySignal` is never a foreign notifier.
- `Effect` — reactive side effect with microtask-coalesced reruns and a cleanup registrar; a runaway effect whose reruns keep writing to a signal it reads disposes itself and throws a `StateError` after 100 consecutive self-triggered reruns, instead of silently starving the event loop.
- `Observer` — auto-tracking widget, plus `Observer.withChild` for static subtrees, `listenables` for foreign `Listenable`s (a `FocusNode`, a text controller) observed alongside the tracked reads, and debug errors when the builder tracks nothing or writes to a signal it tracks.
- `Signal.update()` — derives the next value from the current one, read with `peek()`, keeping the equality guard of the setter.
- `listen()` on any `ReadonlySignal` — side effect with the previous and the next value, built on `Effect`: coalesced per microtask, silent on spurious `Computed` notifications, untracked callback, returning the `Effect` as the subscription handle.
- `when()` on any `ReadonlySignal` — a `Future` completing with the first value that satisfies a condition, checking the current value first and subscribing only when needed.
- `untracked()` and `peek()` escape hatches for reading without subscribing.
- `batch()` — groups several writes into one atomic update: listeners are notified once, at the end, so the half-applied state a group passes through never escapes, and a `Computed` reconciles once per batch instead of once per write. The equality guard covers the group — a batch that moves a value and puts it back notifies nobody. Reads inside the block stay current, batches nest, and pending notifications are delivered even when the body throws.
- Runaway propagation guard — a listener that writes back to the value it was notified about settles in the same propagation, but one that never converges throws a `StateError` after 100 rounds naming the likely cause, instead of hanging the isolate with no error and no stack.
- A `Computed` whose function throws no longer silences the nodes reconciled after it: the rest of the graph still settles and notifies, the first exception surfaces from the write, and any further one is reported to `FlutterError`. Notification no longer depends on the order the computeds were declared in.
- Notifications always run untracked — a listener that reads a `Signal` or `Computed` no longer reports that read to the tracked scope that triggered the write, so an `Effect` writing from its body never subscribes to what its listeners happen to read.
- `AsyncValue<T>` and `AsyncSignal<T>` — asynchronous state as a synchronous reactive value: idle/loading/data/error with previous data carried through reloads, latest-wins `run` and debug-friendly `toString`; a fresh signal starts `AsyncIdle`.
