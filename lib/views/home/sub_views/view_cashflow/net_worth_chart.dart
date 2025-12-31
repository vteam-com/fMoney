import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:money/controller/preferences_controller.dart';
import 'package:money/data/storage/data/data.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/models/chart_event.dart';
import 'package:money/models/money_objects/categories/category.dart';
import 'package:money/models/money_objects/events/event.dart';
import 'package:money/models/money_objects/transactions/transactions.dart';
import 'package:money/views/home/sub_views/view_stocks/stock_chart.dart';
import 'package:money/widgets/charts/my_line_chart.dart';

class NetWorthChart extends StatefulWidget {
  const NetWorthChart({
    super.key,
    required this.minYear,
    required this.maxYear,
  });

  final int maxYear;
  final int minYear;

  @override
  NetWorthChartState createState() => NetWorthChartState();
}

class NetWorthChartState extends State<NetWorthChart> {
  List<ChartEvent> _milestoneTransactions = <ChartEvent>[];

  List<Transaction> _transactions = <Transaction>[];

  final List<FlSpot> _yearMonthDataPoints = <FlSpot>[];

  @override
  void initState() {
    super.initState();

    _transactions = Data().transactions
        .iterableList(includeDeleted: true)
        .where((Transaction t) => t.isTransfer == false)
        .toList();

    final List<FlSpot> tmpDataPointsWithNetWorth = Transactions.cumulateTransactionPerYearMonth(_transactions);

    _yearMonthDataPoints.addAll(
      tmpDataPointsWithNetWorth.where(
        (FlSpot entry) => isBetweenOrEqual(
          DateTime.fromMillisecondsSinceEpoch(entry.x.toInt()).year,
          widget.minYear,
          widget.maxYear,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double marginLeft = 80.0;
    const double marginBottom = 50.0;

    final List<Transaction> transactionSubSet = _transactions
        .where(
          (Transaction t) => isBetweenOrEqual(
            t.fieldDateTime.value!.year,
            widget.minYear,
            widget.maxYear,
          ),
        )
        .toList();

    _milestoneTransactions = getMilestonesEvents(transactionSubSet);

    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: marginLeft,
            bottom: marginBottom,
          ),
          child: CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: PaintActivities(
              activities: _milestoneTransactions,
              minX: _yearMonthDataPoints.first.x,
              maxX: _yearMonthDataPoints.last.x,
            ),
          ),
        ),
        MyLineChart(dataPoints: _yearMonthDataPoints, showDots: false),
      ],
    );
  }
}

List<ChartEvent> getMilestonesEvents(final List<Transaction> transactions) {
  final List<ChartEvent> milestoneTransactions = <ChartEvent>[];

  if (PreferenceController.to.netWorthEventThreshold.value == 0) {
    for (final Event event in Data().events.iterableList()) {
      final Category? category = Data().categories.get(
        event.fieldCategoryId.value,
      );
      milestoneTransactions.add(
        ChartEvent(
          dates: DateRange(min: event.fieldDateBegin.value!),
          amount: 0,
          quantity: 1,
          colorBasedOnQuantity: false, // use Amount
          description: event.fieldName.value,
          color: category == null ? Colors.blue : category.getColorOrAncestorsColor(),
        ),
      );
    }
    return milestoneTransactions;
  }

  // Calculate Z-scores for outlier detection based on amount
  final List<double> amounts = transactions.map((Transaction t) => t.fieldAmount.value.asDouble()).toList();
  if (amounts.isEmpty) {
    // nothing to work on;
    return <ChartEvent>[];
  }

  // Find outlier events
  final double mean = amounts.reduce((double a, double b) => a + b) / amounts.length;
  final double variance =
      amounts.map((double amount) => (amount - mean) * (amount - mean)).reduce((double a, double b) => a + b) /
      amounts.length;
  final double stdDev = sqrt(variance);

  final List<double> zScores = amounts.map((double amount) => stdDev == 0 ? 0.0 : (amount - mean) / stdDev).toList();

  for (int i = 0; i < transactions.length; i++) {
    final double zScore = zScores[i];
    if (zScore.abs() >= PreferenceController.to.netWorthEventThreshold.value) {
      final Transaction t = transactions[i];
      milestoneTransactions.add(
        ChartEvent(
          dates: DateRange(min: t.fieldDateTime.value!),
          amount: t.fieldAmount.value.asDouble(),
          quantity: 1,
          colorBasedOnQuantity: false, // use Amount
          description: t.oneLinePayeeAndDescription,
        ),
      );
    }
  }
  milestoneTransactions.sort(
    (ChartEvent a, ChartEvent b) => sortByDate(a.dates.min, b.dates.min, true),
  );
  return milestoneTransactions;
}
