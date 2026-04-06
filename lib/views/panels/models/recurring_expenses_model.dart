import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/data/models/ranges_model.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';

/// Represents recurring expenses.
class RecurringExpenses {
  RecurringExpenses({
    required this.category,
    required this.sumOfAllTransactions,
    this.sumPerMonth = 0,
    this.sumIncome = 0,
    this.sumExpense = 0,
    this.sumBudget = 0,
    this.dates,
  });

  final Category category;
  final double sumOfAllTransactions;

  double sumBudget = 0;
  double sumExpense = 0;
  double sumIncome = 0;
  double sumPerMonth = 0;

  DateRange? dates = DateRange();

  /// Returns budgeted recurring expenses for the specified year range.
  static List<RecurringExpenses> getBudgetedTransactions(
    final int minYear,
    final int maxYear,
    final bool onlyNonZeroBudget,
    final List<CategoryType> categoryTypes,
    final double multiplier,
  ) {
    if (multiplier == 0) {
      // Reserved for future budget scaling.
    }
    final List<RecurringExpenses> items = <RecurringExpenses>[];

    final Iterable<Category> recurringCategories = Data().categories.iterableList().where((Category c) {
      if (!categoryTypes.contains(c.fieldType.value)) {
        return false;
      }
      if (onlyNonZeroBudget && c.fieldBudget.value.asDouble() == 0) {
        return false;
      }
      return true;
    });

    for (final Category category in recurringCategories) {
      final List<Category> listOfDescendants = <Category>[
        category,
      ]; // include this Category

      category.getDescendants(listOfDescendants);

      // get all transactions meeting the request of date and type
      bool whereClause(Transaction t) {
        return listOfDescendants.contains(t.category) &&
            isBetweenOrEqual(t.fieldDateTime.value!.year, minYear, maxYear);
      }

      final List<Transaction> flatTransactions = Data().transactions.getListFlattenSplits(whereClause: whereClause);

      double totalForAllTimeForThisCategory = 0;
      final DateRange dateRangeOfTransactions = DateRange();

      for (final Transaction transaction in flatTransactions) {
        totalForAllTimeForThisCategory += transaction.fieldAmount.value.asDouble();
        dateRangeOfTransactions.inflate(transaction.fieldDateTime.value);
      }

      final double sumByMonthForTheCategory = totalForAllTimeForThisCategory / dateRangeOfTransactions.durationInMonths;

      final RecurringExpenses item = RecurringExpenses(
        category: category,
        sumOfAllTransactions: totalForAllTimeForThisCategory,
        sumPerMonth: sumByMonthForTheCategory,
        sumBudget: 0,
      );
      item.dates = dateRangeOfTransactions;

      items.add(item);
    }

    items.sort(
      (RecurringExpenses a, RecurringExpenses b) => a.sumOfAllTransactions.compareTo(b.sumOfAllTransactions),
    );
    return items;
  }

  /// Returns a map of yearly income/expense sums across all categories.
  static Map<int, RecurringExpenses> getSumByIncomeExpenseByYears(
    int minYear,
    int maxYear,
    bool includeAssetAccounts,
    double multiplier,
  ) {
    final Map<int, RecurringExpenses> yearMap = <int, RecurringExpenses>{};

    final List<Transaction> flatTransactions = Data().transactions.getListFlattenSplits(
      whereClause: (Transaction t) =>
          t.category != null &&
          isBetweenOrEqual(
            t.fieldDateTime.value!.year,
            minYear,
            maxYear,
          ) &&
          (includeAssetAccounts || !t.isAssetAccount),
    );

    for (final Transaction t in flatTransactions) {
      if (t.category != null) {
        final int year = t.fieldDateTime.value!.year;
        if (!yearMap.containsKey(year)) {
          yearMap[year] = RecurringExpenses(
            category: t.category!,
            sumOfAllTransactions: 0,
          );
        }
        yearMap[year]!.sumBudget += (t.category!).fieldBudget.value.asDouble() * multiplier;

        final double amount = t.fieldAmount.value.asDouble();
        if ((t.category!).isExpense) {
          yearMap[year]!.sumExpense += amount;
        }
        if ((t.category!).isIncome) {
          yearMap[year]!.sumIncome += amount;
        }
      }
    }

    return yearMap;
  }
}
