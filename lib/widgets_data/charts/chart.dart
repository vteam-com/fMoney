import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:money/constants.dart';
import 'package:money/currencies/currency.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/widgets/center_message.dart';
import 'package:money/widgets/theme_custom.dart';

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
      return const CenterMessage(message: 'No chart to display');
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final List<BarChartGroupData> barChartData = <BarChartGroupData>[];

        double maxY = 0.0;
        double minY = 0.0;

        // 1. Calculate available width:
        double barWidth = getBarWidth(constraints, list.length);
        barWidth /= 2;

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
                borderRadius: BorderRadius.circular(2),
                color: entry.yValue1 < 0 ? Colors.red : Colors.green,
                width: barWidth, // Dynamically set the bar width
              ),
              if (entry.yValue2 != null)
                BarChartRodData(
                  toY: entry.yValue2!.toDouble(),
                  borderRadius: BorderRadius.circular(2),
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
                  reservedSize: 80,
                  getTitlesWidget: getWidgetChartAmount,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: _buildLegendBottom,
                  interval: 1,
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

  static BarTouchData getBarTouchedData(
    final BuildContext context,
    final String Function(BarChartGroupData group, BarChartRodData rod) renderTooltip,
  ) => BarTouchData(
    enabled: true,
    touchTooltipData: BarTouchTooltipData(
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      getTooltipColor: (BarChartGroupData group) => getColorTheme(context).secondaryContainer,

      getTooltipItem:
          (
            final BarChartGroupData group,
            final int groupIndex,
            final BarChartRodData rod,
            final int rodIndex,
          ) => BarTooltipItem(
            renderTooltip(group, rod),
            TextStyle(color: getColorTheme(context).primary),
            textAlign: TextAlign.start,
          ),
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

  static double getBarWidth(
    BoxConstraints constraints,
    final int numberOfBars,
  ) {
    // 1. Calculate available width:
    final double margins = 80 * 2;
    final double availableWidth = constraints.maxWidth - margins;

    // 2. Calculate bar width (adjust as needed):
    double barWidth = availableWidth / numberOfBars;

    if (barWidth > 30) {
      // Set max bar width to 30
      barWidth = 30;
    }

    if (barWidth < 5) {
      // Set min bar width to 5
      barWidth = 5;
    }
    return barWidth;
  }

  static FlGridData getChartGridData() => FlGridData(
    drawVerticalLine: false,
    getDrawingHorizontalLine: (final double value) => FlLine(
      color: getHorizontalLineColorBasedOnValue(value),
      strokeWidth: 1, // Set the thickness of the grid lines
    ),
  );

  String getTooltipText(BarChartGroupData group, BarChartRodData rod) =>
      '${list[group.x].xText}\n${Currency.getAmountAsStringUsingCurrency(rod.toY, iso4217code: currency)}';

  Widget _buildLegendBottom(final double value, final TitleMeta meta) => Container(
    padding: const EdgeInsets.only(top: 8),
    constraints: const BoxConstraints(maxWidth: 60),
    child: Text(
      list[value.toInt()].xText,
      softWrap: true,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 10),
    ),
  );
}

class PairXYY {
  PairXYY(this.xText, this.yValue1, [this.yValue2]);

  String xText = '';
  num yValue1 = 0.0;

  num? yValue2;
}

FlBorderData getBorders(final double min, final double max) => FlBorderData(
  show: true,
  border: Border(
    top: BorderSide(color: getHorizontalLineColorBasedOnValue(max)),
    bottom: BorderSide(color: getHorizontalLineColorBasedOnValue(min)),
  ),
);

Color getHorizontalLineColorBasedOnValue(final double value) =>
    Theme.of(Get.context!).extension<MoneyThemeData>()!.colorBasedOnValue(value).withValues(alpha: 0.3);

Widget getWidgetChartAmount(final double value, final TitleMeta meta) {
  final Widget widget = Text(
    Currency.getAmountAsStringUsingCurrency(value, decimalDigits: 0),
    textAlign: TextAlign.end,
    softWrap: false,
    style: const TextStyle(fontSize: 10),
  );

  return SideTitleWidget(meta: meta, child: widget);
}
