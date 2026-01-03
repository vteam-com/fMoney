import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/widgets/form_field_switch.dart';
import 'package:money/widgets/form_field_widget.dart';
import 'package:money/widgets/misc_widgets.dart';
import 'package:money/widgets/quantity_widget.dart';
import 'package:money/widgets/theme_custom.dart';
import 'package:money/widgets_data/money_object/field_filters.dart';
import 'package:money/widgets_data/money_object/field_type.dart';
import 'package:money/widgets_data/money_object/money_model.dart';
import 'package:money/widgets_data/money_object/money_widget.dart';
import 'package:money/widgets_data/money_object/mutation_types.dart';

// Exports
export 'package:money/widgets_data/money_object/field_type.dart';
export 'package:money/widgets_data/money_object/money_model.dart';
export 'package:money/widgets_data/money_object/mutation_types.dart';

dynamic defaultCallbackValue(final dynamic instance) => '';

bool defaultCallbackValueTrue(final dynamic instance) => true;

bool defaultCallbackValueFalse(final dynamic instance) => false;

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
          getValueForDisplay = (final MoneyObject c) => value as num;
          getValueForSerialization = getValueForDisplay;
        case FieldType.text:
          getValueForDisplay = (final MoneyObject objectInstance) => value.toString();
        case FieldType.amount:
          getValueForDisplay = (final MoneyObject c) => MoneyWidget(amountModel: value as MoneyModel);
        case FieldType.date:
          getValueForDisplay = (final MoneyObject c) => dateToString(value as DateTime?);
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
                final MoneyObject a,
                final MoneyObject b,
                final bool ascending,
              ) => sortByValue(
                (getValueForDisplay(a) ?? 0) as num,
                (getValueForDisplay(b) ?? 0) as num,
                ascending,
              );
        case FieldType.amount:
          sort =
              (
                final MoneyObject a,
                final MoneyObject b,
                final bool ascending,
              ) => sortByAmount(
                getValueForDisplay(a) as MoneyModel,
                getValueForDisplay(b) as MoneyModel,
                ascending,
              );
        case FieldType.date:
          sort =
              (
                final MoneyObject a,
                final MoneyObject b,
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
                final MoneyObject a,
                final MoneyObject b,
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
  Widget Function(MoneyObject, void Function(bool wasModified) onEdited)? getEditWidget;

  /// override the value edited
  dynamic Function(MoneyObject, dynamic)? setValue;

  /// Only need for FieldType.widget
  dynamic Function(MoneyObject)? getValueForReading;

  TextAlign align;
  ColumnWidth columnWidth;
  bool fixedFont = false;
  // indicate how to handle the column footer
  FooterType footer;

  /// Get the value
  dynamic Function(MoneyObject) getValue;

  /// Get the value of the instance
  dynamic Function(MoneyObject) getValueForDisplay;

  /// Get the value for storing the instance
  dynamic Function(MoneyObject) getValueForSerialization;

  // Static properties
  String name;

  String serializeName;
  FieldType type;
  // This properties are evaluated against the instance of the object
  bool Function(MoneyObject) useAsDetailPanels;

  int Function(MoneyObject, MoneyObject, bool)? sort;

  late T _value;

  String getBestFieldDescribingName() {
    if (serializeName.isNotEmpty) {
      return serializeName;
    }
    if (name.isNotEmpty) {
      return name;
    }
    return T.toString();
  }

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
        if (type is MoneyModel) {
          return (value as MoneyModel).toString();
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

  Widget getValueAsWidget(MoneyObject instance) {
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

  void setAmount(final dynamic newValue) {
    (this as FieldMoney).value.setAmount(newValue);
  }

  // ignore: unnecessary_getters_setters
  T get value {
    return _value;
  }

  set value(T v) {
    _value = v;
  }
}

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

class FieldId extends Field<int> {
  FieldId({super.getValueForDisplay, super.getValueForSerialization})
    : super(
        serializeName: 'Id',
        useAsDetailPanels: defaultCallbackValueFalse,
        defaultValue: -1,
        columnWidth: ColumnWidth.hidden,
      );
}

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

class FieldMoney extends Field<MoneyModel> {
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
         defaultValue: MoneyModel(amount: 0.00, autoColor: true),
         align: TextAlign.right,
         type: FieldType.amount,
       );
}

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
            final MoneyObject a,
            final MoneyObject b,
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
        fontFamily: 'RobotoMono',
        color: Get.context == null
            ? null
            : Theme.of(Get.context!).extension<MoneyThemeData>()?.getTextColorToUse(value as num),
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

class MoneyObject {
  factory MoneyObject.fromJSon(final MyJson json, final double runningBalance) {
    return MoneyObject();
  }
  MoneyObject();

  static void Function({
    required MutationType mutation,
    required MoneyObject moneyObject,
    bool recalculateBalances,
  })?
  onMutationChanged;

  static String Function(int id) getCategoryName = (int id) => id.toString();
  static double Function(String symbol) getCurrencyRatio = (String symbol) => 1.0;

  /// State of any and all object instances
  /// to indicated any alteration to the data set of the users
  /// to reflect on the customer CRUD actions [Create|Rename|Update|Delete]
  MutationType mutation = MutationType.none;

  MyJson? valueBeforeEdit;

  @override
  String toString() {
    final List<String> fieldsAsText = fieldDefinitions
        .where((Field<dynamic> field) => field.serializeName.isNotEmpty)
        .map(
          (Field<dynamic> field) => '${field.serializeName}:${field.getValueForSerialization(this)}',
        )
        .toList();

    return fieldsAsText.join('|');
  }

  ///
  /// Title       |
  /// ------------+ Right
  /// SubTitle    |
  ///
  /// Expect this to be override by the derived domain classes
  Widget buildFieldsAsWidgetForSmallScreen() => const Text('Small screen content goes here');

  ///
  /// Name: Bob
  /// Date: 2020-12-31
  List<Widget> buildListOfNamesValuesWidgets({
    void Function(bool wasModified)? onEdit,
    bool compact = false,
  }) {
    if (fieldDefinitions.isEmpty) {
      return <Widget>[Center(child: Text('No fields found for $this'))];
    }
    final List<Widget> widgets = <Widget>[];

    {
      final FieldDefinitions definitions = getFieldDefinitionsForPanel();

      for (final Field<dynamic> fieldDefinition in definitions) {
        final Widget widget = buildWidgetNameValueFromFieldDefinition(
          objectInstance: this,
          fieldDefinition: fieldDefinition,
          singleLineNameValue: compact, // when passing true, the onEdit is ignored
          onEdited: onEdit,
          isFirstItem: fieldDefinition == definitions.first,
          isLastItem: fieldDefinition == definitions.last,
        );
        widgets.add(
          Padding(
            padding: compact ? const EdgeInsets.all(0) : const EdgeInsets.all(SizeForPadding.normal),
            child: widget,
          ),
        );
      }
    }

    // Also add the MoneyObject ID
    widgets.add(
      Padding(
        padding: const EdgeInsets.all(SizeForPadding.medium),
        child: Opacity(
          opacity: 0.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('ID: '),
              SelectableText(uniqueId.toString()),
            ],
          ),
        ),
      ),
    );

    return widgets;
  }

  Widget buildWidgetNameValueFromFieldDefinition({
    required final MoneyObject objectInstance,
    required final Field<dynamic> fieldDefinition,
    required final bool singleLineNameValue,
    required final void Function(bool)? onEdited,
    final bool isFirstItem = false,
    final bool isLastItem = false,
  }) {
    final dynamic fieldValue = fieldDefinition.getValueForDisplay(
      objectInstance,
    );

    if (singleLineNameValue) {
      // simple [Name  Value] pair
      return _buildNameValuePair(fieldDefinition, fieldValue);
    }
    final bool isReadOnly = onEdited == null || fieldDefinition.setValue == null;

    final InputDecoration decoration = myFormFieldDecoration(
      fieldName: fieldDefinition.name,
      isReadOnly: isReadOnly,
    );

    // Editing Field
    if (!isReadOnly && fieldDefinition.getEditWidget != null) {
      // Editing mode and the MoneyObject has a custom edit widget
      return InputDecorator(
        decoration: InputDecoration(
          labelText: fieldDefinition.name,
          border: const OutlineInputBorder(),
        ),
        child: fieldDefinition.getEditWidget!(objectInstance, onEdited),
      );
    }

    // Read only
    switch (fieldDefinition.type) {
      case FieldType.toggle:
        if (isReadOnly) {
          return MyFormFieldForWidget(
            title: fieldDefinition.name,
            valueAsText: fieldDefinition.getValueForDisplay(objectInstance).toString(),
            isReadOnly: true,
            onChanged: (final String value) {},
          );
        }
        return InputDecorator(
          decoration: InputDecoration(
            labelText: fieldDefinition.name,
            border: const OutlineInputBorder(),
          ),
          child: SwitchFormField(
            title: fieldDefinition.name,
            initialValue: fieldDefinition.getValueForDisplay(objectInstance) as bool,
            isReadOnly: isReadOnly,
            validator: (bool? value) {
              /// Todo
              return null;
            },
            onSaved: (bool? value) {
              fieldDefinition.setValue?.call(objectInstance, value);
              onEdited(true);
            },
          ),
        );

      case FieldType.widget:
        final String valueAsString = fieldDefinition.getValueForSerialization(objectInstance).toString();
        return Opacity(
          opacity: isReadOnly ? 0.5 : 1.0,
          child: MyFormFieldForWidget(
            title: fieldDefinition.name,
            valueAsText: valueAsString,
            isReadOnly: isReadOnly,
            onChanged: (final String value) {
              fieldDefinition.setValue?.call(objectInstance, value);
              onEdited?.call(false);
            },
          ),
        );

      // all others will be a normal text input
      default:
        String value = fieldDefinition.getString(fieldValue);
        if (value.isEmpty && isReadOnly) {
          value = '';
        }
        return Row(
          children: <Widget>[
            Expanded(
              child: Opacity(
                opacity: isReadOnly ? 0.5 : 1.0,
                child: TextFormField(
                  initialValue: value,
                  decoration: decoration,
                  // allow mutation of the value
                  readOnly: isReadOnly,

                  onFieldSubmitted: (String value) {
                    onEdited?.call(false);
                  },
                  onEditingComplete: () {
                    onEdited?.call(false);
                  },
                  onChanged: (String newValue) {
                    fieldDefinition.setValue!(objectInstance, newValue);
                    onEdited?.call(false);
                  },
                ),
              ),
            ),
          ],
        );
    }
  }

  FieldDefinitions get fieldDefinitions => <Field<dynamic>>[];

  FieldDefinitions getFieldDefinitionsForPanel() {
    return fieldDefinitions.where((Field<dynamic> element) => element.useAsDetailPanels(this)).toList();
  }

  MyJson getMutatedDiff<T>() {
    final MyJson afterEditing = getPersistableJSon();
    return myJsonDiff(
      before: valueBeforeEdit ?? <String, dynamic>{},
      after: afterEditing,
    );
  }

  Color getMutationColor() {
    switch (mutation) {
      case MutationType.inserted:
        return Theme.of(Get.context!).extension<MoneyThemeData>()!.getColorForState(ColorState.success);
      case MutationType.changed:
        return Theme.of(Get.context!).extension<MoneyThemeData>()!.getColorForState(ColorState.warning);
      case MutationType.deleted:
        return Theme.of(Get.context!).extension<MoneyThemeData>()!.getColorForState(ColorState.error);
      default:
        return Colors.transparent;
    }
  }

  /// Serialize object instance to a JSon format
  MyJson getPersistableJSon() {
    final MyJson json = <String, dynamic>{};

    for (final Field<dynamic> field in fieldDefinitions) {
      if (field.serializeName != '') {
        json[field.serializeName] = field.getValueForSerialization(this);
      }
    }
    return json;
  }

  /// Return the best way to identify this instance, e.g. Name
  String getRepresentation() {
    return 'Id: $uniqueId'; // By default the ID is the best unique way
  }

  /// Return the where clause use to identify the unique storage identification of a row in the database
  /// for most table it will be " where Id='1' "
  String getWhereClause() {
    return 'Id=$uniqueId'; // By default the ID is the best unique way
  }

  bool get isChanged => mutation == MutationType.changed;

  static bool isDataModified(MoneyObject moneyObject) {
    final MyJson afterEditing = moneyObject.getPersistableJSon();
    final MyJson diff = myJsonDiff(
      before: moneyObject.valueBeforeEdit ?? <String, dynamic>{},
      after: afterEditing,
    );
    return diff.keys.isNotEmpty;
  }

  bool get isDeleted => mutation == MutationType.deleted;

  bool get isInserted => mutation == MutationType.inserted;

  bool isMutated<T>() {
    return getMutatedDiff<T>().keys.isNotEmpty;
  }

  void mutateField(
    final String fieldName,
    final dynamic newValue,
    final bool rebalance,
  ) {
    stashValueBeforeEditing();
    final Field<dynamic>? field = getFieldDefinitionByName(
      fieldDefinitions,
      fieldName,
    );
    if (field != null && field.setValue != null) {
      field.setValue!(this, newValue);
      onMutationChanged?.call(
        mutation: MutationType.changed,
        moneyObject: this,
        recalculateBalances: rebalance,
      );
    }
  }

  MoneyObject rollup(List<MoneyObject> moneyObjectInstances) {
    if (moneyObjectInstances.isEmpty) {
      return MoneyObject();
    }
    if (moneyObjectInstances.length == 1) {
      return moneyObjectInstances.first;
    }

    MyJson commonJson = moneyObjectInstances.first.getPersistableJSon();

    for (MoneyObject t in moneyObjectInstances.skip(1)) {
      commonJson = compareAndGenerateCommonJson(
        commonJson,
        t.getPersistableJSon(),
      );
    }
    return MoneyObject.fromJSon(commonJson, 0);
  }

  void stashValueBeforeEditing() {
    if (valueBeforeEdit == null) {
      valueBeforeEdit = getPersistableJSon();
    } else {
      // already stashed
    }
  }

  String toJsonString() {
    return getPersistableJSon().toString();
  }

  /// attempt to get text that a human could read
  String toReadableString(Field<dynamic> field) {
    switch (field.type) {
      case FieldType.widget:
        if (field.getValueForReading == null) {
          return field.getValueForSerialization(this).toString();
        } else {
          return field.getValueForReading!(this).toString();
        }
      case FieldType.text:
      default:
        return field.getValueForDisplay(this).toString();
    }
  }

  /// All object must have a unique identified
  int get uniqueId => -1;

  // must be implemented by derived classes
  set uniqueId(int value) {
    assert(false, 'derived class must implement uniqueId');
  }

  Widget _buildNameValuePair(
    Field<dynamic> fieldDefinition,
    final dynamic fieldValue,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: Text(fieldDefinition.name),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: fieldDefinition.getValueWidgetForDetailView(fieldValue),
            ),
          ),
        ],
      ),
    );
  }
}

/// Return the first element of type T in a list given a list of possible index;
T? getMoneyObjectFromFirstSelectedId<T>(
  final List<int> selectedIds,
  final List<dynamic> listOfItems,
) {
  if (selectedIds.isNotEmpty) {
    final int id = selectedIds.first;
    return listOfItems.firstWhereOrNull(
          (final dynamic element) => (element as MoneyObject).uniqueId == id,
        )
        as T?;
  }
  return null;
}
