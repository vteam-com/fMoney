// ignore_for_file: unnecessary_this

import 'dart:math';

import 'package:money/helpers/accumulator.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/pairs.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/shared/domain/category_domain.dart';
import 'package:money/shared/domain/data_domain.dart';
import 'package:money/shared/domain/transaction_domain.dart';
import 'package:money/views/panels/distribution_bar.dart';

const int _monthsPerYear = 12;
const int _zeroInt = 0;
const int _oneInt = 1;
const int _twoInt = 2;
const int _monthOffset = 1;
const int _topDistributionsDefault = 4;
const double _zeroDouble = 0.0;

/// Represents recurring payment.
class RecurringPayment {
  RecurringPayment({
    required this.payeeId,
    required this.forIncomeTransaction,
    required this.transactions,
  }) {
    total = _zeroDouble;
    dateRangeFound = DateRange();
    categoryIdsAndSums = <Pair<int, double>>[];
    frequency = transactions.length;

    final MapAccumulatorSum<int, int, double> payeeIdMonthAndSums = MapAccumulatorSum<int, int, double>();
    final Map<int, AccumulatorSum<int, double>> payeeIdCategoryIdsAndSums = <int, AccumulatorSum<int, double>>{};

    averagePerMonths = List<Pair<int, double>>.generate(
      _monthsPerYear,
      (int _) => Pair<int, double>(_zeroInt, _zeroDouble),
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
      final int transactionMonth = transaction.fieldDateTime.value!.month - _monthOffset;
      final Pair<int, double> pair = averagePerMonths[transactionMonth];
      if (pair.first == _zeroInt) {
        // first time
        averagePerMonths[transactionMonth] = Pair<int, double>(
          _oneInt,
          transaction.fieldAmount.value.asDouble(),
        );
      } else {
        averagePerMonths[transactionMonth] = Pair<int, double>(
          pair.first + _oneInt,
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
    sumPerMonths = List<double>.generate(_monthsPerYear, (int _) => _zeroDouble);
    final AccumulatorSum<int, double> monthSums2 = payeeIdMonthAndSums.getLevel1(payeeId)!;
    monthSums2.values.forEach((int month, double sum) {
      sumPerMonths[month - _monthOffset] = sum.abs();
    });

    categoryIdsAndSums = convertMapToListOfPair<int, double>(
      payeeIdCategoryIdsAndSums[payeeId]!.values,
    );

    categoryDistribution = getTopDistributions(
      payment: this,
      asIncome: forIncomeTransaction,
      topN: _topDistributionsDefault,
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

  /// Returns the average of two numbers with special handling for negative values.
  double averageTwoNumbers(final double a, final double b) {
    // (-10 - -20) = -30 / 2 = -15
    if (a < 0 && b < 0) {
      return (a.abs() + b.abs()) / -_twoInt;
    }

    // (+10 + 20) = +30 / 2 = +15
    return (a + b) / _twoInt;
  }

  /// Returns a list of category ID and sum pairs for the payment.
  List<Pair<int, double>> getListOfCategoryIdAndSum() {
    return categoryIdsAndSums;
  }

  /// Returns the top N category distributions by summed amount.
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
