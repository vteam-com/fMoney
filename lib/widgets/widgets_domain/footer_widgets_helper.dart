import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/accumulator_helper.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/data/models/ranges_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/widgets/pure/display_date.dart';
import 'package:money/widgets/pure/scale_down_widget.dart';
import 'package:money/widgets/pure/theme_custom_model.dart';

const double _dateFooterMinWidth = 80;
const double _dateFooterFontSize = 10;
const int _dateDurationPadWidth = 10;
const int _dateDurationMaxLines = 2;
const double _numericFooterMinWidth = 60;
const double _numericFooterFontSize = 9;
const int _numericFooterMaxLines = 1;
const num _smallValueThreshold = 10000;

/// Builds a footer widget for a [DateRange] (min/max plus duration).
Widget getFooterForDateRange(DateRange dateRange) {
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
            if (showDates) DisplayDate(date: dateRange.min),
            if (showDates) DisplayDate(date: dateRange.max),
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

/// Builds a footer widget for a monetary [amount] in the [iso4217code] currency.
Widget getFooterForAmount(
  double amount, {
  String prefix = '',
  String iso4217code = Constants.defaultCurrency,
}) {
  return scaleDown(
    Text(
      prefix + _formatValue(amount, FieldType.amount, iso4217code: iso4217code),
      style: TextStyle(
        color: AppRouter.context!.colorTheme.colorBasedOnValue(amount),
        fontFamily: 'RobotoMono',
      ),
    ),
  );
}

/// Builds a footer widget for an integer-like numeric [value].
Widget getFooterForInt(
  num value, {
  bool applyColorBasedOnValue = true,
  String prefix = '',
}) {
  return scaleDown(
    Text(
      prefix + _formatValue(value.toDouble(), FieldType.numeric),
      style: TextStyle(
        color: applyColorBasedOnValue ? AppRouter.context!.colorTheme.colorBasedOnValue(value) : null,
        fontFamily: 'RobotoMono',
      ),
    ),
  );
}

/// Builds a footer widget that displays min/avg/max for a numeric [range]; amounts use the [iso4217code] currency.
Widget getFooterForNumericRange(
  RunningAverage range,
  FieldType fieldType, {
  String iso4217code = Constants.defaultCurrency,
}) {
  return LayoutBuilder(
    builder: (BuildContext _, BoxConstraints constraints) {
      final bool showLabels = constraints.maxWidth > _numericFooterMinWidth;
      final String min = _formatValue(range.range.min.toDouble(), fieldType, iso4217code: iso4217code);
      final String max = _formatValue(range.range.max.toDouble(), fieldType, iso4217code: iso4217code);
      final String avg = _formatValue(range.getAverage(), fieldType, iso4217code: iso4217code);

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
                      Text(AppL10n.tr(AppTranslationKeys.minLabel)),
                      Text(min, textAlign: TextAlign.right),
                    ],
                  ),
                  TableRow(
                    children: <Widget>[
                      Text(AppL10n.tr(AppTranslationKeys.avgLabel)),
                      Text(avg, textAlign: TextAlign.right),
                    ],
                  ),
                  TableRow(
                    children: <Widget>[
                      Text(AppL10n.tr(AppTranslationKeys.maxLabel)),
                      Text(max, textAlign: TextAlign.right),
                    ],
                  ),
                ],
              )
            else ...<Widget>[
              Text(
                min,
                maxLines: _numericFooterMaxLines,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                avg,
                maxLines: _numericFooterMaxLines,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                max,
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

/// Formats a footer [value] for [fieldType]: in full when small, as shorthand (e.g. "€12K") otherwise.
///
/// Amounts use the [iso4217code] currency.
String _formatValue(
  double value,
  FieldType fieldType, {
  String iso4217code = Constants.defaultCurrency,
}) {
  if (!isNumber(value)) {
    return '---';
  }
  switch (fieldType) {
    case FieldType.amount:
      return isSmallValue(value)
          ? getAmountAsStringUsingCurrency(value, iso4217code: iso4217code)
          : getAmountAsShortHandStringUsingCurrency(value, iso4217code: iso4217code);
    case FieldType.quantity:
      return formatDoubleUpToFiveZero(value);
    case FieldType.numeric:
    case FieldType.text:
    case FieldType.numericShorthand:
    case FieldType.percentage:
    case FieldType.amountShorthand:
    case FieldType.date:
    case FieldType.dateRange:
    case FieldType.toggle:
    case FieldType.widget:
      return isSmallValue(value) ? getIntAsText(value.toInt()) : getNumberShorthandText(value);
  }
}

/// Returns true if [value] is small enough to display without shorthand formatting.
bool isSmallValue(num value) {
  return isBetween(value, -_smallValueThreshold, _smallValueThreshold);
}
