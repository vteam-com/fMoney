// ignore: fcheck_one_class_per_file

import 'package:flutter/material.dart';
import 'package:money/data/models/field_filter_model.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/pure/quantity_widget.dart';
import 'package:money/widgets/pure/scale_down_widget.dart';
import 'package:money/widgets/pure/theme_custom_model.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/field_filters_model.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const double _percentZeroOpacity = 0.4;
const double _percentNonZeroOpacity = 1.0;
const double _percentSymbolOpacity = 0.8;
const int _percentValueScale = 100;
const int _percentDecimalPlaces = 3;
const double _percentSymbolFontSize = 9;

/// Default callback that returns an empty string.
dynamic defaultCallbackValue(final DataInterface _) => '';

/// Default callback that always returns true.
bool defaultCallbackValueTrue(final DataInterface _) => true;

/// Default callback that always returns false.
bool defaultCallbackValueFalse(final DataInterface _) => false;

/// A generic class representing a field in a data model.
///
/// This class is designed to be flexible and can handle various types of fields
/// commonly found in financial and data management applications. It provides
/// properties and methods for managing field values, display, serialization,
/// and UI representation.
///
/// Type parameter:
/// - T: The type of the field's value.
///
/// Key features:
/// - Supports various field types through the [FieldType] enum.
/// - Customizable display and serialization methods.
/// - Configurable UI properties like alignment and column width.
/// - Support for footer calculations in list views.
/// - Flexible value getting and setting mechanisms.

class Field<T> {
  Field({
    // Value related
    required final T defaultValue,
    this.name = '',
    this.serializeName = '',
    this.type = FieldType.text,
    this.align = TextAlign.left,
    this.useAsDetailPanels = defaultCallbackValueTrue,
    this.columnWidth = ColumnWidth.normal,
    this.footer = FooterType.none,
    this.fixedFont = false,
    this.getValue = defaultCallbackValue,
    this.getValueForDisplay = defaultCallbackValue,
    // ignore: avoid_init_to_null
    this.getValueForReading = null,
    this.getValueForSerialization = defaultCallbackValue,
    this.getEditWidget,
    this.setValue,
    this.sort,
  }) {
    ///----------------------------------------------
    /// default value for this field
    value = defaultValue;

    ///----------------------------------------------
    /// The name for this field
    if (name.isEmpty) {
      name = serializeName;
    }

    ///----------------------------------------------
    /// How to get the value of this field
    if (getValueForDisplay == defaultCallbackValue) {
      switch (this.type) {
        case FieldType.numeric:
        case FieldType.quantity:
          getValueForDisplay = (final DataInterface _) => value as num;
          getValueForSerialization = getValueForDisplay;
        case FieldType.text:
          getValueForDisplay = (final DataInterface _) => value.toString();
        case FieldType.amount:
          getValueForDisplay = (final DataInterface _) => WidgetFromData(amountModel: value as AmountModel);
        case FieldType.date:
          getValueForDisplay = (final DataInterface _) => dateToString(value as DateTime?);
        default:
          //
          debugPrint('No match');
      }
    }

    ///----------------------------------------------
    /// How to serialize this field
    if (getValueForSerialization == defaultCallbackValue) {
      // if there's no override function
      // apply the same data value to serial
      getValueForSerialization = getValueForDisplay;
    }

    ///----------------------------------------------
    /// How to Sort on this field
    if (sort == null) {
      // if no override on sorting fallback to type sorting
      switch (this.type) {
        case FieldType.numeric:
        case FieldType.numericShorthand:
        case FieldType.quantity:
        case FieldType.amountShorthand:
          sort =
              (
                final DataInterface a,
                final DataInterface b,
                final bool ascending,
              ) => sortByValue(
                (getValueForDisplay(a) ?? 0) as num,
                (getValueForDisplay(b) ?? 0) as num,
                ascending,
              );
        case FieldType.amount:
          sort =
              (
                final DataInterface a,
                final DataInterface b,
                final bool ascending,
              ) => sortByAmount(
                getValueForDisplay(a) as AmountModel,
                getValueForDisplay(b) as AmountModel,
                ascending,
              );
        case FieldType.date:
          sort =
              (
                final DataInterface a,
                final DataInterface b,
                final bool ascending,
              ) => sortByDate(
                getValueForDisplay(a) as DateTime?,
                getValueForDisplay(b) as DateTime?,
                ascending,
              );
        case FieldType.text:
        default:
          sort =
              (
                final DataInterface a,
                final DataInterface b,
                final bool ascending,
              ) => sortByString(
                getValueForDisplay(a).toString(),
                getValueForDisplay(b).toString(),
                ascending,
              );
      }
    }
  }

