import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/shared_strings.dart';

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

extension CategoryTypeExtension on CategoryType {
  /// Returns CategoryType from integer index, with bounds checking.
  static CategoryType fromInt(final int index) {
    if (isBetween(index, -1, CategoryType.values.length)) {
      return CategoryType.values[index];
    }
    return CategoryType.none;
  }

  /// Returns CategoryType from string name, case-insensitive.
  static CategoryType fromName(final String categoryTypeName) {
    switch (categoryTypeName.toLowerCase()) {
      case SharedStrings.categoryTypeIncomeToken:
        return CategoryType.income;
      case SharedStrings.categoryTypeExpenseToken:
        return CategoryType.expense;
      case SharedStrings.categoryTypeRecurringExpenseToken:
      case SharedStrings.categoryTypeExpenseRecurringToken:
        return CategoryType.recurringExpense;
      case SharedStrings.categoryTypeSavingToken:
        return CategoryType.saving;
      case SharedStrings.categoryTypeReservedToken:
        return CategoryType.reserved;
      case SharedStrings.categoryTypeTransferToken:
        return CategoryType.transfer;
      case SharedStrings.categoryTypeInvestmentToken:
        return CategoryType.investment;
      default:
        return CategoryType.none;
    }
  }

  /// Returns list of all category type names as strings.
  static List<String> getNames() {
    return <String>[
      CategoryType.income.asString(),
      CategoryType.expense.asString(),
      CategoryType.recurringExpense.asString(),
      CategoryType.saving.asString(),
      CategoryType.reserved.asString(),
      CategoryType.transfer.asString(),
      CategoryType.investment.asString(),
      CategoryType.none.asString(),
    ];
  }

  /// Returns the category type as a formatted string.
  String asString() {
    switch (this) {
      case CategoryType.income:
        return SharedStrings.categoryTypeIncomeLabel;
      case CategoryType.expense:
        return SharedStrings.categoryTypeExpenseLabel;
      case CategoryType.recurringExpense:
        return SharedStrings.categoryTypeExpenseRecurringLabel;
      case CategoryType.saving:
        return SharedStrings.categoryTypeSavingLabel;
      case CategoryType.reserved:
        return SharedStrings.categoryTypeReservedLabel;
      case CategoryType.transfer:
        return SharedStrings.categoryTypeTransferLabel;
      case CategoryType.investment:
        return SharedStrings.categoryTypeInvestmentLabel;
      case CategoryType.none:
        return SharedStrings.categoryTypeNoneLabel;
    }
  }
}
