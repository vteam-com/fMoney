/// Interface for objects that can be merged (like transactions with payee and category IDs)
abstract class MergeableItem {
  /// Gets the payee ID associated with this item.
  int get payeeId;

  /// Sets the payee ID associated with this item.
  set payeeId(int value);

  /// Gets the category ID associated with this item.
  int get categoryId;

  /// Sets the category ID associated with this item.
  set categoryId(int value);
}
