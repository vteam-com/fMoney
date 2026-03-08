import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_router.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/pair_xyz.dart';
import 'package:money/widgets/pure/center_message.dart';
import 'package:money/widgets/pure/theme_custom.dart';

const double _barBorderRadius = 2;
const double _leftTitlesReservedSize = 80;
const double _bottomTitlesReservedSize = 50;
const double _bottomTitlesInterval = 1;
const double _barWidthMargin = 80;
const double _barWidthMargins = _barWidthMargin * 2;
const double _barWidthDivisor = 2;
const double _maxBarWidth = 30;
const double _minBarWidth = 5;
const double _gridLineWidth = 1;
const double _legendPaddingTop = 8;
const double _legendMaxWidth = 60;
const double _legendFontSize = 10;
const double _horizontalLineAlpha = 0.3;

/// A stateless widget for chart.
class Chart extends StatelessWidget {
  const Chart({
    super.key,
    required this.list,
    this.currency = Constants.defaultCurrency,
  });

  final String currency;
  final List<PairXYY> list;

  @override
  Widget build(final BuildContext context) {
    if (list.isEmpty) {
      return CenterMessage(message: AppL10n.tr(AppTranslationKeys.noChartToDisplay));
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final List<BarChartGroupData> barChartData = <BarChartGroupData>[];

        double maxY = 0.0;
        double minY = 0.0;

        // 1. Calculate available width:
        double barWidth = getBarWidth(constraints, list.length);
        barWidth /= _barWidthDivisor;

        for (int index = 0; index < list.length; index++) {
          final PairXYY entry = list[index];
          maxY = max(maxY, entry.yValue1.toDouble());
          minY = min(minY, entry.yValue1.toDouble());
          if (entry.yValue2 != null) {
            maxY = max(maxY, entry.yValue2!.toDouble());
            minY = min(minY, entry.yValue2!.toDouble());
          }
          final BarChartGroupData bar = BarChartGroupData(
            x: index,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: entry.yValue1.toDouble(),
                borderRadius: BorderRadius.circular(_barBorderRadius),
                color: entry.yValue1 < 0 ? Colors.red : Colors.green,
                width: barWidth, // Dynamically set the bar width
              ),
              if (entry.yValue2 != null)
                BarChartRodData(
                  toY: entry.yValue2!.toDouble(),
                  borderRadius: BorderRadius.circular(_barBorderRadius),
                  color: Colors.blue,
                  width: barWidth, // Dynamically set the bar width
                ),
            ],
          );

          barChartData.add(bar);
        }

        maxY = roundToTheNextNaturalFit(maxY.toInt()).toDouble();
        minY = minY == 0 ? 0 : -roundToTheNextNaturalFit(minY.toInt().abs()).toDouble();

        return BarChart(
          BarChartData(
            barGroups: barChartData,
            maxY: maxY,
            minY: minY,
            backgroundColor: Colors.transparent,
            borderData: getBorders(minY, maxY),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(), // hide
              rightTitles: const AxisTitles(), // hide
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: _leftTitlesReservedSize,
                  getTitlesWidget: getWidgetChartAmount,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: _bottomTitlesReservedSize,
                  getTitlesWidget: _buildLegendBottom,
                  interval: _bottomTitlesInterval,
                ),
              ),
            ),
            gridData: getChartGridData(),
            barTouchData: getBarTouchedData(context, getTooltipText),
          ),
        );
      },
    );
  }

  /// Returns BarTouchData with tooltip rendering for bar charts.
  static BarTouchData getBarTouchedData(
    final BuildContext context,
    final String Function(BarChartGroupData, BarChartRodData) renderTooltip,
  ) => BarTouchData(
    enabled: true,
    touchTooltipData: BarTouchTooltipData(
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      getTooltipColor: (BarChartGroupData _) => getColorTheme(context).secondaryContainer,

      getTooltipItem:
          (
            final BarChartGroupData group,
            final int groupIndex,
            final BarChartRodData rod,
            final int rodIndex,
          ) {
            keepUnused(groupIndex, rodIndex);
            return BarTooltipItem(
              renderTooltip(group, rod),
              TextStyle(color: getColorTheme(context).primary),
              textAlign: TextAlign.start,
            );
          },
    ),
    touchCallback:
        (
          final FlTouchEvent event,
          final BarTouchResponse? barTouchResponse,
        ) {
          if (event is FlLongPressStart) {
            if (barTouchResponse != null) {
              if (barTouchResponse.spot != null) {
                HapticFeedback.lightImpact();
                copyToClipboardAndInformUser(
                  context,
                  renderTooltip(
                    barTouchResponse.spot!.touchedBarGroup,
                    barTouchResponse.spot!.touchedRodData,
                  ),
                );
              }
            }
          }
        },
  );

  /// Calculates the bar width based on constraints and number of bars.
  static double getBarWidth(
    BoxConstraints constraints,
    final int numberOfBars,
  ) {
    // 1. Calculate available width:
    const double margins = _barWidthMargins;
    final double availableWidth = constraints.maxWidth - margins;

    // 2. Calculate bar width (adjust as needed):
    double barWidth = availableWidth / numberOfBars;

    if (barWidth > _maxBarWidth) {
      // Set max bar width to 30
      barWidth = _maxBarWidth;
    }

    if (barWidth < _minBarWidth) {
      // Set min bar width to 5
      barWidth = _minBarWidth;
    }
    return barWidth;
  }

  /// Returns FlGridData with optional horizontal grid lines.
  static FlGridData getChartGridData() => FlGridData(
    drawVerticalLine: false,
    getDrawingHorizontalLine: (final double value) => FlLine(
      color: getHorizontalLineColorBasedOnValue(value),
      strokeWidth: _gridLineWidth, // Set the thickness of the grid lines
    ),
  );

  /// Formats tooltip text for a bar chart group and rod.
  String getTooltipText(BarChartGroupData group, BarChartRodData rod) =>
      '${list[group.x].xText}\n${getAmountAsStringUsingCurrency(rod.toY, iso4217code: currency)}';

  Widget _buildLegendBottom(final double value, final TitleMeta _) => Container(
    padding: const EdgeInsets.only(top: _legendPaddingTop),
    constraints: const BoxConstraints(maxWidth: _legendMaxWidth),
    child: Text(
      list[value.toInt()].xText,
      softWrap: true,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: _legendFontSize),
    ),
  );
}

/// Returns FlBorderData with themed top/bottom borders for the given range.
FlBorderData getBorders(final double min, final double max) => FlBorderData(
  show: true,
  border: Border(
    top: BorderSide(color: getHorizontalLineColorBasedOnValue(max)),
    bottom: BorderSide(color: getHorizontalLineColorBasedOnValue(min)),
  ),
);

/// Returns a themed horizontal line color based on the numeric value.
Color getHorizontalLineColorBasedOnValue(final double value) => Theme.of(
  AppRouter.context!,
).extension<MoneyThemeData>()!.colorBasedOnValue(value).withValues(alpha: _horizontalLineAlpha);

/// Builds a currency-formatted widget for chart axis labels.
Widget getWidgetChartAmount(final double value, final TitleMeta meta) {
  final Widget widget = Text(
    getAmountAsStringUsingCurrency(value, decimalDigits: 0),
    textAlign: TextAlign.end,
    softWrap: false,
    style: const TextStyle(fontSize: _legendFontSize),
  );

  return SideTitleWidget(meta: meta, child: widget);
}
