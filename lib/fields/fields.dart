// Imports
import 'package:flutter/material.dart';
import 'package:money/fields/field_filters.dart';
import 'package:money/fields/money_objects.dart';

// Exports
export 'package:money/fields/field.dart';

/// Manages a collection of field definitions for a specific data type.
///
/// The `Fields<T>` class provides a way to define and manage a set of fields
/// associated with a specific data type `T`. It allows you to:
///
/// - Define field definitions, including their name, type, and other properties.
/// - Retrieve the field definitions that should be used as columns.
/// - Check if the field definitions are empty.
/// - Apply filters to a `MoneyObject` instance based on free-style text search
///   and column-based filtering.
/// - Get a list of field values as strings for a given `MoneyObject` instance.
/// - Generate a row of columns for a table view based on the field definitions.
/// - Set the field definitions for the class.
///
/// The `Fields<T>` class is designed to be used in the context of the
/// `MoneyTools/MoneyFlutter` project, where it plays a crucial role in
/// managing the fields and filtering functionality for the application.
///
/// @param ```<T>``` The data type associated with the field definitions.
class Fields<T> {
  /// Constructor
  Fields() {
    assert(T != dynamic, 'Type T cannot be dynamic');
  }

  final FieldDefinitions definitions = <Field<dynamic>>[];

  bool applyFilters(
    final MoneyObject objectInstance,
    final String filterBytFreeStyleLowerCaseText, // Optional empty string
    final FieldFilters filterByFieldsValue, // Optional empty array
  ) {
    // Optimize - Simple case of using partial text search in all fields, no Column field filtering
    if (filterByFieldsValue.isEmpty) {
      // If no field filters are provided, check if the lowerCaseTextToFind matches
      return isMatchingFreeStyleText(
        objectInstance,
        filterBytFreeStyleLowerCaseText,
      );
    }

    // Optimize - Looking for column matching
    if (filterBytFreeStyleLowerCaseText.isEmpty) {
      return isMatchingColumnFiltering(objectInstance, filterByFieldsValue);
    }

    // Looking for Both freestyle text and column filtering, both condition needs to be met
    return isMatchingFreeStyleText(
          objectInstance,
          filterBytFreeStyleLowerCaseText,
        ) &&
        isMatchingColumnFiltering(objectInstance, filterByFieldsValue);
  }

  Field<dynamic> getFieldByName(final String name) {
    return definitions.firstWhere((Field<dynamic> field) => field.name == name);
  }

  /// Used in table view
  static Widget getRowOfColumns(
    final FieldDefinitions definitions,
    final MoneyObject objectInstance,
  ) {
    final List<Widget> cells = <Widget>[];

    for (final Field<dynamic> fieldDefinition in definitions) {
      if (fieldDefinition.columnWidth != ColumnWidth.hidden) {
        final dynamic value = fieldDefinition.getValueForDisplay(
          objectInstance,
        );
        cells.add(
          Expanded(
            flex: fieldDefinition.columnWidth.index,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
              child: buildWidgetFromTypeAndValue(
                value: value,
                type: fieldDefinition.type,
                align: fieldDefinition.align,
                fixedFont: fieldDefinition.fixedFont,
              ),
            ),
          ),
        );
      }
    }

    return Row(children: cells);
  }

  String getStringValueUsingFieldName(
    final MoneyObject objectInstance,
    final String fieldName,
  ) {
    final Field<dynamic>? fieldFound = definitions.firstWhereOrNull(
      (Field<dynamic> f) => f.name == fieldName,
    );
    if (fieldFound != null) {
      return _getFieldValueAsStringForFiltering(objectInstance, fieldFound);
    }
    return '';
  }

  bool get isEmpty => definitions.isEmpty;

  bool isMatchingColumnFiltering(
    final MoneyObject objectInstance,
    final FieldFilters filterByFieldsValue,
  ) {
    for (final FieldFilter filter in filterByFieldsValue.list) {
      final Field<dynamic> fieldDefinition = getFieldByName(filter.fieldName);
      if (filter.byDateRange) {
        // caller supplied a date range
        final DateTime date = _getFieldValueAsDate(
          objectInstance,
          fieldDefinition,
        );

        if (filter.asDateRange != null && filter.asDateRange!.isBetweenEqual(date) == false) {
          return false;
        }
      } else {
        // using a list of strings to match
        final String fieldValueAsString = _getFieldValueAsStringForFiltering(
          objectInstance,
          fieldDefinition,
        );
        if (!filter.contains(fieldValueAsString)) {
          return false;
        }
      }
    }
    return true;
  }

  // check if the lowerCaseTextToFind matches any of the fields text value
  bool isMatchingFreeStyleText(
    MoneyObject objectInstance,
    String filterBytFreeStyleLowerCaseText,
  ) {
    for (final Field<dynamic> fieldDefinition in definitions) {
      final String fieldValueAsString = _getFieldValueAsStringForFiltering(
        objectInstance,
        fieldDefinition,
      );

      if (fieldValueAsString.contains(filterBytFreeStyleLowerCaseText)) {
        return true;
      }
    }
    return false;
  }

  void setDefinitions(List<Field<dynamic>> list) {
    definitions.clear();
    for (Field<dynamic> object in list) {
      definitions.add(object);
    }
  }

  DateTime _getFieldValueAsDate(
    final MoneyObject objectInstance,
    final Field<dynamic> fieldDefinition,
  ) {
    final dynamic fieldValue = fieldDefinition.getValueForDisplay(
      objectInstance,
    );
    return fieldValue as DateTime;
  }

  /// Converts the given field value to a string representation suitable for filtering.
  ///
  /// For date fields, the value is converted to a string in the format "YYYY-MM-DD" without the time component.
  /// For all other field types, the value is converted to a lowercase string using the generic `toString()` method.
  ///
  /// This function is used to prepare field values for comparison during the filtering process.
  ///
  /// @param fieldDefinition The [Field] definition for the current field.
  /// @param fieldValue The value of the current field.
  /// @return The string representation of the field value, suitable for filtering.
  String _getFieldValueAsStringForFiltering(
    final MoneyObject objectInstance,
    final Field<dynamic> fieldDefinition,
  ) {
    switch (fieldDefinition.type) {
      case FieldType.widget:
        if (fieldDefinition.getValueForReading == null) {
          return fieldDefinition.getValueForSerialization(objectInstance).toString().toLowerCase();
        } else {
          return fieldDefinition.getValueForReading!(objectInstance) as String;
        }

      case FieldType.date:
        final dynamic fieldValue = fieldDefinition.getValueForDisplay(
          objectInstance,
        );
        return dateToString(fieldValue as DateTime?);

      case FieldType.quantity:
        final dynamic fieldValue = fieldDefinition.getValueForDisplay(
          objectInstance,
        );
        if (fieldValue is num) {
          return formatDoubleTrimZeros(fieldValue.toDouble());
        } else {
          return fieldValue.toString();
        }

      default:
        final dynamic fieldValue = fieldDefinition.getValueForDisplay(
          objectInstance,
        );
        return fieldValue.toString().toLowerCase();
    }
  }
}
