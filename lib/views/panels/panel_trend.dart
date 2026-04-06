import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:money/data/models/field_filter.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/shared/domain/category_domain.dart';
import 'package:money/shared/domain/data_domain.dart';
import 'package:money/views/panels/recurring_expenses.dart';
import 'package:money/widgets/charts/chart.dart';
import 'package:money/widgets/pure/theme_custom.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/widgets_domain/field_filters.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const int _unsetId = -1;
const int _oneInt = 1;
const double _zeroDouble = 0.0;
const double _tooltipPadding = 8.0;
const double _tooltipMargin = 16.0;
const double _tooltipMaxWidth = 300.0;
const double _tooltipTitleFontSize = 20.0;
const double _tooltipBodyFontSize = 16.0;
const double _profitScale = 1.1;
const double _axisLabelFontSize = 10.0;
const double _axisReservedWidth = 120.0;
const double _axisReservedBottom = 30.0;
const double _barWidthWide = 20.0;
const double _barWidthNarrow = 10.0;
const double _barRadius = 8.0;
const int _barAlpha = 120;
const double _lineAlpha = 0.3;
const int _lineFeedCodePoint = 10;
const int _tabCodePoint = 9;

/// Widget that displays recurring cashflow trends over time as a bar chart.
/// Shows income, expenses and profit/loss for each time period.
class PanelTrend extends StatefulWidget {
  const PanelTrend({
    super.key,
    required this.dateRangeSearch,
    required this.minYear,
    required this.maxYear,
    required this.viewRecurringAs,
    required this.includeAssetAccounts,
  });

  final DateRange dateRangeSearch;
  final bool includeAssetAccounts;
  final int maxYear;
  final int minYear;
  final CashflowViewAs viewRecurringAs;

  @override
  State<PanelTrend> createState() => _PanelTrendState();
}

/// State management for the PanelTrend widget.
/// Handles data preparation and chart rendering.
class _PanelTrendState extends State<PanelTrend> {
  double maxY = _zeroDouble;

  double minY = _zeroDouble;

  Map<int, RecurringExpenses> yearCategoryIncomeExpenseSums = <int, RecurringExpenses>{};

  List<int> years = <int>[];

  @override
  void initState() {
    super.initState();
    _generateList();
  }

