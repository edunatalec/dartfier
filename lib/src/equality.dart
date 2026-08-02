/// Compares [previous] and [next] with [equals], falling back to `==`.
///
/// The write guard of a `Signal`, the recomputation guard of a `Computed` and
/// the change guard of a `Watch` all ask the same question, and a custom
/// comparator is optional in each of them.
bool isEqual<T>(
  T previous,
  T next, {
  bool Function(T previous, T next)? equals,
}) => equals != null ? equals(previous, next) : previous == next;
