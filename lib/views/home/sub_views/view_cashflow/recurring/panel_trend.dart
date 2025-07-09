import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:money/core/controller/preferences_controller.dart';
import 'package:money/core/widgets/chart.dart';
import 'package:money/data/models/fields/field_filters.dart';
import 'package:money/data/models/money_objects/categories/category.dart';
import 'package:money/data/storage/data/data.dart';
import 'package:money/views/home/sub_views/view_cashflow/recurring/recurring_expenses.dart';

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
  double maxY = 0;
  double minY = 0;
  Map<int, RecurringExpenses> yearCategoryIncomeExpenseSums = <int, RecurringExpenses>{};
  List<int> years = <int>[];

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
  void initState() {
    super.initState();
    _generateList();
  }

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 16, // Increased margin to prevent clipping
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            maxContentWidth: 300,
            getTooltipColor: (BarChartGroupData group) => Colors.black,
            getTooltipItem:
                (
                  BarChartGroupData group,
                  int groupIndex,
                  BarChartRodData rod,
                  int rodIndex,
                ) {
                  final int year = years[groupIndex];
                  final RecurringExpenses yearData = yearCategoryIncomeExpenseSums[year]!;
                  final double profit = yearData.sumIncome + yearData.sumExpense;
                  return BarTooltipItem(
                    year.toString(),
                    textAlign: TextAlign.end,
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '\nRevenue\t${MoneyModel(amount: yearData.sumIncome).toShortHand()}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      TextSpan(
                        text: '\nExpense\t${MoneyModel(amount: yearData.sumExpense).toShortHand()}',
                        style: TextStyle(
                          color: Colors.red.shade100,
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      TextSpan(
                        text: '\n${profit > 0 ? 'Profit' : 'Loss'}\t${MoneyModel(amount: profit).toShortHand()}',
                        style: TextStyle(
                          color: profit > 0 ? Colors.blue : Colors.orange,
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
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
                selectedId: -1,
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
        maxY: maxY * 1.1, // add 10%
        minY: minY * 1.1, // add 10%
        backgroundColor: Colors.transparent,
        borderData: getBorders(minY, maxY),
        titlesData: _buildTitlesData(),
        gridData: Chart.getChartGridData(),
      ),
    );
  }

  FlBorderData getBorders(final double min, final double max) {
    return FlBorderData(
      show: true,
      border: Border(
        top: BorderSide(color: getHorizontalLineColorBasedOnValue(max)),
        bottom: BorderSide(color: getHorizontalLineColorBasedOnValue(min)),
      ),
    );
  }

  Color getHorizontalLineColorBasedOnValue(final double value) {
    return colorBasedOnValue(value).withValues(alpha: 0.3);
  }

  // Data for the chart
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
            fromY: 0,
            toY: yearData.sumIncome,
            color: getTextColorToUse(yearData.sumIncome)!.withAlpha(120),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          BarChartRodData(
            fromY: 0,
            toY: yearData.sumExpense,
            color: getTextColorToUse(yearData.sumExpense)!.withAlpha(120),
            width: 20,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          BarChartRodData(
            fromY: 0,
            toY: profit,
            color: profit > 0 ? Colors.blue : Colors.orange,
            width: 10,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(0)),
          ),
        ],
        barsSpace: 0,
      );
    });
  }

  // Titles on the x-axis
  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 120,
          getTitlesWidget: (double value, TitleMeta meta) {
            return MoneyWidget.fromDouble(value);
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (final double value, final TitleMeta meta) {
            final List<int> years = yearCategoryIncomeExpenseSums.keys.toList()..sort();
            if (value.toInt() >= years.length) {
              return const Text('');
            }
            return Text(
              years[value.toInt()].toString(),
              style: const TextStyle(fontSize: 10),
            );
          },
          interval: 1,
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  void _generateList() {
    yearCategoryIncomeExpenseSums = RecurringExpenses.getSumByIncomeExpenseByYears(
      widget.minYear,
      widget.maxYear,
      widget.includeAssetAccounts,
      1,
    );
    years = yearCategoryIncomeExpenseSums.keys.toList()..sort();

    maxY = 0;
    minY = 0;

    for (final RecurringExpenses yearData in yearCategoryIncomeExpenseSums.values) {
      maxY = max(max(maxY, yearData.sumExpense), yearData.sumIncome);
      minY = min(min(minY, yearData.sumExpense), yearData.sumIncome);
    }
  }
}
