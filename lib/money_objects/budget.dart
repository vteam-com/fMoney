import 'dart:math';

import 'package:money/money_objects/transactions/transaction.dart';

class BudgetRecommendation {
  BudgetRecommendation({
    required this.recommendedExpense,
    required this.minimumExpense,
    required this.maximumExpense,
    required this.projectedIncome,
    required this.categoryBudgetsIncomes,
    required this.categoryBudgetsExpenses,
    required this.savingsRate,
  });

  final Map<String, BudgetCumulator> categoryBudgetsExpenses;
  final Map<String, BudgetCumulator> categoryBudgetsIncomes;
  final double maximumExpense;
  final double minimumExpense;
  final double projectedIncome;
  final double recommendedExpense;
  final double savingsRate;
}

class BudgetCumulator {
  BudgetCumulator({
    required this.monthlyAmount,
    required this.frequency,
    required this.originalAmount,
  });

  final ExpenseFrequency frequency;
  final double monthlyAmount;
  final double originalAmount;
}

enum ExpenseFrequency {
  monthly, // Occurs every month
  quarterly, // Occurs every 3 months
  biannual, // Occurs every 6 months
  annual, // Occurs once a year
  irregular, // Irregular pattern
}

class BudgetAnalyzer {
  BudgetAnalyzer(this.transactions);

  final List<Transaction> transactions;

  ({DateTime start, DateTime end}) _calculateDateRange(
    List<Transaction> transactions,
  ) {
    final List<DateTime> dates = transactions.map((Transaction t) => t.fieldDateTime.value!).toList();
    return (
      start: dates.reduce((DateTime a, DateTime b) => a.isBefore(b) ? a : b),
      end: dates.reduce((DateTime a, DateTime b) => a.isAfter(b) ? a : b),
    );
  }

  ({double average, double stdDev, double trend}) _calculateStatistics(
    List<double> values,
  ) {
    if (values.isEmpty) {
      return (average: 0.0, stdDev: 0.0, trend: 0.0);
    }

    final double average = values.reduce((double a, double b) => a + b) / values.length;

    final Iterable<double> squaredDiffs = values.map(
      (double value) => (value - average) * (value - average),
    );
    final double variance = squaredDiffs.reduce((double a, double b) => a + b) / values.length;
    final double stdDev = sqrt(variance);

    double trend = 0.0;
    if (values.length > 1) {
      final double firstAvg = values.take(2).reduce((double a, double b) => a + b) / 2;
      final double lastAvg = values.skip(values.length - 2).reduce((double a, double b) => a + b) / 2;
      trend = firstAvg != 0 ? (lastAvg - firstAvg) / firstAvg : 0;
    }

    return (average: average, stdDev: stdDev, trend: trend);
  }

  BudgetRecommendation calculateMonthlyBudget() {
    final List<Transaction> incomeTransactions = transactions.where((Transaction t) => t.isIncome).toList();
    final List<Transaction> expenseTransactions = transactions.where((Transaction t) => t.isExpense).toList();

    final Map<DateTime, double> monthlyIncome = _calculateMonthlyTotals(
      incomeTransactions,
    );
    final Map<DateTime, double> monthlyExpenses = _calculateMonthlyTotals(
      expenseTransactions,
    );

    final ({double average, double stdDev, double trend}) incomeStats = _calculateStatistics(
      monthlyIncome.values.toList(),
    );
    final ({double average, double stdDev, double trend}) expenseStats = _calculateStatistics(
      monthlyExpenses.values.toList(),
    );

    final Map<String, BudgetCumulator> categoryBudgetsIncomes = _calculateCategoryBudgets(incomeTransactions);
    final Map<String, BudgetCumulator> categoryBudgetsExpenses = _calculateCategoryBudgets(expenseTransactions);
    final double savingsRate = _calculateSavingsRate(
      monthlyIncome,
      monthlyExpenses,
    );

    return BudgetRecommendation(
      recommendedExpense: expenseStats.average * (1 + expenseStats.trend),
      minimumExpense: expenseStats.average * 0.9,
      maximumExpense: expenseStats.average * 1.2,
      projectedIncome: incomeStats.average * (1 + incomeStats.trend),
      categoryBudgetsIncomes: categoryBudgetsIncomes,
      categoryBudgetsExpenses: categoryBudgetsExpenses,
      savingsRate: savingsRate,
    );
  }

