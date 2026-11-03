import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/shared_strings_helper.dart';

enum CategoryType {
  none, // 0
  income, // 1
  expense, // 2
  saving, // 3
  reserved, // 4 this is not used (but hard to delete because of database).
  transfer, // 5 special category only used by pie charts
  investment, // 6 so you can separate out investment income and expenditures.
  recurringExpense, // 7 so you can clearly mark bills that are repeatable.
}

/// Display label of each category type, in picker order; the single source for
/// [CategoryTypeExtension.asString] and [CategoryTypeExtension.valuesInDisplayOrder].
const Map<CategoryType, String> _categoryTypeLabels = <CategoryType, String>{
  CategoryType.income: SharedStrings.categoryTypeIncomeLabel,
  CategoryType.expense: SharedStrings.categoryTypeExpenseLabel,
  CategoryType.recurringExpense: SharedStrings.categoryTypeExpenseRecurringLabel,
  CategoryType.saving: SharedStrings.categoryTypeSavingLabel,
  CategoryType.reserved: SharedStrings.categoryTypeReservedLabel,
  CategoryType.transfer: SharedStrings.categoryTypeTransferLabel,
  CategoryType.investment: SharedStrings.categoryTypeInvestmentLabel,
  CategoryType.none: SharedStrings.categoryTypeNoneLabel,
};

extension CategoryTypeExtension on CategoryType {
  /// Returns CategoryType from integer index, with bounds checking.
  static CategoryType fromInt(int index) {
    if (isBetween(index, -1, CategoryType.values.length)) {
      return CategoryType.values[index];
    }
    return CategoryType.none;
  }

  /// Category types in the order they are offered to the user.
  static List<CategoryType> get valuesInDisplayOrder => _categoryTypeLabels.keys.toList();

  /// Returns the category type as a formatted string.
  String asString() => _categoryTypeLabels[this]!;
}
