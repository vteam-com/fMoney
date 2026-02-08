import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const int _trendSampleSize = 2;
const double _lineWidth = 1.0;
const int _gradientTopAlpha = 100;
const int _gradientBottomAlpha = 10;

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
  } else if (dataPoints.length >= _trendSampleSize) {
    color = dataPoints.last.y >= dataPoints.first.y ? Colors.green : Colors.red;
  }

  return LineChartBarData(
    spots: dataPoints,
    isCurved: false,
    color: color,
    barWidth: _lineWidth,
    belowBarData: BarAreaData(
      show: true,
      gradient: LinearGradient(
        colors: <Color>[
          color.withAlpha(_gradientTopAlpha), // top
          color.withAlpha(_gradientBottomAlpha), // bottom
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),

    dotData: FlDotData(show: showDots), // Hide dots at endpoints
  );
}
