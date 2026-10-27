import 'package:flutter/material.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/pure/display_date.dart';
import 'package:money/widgets/pure/quantity_widget.dart';
import 'package:money/widgets/pure/scale_down_widget.dart';
import 'package:money/widgets/pure/theme_custom_model.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/data_object_widget_builders_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const double _percentZeroOpacity = 0.4;
const double _percentNonZeroOpacity = 1.0;
const double _percentSymbolOpacity = 0.8;
const int _percentValueScale = 100;
const int _percentDecimalPlaces = 3;
const double _percentSymbolFontSize = 9;

/// Returns the generic widget for [field] on [instance], based on the field type only.
Widget buildFieldValueWidget(DataInterface instance, Field<dynamic> field) {
  return buildWidgetFromTypeAndValue(
    value: field.getValueForDisplay(instance),
    type: field.type,
    align: field.align,
    fixedFont: field.fixedFont,
  );
}

/// Builds the generic detail-view widget for a [field] [value].
Widget buildFieldValueWidgetForDetailView(Field<dynamic> field, dynamic value) {
  return SelectableText(
    textAlign: TextAlign.right,
    field.getString(value),
    maxLines: 1,
    style: const TextStyle(fontWeight: FontWeight.bold),
  );
}

/// Returns the cell widget for [field] on [instance], preferring the entity-specific widget from [builders].
Widget buildFieldCellWidget(DataObject instance, Field<dynamic> field, DataObjectWidgetBuilders builders) {
  return builders.buildFieldWidget(instance, field) ?? buildFieldValueWidget(instance, field);
}

/// Builds a table row for [objectInstance], one cell per visible field.
Widget buildRowOfColumns(
  FieldDefinitions definitions,
  DataObject objectInstance,
  DataObjectWidgetBuilders builders,
) {
  final List<Widget> cells = <Widget>[];

  for (final Field<dynamic> fieldDefinition in definitions) {
    if (fieldDefinition.columnWidth != ColumnWidth.hidden) {
      cells.add(
        Expanded(
          flex: fieldDefinition.columnWidth.index,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(SizeForPadding.nano, 0, SizeForPadding.nano, 0),
            child: buildFieldCellWidget(objectInstance, fieldDefinition, builders),
          ),
        ),
      );
    }
  }

  return Row(children: cells);
}

/// Builds a display widget for a field [value] based on [type].
Widget buildWidgetFromTypeAndValue({
  required dynamic value,
  required FieldType type,
  required TextAlign align,
  required bool fixedFont,
  String currency = Constants.defaultCurrency,
}) {
  keepUnused(currency);
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
      if (value is AmountModel) {
        return WidgetFromData(amountModel: value);
      }
      return WidgetFromData(amountModel: AmountModel(amount: value as double));

    // Amount short hand
    case FieldType.amountShorthand:
      return buildFieldWidgetForAmount(
        value: value,
        shorthand: true,
        align: align,
      );

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
        DisplayDate(date: value as DateTime?, align: align),
        Alignment.centerLeft,
      );

    // Widget fields without an entity-specific widget fall back to their text value
    case FieldType.widget:
      if (value is Widget) {
        return value;
      }
      return buildFieldWidgetForText(
        text: value.toString(),
        align: align,
        fixedFont: fixedFont,
      );

    case FieldType.text:
    case FieldType.dateRange:
    case FieldType.toggle:
      return buildFieldWidgetForText(
        text: value.toString(),
        align: align,
        fixedFont: fixedFont,
      );
  }
}

/// Builds an amount widget, optionally using shorthand formatting.
Widget buildFieldWidgetForAmount({
  dynamic value = 0,
  String currency = Constants.defaultCurrency,
  bool shorthand = false,
  TextAlign align = TextAlign.right,
}) {
  return scaleDown(
    Text(
      shorthand
          ? getAmountAsShorthandText(value as num)
          : getAmountAsStringUsingCurrency(
              value,
              iso4217code: currency,
            ),
      textAlign: align,
      style: TextStyle(
        fontFamily: SharedStrings.fontRobotoMono,
        color: AppRouter.context?.colorTheme.getTextColorToUse(value as num),
      ),
    ),
    textAlignToAlignment(align),
  );
}

/// Builds a numeric widget for [value], optionally using shorthand formatting.
Widget buildFieldWidgetForNumber({
  num value = 0,
  bool shorthand = false,
  TextAlign align = TextAlign.right,
}) {
  return scaleDown(
    Text(
      shorthand
          ? (value is double ? getAmountAsShorthandText(value) : getNumberShorthandText(value))
          : value.toString(),
      textAlign: align,
      style: const TextStyle(fontFamily: SharedStrings.fontRobotoMono),
    ),
    textAlignToAlignment(align),
  );
}

/// Builds a percentage widget using an opacity style for zero vs non-zero values.
Widget buildFieldWidgetForPercentage({double value = 0}) {
  // 0.000 to 100.000%
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: <Widget>[
      Opacity(
        opacity: value == 0 ? _percentZeroOpacity : _percentNonZeroOpacity,
        child: Text(
          (value * _percentValueScale).toStringAsFixed(_percentDecimalPlaces),
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: SharedStrings.fontRobotoMono),
        ),
      ),
      const Opacity(
        opacity: _percentSymbolOpacity,
        child: Text(' %', style: TextStyle(fontSize: _percentSymbolFontSize)),
      ),
    ],
  );
}

/// Builds a text widget using either fixed-width or proportional font.
Widget buildFieldWidgetForText({
  String text = '',
  TextAlign align = TextAlign.left,
  bool fixedFont = false,
}) {
  return Text(
    text,
    textAlign: align,
    overflow: TextOverflow.ellipsis, // Clip with ellipsis
    maxLines: 1, // Restrict to single line,
    style: TextStyle(
      fontFamily: fixedFont ? SharedStrings.fontRobotoMono : SharedStrings.fontRobotoFlex,
    ),
  );
}

/// Converts a [TextAlign] to a corresponding [Alignment].
Alignment textAlignToAlignment(TextAlign textAlign) {
  switch (textAlign) {
    case TextAlign.left:
      return Alignment.centerLeft;
    case TextAlign.center:
      return Alignment.center;
    case TextAlign.right:
    default:
      return Alignment.centerRight;
  }
}
