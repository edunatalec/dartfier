[![pub package](https://img.shields.io/pub/v/dartfier.svg)](https://pub.dev/packages/dartfier)
[![package publisher](https://img.shields.io/pub/publisher/dartfier.svg)](https://pub.dev/packages/dartfier/publisher)

Fine-grained reactivity for Flutter, built entirely on `ChangeNotifier`:
`Signal`, `Computed`, `Effect` and an auto-tracking `Observer` widget.

Flutter only, zero dependencies, no code generation, full `ValueListenable`
interop.

## Requirements

Flutter 3.32 or newer, which ships Dart 3.8:

```bash
flutter --version
```

## Installation

```sh
flutter pub add dartfier
```

Or in `pubspec.yaml`:

```yaml
dependencies:
  dartfier: ^0.1.0
```

```dart
import 'package:dartfier/dartfier.dart';
```

## Quick start

A counter, end to end — the signal, the derived value, the widget that tracks
them and the disposal that ends them:

```dart
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  final Signal<int> count = Signal(0);
  late final Computed<int> doubled = Computed(() => count.value * 2);

  @override
  void dispose() {
    doubled.dispose();
    count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Observer(
          (context) => Text('${count.value} × 2 = ${doubled.value}'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

Reading `.value` inside a tracked scope — an `Observer` builder, a `Computed`
function or an `Effect` body — subscribes the reader automatically. No
listenable lists, no `Listenable.merge`.

Every `Signal`, `Computed` and `Effect` has an owner, and the owner disposes
it — that is the `dispose()` above, and the full ownership rule is in
[Rules of use](#rules-of-use).

## Contents

- [Why dartfier](#why-dartfier)
- [API](#api)
- [Semantics](#semantics)
- [Rules of use](#rules-of-use)
- [Example app](#example-app)
- [Contributing](#contributing)
- [License](#license)

## Why dartfier

- **Native by construction.** `Signal` and `Computed` are `ChangeNotifier`s
  implementing `ValueListenable`, so `ValueListenableBuilder`,
  `Listenable.merge`, `AnimatedBuilder` and any API that accepts a
  `Listenable` work out of the box — and a codebase built on `ValueNotifier`
  can adopt dartfier one variable at a time.
- **No build step.** Zero dependencies and no code generation: nothing to
  regenerate after an edit, and the engine is a few hundred lines you can read
  end to end.
- **Explicit semantics.** The guarantees and the limits — consistent reads,
  coalesced effects, synchronous-only tracking, dispose ownership — are
  written down below and pinned by the test suite, including the hard cases:
  diamond graphs, conditional dependencies, cycles, cleanup order.
- **Debug errors instead of silence.** An `Observer` that tracks nothing
  throws in debug mode rather than never rebuilding, which turns the classic
  failure mode of read-based tracking into a first-run error.

## API

### Signal

A reactive value. Writes notify listeners, guarded by equality (`==` by
default, or a custom `equals`):

```dart
final Signal<List<int>> items = Signal([1, 2], equals: listEquals);

items.value = [1, 2]; // equal by listEquals — listeners not notified
items.value = [1, 2, 3]; // notifies
```

**Collections are replaced, never mutated in place.** Like `ValueNotifier`, a
`Signal` notifies on assignment, not on what you do to the object it holds —
`items.value.add(4)` changes the list and notifies nobody, because the signal
never saw a write. Assign a new collection instead:

```dart
final Signal<List<int>> items = Signal([1, 2]);

items.value.add(3); // silent — the widget will not rebuild
items.value = [...items.value, 3]; // notifies

final Signal<Map<String, int>> scores = Signal({'a': 1});

scores.value = {...scores.value, 'b': 2}; // same rule for maps and sets
```

The write is swallowed rather than rejected because the equality guard sees the
same object on both sides. `equals: listEquals` changes what counts as equal, not
this: a mutated list is still the very same list.

`update()` derives the next value from the current one, reading it with
`peek()` — so calling it inside a tracked scope does not subscribe that scope
to the signal it writes:

```dart
count.update((current) => current + 1);
```

`Signal` implements `ValueListenable`, so it plugs into
`ValueListenableBuilder`, `Listenable.merge` and any Flutter API that accepts
a `Listenable` — no adapters.

### Computed

A lazy derived value with automatic dependency tracking. It computes on first
read, caches until a dependency notifies, and rediscovers its dependencies on
every recomputation — conditional reads subscribe to exactly what the last run
read.

```dart
final Computed<List<Chapter>> visible = Computed(
  () => filter(chapters.value, query.value),
  equals: listEquals,
);
```

With `equals`, a recomputation that produces an equal result keeps the
previous object, preserving identity for downstream `==` checks. A dependency
cycle throws a `StateError` on read.

### ReadonlySignal

The read-only supertype of `Signal` and `Computed`. Expose a value as
`ReadonlySignal` to hand consumers reading and listening without writing — the
natural parameter type for a leaf widget:

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

The interface is `abstract final` and the concrete classes are `base`:
implementing them outside dartfier is a compile error, so a `ReadonlySignal`
is always a `Signal` or a `Computed` underneath — never a foreign notifier —
and an `Observer` reading one subscribes. Extending `Signal`/`Computed`
remains possible: the subclass must itself be marked `base`, `final` or
`sealed` (Dart's modifier transitivity), and it inherits the tracked reads. In
tests, the stand-in for a `ReadonlySignal` is a real `Signal`.

### Effect

A reactive side effect. The body runs synchronously on creation and reruns
when any value it read changes. Reruns are coalesced through the microtask
queue: a burst of synchronous writes produces a single rerun reading
consistent state.

The body receives a cleanup registrar — cleanups run in reverse order before
the next rerun and on `dispose()`:

```dart
final Effect ticker = Effect((onCleanup) {
  final Timer timer = Timer.periodic(period.value, onTick);
  onCleanup(timer.cancel);
});

ticker.dispose(); // cancels the last timer
```

That first run is not optional — it is what collects the dependencies, and it
is also what brings the world in sync with the state that is already there: the
timer above exists from the start, not from the first period change. To react
only to a *change*, use [`Watch`](#watch) instead.

### Observer

A widget whose builder runs under tracking:

```dart
Observer((context) => Text('${count.value}'))
```

For heavy static subtrees, `Observer.withChild` builds the child once and
hands it back on every rebuild:

```dart
Observer.withChild(
  builder: (context, child) => Column(
    children: [Text('${count.value}'), child!],
  ),
  child: const HeavyStaticWidget(),
)
```

A foreign `Listenable` — a `FocusNode`, a `ScrollController`, any notifier
that is not a signal — is invisible to tracking. Pass it through `listenables`
and the observer also rebuilds when it notifies, alongside the tracked reads:

```dart
Observer(
  (context) => Text(focusNode.hasFocus ? query.value : ''),
  listenables: [focusNode],
)
```

In debug mode, an `Observer` whose builder tracks nothing and lists no
`listenables` throws a `FlutterError` — such a widget would never rebuild,
which is the silent bug this model is most prone to.

### AsyncSignal

The bridge between the synchronous graph and asynchronous work. An
`AsyncSignal<T>` is a `Signal<AsyncValue<T>>`: it starts `AsyncIdle`, and
`run` executes a fetcher and publishes `AsyncLoading` → `AsyncData` /
`AsyncError`, with latest-wins semantics — starting a new `run` drops the
outcome of any older one still in flight.

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

`AsyncLoading` and `AsyncError` carry the previous data, so a refetch keeps
showing the old content instead of flashing a spinner — `value.valueOrNull` is
the shortcut for "latest usable data". Tracking stays fully synchronous: the
fetcher runs outside the graph and writes its outcome back.

### listen and when

Side effects that care about the *change*, not just the current value.
`listen` calls back with the previous and the next value and returns the
`Effect` behind it — dispose it to unsubscribe:

```dart
final Effect subscription = status.listen((previous, next) {
  analytics.log('status', from: previous, to: next);
});

subscription.dispose();
```

A `listen` is an `Effect` with memory, and that buys the hard parts for free.
Callbacks coalesce per microtask, so a burst of synchronous writes fires once,
carrying the value from before the burst and the value after it; and a
`listen` on a `Computed` never observes the inconsistent mid-diamond state a
raw `addListener` would. The callback does not fire on creation (the first run
only captures the current value), and its reads are untracked, so consulting
other signals inside it subscribes to nothing.

`when` completes a `Future` with the first value that satisfies a condition —
state semantics, not stream semantics: the current value is checked first,
with `peek()`, so an already-satisfied condition completes immediately,
without subscribing to anything.

```dart
final int reached = await progress.when((value) => value >= 5);
```

It is for whoever needs a state but did not put it there. A handler that both
starts the work and awaits it does not need `when` — `await results.run(...)`
says the same thing with fewer moving parts. The gain shows up when the two
are different places:

```dart
final AsyncValue<List<Book>> loaded = await results.when(
  (value) => value is AsyncData<List<Book>>,
);
```

Called from a share button while the screen is already loading, this waits for
the request in flight instead of starting a second one — and returns at once if
the data already arrived. Calling `run` again would do neither: `run` is
latest-wins, so the outcome of the older call would be dropped.

Changes are observed through `listen`, so a synchronous burst completes the
future with the value at the end of the burst. There is no built-in timeout:
while the condition is never satisfied — including after the signal is
disposed — the future never completes, so wrap the call in `Future.timeout`
when that matters.

### Watch

`listen` is scoped to a single signal. `Watch` observes an *expression*: the
tracking function runs under tracking, so it may read as many reactive values
as it needs, and the callback receives the previous and the next result.

```dart
final Watch<(String, bool)> watcher = Watch(
  () => (user.value, premium.value),
  (previous, next) => showBanner(next),
);

watcher.dispose();
```

A record is the idiomatic way to track several values at once: records compare
structurally, so the callback runs when any component changes and stays silent
when the group returns to what it was.

It is an `Effect` underneath, so everything a `listen` buys applies here —
reruns coalesce per microtask, the callback runs untracked, and dependencies
are rediscovered on every run, so a tracking function reading `useLeft.value ?
left.value : right.value` stops depending on `right` while the flag is true.
Results are compared with `==` unless `equals` is given, which a tracking
function returning a collection needs.

The first run only captures the value, so nothing fires on creation. That is
the whole difference from `Effect`: reach for a `Watch` to react to a
*transition*, and for an `Effect` to keep something in sync with the current
state — including on the first run.

### untracked and peek

Escape hatches for reading without subscribing:

```dart
final Effect logger = Effect(
  (_) => log(tracked.value, untracked(() => verbosity.value)),
);

final Computed<int> shifted = Computed(() => doubled.peek() + 1);
```

`untracked(fn)` suspends tracking for a block; `peek()` reads a single
`Signal` or `Computed` without registering a dependency.

### batch

Writes that belong together often pass through a state that is not valid on
its own. Outside a batch every write notifies immediately, so a listener can
observe that half-applied state — swapping two signals lets `BB` escape
between `AB` and `BA`. `batch` makes the group atomic:

```dart
batch(() {
  final String held = first.peek();
  first.value = second.peek();
  second.value = held;
});
```

Listeners are notified once, at the end, with the final value. Reads inside
the block stay current — staleness still propagates per write, so a `Computed`
read mid-batch already reflects the writes made so far; only the notifications
are held back.

The equality guard covers the group, not just each write: a batch that moves a
value and puts it back notifies nobody, because the notification is compared
against the value the signal held when the batch first wrote to it.

```dart
batch(() {
  count.value = 2;
  count.value = 1;
}); // count was already 1 — no notification
```

Because a `Computed` reconciles once per batch instead of once per write, this
is also how a burst of related writes avoids recomputing repeatedly:

```dart
batch(() {
  query.value = '';
  category.value = null;
  inStock.value = false;
});
```

Batches nest — only the outermost flushes — and pending notifications are
still delivered when the body throws.

`batch` is not required: a single write is already atomic, and state that
always changes together belongs in one `Signal` — `filters.value = Filters(…)`
needs no batch at all. Reach for it when independent signals must move as a
unit, or when a burst feeds an expensive `Computed`. It does not help with
writes arriving in separate turns — a scroll position, a stream — since there
is no group to close.

Every member is documented with a runnable example in the
[API reference](https://pub.dev/documentation/dartfier/latest/), grouped into
Core, Widgets, Async and Utilities.

## Semantics

**Staleness first, notifications last.** A write to a `Signal` runs in two
phases. First it marks the reachable graph stale, waking nobody. Only then
does each stale `Computed` that someone listens to resolve itself and notify —
and only if its value actually changed. Consequences:

- **Reads are always consistent.** Any read after any notification recomputes
  against current state — including diamond graphs (A feeds B and C; D reads B
  and C): D notifies once and reads consistently. Nothing recomputes until the
  whole graph is marked, so no value is ever compared against a half-updated
  dependency.
- **A `Computed` that lands on an equal value does not notify.**
  `Computed(() => user.value?.isPremium ?? false)` stays silent when `user`
  changes but `isPremium` doesn't: the widget does not rebuild and dependents
  further down neither recompute nor notify. Custom `equals` decides what
  "equal" means.
- **Laziness survives.** A `Computed` nobody listens to has no notification to
  suppress, so a write does not recompute it — it stays stale until read.
  There is no observed/unobserved mode to opt into and nothing to keep alive.

**Tracking per read.** Each layer subscribes one level down: an `Observer`
reading a `Computed` subscribes to the `Computed`, not to the signals inside
it.

**Notifications run untracked.** Listeners run outside any tracking scope, so
a listener that reads a `Signal` or `Computed` never subscribes whoever
triggered the write — an `Effect` that writes from its body does not inherit
the reads its listeners make.

**A throwing compute does not silence its siblings.** When a `Computed`
function throws while the graph settles, the remaining stale nodes still
reconcile and notify; the first exception then surfaces from the write that
triggered it, and any further one is reported to `FlutterError`. Which
computed happens to be reconciled first never decides who gets notified.

**Effects coalesce per microtask.** The first run is synchronous (on creation,
to collect dependencies). Reruns are scheduled at the end of the microtask
queue, so effects never observe a diamond glitch.

## Rules of use

1. **`Computed` functions and `Effect` bodies are synchronous.** An `await`
   loses the tracking context — reads after it register nothing. The types
   (`T Function()`) already reject `async`; do not work around it with
   `.then`.
2. **Read `.value` in the `Observer` builder body.** Closures that run later —
   a nested `Builder`, a gesture callback — execute outside tracking and do
   not subscribe. The builder must also not *write* to a signal it tracks: the
   framework discards a rebuild marked from inside a build, so the UI would
   silently lag one value behind — in debug, that write throws a
   `FlutterError`.
3. **An `Effect` must not write to a signal it reads.** During the first run
   the write falls into the void (subscriptions attach after the body runs);
   from the first rerun on, every self-write schedules another rerun. A
   self-write that converges in a few steps keeps working, but after 100
   consecutive self-triggered reruns the effect assumes it will never
   stabilize, disposes itself and throws a `StateError` — instead of silently
   starving the event loop.
4. **Dispose is yours.** `Signal`, `Computed` and `Effect` have owners:
   whoever creates them disposes them. Never dispose one from inside a
   listener it is notifying — `ChangeNotifier` asserts against mutating its
   listener list mid-notification. Disposing a *different* node while the
   propagation runs is safe: its pending notification is dropped and its
   reconciliation skipped.
5. **A listener that writes back to what notified it must converge.** Writing
   from a listener is allowed and settles in the same propagation, but if
   every round schedules another one the propagation throws a `StateError`
   after 100 rounds — the same cutoff `Effect` uses, and for the same reason:
   hanging the isolate is the worst failure mode, since it leaves no trace.

## Example app

A demo app lives in [`example/`](https://github.com/edunatalec/dartfier/tree/master/example). It runs in two halves: an API tour,
one page per feature with the guarantees on screen, and four real-world recipes
— a debounced search, a checkout, session events and an action that waits for
its prerequisite — each one showing why it picked that API over the
neighbouring one. Run it with:

```sh
cd example
flutter create .   # generate platform folders the first time
flutter run
```

## Contributing

[CONTRIBUTING.md](https://github.com/edunatalec/dartfier/blob/master/CONTRIBUTING.md) is the contract for whoever writes code here: the one command that has to be green before a pull request, what the two CI jobs check, the conventions, and the deliberate gaps a PR should not try to fix.

## License

MIT — see [LICENSE](https://github.com/edunatalec/dartfier/blob/master/LICENSE).
