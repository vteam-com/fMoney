/// Represents the different types of mutations that can occur on a money object.
///
/// - `none`: No mutation has occurred.
/// - `changed`: The money object has been changed.
/// - `inserted`: A new money object has been inserted.
/// - `deleted`: A money object has been deleted.
/// - `reloaded`: The money object has been reloaded.
/// - `rebalanced`: The money object has been rebalanced.
/// - `childChanged`: A child of the money object has changed.
/// - `transientChanged`: A transient property of the money object has changed.
enum MutationType {
  none,
  changed,
  inserted,
  deleted,
  reloaded,
  rebalanced,
  childChanged,
  transientChanged,
}
