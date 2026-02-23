// ignore: fcheck_dead_code
import 'package:collection/collection.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/views/money_objects.dart';
import 'package:money/views/providers/category.dart';
import 'package:money/views/providers/data_abstract.dart';
import 'package:money/views/transactions.dart';
import 'package:money/widgets/pure/mutation_types.dart';

/// Represents categories.
class Categories extends MoneyObjects<Category> {
  Categories() {
    collectionName = 'Categories';
  }
  late DataAbstract data;

  Category? _split;

  @override
  Category instanceFromJson(final MyJson json) {
    return Category.fromJson(json, data);
  }

  @override
  void onAllDataLoaded() {
    // reset to zero all counters and sums
    for (final Category category in iterableList()) {
      category.fieldTransactionCount.value = 0;
      category.fieldSum.value.setAmount(0);

      category.fieldTransactionCountRollup.value = 0;
      category.fieldSumRollup.value.setAmount(0);
    }

    // first tally the direct category transactions
    for (final Transaction t in data.getTransactions().cast<Transaction>()) {
      final Category? item = get(t.fieldCategoryId.value);
      if (item != null) {
        item.fieldTransactionCount.value++;
        item.fieldSum.value += t.fieldAmount.value.asDouble();
        item.fieldTransactionCountRollup.value++;
        item.fieldSumRollup.value += t.fieldAmount.value.asDouble();

        final List<Category> ancestors = <Category>[];
        item.getAncestors(ancestors);
        for (final Category ancestorCategory in ancestors) {
          ancestorCategory.fieldTransactionCountRollup.value++;
          ancestorCategory.fieldSumRollup.value += t.fieldAmount.value;
        }
      }
    }
  }

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }

  static Widget categoryWidgetForSplit = DottedBorder(
    options: RoundedRectDottedBorderOptions(
      color: Colors.grey.shade600,
      padding: const EdgeInsets.symmetric(horizontal: SizeForPadding.medium),
      radius: const Radius.circular(3),
    ),
    child: const Text('Split'),
  );

  /// Add a new Category ensure that the name is unique under the parent or root
  Category addNewCategory({
    final int parentId = -1,
    final String name = 'New Category',
    final CategoryType? type,
    final String color = '',
    final String description = '',
  }) {
    assert(
      name.contains(':') && parentId == -1 || !name.contains(':'),
      'Supply a parent ID or hierarchy names but not both',
    );

    final dynamic parent = data.getCategory(parentId);

    if (parent == null && name.contains(':')) {
      return ensureAncestorExist(name: name, overrideTypeOfParent: type);
    }

    // find next available name
    final String prefixName = parent == null ? name : '${parent.fieldName.value}:$name';
    String nextAvailableName = prefixName;
    int next = 1;
    while (getByName(nextAvailableName) != null) {
      // already taken
      nextAvailableName = '$name $next';
      // the the next one
      next++;
    }

    CategoryType typeToUse = type ?? CategoryType.none;

    if (type == null && parent != null) {
      typeToUse = (parent as dynamic).fieldType.value as CategoryType;
    }

    // add a new Category
    final Category category = Category(
      id: -1,
      parentId: parentId,
      name: nextAvailableName,
      type: typeToUse,
      color: color,
      description: description,
    );

    data.appendNewCategory(category);

    return category;
  }

  /// Appends a new category with required fields; optionally fires notification.
  Category appendNewCategory({
    required int parentId,
    required String name,
    required final CategoryType type,
    bool fireNotification = false,
  }) {
    final Category category = Category(
      id: -1,
      parentId: parentId,
      name: name,
      type: type,
    );

    appendNewMoneyObject(category, fireNotification: fireNotification);
    return category;
  }

  /// Ensures ancestor categories exist for a colon-separated [name]; creates missing ones.
  Category ensureAncestorExist({
    required final String name,
    final CategoryType? overrideTypeOfParent,
  }) {
    final List<String> categoryNameParts = name.split(':');

    int parentCategoryId = -1;
    String cumulativeCategoryName = '';

    for (final String part in categoryNameParts) {
      cumulativeCategoryName = cumulativeCategoryName.isEmpty ? part : '$cumulativeCategoryName:$part';

      CategoryType typeToUse = CategoryType.none;
      if (overrideTypeOfParent == null) {
        if (parentCategoryId != -1) {
          // try to get the parent type
          typeToUse = get(parentCategoryId)!.fieldType.value;
        }
      } else {
        typeToUse = overrideTypeOfParent;
      }
      Category? category = getByName(cumulativeCategoryName);
      category ??= appendNewCategory(
        parentId: parentCategoryId,
        name: cumulativeCategoryName,
        type: typeToUse,
      );
      parentCategoryId = category.uniqueId;
    }
    return getByName(name)!;
  }

  /// Returns all expense categories.
  List<Category> getAllExpenseCategories() {
    return iterableList().where((Category category) => category.isExpense).toList();
  }

  /// Returns all income categories.
  List<Category> getAllIncomeCategories() {
    return iterableList().where((Category category) => category.isIncome).toList();
  }

  /// Finds a category by exact name.
  Category? getByName(final String name) {
    return iterableList().firstWhereOrNull(
      (final Category category) => category.fieldName.value == name,
    );
  }

  /// Returns the ID for a category by name; -1 if not found.
  int? getIdByName(final String name) {
    final Category? found = iterableList().firstWhereOrNull(
      (final Category category) => category.fieldName.value == name,
    );
    return found?.uniqueId ?? -1;
  }

  /// Returns all category names as strings.
  List<String> getCategoriesAsStrings() {
    return this.getListSorted().map((Category element) => element.fieldName.value).toList();
  }

  /// Returns direct child categories of the given [parentId].
  List<Category> getCategoriesWithThisParent(final int parentId) {
    final List<Category> list = <Category>[];
    for (final Category item in iterableList()) {
      if (item.fieldParentId.value == parentId) {
        list.add(item);
      }
    }
    return list;
  }

  /// Returns a widget representing the category for the given [id].
  Widget getCategoryWidget(final int id) {
    if (id == -1) {
      return const Text('?');
    }

    if (id == splitCategoryId()) {
      return categoryWidgetForSplit;
    }

    return get(id)?.getColorAndNameWidget() ?? const Text('Unknown');
  }

  /// Returns a sorted list of all categories by name.
  List<Category> getListSorted() {
    final List<Category> list = iterableList().toList();
    list.sort(
      (Category a, Category b) => sortByString(a.fieldName.value, b.fieldName.value, true),
    );
    return list;
  }

  /// Gets the category name for the given [id]; handles special cases.
  String getNameFromId(final int id) {
    if (id == -1) {
      return '';
    }

    if (id == splitCategoryId()) {
      return '<Split>';
    }
    return Category.getName(get(id));
  }

  /// Gets or creates a category by [name] and [type]; restores if deleted.
  Category getOrCreate(final String name, final CategoryType type) {
    Category? category = getByName(name);

    if (category == null) {
      category = ensureAncestorExist(name: name, overrideTypeOfParent: type);
    } else {
      if (category.isDeleted) {
        category.mutation = MutationType.none; // Bring it back to life
      }
    }

    return category;
  }

  /// Walks up the hierarchy to return the top-level ancestor category.
  Category getTopAncestor(final Category category) {
    if (category.fieldParentId.value == -1) {
      return category; // this is the top
    }
    final Category? parent = get(category.fieldParentId.value);
    if (parent == null) {
      return category;
    }
    return getTopAncestor(parent);
  }

  /// Returns all descendant IDs in the tree starting from [rootIdToStartFrom].
  List<int> getTreeIds(final int rootIdToStartFrom) {
    final List<int> list = <int>[];
    if (rootIdToStartFrom > 0) {
      getTreeIdsRecursive(rootIdToStartFrom, list);
    }
    return list;
  }

  /// Recursive helper to collect descendant category IDs.
  void getTreeIdsRecursive(final int categoryId, final List<int> list) {
    if (categoryId > 0) {
      list.add(categoryId);
      final List<Category> descendants = getCategoriesWithThisParent(
        categoryId,
      );
      for (final Category c in descendants) {
        getTreeIdsRecursive(c.fieldId.value, list);
      }
    }
  }

  /// Gets or creates the 'Savings:Interest' income category.
  Category get interestEarned {
    return getOrCreate('Savings:Interest', CategoryType.income);
  }

  /// Gets or creates the 'Investments:Bonds' expense category.
  Category get investmentBonds {
    return getOrCreate('Investments:Bonds', CategoryType.expense);
  }

  /// Gets or creates the 'Investments:Credit' income category.
  Category get investmentCredit {
    return getOrCreate('Investments:Credit', CategoryType.income);
  }

  /// Gets or creates the 'Investments:Debit' expense category.
  Category get investmentDebit {
    return getOrCreate('Investments:Debit', CategoryType.expense);
  }

  /// Gets or creates the 'Investments:Dividends' income category.
  Category get investmentDividends {
    return getOrCreate('Investments:Dividends', CategoryType.income);
  }

  /// Gets or creates the 'Investments:Fees' expense category.
  Category get investmentFees {
    return getOrCreate('Investments:Fees', CategoryType.expense);
  }

  /// Gets or creates the 'Investments:Interest' income category.
  Category get investmentInterest {
    return getOrCreate('Investments:Interest', CategoryType.income);
  }

  /// Gets or creates the 'Investments:Long Term Capital Gains Distribution' income category.
  Category get investmentLongTermCapitalGainsDistribution {
    return getOrCreate(
      'Investments:Long Term Capital Gains Distribution',
      CategoryType.income,
    );
  }

  /// Gets or creates the 'Investments:Miscellaneous' expense category.
  Category get investmentMiscellaneous {
    return getOrCreate('Investments:Miscellaneous', CategoryType.expense);
  }

  /// Gets or creates the 'Investments:Mutual Funds' expense category.
  Category get investmentMutualFunds {
    return getOrCreate('Investments:Mutual Funds', CategoryType.expense);
  }

  /// Gets or creates the 'Investments:Options' expense category.
  Category get investmentOptions {
    return getOrCreate('Investments:Options', CategoryType.expense);
  }

  /// Gets or creates the 'Investments:Other' expense category.
  Category get investmentOther {
    return getOrCreate('Investments:Other', CategoryType.expense);
  }

  /// Gets or creates the 'Investments:Reinvest' category.
  Category get investmentReinvest {
    return getOrCreate('Investments:Reinvest', CategoryType.none);
  }

  /// Gets or creates the 'Investments:Short Term Capital Gains Distribution' income category.
  Category get investmentShortTermCapitalGainsDistribution {
    return getOrCreate(
      'Investments:Short Term Capital Gains Distribution',
      CategoryType.income,
    );
  }

  /// Gets or creates the 'Investments:Stocks' expense category.
  Category get investmentStocks {
    return getOrCreate('Investments:Stocks', CategoryType.expense);
  }

  /// Gets or creates the 'Investments:Transfer' category.
  Category get investmentTransfer {
    return getOrCreate('Investments:Transfer', CategoryType.none);
  }

  /// Returns `true` if the category with [categoryId] is an expense category.
  bool isCategoryAnExpense(final int categoryId) => get(categoryId)?.isExpense ?? false;

  /// Returns `true` if the category with [categoryId] is an income category.
  bool isCategoryAnIncome(final int categoryId) => get(categoryId)?.isIncome ?? false;

  /// Moves [categoryToReparent] under [newParentCategory] and updates descendants' names.
  void reparentCategory(
    final Category categoryToReparent,
    final Category newParentCategory,
  ) {
    categoryToReparent.stashValueBeforeEditing();
    categoryToReparent.fieldParentId.value = newParentCategory.uniqueId;

    final List<int> descendants = getTreeIds(categoryToReparent.uniqueId);
    for (final int id in descendants) {
      final Category? category = get(id);
      if (category != null) {
        category.updateNameBaseOnParent();
      }
    }

    this.data.updateAll();
  }

  /// Gets or creates the 'Taxes:Sales Tax' expense category.
  Category get salesTax {
    return getOrCreate('Taxes:Sales Tax', CategoryType.expense);
  }

  /// Gets or creates the 'Savings' income category.
  Category get savings {
    return getOrCreate('Savings', CategoryType.income);
  }

  /// Gets or creates the special 'Split' category (cached).
  Category get split {
    // ignore: prefer_conditional_assignment
    if (_split == null) {
      _split = getOrCreate('Split', CategoryType.none);
    }
    return _split!;
  }

  /// Returns the unique ID of the special 'Split' category.
  int splitCategoryId() {
    return split.uniqueId;
  }

  /// Gets or creates the special 'Transfer' category.
  Category get transfer {
    return getOrCreate('Transfer', CategoryType.none);
  }

  /// Returns the unique ID of the special 'Transfer' category.
  int transferCategoryId() {
    return transfer.uniqueId;
  }

  /// Gets or creates the 'Xfer from Deleted Account' category.
  Category get transferFromDeletedAccount {
    return getOrCreate('Xfer from Deleted Account', CategoryType.none);
  }

  /// Gets or creates the 'Xfer to Deleted Account' category.
  Category get transferToDeletedAccount {
    return getOrCreate('Xfer to Deleted Account', CategoryType.none);
  }

  /// Gets or creates the 'UnassignedSplit' category.
  Category get unassignedSplit {
    return getOrCreate('UnassignedSplit', CategoryType.none);
  }

  /// Gets or creates the 'Unknown' category.
  Category get unknown {
    return getOrCreate('Unknown', CategoryType.none);
  }
}
