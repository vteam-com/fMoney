import 'package:money/core/helpers/misc_helpers.dart';

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
  static CategoryType fromInt(final int index) {
    if (isBetween(index, -1, CategoryType.values.length)) {
      return CategoryType.values[index];
    }
    return CategoryType.none;
  }

  static CategoryType fromName(final String categoryTypeName) {
    switch (categoryTypeName.toLowerCase()) {
      case 'income':
        return CategoryType.income;
      case 'expense':
        return CategoryType.expense;
      case 'recurringexpense':
      case 'expenserecurring':
        return CategoryType.recurringExpense;
      case 'saving':
        return CategoryType.saving;
      case 'reserved':
        return CategoryType.reserved;
      case 'transfer':
        return CategoryType.transfer;
      case 'investment':
        return CategoryType.investment;
      default:
        return CategoryType.none;
    }
  }

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

  String asString() {
    switch (this) {
      case CategoryType.income:
        return 'Income';
      case CategoryType.expense:
        return 'Expense';
      case CategoryType.recurringExpense:
        return 'ExpenseRecurring';
      case CategoryType.saving:
        return 'Saving';
      case CategoryType.reserved:
        return 'Reserved';
      case CategoryType.transfer:
        return 'Transfer';
      case CategoryType.investment:
        return 'Investment';
      case CategoryType.none:
        return 'None';
    }
  }
}
