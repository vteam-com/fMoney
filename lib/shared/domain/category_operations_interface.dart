import 'package:money/data/models/data_object_model.dart';

/// Category lookups and maintenance.
abstract class CategoryOperations {
  /// Returns the name of a category by ID.
  String getCategoryNameFromId(int id);

  /// Returns a category by ID.
  DataObject? getCategory(int id);

  /// Returns all categories as strings.
  List<String> getCategoriesAsStrings();

  /// Returns a category ID from its name.
  int? getCategoryIdFromName(String name);

  /// Returns true if the category is an expense type.
  bool isCategoryExpense(int id);

  /// Returns true if the category is an income type.
  bool isCategoryIncome(int id);

  /// Returns all category tree IDs.
  List<int> getCategoryTreeIds(int categoryId);

  /// Returns the parent of [category], its grandparent and so on up to the top-level category.
  List<DataObject> getCategoryAncestors(DataObject category);

  /// Appends a new category.
  void appendNewCategory(DataObject category);

  /// Returns the split category ID.
  int getSplitCategoryId();

  /// Returns how many of [payeeId]'s non-transfer transactions use each category, most used first.
  Map<int, int> getCategoryCountsForPayee(int payeeId);
}
