The reactive values themselves.

`Signal` holds a value you write. `Computed` derives one from other reactive
values, lazily and with automatic dependency tracking. `ReadonlySignal` is the
read-only supertype both implement — the type to expose when a consumer should
read and listen, but never write.

All three are `ChangeNotifier`s implementing `ValueListenable`, so they plug
into `ValueListenableBuilder`, `Listenable.merge` and any Flutter API that
accepts a `Listenable`.
