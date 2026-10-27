import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/string_helper.dart';

/// This enum defines the different types of fields supported
enum FieldType {
  text,
  numeric,
  numericShorthand,
  quantity,
  percentage,
  amount,
  amountShorthand,
  date,
  dateRange,
  toggle, // On/Off
  widget;

  /// Returns how to turn a field value into its default display value, or null when this type has no default.
  dynamic Function(dynamic)? get defaultDisplayConverter => switch (this) {
    FieldType.numeric || FieldType.quantity => (dynamic number) => number as num,
    FieldType.text => (dynamic text) => text.toString(),
    FieldType.amount => (dynamic amount) => amount as AmountModel,
    FieldType.date => (dynamic date) => dateToString(date as DateTime?),
    FieldType.numericShorthand ||
    FieldType.percentage ||
    FieldType.amountShorthand ||
    FieldType.dateRange ||
    FieldType.toggle ||
    FieldType.widget => null,
  };

  /// Compares two display values of this type for the default column sort.
  int compareDisplayValues(dynamic a, dynamic b, bool ascending) => switch (this) {
    FieldType.numeric ||
    FieldType.numericShorthand ||
    FieldType.quantity ||
    FieldType.amountShorthand => sortByValue((a ?? 0) as num, (b ?? 0) as num, ascending),
    FieldType.amount => sortByAmount(a as AmountModel, b as AmountModel, ascending),
    FieldType.date => sortByDate(a as DateTime?, b as DateTime?, ascending),
    FieldType.text ||
    FieldType.percentage ||
    FieldType.dateRange ||
    FieldType.toggle ||
    FieldType.widget => sortByString(a.toString(), b.toString(), ascending),
  };

  /// Formats [value] as text according to this type.
  String formatValue(dynamic value) => switch (this) {
    FieldType.numeric => value.toString(),
    FieldType.numericShorthand => getAmountAsShorthandText(value as num),
    FieldType.quantity || FieldType.percentage => formatDoubleUpToFiveZero(value as double),
    FieldType.amount => value is double ? getAmountAsStringUsingCurrency(value) : value.toString(),
    FieldType.amountShorthand => getAmountAsShorthandText(value as double),
    FieldType.widget => value as String,
    FieldType.text || FieldType.date || FieldType.dateRange || FieldType.toggle => value.toString(),
  };
}
