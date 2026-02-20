import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money/helpers/accumulator.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/widgets/pure/scale_down.dart';
import 'package:money/widgets/pure/theme_custom.dart';
import 'package:money/widgets/widgets_domain/field_type.dart';

const double _dateFooterMinWidth = 80;
const double _dateFooterFontSize = 10;
const int _dateDurationPadWidth = 10;
const int _dateDurationMaxLines = 2;
const double _numericFooterMinWidth = 60;
const double _numericFooterFontSize = 9;
const int _numericFooterMaxLines = 1;
const num _smallValueThreshold = 10000;

Widget getFooterForDateRange(final DateRange dateRange) {
  return LayoutBuilder(
    builder: (BuildContext _, BoxConstraints constraints) {
      final bool showDates = constraints.maxWidth > _dateFooterMinWidth;
      return DefaultTextStyle(
        style: const TextStyle(
          fontSize: _dateFooterFontSize,
          color: Colors.grey,
          fontFamily: 'RobotoMono',
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (showDates) Text(dateToString(dateRange.min)),
            if (showDates) Text(dateToString(dateRange.max)),
            Text(
              dateRange.toStringDuration().padLeft(_dateDurationPadWidth),
              softWrap: true,
              maxLines: _dateDurationMaxLines,
            ),
          ],
        ),
      );
    },
  );
}

Widget getFooterForAmount(final double amount, {final String prefix = ''}) {
  final TextStyle style = TextStyle(
    color: Theme.of(Get.context!).extension<MoneyThemeData>()!.colorBasedOnValue(amount),
    fontFamily: 'RobotoMono',
  );

  if (isSmallValue(amount)) {
    return scaleDown(
      Text(
        prefix + getAmountAsStringUsingCurrency(amount),
        style: style,
      ),
    );
  }
  return scaleDown(
    Text('$prefix\$${getAmountAsShorthandText(amount)}', style: style),
  );
}

Widget getFooterForInt(
  final num value, {
  final bool applyColorBasedOnValue = true,
  final String prefix = '',
}) {
  final TextStyle style = TextStyle(
    color: applyColorBasedOnValue ? Theme.of(Get.context!).extension<MoneyThemeData>()!.colorBasedOnValue(value) : null,
    fontFamily: 'RobotoMono',
  );

  if (isSmallValue(value)) {
    return scaleDown(Text(prefix + getIntAsText(value.toInt()), style: style));
  }
  return scaleDown(Text(prefix + getNumberShorthandText(value), style: style));
}

Widget getFooterForNumericRange(final RunningAverage range, final FieldType fieldType) {
  return LayoutBuilder(
    builder: (BuildContext _, BoxConstraints constraints) {
      final bool showLabels = constraints.maxWidth > _numericFooterMinWidth;
      final double min = range.range.min.toDouble();
      final double max = range.range.max.toDouble();
      final double avg = range.getAverage();

      return DefaultTextStyle(
        style: const TextStyle(
          fontSize: _numericFooterFontSize,
          color: Colors.grey,
          fontFamily: 'RobotoMono',
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (showLabels)
              Table(
                columnWidths: const <int, TableColumnWidth>{
                  0: IntrinsicColumnWidth(),
                  1: IntrinsicColumnWidth(),
                },
                children: <TableRow>[
                  TableRow(
                    children: <Widget>[
                      const Text('Min: '),
                      Text(_formatValue(min, fieldType), textAlign: TextAlign.right),
                    ],
                  ),
                  TableRow(
                    children: <Widget>[
                      const Text('Avg: '),
                      Text(_formatValue(avg, fieldType), textAlign: TextAlign.right),
                    ],
                  ),
                  TableRow(
                    children: <Widget>[
                      const Text('Max: '),
                      Text(_formatValue(max, fieldType), textAlign: TextAlign.right),
                    ],
                  ),
                ],
              )
            else ...<Widget>[
              Text(
                _formatValue(min, fieldType),
                maxLines: _numericFooterMaxLines,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatValue(avg, fieldType),
                maxLines: _numericFooterMaxLines,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatValue(max, fieldType),
                maxLines: _numericFooterMaxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      );
    },
  );
}

String _formatValue(double value, FieldType fieldType) {
  if (!isNumber(value)) {
    return '---';
  }
  switch (fieldType) {
    case FieldType.amount:
      return isSmallValue(value) ? getAmountAsStringUsingCurrency(value) : '\$${getAmountAsShorthandText(value)}';
    case FieldType.quantity:
      return formatDoubleUpToFiveZero(value);
    case FieldType.numeric:
    default:
      return isSmallValue(value) ? getIntAsText(value.toInt()) : getNumberShorthandText(value);
  }
}

bool isSmallValue(final num value) {
  return isBetween(value, -_smallValueThreshold, _smallValueThreshold);
}
