import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/form_field_switch.dart';
import 'package:money/widgets/form_field_widget.dart';
import 'package:money/widgets/misc_widgets.dart';
import 'package:money/widgets/quantity_widget.dart';
import 'package:money/widgets/theme_custom.dart';
import 'package:money/widgets_data/field.dart';
import 'package:money/widgets_data/field_type.dart';
import 'package:money/widgets_data/money_model.dart';
import 'package:money/widgets_data/money_widget.dart';
import 'package:money/widgets_data/mutation_types.dart';

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
