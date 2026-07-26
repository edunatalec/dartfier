# dartfier

Fine-grained reactivity for Flutter, built entirely on `ChangeNotifier`: `Signal`, `Computed`, `Effect` and an auto-tracking `Observer` widget. Zero dependencies, no code generation, full `ValueListenable` interop.

## Table of Contents

- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Why dartfier?](#why-dartfier)
- [API](#api)
  - [Signal](#signal)
  - [Computed](#computed)
  - [Effect](#effect)
  - [Observer](#observer)
  - [AsyncSignal](#asyncsignal)
  - [untracked and peek](#untracked-and-peek)
- [Semantics](#semantics)
- [Rules of Use](#rules-of-use)
- [License](#license)

## Installation

```yaml
dependencies:
  dartfier: ^0.1.0
```

## Basic Usage

```dart
final Signal<int> count = Signal(0);
final Computed<int> doubled = Computed(() => count.value * 2);

Observer((context) => Text('${count.value} × 2 = ${doubled.value}'))
```

Reading `.value` inside a tracked scope — an `Observer` builder, a `Computed` function or an `Effect` body — subscribes the reader automatically. No listenable lists, no `Listenable.merge`.

## Why dartfier?

- **Native by construction.** `Signal` and `Computed` are `ChangeNotifier`s implementing `ValueListenable` — the whole engine speaks Flutter's own observability language. `ValueListenableBuilder`, `Listenable.merge`, `AnimatedBuilder` and any API that accepts a `Listenable` work out of the box, and a codebase built on `ValueNotifier` can adopt dartfier one variable at a time.
- **Small enough to audit.** A few hundred lines, zero dependencies, no code generation. When you need to understand why something rebuilt, you can read the entire engine in one sitting.
- **Explicit semantics.** The guarantees and the limits — consistent reads, coalesced effects, synchronous-only tracking, dispose ownership — are written down in this README and pinned by the test suite, including the hard cases: diamond graphs, conditional dependencies, cycles, cleanup order.
- **Loud where it matters.** In debug mode, an `Observer` that tracks nothing throws instead of silently never rebuilding — the classic failure mode of read-based tracking becomes a first-run error.

## API

### Signal

A reactive value. Writes notify listeners, guarded by equality (`==` by default, or a custom `equals`):

```dart
final Signal<List<int>> items = Signal([1, 2], equals: listEquals);

items.value = [1, 2]; // equal by listEquals — listeners not notified
items.value = [1, 2, 3]; // notifies
```

`Signal` implements `ValueListenable`, so it plugs into `ValueListenableBuilder`, `Listenable.merge` and any Flutter API that accepts a `Listenable` — no adapters.

### Computed

A lazy derived value with automatic dependency tracking. It computes on first read, caches until a dependency notifies, and rediscovers its dependencies on every recomputation — conditional reads subscribe to exactly what the last run read.

```dart
final Computed<List<Chapter>> visible = Computed(
  () => filter(chapters.value, query.value),
  equals: listEquals,
);
```

With `equals`, a recomputation that produces an equal result keeps the previous object, preserving identity for downstream `==` checks. A dependency cycle throws a `StateError` on read.

### Effect

A reactive side effect. The body runs synchronously on creation and reruns when any value it read changes. Reruns are coalesced through the microtask queue: a burst of synchronous writes produces a single rerun reading consistent state.

The body receives a cleanup registrar — cleanups run in reverse order before the next rerun and on `dispose()`:

```dart
final Effect ticker = Effect((onCleanup) {
  final Timer timer = Timer.periodic(period.value, onTick);
  onCleanup(timer.cancel);
});

ticker.dispose(); // cancels the last timer
```

### Observer

A widget whose builder runs under tracking:

```dart
Observer((context) => Text('${count.value}'))
```

For heavy static subtrees, `Observer.withChild` builds the child once and hands it back on every rebuild:

```dart
Observer.withChild(
  builder: (context, child) => Column(
    children: [Text('${count.value}'), child!],
  ),
  child: const HeavyStaticWidget(),
)
```

In debug mode, an `Observer` whose builder tracks nothing throws a `FlutterError` — such a widget would never rebuild, which is the silent bug this model is most prone to.

### AsyncSignal

The bridge between the synchronous graph and asynchronous work. An `AsyncSignal<T>` is a `Signal<AsyncValue<T>>`: `run` executes a fetcher and publishes `AsyncLoading` → `AsyncData` / `AsyncError`, with latest-wins semantics — starting a new `run` drops the outcome of any older one still in flight.

```dart
final AsyncSignal<List<Book>> results = AsyncSignal();

unawaited(results.run(() => api.search(query.value)));

Observer((context) => switch (results.value) {
  AsyncLoading(:final previous?) => BookList(previous, refreshing: true),
  AsyncLoading() => const Spinner(),
  AsyncData(:final value) => BookList(value),
  AsyncError(:final error) => ErrorView(error),
})
```

`AsyncLoading` and `AsyncError` carry the previous data, so a refetch keeps showing the old content instead of flashing a spinner — `value.valueOrNull` is the shortcut for "latest usable data". Tracking stays fully synchronous: the fetcher runs outside the graph and writes its outcome back.

### untracked and peek

Escape hatches for reading without subscribing:

```dart
final Effect logger = Effect(
  (_) => log(tracked.value, untracked(() => verbosity.value)),
);

final Computed<int> shifted = Computed(() => doubled.peek() + 1);
```

`untracked(fn)` suspends tracking for a block; `peek()` reads a single `Signal` or `Computed` without registering a dependency.

## Semantics

**Push-dirty, pull-compute.** Writing a `Signal` pushes dirtiness and notifications through dependents; recomputation happens on read. Consequences:

- **Reads are always consistent.** Any read after any notification recomputes against current state — including diamond graphs (A feeds B and C; D reads B and C): D notifies once and reads consistently.
- **Notifications may be spurious.** A `Computed` notifies when it becomes dirty, before knowing whether the new result differs. Widgets absorb this (rebuilds are frame-coalesced); raw listeners must tolerate notification without a value change.

**Tracking per read.** Each layer subscribes one level down: an `Observer` reading a `Computed` subscribes to the `Computed`, not to the signals inside it.

**Effects coalesce per microtask.** The first run is synchronous (on creation, to collect dependencies). Reruns are scheduled at the end of the microtask queue, so effects never observe a diamond glitch.

## Rules of Use

1. **`Computed` functions and `Effect` bodies are synchronous.** An `await` loses the tracking context — reads after it register nothing. The types (`T Function()`) already reject `async`; do not work around it with `.then`.
2. **Read `.value` in the `Observer` builder body.** Closures that run later — a nested `Builder`, a gesture callback — execute outside tracking and do not subscribe.
3. **An `Effect` must not write to a signal it reads.** During the first run the write falls into the void (subscriptions attach after the body runs); from the first rerun on, it reschedules forever.
4. **Dispose is yours.** `Signal`, `Computed` and `Effect` have owners: whoever creates them disposes them.

## License

[MIT](LICENSE)
