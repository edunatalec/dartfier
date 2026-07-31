Asynchronous work exposed as synchronous reactive state.

`AsyncSignal` runs a fetcher and publishes the outcome as an `AsyncValue`:
idle, loading, data or error. Loading and error states carry the previous data,
so a refetch keeps showing content instead of flashing a spinner, and a new run
drops the outcome of any older one still in flight.

Tracking stays fully synchronous — the fetcher runs outside the graph and
writes its result back.
