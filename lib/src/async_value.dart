/// The state of an asynchronous operation exposed as a synchronous value.
///
/// Pattern-match the three cases with a `switch`:
///
/// ```dart
/// switch (results.value) {
///   AsyncLoading(:final previous?) => ListView(previous),
///   AsyncLoading() => const Spinner(),
///   AsyncData(:final value) => ListView(value),
///   AsyncError(:final error) => ErrorView(error),
/// }
/// ```
///
/// [AsyncLoading] and [AsyncError] carry the previous data through reloads,
/// so UIs can keep showing the old value instead of flashing a spinner.
sealed class AsyncValue<T> {
  const AsyncValue();

  /// The most recent usable data: the current value when loaded, or the
  /// previous one carried through loading and error states. `null` when no
  /// data was ever produced.
  T? get valueOrNull => switch (this) {
    AsyncData<T>(:final T value) => value,
    AsyncLoading<T>(:final T? previous) => previous,
    AsyncError<T>(:final T? previous) => previous,
  };

  /// Whether the operation is currently in flight.
  bool get isLoading => this is AsyncLoading<T>;
}

/// Operation in flight, optionally carrying the [previous] data.
final class AsyncLoading<T> extends AsyncValue<T> {
  /// Creates a loading state carrying the [previous] data, if any.
  const AsyncLoading({this.previous});

  /// Data from before this reload, kept so UIs can avoid a spinner flash.
  final T? previous;

  @override
  bool operator ==(Object other) =>
      other is AsyncLoading<T> && other.previous == previous;

  @override
  int get hashCode => Object.hash(AsyncLoading, T, previous);
}

/// Operation completed with [value].
final class AsyncData<T> extends AsyncValue<T> {
  /// Creates a data state holding [value].
  const AsyncData(this.value);

  /// The produced data.
  final T value;

  @override
  bool operator ==(Object other) =>
      other is AsyncData<T> && other.value == value;

  @override
  int get hashCode => Object.hash(AsyncData, T, value);
}

/// Operation failed with [error], optionally carrying the [previous] data.
///
/// Equality compares [error] and [previous]; [stackTrace] is excluded.
final class AsyncError<T> extends AsyncValue<T> {
  /// Creates an error state holding [error].
  const AsyncError(this.error, {this.stackTrace, this.previous});

  /// The thrown error.
  final Object error;

  /// The stack trace captured with [error], when available.
  final StackTrace? stackTrace;

  /// Data from before this failure, kept so UIs can avoid losing content.
  final T? previous;

  @override
  bool operator ==(Object other) =>
      other is AsyncError<T> &&
      other.error == error &&
      other.previous == previous;

  @override
  int get hashCode => Object.hash(AsyncError, T, error, previous);
}
