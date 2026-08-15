import 'dart:math';

import 'package:flutter/material.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/pairs_model.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/pure/theme_custom_model.dart';
import 'package:money/widgets/pure/vertical_line_with_tooltip_widget.dart';

const double _defaultLineWidth = 2;
const double _daysPerYear = 365.25;
const double _barAlpha = 0.5;
const int _inclusiveYearOffset = 1;

/// A stateless widget for mini timeline daily.
class MiniTimelineDaily extends StatelessWidget {
  const MiniTimelineDaily({
    required this.yearStart,
    required this.yearEnd,
    required this.values,
    required this.offsetStartingDay,
    super.key,
    this.color,
    this.lineWidth = _defaultLineWidth,
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
      builder: (BuildContext context, BoxConstraints constraints) {
        final int numberOfYears = yearEnd - yearStart + _inclusiveYearOffset;

        // X Ratio
        final double numberOfDays = numberOfYears * _daysPerYear;
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
                color: context.colorTheme.colorBasedOnValue(value.second).withValues(alpha: _barAlpha),
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
