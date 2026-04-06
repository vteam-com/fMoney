import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

/// Builds a unique string list for text-like field values.
List<String> collectUniqueStringValues(
  List<DataObject> data,
  Field<dynamic> field,
) {
  final Set<String> values = <String>{};
  for (final DataObject item in data) {
    values.add(field.getValueForDisplay(item).toString());
  }
  return values.toList();
}

/// Builds a sorted unique list for date field values.
List<String> collectUniqueDateValues(
  List<DataObject> data,
  Field<dynamic> field,
) {
  final Set<String> values = <String>{};
  for (final DataObject item in data) {
    values.add(dateToString(field.getValueForDisplay(item) as DateTime?));
  }
  final List<String> uniqueValues = values.toList();
  uniqueValues.sort();
  return uniqueValues;
}

/// Builds a numerically sorted unique list for numeric field values.
List<String> collectUniqueNumericValues(
  List<DataObject> data,
  Field<dynamic> field,
) {
  final Set<String> values = <String>{};
  for (final DataObject item in data) {
    values.add(formatDoubleTrimZeros(field.getValueForDisplay(item) as double));
  }
  final List<String> uniqueValues = values.toList();
  uniqueValues.sort((String a, String b) => compareStringsAsNumbers(a, b));
  return uniqueValues;
}

/// Builds a sorted unique list for widget-readable field values.
List<String> collectUniqueWidgetValues(
  List<DataObject> data,
  Field<dynamic> field,
) {
  final Set<String> values = <String>{};
  for (final DataObject item in data) {
    final String value = field.getValueForReading?.call(item) as String? ?? '';
    values.add(value);
  }
  final List<String> uniqueValues = values.toList();
  uniqueValues.sort();
  return uniqueValues;
}
