import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:money/helpers/chart_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/chart.dart';

class MyLineChart extends StatelessWidget {
  const MyLineChart({
    super.key,
    required this.dataPoints,
    required this.showDots,
    this.marginLeft = 80,
    this.marginBottom = 50,
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
                  style: const TextStyle(fontSize: 10),
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

String formatDate(DateTime date) => DateFormat('yyyy\nMMM').format(date);
