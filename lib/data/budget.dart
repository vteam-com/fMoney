// ignore: fcheck_one_class_per_file
import 'dart:math';

import 'package:money/data/entities/transaction.dart';

const double _zeroDouble = 0.0;
const int _zeroInt = 0;
const int _oneInt = 1;
const int _twoInt = 2;
const int _monthsPerYear = 12;
const int _quarterMonths = 3;
const int _biannualMonths = 6;
const double _minimumExpenseMultiplier = 0.9;
const double _maximumExpenseMultiplier = 1.2;
const double _trendNeutralMultiplier = 1.0;
const double _irregularStdDevThreshold = 0.5;
const int _monthlyMaxIntervalDays = 45;
const int _annualMinIntervalDays = 300;
const int _annualMaxIntervalDays = 430;
const int _biannualMinIntervalDays = 150;
const int _biannualMaxIntervalDays = 210;
const int _quarterlyMinIntervalDays = 75;
const int _quarterlyMaxIntervalDays = 105;

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
      return (average: _zeroDouble, stdDev: _zeroDouble, trend: _zeroDouble);
    }

    final double average = values.reduce((double a, double b) => a + b) / values.length;

    final Iterable<double> squaredDiffs = values.map(
      (double value) => (value - average) * (value - average),
    );
    final double variance = squaredDiffs.reduce((double a, double b) => a + b) / values.length;
    final double stdDev = sqrt(variance);

    double trend = _zeroDouble;
    if (values.length > _oneInt) {
      final double firstAvg = values.take(_twoInt).reduce((double a, double b) => a + b) / _twoInt;
      final double lastAvg = values.skip(values.length - _twoInt).reduce((double a, double b) => a + b) / _twoInt;
      trend = firstAvg != _zeroDouble ? (lastAvg - firstAvg) / firstAvg : _zeroDouble;
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
      recommendedExpense: expenseStats.average * (_trendNeutralMultiplier + expenseStats.trend),
      minimumExpense: expenseStats.average * _minimumExpenseMultiplier,
      maximumExpense: expenseStats.average * _maximumExpenseMultiplier,
      projectedIncome: incomeStats.average * (_trendNeutralMultiplier + incomeStats.trend),
      categoryBudgetsIncomes: categoryBudgetsIncomes,
      categoryBudgetsExpenses: categoryBudgetsExpenses,
      savingsRate: savingsRate,
    );
  }

  double _calculateAverageOriginalAmount(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return _zeroDouble;
    }
    final double totalAmount = transactions.fold(
      _zeroDouble,
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
      categoryTransactions
          .putIfAbsent((transaction.category as dynamic).name as String, () => <Transaction>[])
          .add(transaction);
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
      return _zeroDouble;
    }

    // Calculate total amount over the period
    final double totalAmount = transactions.fold(
      _zeroDouble,
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
        monthlyAmount = (totalAmount / (monthsSpan / _quarterMonths)) / _quarterMonths;
        break;
      case ExpenseFrequency.biannual:
        monthlyAmount = (totalAmount / (monthsSpan / _biannualMonths)) / _biannualMonths;
        break;
      case ExpenseFrequency.annual:
        monthlyAmount = (totalAmount / (monthsSpan / _monthsPerYear)) / _monthsPerYear;
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
        _oneInt,
      );

      monthlyTotals[monthStart] = (monthlyTotals[monthStart] ?? _zeroDouble) + transaction.fieldAmount.value.asDouble();
    }

    return monthlyTotals;
  }

  int _calculateMonthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * _monthsPerYear + end.month - start.month + _oneInt;
  }

  double _calculateSavingsRate(
    Map<DateTime, double> monthlyIncome,
    Map<DateTime, double> monthlyExpenses,
  ) {
    final Set<DateTime> months = Set<DateTime>.from(
      monthlyIncome.keys,
    ).intersection(Set<DateTime>.from(monthlyExpenses.keys));

    if (months.isEmpty) {
      return _zeroDouble;
    }

    double totalSavingsRate = _zeroDouble;
    int monthCount = _zeroInt;

    for (final DateTime month in months) {
      final double income = monthlyIncome[month] ?? _zeroDouble;
      final double expenses = monthlyExpenses[month] ?? _zeroDouble;

      if (income > _zeroDouble) {
        totalSavingsRate += (income - expenses) / income;
        monthCount++;
      }
    }

    return monthCount > _zeroInt ? totalSavingsRate / monthCount : _zeroDouble;
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
    for (int i = _oneInt; i < transactions.length; i++) {
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
          _zeroDouble,
          (double sum, int interval) => sum + pow(interval - avgInterval, _twoInt),
        ) /
        intervals.length;
    final double stdDev = sqrt(variance);

    // If standard deviation is too high relative to average, consider it irregular
    if (stdDev > avgInterval * _irregularStdDevThreshold) {
      return ExpenseFrequency.irregular;
    }

    // More precise thresholds based on monthly intervals
    if (avgInterval <= _monthlyMaxIntervalDays) {
      return ExpenseFrequency.monthly;
    }
    if (avgInterval >= _annualMinIntervalDays && avgInterval <= _annualMaxIntervalDays) {
      // Around 365 days
      return ExpenseFrequency.annual;
    }
    if (avgInterval >= _biannualMinIntervalDays && avgInterval <= _biannualMaxIntervalDays) {
      // Around 180 days
      return ExpenseFrequency.biannual;
    }
    if (avgInterval >= _quarterlyMinIntervalDays && avgInterval <= _quarterlyMaxIntervalDays) {
      // Around 90 days
      return ExpenseFrequency.quarterly;
    }
    return ExpenseFrequency.irregular;
  }
}
