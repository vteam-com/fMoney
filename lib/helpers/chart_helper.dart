import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Helper functions for creating line charts.
/// Features:
/// - Data point sorting
/// - Color selection based on trends
/// - Gradient area fills
/// - Configurable dot display
/// Creates and returns a LineChartBarData object for displaying a line chart.
/// The data points are sorted by x value (date) in ascending order.
/// The line color is determined by the trend of the data:
/// - Orange for negative final value
/// - Green if trending upward
/// - Red if trending downward
/// - Grey otherwise
LineChartBarData getLineChartBarData(
  final List<FlSpot> dataPoints, {
  bool showDots = false,
}) {
  dataPoints.sort((FlSpot a, FlSpot b) => a.x.compareTo(b.x));

  Color color = Colors.grey;
  if (dataPoints.last.y.isNegative) {
    color = Colors.orange;
  } else if (dataPoints.length >= 2) {
    color = dataPoints.last.y >= dataPoints.first.y ? Colors.green : Colors.red;
  }

  return LineChartBarData(
    spots: dataPoints,
    isCurved: false,
    color: color,
    barWidth: 1,
    belowBarData: BarAreaData(
      show: true,
      gradient: LinearGradient(
        colors: <Color>[
          color.withAlpha(100), // top
          color.withAlpha(10), // bottom
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),

    dotData: FlDotData(show: showDots), // Hide dots at endpoints
  );
}
