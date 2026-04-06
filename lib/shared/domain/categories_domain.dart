// ignore: fcheck_dead_code
import 'package:collection/collection.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:money/data/models/category_types.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/shared/domain/category_domain.dart';
import 'package:money/shared/domain/data_abstract.dart';
import 'package:money/shared/domain/money_objects.dart';
import 'package:money/shared/domain/transactions_domain.dart';
import 'package:money/widgets/pure/mutation_types.dart';

/// Represents categories.
class Categories extends MoneyObjects<Category> {
  Categories() {
    collectionName = SharedDomainStrings.domainString028;
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
      radius: const Radius.circular(SizeForPadding.small),
    ),
    child: Text(AppL10n.tr(AppTranslationKeys.split)),
  );

  /// Add a new Category ensure that the name is unique under the parent or root
  Category addNewCategory({
    final int parentId = -1,
    final String name = SharedDomainStrings.domainString089,
    final CategoryType? type,
    final String color = '',
    final String description = '',
  }) {
    assert(
      name.contains(':') && parentId == -1 || !name.contains(':'),
      SharedDomainStrings.domainString130,
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

    return get(id)?.getColorAndNameWidget() ?? Text(AppL10n.tr(AppTranslationKeys.unknown));
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
      return SharedDomainStrings.domainString008;
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

  /// Gets or creates the SharedDomainStrings.domainString123 income category.
  Category get interestEarned {
    return getOrCreate(SharedDomainStrings.domainString123, CategoryType.income);
  }

  /// Gets or creates the SharedDomainStrings.domainString062 expense category.
  Category get investmentBonds {
    return getOrCreate(SharedDomainStrings.domainString062, CategoryType.expense);
  }

  /// Gets or creates the SharedDomainStrings.domainString063 income category.
  Category get investmentCredit {
    return getOrCreate(SharedDomainStrings.domainString063, CategoryType.income);
  }

  /// Gets or creates the SharedDomainStrings.domainString064 expense category.
  Category get investmentDebit {
    return getOrCreate(SharedDomainStrings.domainString064, CategoryType.expense);
  }

  /// Gets or creates the SharedDomainStrings.domainString065 income category.
  Category get investmentDividends {
    return getOrCreate(SharedDomainStrings.domainString065, CategoryType.income);
  }

  /// Gets or creates the SharedDomainStrings.domainString066 expense category.
  Category get investmentFees {
    return getOrCreate(SharedDomainStrings.domainString066, CategoryType.expense);
  }

  /// Gets or creates the SharedDomainStrings.domainString067 income category.
  Category get investmentInterest {
    return getOrCreate(SharedDomainStrings.domainString067, CategoryType.income);
  }

  /// Gets or creates the SharedDomainStrings.domainString068 income category.
  Category get investmentLongTermCapitalGainsDistribution {
    return getOrCreate(
      SharedDomainStrings.domainString068,
      CategoryType.income,
    );
  }

  /// Gets or creates the SharedDomainStrings.domainString069 expense category.
  Category get investmentMiscellaneous {
    return getOrCreate(SharedDomainStrings.domainString069, CategoryType.expense);
  }

  /// Gets or creates the SharedDomainStrings.domainString070 expense category.
  Category get investmentMutualFunds {
    return getOrCreate(SharedDomainStrings.domainString070, CategoryType.expense);
  }

  /// Gets or creates the SharedDomainStrings.domainString071 expense category.
  Category get investmentOptions {
    return getOrCreate(SharedDomainStrings.domainString071, CategoryType.expense);
  }

  /// Gets or creates the SharedDomainStrings.domainString072 expense category.
  Category get investmentOther {
    return getOrCreate(SharedDomainStrings.domainString072, CategoryType.expense);
  }

  /// Gets or creates the SharedDomainStrings.domainString073 category.
  Category get investmentReinvest {
    return getOrCreate(SharedDomainStrings.domainString073, CategoryType.none);
  }

  /// Gets or creates the SharedDomainStrings.domainString074 income category.
  Category get investmentShortTermCapitalGainsDistribution {
    return getOrCreate(
      SharedDomainStrings.domainString074,
      CategoryType.income,
    );
  }

  /// Gets or creates the SharedDomainStrings.domainString075 expense category.
  Category get investmentStocks {
    return getOrCreate(SharedDomainStrings.domainString075, CategoryType.expense);
  }

  /// Gets or creates the SharedDomainStrings.domainString076 category.
  Category get investmentTransfer {
    return getOrCreate(SharedDomainStrings.domainString076, CategoryType.none);
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

  /// Gets or creates the SharedDomainStrings.domainString139 expense category.
  Category get salesTax {
    return getOrCreate(SharedDomainStrings.domainString139, CategoryType.expense);
  }

  /// Gets or creates the SharedDomainStrings.domainString122 income category.
  Category get savings {
    return getOrCreate(SharedDomainStrings.domainString122, CategoryType.income);
  }

  /// Gets or creates the special SharedDomainStrings.domainString126 category (cached).
  Category get split {
    // ignore: prefer_conditional_assignment
    if (_split == null) {
      _split = getOrCreate(SharedDomainStrings.domainString126, CategoryType.none);
    }
    return _split!;
  }

  /// Returns the unique ID of the special SharedDomainStrings.domainString126 category.
  int splitCategoryId() {
    return split.uniqueId;
  }

  /// Gets or creates the special SharedDomainStrings.domainString144 category.
  Category get transfer {
    return getOrCreate(SharedDomainStrings.domainString144, CategoryType.none);
  }

  /// Returns the unique ID of the special SharedDomainStrings.domainString144 category.
  int transferCategoryId() {
    return transfer.uniqueId;
  }

  /// Gets or creates the SharedDomainStrings.domainString154 category.
  Category get transferFromDeletedAccount {
    return getOrCreate(SharedDomainStrings.domainString154, CategoryType.none);
  }

  /// Gets or creates the SharedDomainStrings.domainString155 category.
  Category get transferToDeletedAccount {
    return getOrCreate(SharedDomainStrings.domainString155, CategoryType.none);
  }

  /// Gets or creates the SharedDomainStrings.domainString147 category.
  Category get unassignedSplit {
    return getOrCreate(SharedDomainStrings.domainString147, CategoryType.none);
  }

  /// Gets or creates the SharedDomainStrings.domainString150 category.
  Category get unknown {
    return getOrCreate(SharedDomainStrings.domainString150, CategoryType.none);
  }
}
