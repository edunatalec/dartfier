# Changelog

## [0.1.0] - 2026-07-25

### Added

- `Signal<T>` — reactive value on `ChangeNotifier` implementing `ValueListenable`, with an equality write guard and custom `equals`.
- `Computed<T>` — lazy derived value with automatic dependency tracking, cycle detection and identity-preserving `equals`.
- `Effect` — reactive side effect with microtask-coalesced reruns and a cleanup registrar.
- `Observer` — auto-tracking widget, plus `Observer.withChild` for static subtrees and a debug error when the builder tracks nothing.
- `untracked()` and `peek()` escape hatches for reading without subscribing.
- `AsyncValue<T>` and `AsyncSignal<T>` — asynchronous state as a synchronous reactive value: loading/data/error with previous data carried through reloads and latest-wins `run`.
