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

  /// Returns the transfer category.
  DataObject getTransferCategory();

  /// Returns the split category.
  DataObject getSplitCategory();

  /// Returns all category tree IDs.
  List<int> getCategoryTreeIds(int categoryId);

  /// Appends a new category.
  void appendNewCategory(DataObject category);

  /// Returns the split category ID.
  int getSplitCategoryId();

  /// Returns the transfer category ID.
  int getTransferCategoryId();

  /// Deletes a category.
  void deleteCategory(DataObject category);

  /// Returns all categories.
  List<DataObject> getCategories({bool includeDeleted = false});
}
