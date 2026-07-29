# dartfier

[![pub package](https://img.shields.io/pub/v/dartfier.svg)](https://pub.dev/packages/dartfier)
[![package publisher](https://img.shields.io/pub/publisher/dartfier.svg)](https://pub.dev/packages/dartfier/publisher)

Fine-grained reactivity for Flutter, built entirely on `ChangeNotifier`: `Signal`, `Computed`, `Effect` and an auto-tracking `Observer` widget. Zero dependencies, no code generation, full `ValueListenable` interop.

## Table of Contents

- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Why dartfier?](#why-dartfier)
- [API](#api)
  - [Signal](#signal)
  - [Computed](#computed)
  - [ReadonlySignal](#readonlysignal)
  - [Effect](#effect)
  - [Observer](#observer)
  - [AsyncSignal](#asyncsignal)
  - [listen and when](#listen-and-when)
  - [untracked and peek](#untracked-and-peek)
- [Semantics](#semantics)
- [Rules of Use](#rules-of-use)
- [Design Decisions](#design-decisions)
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

`update()` derives the next value from the current one, reading it with `peek()` — so calling it inside a tracked scope does not subscribe that scope to the signal it writes:

```dart
count.update((current) => current + 1);
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

### ReadonlySignal

The read-only supertype of `Signal` and `Computed`. Expose a value as `ReadonlySignal` to hand consumers reading and listening without writing — the natural parameter type for a leaf widget:

```dart
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count});

  final ReadonlySignal<int> count;

  @override
  Widget build(BuildContext context) {
    return Observer((context) => Text('${count.value}'));
  }
}
```

The interface is `abstract final` and the concrete classes are `base`: implementing them outside dartfier is a compile error, so a `ReadonlySignal` is always a `Signal` or a `Computed` underneath — never a foreign notifier — and an `Observer` reading one subscribes. Extending `Signal`/`Computed` remains possible: the subclass must itself be marked `base`, `final` or `sealed` (Dart's modifier transitivity), and it inherits the tracked reads. In tests, the stand-in for a `ReadonlySignal` is a real `Signal`.

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

A foreign `Listenable` — a `FocusNode`, a `ScrollController`, any notifier that is not a signal — is invisible to tracking. Pass it through `listenables` and the observer also rebuilds when it notifies, alongside the tracked reads:

```dart
Observer(
  (context) => Text(focusNode.hasFocus ? query.value : ''),
  listenables: [focusNode],
)
```

In debug mode, an `Observer` whose builder tracks nothing and lists no `listenables` throws a `FlutterError` — such a widget would never rebuild, which is the silent bug this model is most prone to.

### AsyncSignal

The bridge between the synchronous graph and asynchronous work. An `AsyncSignal<T>` is a `Signal<AsyncValue<T>>`: it starts `AsyncIdle`, and `run` executes a fetcher and publishes `AsyncLoading` → `AsyncData` / `AsyncError`, with latest-wins semantics — starting a new `run` drops the outcome of any older one still in flight.

```dart
final AsyncSignal<List<Book>> results = AsyncSignal();

unawaited(results.run(() => api.search(query.value)));

Observer((context) => switch (results.value) {
  AsyncIdle() => const SearchPrompt(),
  AsyncLoading(:final previous?) => BookList(previous, refreshing: true),
  AsyncLoading() => const Spinner(),
  AsyncData(:final value) => BookList(value),
  AsyncError(:final error) => ErrorView(error),
})
```

`AsyncLoading` and `AsyncError` carry the previous data, so a refetch keeps showing the old content instead of flashing a spinner — `value.valueOrNull` is the shortcut for "latest usable data". Tracking stays fully synchronous: the fetcher runs outside the graph and writes its outcome back.

### listen and when

Side effects that care about the *change*, not just the current value. `listen` calls back with the previous and the next value and returns the `Effect` behind it — dispose it to unsubscribe:

```dart
final Effect subscription = status.listen((previous, next) {
  analytics.log('status', from: previous, to: next);
});

subscription.dispose();
```

A `listen` is an `Effect` with memory, and that buys the hard parts for free. Callbacks coalesce per microtask, so a burst of synchronous writes fires once, carrying the value from before the burst and the value after it; a `listen` on a `Computed` never observes the inconsistent mid-diamond state a raw `addListener` would; and the spurious notifications described in [Semantics](#semantics) are filtered — a recomputation landing on an equal value does not call back. The callback does not fire on creation (the first run only captures the current value), and its reads are untracked, so consulting other signals inside it subscribes to nothing.

`when` completes a `Future` with the first value that satisfies a condition — state semantics, not stream semantics: the current value is checked first, with `peek()`, so an already-satisfied condition completes immediately, without subscribing to anything.

```dart
unawaited(results.run(() => api.search(query.value)));

final AsyncValue<List<Book>> loaded = await results.when(
  (value) => value is AsyncData<List<Book>>,
);
```

Useful in tests and in orchestration — "wait until it is loaded, then continue". Changes are observed through `listen`, so a synchronous burst completes the future with the value at the end of the burst. There is no built-in timeout: while the condition is never satisfied — including after the signal is disposed — the future never completes, so wrap the call in `Future.timeout` when that matters.

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
2. **Read `.value` in the `Observer` builder body.** Closures that run later — a nested `Builder`, a gesture callback — execute outside tracking and do not subscribe. The builder must also not *write* to a signal it tracks: the framework discards a rebuild marked from inside a build, so the UI would silently lag one value behind — in debug, that write throws a `FlutterError`.
3. **An `Effect` must not write to a signal it reads.** During the first run the write falls into the void (subscriptions attach after the body runs); from the first rerun on, every self-write schedules another rerun. A self-write that converges in a few steps keeps working, but after 100 consecutive self-triggered reruns the effect assumes it will never stabilize, disposes itself and throws a `StateError` — instead of silently starving the event loop.
4. **Dispose is yours.** `Signal`, `Computed` and `Effect` have owners: whoever creates them disposes them.

## Design Decisions

Deliberate gaps, not missing features:

- **No `batch()`.** Effects coalesce through the microtask queue and widget rebuilds coalesce per frame, so a burst of synchronous writes already produces a single rerun/rebuild reading consistent state. A synchronous flush API would break that guarantee.
- **No observable collections.** An equality guard and in-place mutation cannot coexist: a mutated list is identical to itself, so the write would be silently swallowed. The supported pattern is the immutable snapshot — `items.value = [...items.value, next]` — with `equals: listEquals` when notification cuts matter.
- **No `context.watch()`.** Subscribing an `Element` from a getter requires either retaining unmounted elements until the next notification or weak-reference/finalizer machinery — both at odds with a core meant to be read in one sitting. `Observer` does the same job explicitly, one widget away.
- **No async compute.** A `Computed` that awaits would silently stop tracking everything read after the first `await`. Async enters through [`AsyncSignal`](#asyncsignal), where the fetcher runs outside the graph and writes back.
- **No `debounce`/`throttle`.** Timing policy belongs at the call site: a real debounce needs cancelling and flushing, both of which depend on what the effect is for. An `Effect` and its cleanup registrar already express it in three lines, with cancellation included:

  ```dart
  Effect((onCleanup) {
    final String text = query.value;
    final Timer timer = Timer(const Duration(milliseconds: 300), () => search(text));
    onCleanup(timer.cancel);
  });
  ```

- **No event primitive.** A signal holds state, not a sequence in time — every value is observable at any moment, and an event that fires twice with the same payload is not. For a command signal, opt out of the equality guard: `Signal<String>('', equals: (_, _) => false)` notifies on every write, the same trick Solid's `{ equals: false }` uses. Streams remain the right tool for genuine event sequences.
- **No `select()`.** `Computed` already is the select: `Computed(() => user.value.name)` recomputes lazily, notifies only its readers and tracks exactly what it read — a dedicated API would be the same object with a narrower name. Solidart shipped one and removed it.

## License

[MIT](LICENSE)