  double _calculateAverageOriginalAmount(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return 0.0;
    }
    final double totalAmount = transactions.fold(
      0.0,
      (double sum, Transaction t) => sum + t.fieldAmount.value.asDouble(),
    );
    return totalAmount / transactions.length;
  }

  Map<String, BudgetCumulator> _calculateCategoryBudgets(
    List<Transaction> expenses,
  ) {
    // Group transactions by category
    final Map<String, List<Transaction>> categoryTransactions = <String, List<Transaction>>{};
    for (final Transaction transaction in expenses) {
      categoryTransactions.putIfAbsent(transaction.category!.name, () => <Transaction>[]).add(transaction);
    }

    // Analyze each category
    return categoryTransactions.map((
      String category,
      List<Transaction> transactions,
    ) {
      final ExpenseFrequency frequency = _detectExpenseFrequency(transactions);
      final double monthlyAmount = _calculateMonthlyAmount(
        transactions,
        frequency,
      );
      final double originalAmount = _calculateAverageOriginalAmount(
        transactions,
      );

      return MapEntry<String, BudgetCumulator>(
        category,
        BudgetCumulator(
          monthlyAmount: monthlyAmount,
          frequency: frequency,
          originalAmount: originalAmount,
        ),
      );
    });
  }

  double _calculateMonthlyAmount(
    List<Transaction> transactions,
    ExpenseFrequency frequency,
  ) {
    if (transactions.isEmpty) {
      return 0.0;
    }

    // Calculate total amount over the period
    final double totalAmount = transactions.fold(
      0.0,
      (double sum, Transaction t) => sum + t.fieldAmount.value.asDouble(),
    );

    // Calculate the time span in months
    final ({DateTime end, DateTime start}) dateRange = _calculateDateRange(
      transactions,
    );
    final int monthsSpan = _calculateMonthsBetween(
      dateRange.start,
      dateRange.end,
    );

    // Adjust for frequency
    double monthlyAmount;
    switch (frequency) {
      case ExpenseFrequency.monthly:
        monthlyAmount = totalAmount / monthsSpan;
        break;
      case ExpenseFrequency.quarterly:
        monthlyAmount = (totalAmount / (monthsSpan / 3)) / 3;
        break;
      case ExpenseFrequency.biannual:
        monthlyAmount = (totalAmount / (monthsSpan / 6)) / 6;
        break;
      case ExpenseFrequency.annual:
        monthlyAmount = (totalAmount / (monthsSpan / 12)) / 12;
        break;
      case ExpenseFrequency.irregular:
        // For irregular expenses, use a conservative approach
        monthlyAmount = totalAmount / monthsSpan;
        break;
    }

    return monthlyAmount;
  }

  Map<DateTime, double> _calculateMonthlyTotals(List<Transaction> trans) {
    final Map<DateTime, double> monthlyTotals = <DateTime, double>{};

    for (final Transaction transaction in trans) {
      final DateTime monthStart = DateTime(
        transaction.fieldDateTime.value!.year,
        transaction.fieldDateTime.value!.month,
        1,
      );

      monthlyTotals[monthStart] = (monthlyTotals[monthStart] ?? 0.0) + transaction.fieldAmount.value.asDouble();
    }

    return monthlyTotals;
  }

  int _calculateMonthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + end.month - start.month + 1;
  }

  double _calculateSavingsRate(
    Map<DateTime, double> monthlyIncome,
    Map<DateTime, double> monthlyExpenses,
  ) {
    final Set<DateTime> months = Set<DateTime>.from(
      monthlyIncome.keys,
    ).intersection(Set<DateTime>.from(monthlyExpenses.keys));

    if (months.isEmpty) {
      return 0.0;
    }

    double totalSavingsRate = 0.0;
    int monthCount = 0;

    for (final DateTime month in months) {
      final double income = monthlyIncome[month] ?? 0.0;
      final double expenses = monthlyExpenses[month] ?? 0.0;

      if (income > 0) {
        totalSavingsRate += (income - expenses) / income;
        monthCount++;
      }
    }

    return monthCount > 0 ? totalSavingsRate / monthCount : 0.0;
  }

  ExpenseFrequency _detectExpenseFrequency(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return ExpenseFrequency.irregular;
    }

    // Sort transactions by date
    transactions.sort(
      (Transaction a, Transaction b) => a.fieldDateTime.value!.compareTo(b.fieldDateTime.value!),
    );

    // Calculate intervals between transactions
    final List<int> intervals = <int>[];
    for (int i = 1; i < transactions.length; i++) {
      final int difference = transactions[i].fieldDateTime.value!
          .difference(transactions[i - 1].fieldDateTime.value!)
          .inDays;
      intervals.add(difference);
    }

    if (intervals.isEmpty) {
      return ExpenseFrequency.irregular;
    }

    // Calculate average interval
    final double avgInterval = intervals.reduce((int a, int b) => a + b) / intervals.length;

    // Calculate variance to detect regularity
    final double variance =
        intervals.fold(
          0.0,
          (double sum, int interval) => sum + pow(interval - avgInterval, 2),
        ) /
        intervals.length;
    final double stdDev = sqrt(variance);

    // If standard deviation is too high relative to average, consider it irregular
    if (stdDev > avgInterval * 0.5) {
      return ExpenseFrequency.irregular;
    }

    // More precise thresholds based on monthly intervals
    if (avgInterval <= 45) {
      return ExpenseFrequency.monthly;
    }
    if (avgInterval >= 300 && avgInterval <= 430) {
      // Around 365 days
      return ExpenseFrequency.annual;
    }
    if (avgInterval >= 150 && avgInterval <= 210) {
      // Around 180 days
      return ExpenseFrequency.biannual;
    }
    if (avgInterval >= 75 && avgInterval <= 105) {
      // Around 90 days
      return ExpenseFrequency.quarterly;
    }
    return ExpenseFrequency.irregular;
  }
}
