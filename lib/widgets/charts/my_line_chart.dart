import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:money/helpers/chart_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/charts/chart.dart';

const double _defaultMarginLeft = 80;
const double _defaultMarginBottom = 50;
const double _axisLabelFontSize = 10;

/// A stateless widget for my line chart.
class MyLineChart extends StatelessWidget {
  const MyLineChart({
    super.key,
    required this.dataPoints,
    required this.showDots,
    this.marginLeft = _defaultMarginLeft,
    this.marginBottom = _defaultMarginBottom,
  });

  final List<FlSpot> dataPoints;
  final double marginBottom;
  final double marginLeft;
  final bool showDots;

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return const Center(child: Text('No data to display'));
    }
    return LineChart(
      LineChartData(
        lineBarsData: <LineChartBarData>[
          getLineChartBarData(dataPoints, showDots: showDots),
        ],
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(), // hide
          rightTitles: const AxisTitles(), // hide
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: marginLeft,
              getTitlesWidget: getWidgetChartAmount,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: marginBottom,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox();
                }
                final DateTime date = DateTime.fromMillisecondsSinceEpoch(
                  value.toInt(),
                );
                return Text(
                  formatDate(date),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: _axisLabelFontSize),
                ); // Format as HH:MM
              },
            ),
          ),
        ),
        borderData: getBorders(0, 0),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            fitInsideVertically: true,
            fitInsideHorizontally: true,
            getTooltipItems: (List<LineBarSpot> touchedSpots) => touchedSpots.map((LineBarSpot touchedSpot) {
              final DateTime date = DateTime.fromMillisecondsSinceEpoch(
                touchedSpot.x.toInt(),
              );
              return LineTooltipItem(
                '${dateToString(date)}\n${doubleToCurrency(touchedSpot.y)}',
                const TextStyle(color: Colors.white),
              );
            }).toList(),
          ),
          // touchCallback: (LineTouchResponse touchResponse) {},
          handleBuiltInTouches: true,
        ),
      ),
    );
  }
}

/// Formats a DateTime as 'yyyy\nMMM'.
String formatDate(DateTime date) => DateFormat('yyyy\nMMM').format(date);