  @override
  void didUpdateWidget(covariant PanelTrend oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.minYear != oldWidget.minYear ||
        widget.maxYear != oldWidget.maxYear ||
        widget.includeAssetAccounts != oldWidget.includeAssetAccounts) {
      setState(() {
        _generateList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(_tooltipPadding),
            tooltipMargin: _tooltipMargin, // Increased margin to prevent clipping
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            maxContentWidth: _tooltipMaxWidth,
            getTooltipColor: (BarChartGroupData _) => Colors.black,
            getTooltipItem:
                (
                  BarChartGroupData _,
                  int groupIndex,
                  BarChartRodData _,
                  int rodIndex,
                ) {
                  keepUnused(rodIndex);
                  final String lineFeed = String.fromCharCode(_lineFeedCodePoint);
                  final String tab = String.fromCharCode(_tabCodePoint);
                  final int year = years[groupIndex];
                  final RecurringExpenses yearData = yearCategoryIncomeExpenseSums[year]!;
                  final double profit = yearData.sumIncome + yearData.sumExpense;
                  final String profitOrLossLabel = profit > _zeroDouble
                      ? AppL10n.tr(AppTranslationKeys.profit)
                      : AppL10n.tr(AppTranslationKeys.loss);
                  return BarTooltipItem(
                    year.toString(),
                    textAlign: TextAlign.end,
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: _tooltipTitleFontSize,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            '$lineFeed${AppL10n.tr(AppTranslationKeys.incomeLabel)}$tab${AmountModel(amount: yearData.sumIncome).toShortHand()}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.normal,
                          fontSize: _tooltipBodyFontSize,
                        ),
                      ),
                      TextSpan(
                        text:
                            '$lineFeed${AppL10n.tr(AppTranslationKeys.expenseLabel)}$tab${AmountModel(amount: yearData.sumExpense).toShortHand()}',
                        style: TextStyle(
                          color: Colors.red.shade100,
                          fontWeight: FontWeight.normal,
                          fontSize: _tooltipBodyFontSize,
                        ),
                      ),
                      TextSpan(
                        text: '$lineFeed$profitOrLossLabel$tab${AmountModel(amount: profit).toShortHand()}',
                        style: TextStyle(
                          color: profit > _zeroDouble ? Colors.blue : Colors.orange,
                          fontWeight: FontWeight.normal,
                          fontSize: _tooltipBodyFontSize,
                        ),
                      ),
                    ],
                  );
                },
          ),
          touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
            if (event is FlTapUpEvent && response != null && response.spot != null) {
              final int year = years[response.spot!.touchedBarGroupIndex];

              final FieldFilter fieldFilterToUseForYear = FieldFilter(
                fieldName: Constants.viewTransactionFieldNameDate,
                strings: Data().transactions
                    .getAllTransactionDatesForYear(year)
                    .map((DateTime date) => dateToString(date))
                    .toList(),
              );

              // Filter by Category Expense and Income
              final Set<String> categoryNames = <String>{};
              {
                for (final Category category in Data().categories.getAllExpenseCategories()) {
                  categoryNames.add(category.name);
                }
                for (final Category category in Data().categories.getAllIncomeCategories()) {
                  categoryNames.add(category.name);
                }
              }
              final List<String> sortedCategoryList = categoryNames.toList();
              sortedCategoryList.sort();

              final FieldFilter fieldFilterToUseForCategories = FieldFilter(
                fieldName: Constants.viewTransactionFieldNameCategory,
                strings: sortedCategoryList,
              );

              PreferenceController.to.jumpToView(
                viewId: ViewId.viewTransactions,
                selectedId: _unsetId,
                columnFilters: FieldFilters(<FieldFilter>[
                  fieldFilterToUseForYear,
                  fieldFilterToUseForCategories,
                ]),
                textFilter: '',
              );
            }
          },
          handleBuiltInTouches: true,
        ),
        barGroups: _buildBarGroups(),
        alignment: BarChartAlignment.spaceEvenly,
        maxY: maxY * _profitScale, // add 10%
        minY: minY * _profitScale, // add 10%
        backgroundColor: Colors.transparent,
        borderData: getBorders(minY, maxY),
        titlesData: _buildTitlesData(),
        gridData: Chart.getChartGridData(),
      ),
    );
  }

  /// Returns border data with themed top/bottom colors for the trend chart.
  FlBorderData getBorders(final double min, final double max) {
    return FlBorderData(
      show: true,
      border: Border(
        top: BorderSide(color: getHorizontalLineColorBasedOnValue(max)),
        bottom: BorderSide(color: getHorizontalLineColorBasedOnValue(min)),
      ),
    );
  }

  /// Returns a themed horizontal line color based on the numeric value.
  Color getHorizontalLineColorBasedOnValue(final double value) {
    return context.colorTheme.colorBasedOnValue(value).withValues(alpha: _lineAlpha);
  }

  /// Builds grouped bar chart data for each year using income, expense, and profit rods.
  List<BarChartGroupData> _buildBarGroups() {
    return List<BarChartGroupData>.generate(years.length, (int index) {
      final int year = years[index];
      final RecurringExpenses yearData = yearCategoryIncomeExpenseSums[year]!;
      final double profit = yearData.sumIncome + yearData.sumExpense;
      return BarChartGroupData(
        groupVertically: true,
        x: index,
        barRods: <BarChartRodData>[
          // Negative Bar
          BarChartRodData(
            fromY: _zeroDouble,
            toY: yearData.sumIncome,
            color: context.colorTheme.getTextColorToUse(yearData.sumIncome)!.withAlpha(_barAlpha),
            width: _barWidthWide,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(_barRadius),
              topRight: Radius.circular(_barRadius),
            ),
          ),
          BarChartRodData(
            fromY: _zeroDouble,
            toY: yearData.sumExpense,
            color: context.colorTheme.getTextColorToUse(yearData.sumExpense)!.withAlpha(_barAlpha),
            width: _barWidthWide,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(_barRadius),
              bottomRight: Radius.circular(_barRadius),
            ),
          ),
          BarChartRodData(
            fromY: _zeroDouble,
            toY: profit,
            color: profit > _zeroDouble ? Colors.blue : Colors.orange,
            width: _barWidthNarrow,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(_zeroDouble)),
          ),
        ],
        barsSpace: _zeroDouble,
      );
    });
  }

  /// Builds axis title configuration for the bar chart.
  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: _axisReservedWidth,
          getTitlesWidget: (double value, TitleMeta _) {
            return WidgetFromData.fromDouble(value);
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: _axisReservedBottom,
          getTitlesWidget: (final double value, final TitleMeta _) {
            final List<int> years = yearCategoryIncomeExpenseSums.keys.toList()..sort();
            if (value.toInt() >= years.length) {
              return const Text('');
            }
            return Text(
              years[value.toInt()].toString(),
              style: const TextStyle(fontSize: _axisLabelFontSize),
            );
          },
          interval: _oneInt.toDouble(),
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  /// Generates yearly aggregates and chart bounds for the current configuration.
  void _generateList() {
    yearCategoryIncomeExpenseSums = RecurringExpenses.getSumByIncomeExpenseByYears(
      widget.minYear,
      widget.maxYear,
      widget.includeAssetAccounts,
      _oneInt.toDouble(),
    );
    years = yearCategoryIncomeExpenseSums.keys.toList()..sort();

    maxY = _zeroDouble;
    minY = _zeroDouble;

    for (final RecurringExpenses yearData in yearCategoryIncomeExpenseSums.values) {
      maxY = max(max(maxY, yearData.sumExpense), yearData.sumIncome);
      minY = min(min(minY, yearData.sumExpense), yearData.sumIncome);
    }
  }
}
