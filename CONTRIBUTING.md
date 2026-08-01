# Contributing

Thanks for taking the time. This document is the contract for whoever writes code here —
the `README.md` is the contract for whoever uses `dartfier`.

## Before you open a PR

One command has to be green:

```bash
./scripts/verify.sh
```

It is the same script the release runs, minus tag, push and publish: dependencies, README
version pin, the CHANGELOG entry, analyze (package and example), tests, the examples
inside the `///` docs, `dart doc` with zero warnings, the publish dry-run, and a pana
score of 160/160. If it passes locally it passes in CI, because CI runs that file and
nothing else.

It needs network (it asks pub.dev which pana version to use) and a Flutter at or above the
floor declared in `pubspec.yaml`. Running it changes your globally activated pana version —
pub.dev always scores with the newest one, so the script installs exactly that.

## What CI checks

Two jobs, both on every pull request:

- **Verify** — `./scripts/verify.sh` on the current stable Flutter.
- **Floor** — analyze and test on the **lowest** Flutter `dartfier` supports, read straight
  from `pubspec.yaml`. It exists because nothing else catches it: the Flutter framework
  carries no `@Since` annotations, so an API added after the floor looks perfectly valid to
  an analyzer running on a newer SDK, and only breaks for the users we promised to support.

## Conventions

- **No `//` comments.** A fact that needs recording goes in the commit message, in the
  README, or in a test. Analyzer directives (`// ignore:`) are not comments and may stay.
- **`///` dartdoc is mandatory on every public member**, in English, with a runnable example.
  `public_member_api_docs` is enforced, and `scripts/verify_doc_examples.sh` compiles every
  ```dart fence found in `lib/`.
- **The semantic contract is pinned by tests, not by prose.** Diamond consistency,
  conditional retracking, cycle detection, dispose semantics, cleanup order — a behavior
  change without its test change is wrong.
- **The tracking core (`lib/src/tracker.dart`) is internal** and never exported from the
  barrel.
- **A public-API change updates README, CHANGELOG and `example/lib/` in the same commit.**
  A new public API earns a page under `example/lib/pages/`, wired into the `main.dart` menu.
- **Commits are conventional and lowercase**: `feat:`, `fix:`, `chore:`, `docs:`. No body,
  no co-author trailers.

## Deliberate gaps

These are absent by decision, not by omission — a PR adding one will be declined.

- **Observable collections.** The unit of reactivity here is a *value*, and notification
  comes from comparing it. A mutated list is the same object, so an `ObservableList` would
  have to bypass the equality guard that every other behavior rests on. MobX can do it
  because it observes the *operation* instead (`reportChanged()` on every mutating method),
  which costs a wrapper type reimplementing the whole `List` interface. Taking that road
  would also break the promise that a `ValueNotifier` codebase migrates one variable at a
  time: the two would stop behaving alike.
- **`context.watch()`.** Subscribing an `Element` from a getter means holding a reference to
  it, and an unmounted `Element` keeps its whole subtree alive. The alternatives — retaining
  until the next notification, or weak references plus finalizers — are at odds with a core
  meant to be read in one sitting. `Observer` does the same job, one widget away.
- **Async `Computed`.** Tracking is a static scope swapped around a synchronous call
  (`Tracker.collect`). An `await` returns to the event loop, the scope is already restored,
  and every read after it registers nothing — silently. `AsyncSignal` is the supported door:
  the fetcher runs outside the graph and writes its outcome back.
- **`debounce`/`throttle`.** Timing policy is not one thing (cancel or flush? leading or
  trailing? cancel on dispose?) and the right answer depends on the effect. `Effect` plus
  `onCleanup(timer.cancel)` expresses it in three lines, with cancellation already correct.
- **An event primitive.** A signal holds state — always current, always observable — while an
  event is a sequence in time where two identical payloads are two events. The equality guard
  would swallow the second. For command semantics, opt out: `Signal<String>('', equals: (_, _) => false)`.
  For real event sequences, `Stream` is still the right tool.
- **`select()`.** `Computed(() => user.value.name)` already is the select: lazy, notifies only
  its readers, and rediscovers its dependencies on every run. A dedicated API would be the
  same object under a narrower name. Solidart shipped one and removed it.

## Releasing

Releases are cut by the maintainer, from `master`, with `./scripts/release.sh`. It refuses
to run outside `master` or with a dirty working tree — `pub publish` packs the files on
disk, not the commit — then runs the full `verify.sh` before tagging. Nothing publishes
from CI.
