Side effects, escape hatches and write grouping.

`Effect` runs a body under tracking and reruns it when what it read changes,
coalescing a burst of writes into a single rerun and registering cleanups.
`listen` and `when` build on it for callbacks that need the previous value or a
future that completes on a condition, and `Watch` does the same for a tracked
expression instead of a single signal — silent on creation, so it reacts to the
transition rather than to the state that was already there.

`untracked` and `peek` read without subscribing. `batch` groups several writes
so listeners see one notification with the final state, never the half-applied
one in between.
