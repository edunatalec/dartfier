# Changelog

## [Unreleased]

### Changed

- **Breaking (subtle)** — an `Effect` whose reruns keep writing to a signal it reads no longer reschedules forever: after 100 consecutive self-triggered reruns it disposes itself and throws a `StateError` instead of silently starving the event loop. Converging self-writes (a state machine settling in a few steps) keep working.
- Lowered the minimum SDK from Dart `^3.12.2` to `^3.8.0` (Flutter `>=3.32.0`): the constructors of `Signal` and `Computed` no longer use private named parameters, with no change to the public API.
- The example is now a runnable Flutter showcase app — one page per feature — instead of a single `example.dart`.

## [0.1.0] - 2026-07-25

### Added

- `Signal<T>` — reactive value on `ChangeNotifier` implementing `ValueListenable`, with an equality write guard and custom `equals`.
- `Computed<T>` — lazy derived value with automatic dependency tracking, cycle detection and identity-preserving `equals`.
- `ReadonlySignal<T>` — read-only supertype of `Signal` and `Computed`: reading and listening without writing. The interface is `abstract final` and the concrete classes are `base` — implementing them externally is a compile error (extending stays possible; the subclass must be marked `base`, `final` or `sealed`), so a `ReadonlySignal` is never a foreign notifier.
- `Effect` — reactive side effect with microtask-coalesced reruns and a cleanup registrar.
- `Observer` — auto-tracking widget, plus `Observer.withChild` for static subtrees, `listenables` for foreign `Listenable`s (a `FocusNode`, a text controller) observed alongside the tracked reads, and a debug error when the builder tracks nothing.
- `untracked()` and `peek()` escape hatches for reading without subscribing.
- `AsyncValue<T>` and `AsyncSignal<T>` — asynchronous state as a synchronous reactive value: idle/loading/data/error with previous data carried through reloads, latest-wins `run` and debug-friendly `toString`; a fresh signal starts `AsyncIdle`.