  /// Customize/override the edit widget
  Widget Function(DataInterface, void Function(bool /* wasModified */) onEdited)? getEditWidget;

  /// override the value edited
  dynamic Function(DataInterface, dynamic)? setValue;

  /// Only need for FieldType.widget
  dynamic Function(DataInterface)? getValueForReading;

  TextAlign align;
  ColumnWidth columnWidth;
  bool fixedFont = false;
  // indicate how to handle the column footer
  FooterType footer;

  /// Get the value
  dynamic Function(DataInterface) getValue;

  /// Get the value of the instance
  dynamic Function(DataInterface) getValueForDisplay;

  /// Get the value for storing the instance
  dynamic Function(DataInterface) getValueForSerialization;

  // Static properties
  String name;

  String serializeName;
  FieldType type;
  // This properties are evaluated against the instance of the object
  bool Function(DataInterface) useAsDetailPanels;

  int Function(DataInterface, DataInterface, bool)? sort;

  late T _value;

  /// Returns the best name to use for this field in headers and CSV output.
  String getBestFieldDescribingName() {
    if (serializeName.isNotEmpty) {
      return serializeName;
    }
    if (name.isNotEmpty) {
      return name;
    }
    return T.toString();
  }

  /// Returns a string representation for [value] based on this field's type.
  String getString(final dynamic value) {
    switch (type) {
      case FieldType.numeric:
        return value.toString();
      case FieldType.numericShorthand:
        return getAmountAsShorthandText(value as num);
      case FieldType.quantity:
      case FieldType.percentage:
        return formatDoubleUpToFiveZero(value as double);
      case FieldType.amount:
        if (type is AmountModel) {
          return (value as AmountModel).toString();
        }
        if (value is double) {
          return getAmountAsStringUsingCurrency(value);
        }
        return value.toString();
      case FieldType.amountShorthand:
        return getAmountAsShorthandText(value as double);
      case FieldType.widget:
        return value as String;
      case FieldType.text:
      default:
        return value.toString();
    }
  }

  /// Returns the field value rendered as a widget for the given [instance].
  Widget getValueAsWidget(DataInterface instance) {
    final dynamic value = this.getValueForDisplay(instance);
    if (value is Widget) {
      return value;
    }

    return buildWidgetFromTypeAndValue(
      value: value,
      type: type,
      align: align,
      fixedFont: fixedFont,
    );
  }

