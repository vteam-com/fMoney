import 'package:dotted_border/dotted_border.dart';
import 'package:money/core/helpers/color_helper.dart';
import 'package:money/core/helpers/date_helper.dart';
import 'package:money/core/helpers/string_helper.dart';
import 'package:money/core/widgets/money_widget.dart';
import 'package:money/core/widgets/quantity_widget.dart';
import 'package:money/data/models/fields/field.dart';
import 'package:money/data/models/money_objects/currencies/currency.dart';

// Exports
export 'package:flutter/material.dart';

/// If the space for rendering the widget is too small this will scale the widget to fit
Widget scaleDown(
  final Widget child, [
  AlignmentGeometry alignment = Alignment.center,
]) {
  return FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child);
}

///
///                                       ------
/// Display a border and a question mark | ?    |
///                                       ------
///
Widget buildDashboardWidget(final Widget child) {
  return DottedBorder(
    options: RoundedRectDottedBorderOptions(
      color: Colors.grey.shade600,
      padding: const EdgeInsets.symmetric(horizontal: SizeForPadding.medium),
      radius: const Radius.circular(3),
    ),

    child: child,
  );
}

extension ViewExtension on BuildContext {
  bool get isWidthSmall => MediaQuery.of(this).size.width <= Constants.screenWidthSmall;
  bool get isWidthMedium => MediaQuery.of(this).size.width <= Constants.screenWidthMedium;
  bool get isWidthLarge => MediaQuery.of(this).size.width > Constants.screenWidthMedium;
}

Widget buildFieldWidgetForAmount({
  final dynamic value = 0,
  final String currency = Constants.defaultCurrency,
  final bool shorthand = false,
  final TextAlign align = TextAlign.right,
}) {
  return scaleDown(
    Text(
      shorthand
          ? getAmountAsShorthandText(value as num)
          : Currency.getAmountAsStringUsingCurrency(
              value,
              iso4217code: currency,
            ),
      textAlign: align,
      style: TextStyle(
        fontFamily: 'RobotoMono',
        color: getTextColorToUse(value as num),
      ),
    ),
    textAlignToAlignment(align),
  );
}

Widget buildFieldWidgetForDate({
  final DateTime? date,
  final TextAlign align = TextAlign.left,
}) {
  return Text(
    dateToString(date),
    textAlign: align,
    overflow: TextOverflow.ellipsis, // Clip with ellipsis
    maxLines: 1, // Restrict to single line,
    style: const TextStyle(fontFamily: 'RobotoMono'),
  );
}

Widget buildFieldWidgetForNumber({
  final num value = 0,
  final bool shorthand = false,
  final TextAlign align = TextAlign.right,
}) {
  return scaleDown(
    Text(
      shorthand
          ? (value is double ? getAmountAsShorthandText(value) : getNumberShorthandText(value))
          : value.toString(),
      textAlign: align,
      style: const TextStyle(fontFamily: 'RobotoMono'),
    ),
    textAlignToAlignment(align),
  );
}

Widget buildFieldWidgetForPercentage({final double value = 0}) {
  // 0.000 to 100.000%
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: <Widget>[
      Opacity(
        opacity: value == 0 ? 0.4 : 1,
        child: Text(
          (value * 100).toStringAsFixed(3),
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'RobotoMono'),
        ),
      ),
      const Opacity(
        opacity: 0.8,
        child: Text(' %', style: TextStyle(fontSize: 9)),
      ),
    ],
  );
}

Widget buildFieldWidgetForText({
  final String text = '',
  final TextAlign align = TextAlign.left,
  final bool fixedFont = false,
}) {
  return Text(
    text,
    textAlign: align,
    overflow: TextOverflow.ellipsis, // Clip with ellipsis
    maxLines: 1, // Restrict to single line,
    style: TextStyle(fontFamily: fixedFont ? 'RobotoMono' : 'RobotoFlex'),
  );
}

Widget buildWidgetFromTypeAndValue({
  required final dynamic value,
  required final FieldType type,
  required final TextAlign align,
  required final bool fixedFont,
  String currency = Constants.defaultCurrency,
}) {
  switch (type) {
    // Numeric
    case FieldType.numeric:
      if (value is String) {
        return buildFieldWidgetForText(
          text: value,
          align: align,
          fixedFont: true,
        );
      }
      return buildFieldWidgetForNumber(
        value: value as num,
        shorthand: false,
        align: align,
      );

    // Numeric shorthand  12K
    case FieldType.numericShorthand:
      return buildFieldWidgetForNumber(
        value: value as num,
        shorthand: true,
        align: align,
      );

    // Quantity
    case FieldType.quantity:
      return Row(
        children: <Widget>[
          Expanded(
            child: (value is num)
                ? QuantityWidget(quantity: value.toDouble(), align: align)
                : Text(value.toString(), textAlign: align),
          ),
        ],
      );

    case FieldType.percentage:
      return buildFieldWidgetForPercentage(value: value as double);

    // Amount
    case FieldType.amount:
      if (value is String) {
        return buildFieldWidgetForText(
          text: value,
          align: align,
          fixedFont: true,
        );
      }
      if (value is MoneyModel) {
        return MoneyWidget(amountModel: value);
      }
      return MoneyWidget(amountModel: MoneyModel(amount: value as double));

    // Amount short hand
    case FieldType.amountShorthand:
      return buildFieldWidgetForAmount(
        value: value,
        shorthand: true,
        align: align,
      );

    // Widget
    case FieldType.widget:
      return value as Widget;

    // Date
    case FieldType.date:
      if (value is String) {
        return buildFieldWidgetForText(
          text: value,
          align: align,
          fixedFont: true,
        );
      }
      // Adapt to available space
      return scaleDown(
        buildFieldWidgetForDate(date: value as DateTime?, align: align),
        Alignment.centerLeft,
      );

    case FieldType.text:
    default:
      return buildFieldWidgetForText(
        text: value.toString(),
        align: align,
        fixedFont: fixedFont,
      );
  }
}
