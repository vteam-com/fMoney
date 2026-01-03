import 'dart:math';
import 'package:flutter/material.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/pairs.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/theme_custom.dart';
import 'package:money/widgets/vertical_line_with_tooltip.dart';

class MiniTimelineDaily extends StatelessWidget {
  const MiniTimelineDaily({
    required this.yearStart,
    required this.yearEnd,
    required this.values,
    required this.offsetStartingDay,
    super.key,
    this.color,
    this.lineWidth = 2,
  });

  final Color? color;

  final double lineWidth;

  /// X values are using days from 1970, use this offset to bring back the X scaling to location
  /// that match the desired UX, supplying the offset days of the first element in the values will start
  /// the graph on the left side of Zero
  final int offsetStartingDay;

  /// [int = Days from millisecondFromEpoch], [double = amount]
  final List<Pair<int, double>> values;

  final int yearEnd;

  final int yearStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final int numberOfYears = yearEnd - yearStart + 1;

        // X Ratio
        final double numberOfDays = numberOfYears * 365.25;
        final double xRatio = constraints.maxWidth / numberOfDays;

        // Y Ratio
        double maxValueFound = 0;
        for (final Pair<int, double> value in values) {
          maxValueFound = max(maxValueFound, value.second.abs());
        }
        final double yRatio = constraints.maxHeight / maxValueFound;

        final List<Widget> bars = <Widget>[];
        for (final Pair<int, double> value in values) {
          final int oneDaySlot = value.first * Duration.millisecondsPerDay;

          bars.add(
            Positioned(
              left: xRatio * (value.first - offsetStartingDay),
              child: VerticalLineWithTooltip(
                height: value.second.abs() * yRatio,
                width: lineWidth,
                color: context.colorTheme.colorBasedOnValue(value.second).withValues(alpha: 0.5),
                tooltip:
                    '${dateToString(DateTime.fromMillisecondsSinceEpoch(oneDaySlot))}\n${doubleToCurrency(value.second)}',
              ),
            ),
          );
        }

        return Stack(
          alignment: AlignmentDirectional.bottomStart,
          children: bars,
        );
      },
    );
  }
}