  /// Builds a widget suitable for detail view display for [value].
  Widget getValueWidgetForDetailView(final dynamic value) {
    if (type == FieldType.widget) {
      return value as Widget;
    } else {
      return SelectableText(
        textAlign: TextAlign.right,
        getString(value),
        maxLines: 1,
        // overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }
  }

  /// Sets the amount model value for money fields.
  void setAmount(final dynamic newValue) {
    (this as FieldMoney).value.setAmount(newValue);
  }

  /// Gets the current field value.
  // ignore: unnecessary_getters_setters
  T get value {
    return _value;
  }

  /// Sets the current field value.
  set value(T v) {
    _value = v;
  }
}

/// Represents field date.
class FieldDate extends Field<DateTime?> {
  FieldDate({
    super.name,
    super.serializeName,
    super.getValueForDisplay,
    super.getValueForSerialization,
    super.setValue,
    super.useAsDetailPanels,
    super.sort,
    super.columnWidth = ColumnWidth.tiny,
    super.getEditWidget,
  }) : super(
         defaultValue: null,
         align: TextAlign.left,
         type: FieldType.date,
         footer: FooterType.range,
       );
}

/// Represents field double.
class FieldDouble extends Field<double> {
  FieldDouble({
    super.name,
    super.serializeName,
    super.getValueForDisplay,
    super.getValueForSerialization,
    super.defaultValue = 0.00,
    super.useAsDetailPanels,
    super.sort,
  }) : super(align: TextAlign.right, type: FieldType.numeric);
}

/// Represents field percentage.
class FieldPercentage extends Field<double> {
  FieldPercentage({
    super.name,
    super.serializeName,
    super.getValueForDisplay,
    super.getValueForSerialization,
    super.defaultValue = 0.000,
    super.useAsDetailPanels,
    super.sort,
  }) : super(
         align: TextAlign.right,
         type: FieldType.percentage,
         fixedFont: true,
       );
}

/// Represents field id.
class FieldId extends Field<int> {
  FieldId({super.getValueForDisplay, super.getValueForSerialization})
    : super(
        serializeName: SharedStrings.fieldId,
        useAsDetailPanels: defaultCallbackValueFalse,
        defaultValue: -1,
        columnWidth: ColumnWidth.hidden,
      );
}

/// Represents field int.
class FieldInt extends Field<int> {
  FieldInt({
    super.name,
    super.serializeName,
    super.getValueForDisplay,
    super.getValueForSerialization,
    super.getValueForReading,
    super.columnWidth,
    super.useAsDetailPanels,
    super.defaultValue = -1,
    super.setValue,
    super.getEditWidget,
    super.sort,
    super.align = TextAlign.right,
    super.type = FieldType.numeric,
    super.footer = FooterType.sum,
  });
}

/// Represents field money.
class FieldMoney extends Field<AmountModel> {
  FieldMoney({
    super.name,
    super.serializeName,
    super.getValueForDisplay,
    super.getValueForSerialization,
    super.setValue,
    super.columnWidth = ColumnWidth.small,
    super.footer = FooterType.sum,
    super.useAsDetailPanels,
    super.sort,
  }) : super(
         defaultValue: AmountModel(amount: 0.00, autoColor: true),
         align: TextAlign.right,
         type: FieldType.amount,
       );
}

/// Represents field quantity.
class FieldQuantity extends Field<double> {
  FieldQuantity({
    super.name,
    super.serializeName,
    super.getValueForDisplay,
    super.getValueForSerialization,
    super.setValue,
    super.columnWidth = ColumnWidth.small,
    super.useAsDetailPanels,
    super.defaultValue = 0,
    super.align = TextAlign.right,
    super.type = FieldType.quantity,
    super.footer = FooterType.sum,
    super.sort,
  });
}

/// Represents field string.
class FieldString extends Field<String> {
  FieldString({
    super.name,
    super.serializeName,
    super.getValueForDisplay,
    super.getValueForReading,
    super.getValueForSerialization,
    super.columnWidth,
    super.useAsDetailPanels = defaultCallbackValueTrue,
    super.align = TextAlign.left,
    super.fixedFont = false,
    super.getEditWidget,
    super.setValue,
    super.type = FieldType.text,
    super.footer = FooterType.count,
    super.sort,
  }) : super(defaultValue: '') {
    if (sort == null) {
      super.sort =
          (
            final DataInterface a,
            final DataInterface b,
            final bool ascending,
          ) {
            return sortByString(
              getValueForDisplay(a),
              getValueForDisplay(b),
              ascending,
            );
          };
    }
  }
}

/// Represents fields.
class Fields<T> {
  /// Constructor
  Fields() {
    assert(T != dynamic, SharedStrings.errorTypeTCannotBeDynamic);
  }

  final FieldDefinitions definitions = <Field<dynamic>>[];

  /// Returns true if [objectInstance] matches free-text and/or column filters.
  bool applyFilters(
    final DataInterface objectInstance,
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

  /// Returns the field definition with the given [name].
  Field<dynamic> getFieldByName(final String name) {
    return definitions.firstWhere((Field<dynamic> field) => field.name == name);
  }

  /// Used in table view
  static Widget getRowOfColumns(
    final FieldDefinitions definitions,
    final DataInterface objectInstance,
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
              padding: const EdgeInsets.fromLTRB(SizeForPadding.nano, 0, SizeForPadding.nano, 0),
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

  /// Returns true if this field definition list has no entries.
  bool get isEmpty => definitions.isEmpty;

  /// Returns true if [objectInstance] matches all column filters.
  bool isMatchingColumnFiltering(
    final DataInterface objectInstance,
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

  /// Returns true if any field contains [filterBytFreeStyleLowerCaseText].
  bool isMatchingFreeStyleText(
    DataInterface objectInstance,
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

  /// Replaces current definitions with [list].
  void setDefinitions(List<Field<dynamic>> list) {
    definitions.clear();
    for (Field<dynamic> object in list) {
      definitions.add(object);
    }
  }

  DateTime _getFieldValueAsDate(
    final DataInterface objectInstance,
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
    final DataInterface objectInstance,
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

/// This is the base class for all field types.
/// It defines common properties and methods that are shared across different field types.

typedef FieldDefinitions = List<Field<dynamic>>;

/// This enum defines the different column widths that can be used for displaying fields in a table or grid layout.
enum ColumnWidth {
  hidden, // 0
  nano, // 1
  tiny, // 1
  small, // 2
  normal, // 3
  large, // 4
  largest, // 5
}

enum FooterType {
  none,
  count,
  countNotEmpty, // TODO   12/50 (24%) - meaning 12 rows out of 50 have data, should this be shown in Percentage?
  sum,
  average,
  range,
}

/// Returns the field definition that matches [nameToFind] by name or serialize name.
Field<dynamic>? getFieldDefinitionByName(
  final FieldDefinitions fields,
  final String nameToFind,
) {
  for (final Field<dynamic> f in fields) {
    if (f.name == nameToFind) {
      return f;
    }
    if (f.serializeName == nameToFind) {
      return f;
    }
  }
  return null;
}

/// Builds a display widget for a field [value] based on [type].
Widget buildWidgetFromTypeAndValue({
  required final dynamic value,
  required final FieldType type,
  required final TextAlign align,
  required final bool fixedFont,
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

/// Builds an amount widget, optionally using shorthand formatting.
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
          : getAmountAsStringUsingCurrency(
              value,
              iso4217code: currency,
            ),
      textAlign: align,
      style: TextStyle(
        fontFamily: SharedStrings.fontRobotoMono,
        color: AppRouter.context == null
            ? null
            : Theme.of(AppRouter.context!).extension<MoneyThemeData>()?.getTextColorToUse(value as num),
      ),
    ),
    textAlignToAlignment(align),
  );
}

/// Builds a date widget for [date].
Widget buildFieldWidgetForDate({
  final DateTime? date,
  final TextAlign align = TextAlign.left,
}) {
  return Text(
    dateToString(date),
    textAlign: align,
    overflow: TextOverflow.ellipsis, // Clip with ellipsis
    maxLines: 1, // Restrict to single line,
    style: const TextStyle(fontFamily: SharedStrings.fontRobotoMono),
  );
}

/// Builds a numeric widget for [value], optionally using shorthand formatting.
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
      style: const TextStyle(fontFamily: SharedStrings.fontRobotoMono),
    ),
    textAlignToAlignment(align),
  );
}

/// Builds a percentage widget using an opacity style for zero vs non-zero values.
Widget buildFieldWidgetForPercentage({final double value = 0}) {
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
  final String text = '',
  final TextAlign align = TextAlign.left,
  final bool fixedFont = false,
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
Alignment textAlignToAlignment(final TextAlign textAlign) {
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
