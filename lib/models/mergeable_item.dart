/// Interface for objects that can be merged (like transactions with payee and category IDs)
abstract class MergeableItem {
  int get payeeId;
  set payeeId(int value);
  int get categoryId;
  set categoryId(int value);
}
