import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money/helpers/accumulator.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/widgets/misc_widgets.dart';
import 'package:money/widgets/theme_custom.dart';
import 'package:money/widgets_data/money_object/currencies/currency.dart';
import 'package:money/widgets_data/money_object/field_type.dart';

export 'package:flutter/material.dart';
export 'package:money/widgets/misc_widgets.dart';

Widget getFooterForDateRange(final DateRange dateRange) {
  return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final bool showDates = constraints.maxWidth > 80;
      return DefaultTextStyle(
        style: const TextStyle(
          fontSize: 10,
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
              dateRange.toStringDuration().padLeft(10),
              softWrap: true,
              maxLines: 2,
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
        prefix + Currency.getAmountAsStringUsingCurrency(amount),
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
    builder: (BuildContext context, BoxConstraints constraints) {
      final bool showLabels = constraints.maxWidth > 60;
      final double min = range.range.min.toDouble();
      final double max = range.range.max.toDouble();
      final double avg = range.getAverage();

      return DefaultTextStyle(
        style: const TextStyle(
          fontSize: 9,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatValue(avg, fieldType),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatValue(max, fieldType),
                maxLines: 1,
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
      return isSmallValue(value)
          ? Currency.getAmountAsStringUsingCurrency(value)
          : '\$${getAmountAsShorthandText(value)}';
    case FieldType.quantity:
      return formatDoubleUpToFiveZero(value);
    case FieldType.numeric:
    default:
      return isSmallValue(value) ? getIntAsText(value.toInt()) : getNumberShorthandText(value);
  }
}

bool isSmallValue(final num value) {
  return isBetween(value, -10000, 10000);
}
