// ignore_for_file: unnecessary_this

import 'dart:math';

import 'package:money/data/data.dart';
import 'package:money/helpers/accumulator.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/models/money_objects/categories/category.dart';
import 'package:money/models/money_objects/transactions/transaction.dart';
import 'package:money/widgets/distribution_bar.dart';

class RecurringPayment {
  RecurringPayment({
    required this.payeeId,
    required this.forIncomeTransaction,
    required this.transactions,
  }) {
    total = 0.00;
    dateRangeFound = DateRange();
    categoryIdsAndSums = <Pair<int, double>>[];
    frequency = transactions.length;

    final MapAccumulatorSum<int, int, double> payeeIdMonthAndSums = MapAccumulatorSum<int, int, double>();
    final Map<int, AccumulatorSum<int, double>> payeeIdCategoryIdsAndSums = <int, AccumulatorSum<int, double>>{};

    averagePerMonths = List<Pair<int, double>>.generate(
      12,
      (int index) => Pair<int, double>(0, 0),
    );

    for (final Transaction transaction in transactions) {
      total += transaction.fieldAmount.value.asDouble();
      dateRangeFound.inflate(transaction.fieldDateTime.value);

      /// Cumulate by [PayeeId].[month].[Sum]
      payeeIdMonthAndSums.cumulate(
        payeeId,
        transaction.fieldDateTime.value!.month,
        transaction.fieldAmount.value.asDouble(),
      );

      /// Rolling average per Month
      final int transactionMonth = transaction.fieldDateTime.value!.month - 1;
      final Pair<int, double> pair = averagePerMonths[transactionMonth];
      if (pair.first == 0) {
        // first time
        averagePerMonths[transactionMonth] = Pair<int, double>(
          1,
          transaction.fieldAmount.value.asDouble(),
        );
      } else {
        averagePerMonths[transactionMonth] = Pair<int, double>(
          pair.first + 1,
          averageTwoNumbers(
            pair.second,
            transaction.fieldAmount.value.asDouble(),
          ),
        );
      }

      if (!payeeIdCategoryIdsAndSums.containsKey(payeeId)) {
        payeeIdCategoryIdsAndSums[payeeId] = AccumulatorSum<int, double>();
      }
      payeeIdCategoryIdsAndSums[payeeId]!.cumulate(
        transaction.fieldCategoryId.value,
        transaction.fieldAmount.value.asDouble(),
      );
    }

    // sum per month
    sumPerMonths = List<double>.generate(12, (int index) => 0);
    final AccumulatorSum<int, double> monthSums2 = payeeIdMonthAndSums.getLevel1(payeeId)!;
    monthSums2.values.forEach((int month, double sum) {
      sumPerMonths[month - 1] = sum.abs();
    });

    categoryIdsAndSums = convertMapToListOfPair<int, double>(
      payeeIdCategoryIdsAndSums[payeeId]!.values,
    );

    categoryDistribution = getTopDistributions(
      payment: this,
      asIncome: forIncomeTransaction,
      topN: 4,
    );
  }

  final bool forIncomeTransaction;
  final int payeeId;
  final List<Transaction> transactions;

  late List<Pair<int, double>> averagePerMonths;
  late List<Distribution> categoryDistribution;
  late List<Pair<int, double>> categoryIdsAndSums;
  late DateRange dateRangeFound;
  late int frequency;
  late List<double> sumPerMonths;
  late double total;

  double averageTwoNumbers(final double a, final double b) {
    // (-10 - -20) = -30 / 2 = -15
    if (a < 0 && b < 0) {
      return (a.abs() + b.abs()) / -2;
    }

    // (+10 + 20) = +30 / 2 = +15
    return (a + b) / 2;
  }

  List<Pair<int, double>> getListOfCategoryIdAndSum() {
    return categoryIdsAndSums;
  }

  List<Distribution> getTopDistributions({
    required RecurringPayment payment,
    required bool asIncome,
    required int topN,
  }) {
    final List<Pair<int, double>> list = payment.getListOfCategoryIdAndSum();
    // Sort descending
    if (asIncome) {
      list.sort(
        (Pair<int, double> a, Pair<int, double> b) => b.second.compareTo(a.second),
      );
    } else {
      list.sort(
        (Pair<int, double> a, Pair<int, double> b) => a.second.compareTo(b.second),
      );
    }

    final List<Distribution> listForDistributionBar = <Distribution>[];

    // keep at most [n] number of items
    final int topCategoryToShow = min(topN, list.length);

    for (final Pair<int, double> categoryIdAndSum in list.take(
      topCategoryToShow,
    )) {
      final Category? category = Data().categories.get(categoryIdAndSum.first);
      listForDistributionBar.add(
        Distribution(
          category: category ?? Data().categories.unknown,
          amount: categoryIdAndSum.second,
        ),
      );
    }
    return listForDistributionBar;
  }
}
