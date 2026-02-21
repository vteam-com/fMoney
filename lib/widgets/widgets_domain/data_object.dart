import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/widgets/pure/form_field_switch.dart';
import 'package:money/widgets/pure/form_field_widget.dart';
import 'package:money/widgets/pure/mutation_types.dart';
import 'package:money/widgets/pure/theme_custom.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/field_type.dart';

const double _readOnlyOpacity = 0.5;
const double _editableOpacity = 1.0;
const double _dividerAlpha = 0.5;
const int _valueFlex = 2;
const double _labelPaddingRight = 10;

/// Represents data object.
class DataObject extends DataInterface {
  factory DataObject.fromJSon(final MyJson json, final double runningBalance) {
    keepUnused(json, runningBalance);
    return DataObject();
  }
  DataObject();

  static void Function({
    required MutationType mutation,
    required DataObject moneyObject,
    bool recalculateBalances,
  })?
  onMutationChanged;

  static String Function(int id) getCategoryName = (int id) => id.toString();
  static double Function(String symbol) getCurrencyRatio = (String _) => 1.0;

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
    void Function(bool /* wasModified */)? onEdit,
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
          opacity: _readOnlyOpacity,
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

  /// Builds a name/value widget for a specific [fieldDefinition] on [objectInstance].
  Widget buildWidgetNameValueFromFieldDefinition({
    required final DataObject objectInstance,
    required final Field<dynamic> fieldDefinition,
    required final bool singleLineNameValue,
    required final void Function(bool)? onEdited,
    final bool isFirstItem = false,
    final bool isLastItem = false,
  }) {
    keepUnused(isFirstItem, isLastItem);
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
            onChanged: (final String _) {},
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
            validator: (bool? _) {
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
          opacity: isReadOnly ? _readOnlyOpacity : _editableOpacity,
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
                opacity: isReadOnly ? _readOnlyOpacity : _editableOpacity,
                child: TextFormField(
                  initialValue: value,
                  decoration: decoration,
                  // allow mutation of the value
                  readOnly: isReadOnly,

                  onFieldSubmitted: (String _) {
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

  /// Returns the field definitions for this object instance.
  FieldDefinitions get fieldDefinitions => <Field<dynamic>>[];

  /// Returns the subset of fields that should be shown in detail panels.
  FieldDefinitions getFieldDefinitionsForPanel() {
    return fieldDefinitions.where((Field<dynamic> element) => element.useAsDetailPanels(this)).toList();
  }

  /// Returns a diff between stashed values and current values for this object.
  MyJson getMutatedDiff<T>() {
    final MyJson afterEditing = getPersistableJSon();
    return myJsonDiff(
      before: valueBeforeEdit ?? <String, dynamic>{},
      after: afterEditing,
    );
  }

  /// Returns a color representing the current mutation state.
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

  /// True if this object was modified.
  bool get isChanged => mutation == MutationType.changed;

  /// Returns true if [moneyObject] has any persisted changes compared to stashed values.
  static bool isDataModified(DataObject moneyObject) {
    final MyJson afterEditing = moneyObject.getPersistableJSon();
    final MyJson diff = myJsonDiff(
      before: moneyObject.valueBeforeEdit ?? <String, dynamic>{},
      after: afterEditing,
    );
    return diff.keys.isNotEmpty;
  }

  /// True if this object is marked as deleted.
  bool get isDeleted => mutation == MutationType.deleted;

  /// True if this object is newly inserted.
  bool get isInserted => mutation == MutationType.inserted;

  /// Returns true if any fields differ from the stashed values.
  bool isMutated<T>() {
    return getMutatedDiff<T>().keys.isNotEmpty;
  }

  /// Mutates a field by name and optionally triggers balance recalculation.
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

  /// Returns a rollup object with fields common across [moneyObjectInstances].
  DataObject rollup(List<DataObject> moneyObjectInstances) {
    if (moneyObjectInstances.isEmpty) {
      return DataObject();
    }
    if (moneyObjectInstances.length == 1) {
      return moneyObjectInstances.first;
    }

    MyJson commonJson = moneyObjectInstances.first.getPersistableJSon();

    for (DataObject t in moneyObjectInstances.skip(1)) {
      commonJson = compareAndGenerateCommonJson(
        commonJson,
        t.getPersistableJSon(),
      );
    }
    return DataObject.fromJSon(commonJson, 0);
  }

  /// Stashes current persisted values as the baseline for mutation tracking.
  void stashValueBeforeEditing() {
    if (valueBeforeEdit == null) {
      valueBeforeEdit = getPersistableJSon();
    } else {
      // already stashed
    }
  }

  /// Returns the persisted JSON for this object as a string.
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
  @override
  int get uniqueId => -1;

  // must be implemented by derived classes
  @override
  set uniqueId(int value) {
    assert(false, 'derived class must implement uniqueId');
  }

  /// Builds a compact name/value row used by detail panels.
  Widget _buildNameValuePair(
    Field<dynamic> fieldDefinition,
    final dynamic fieldValue,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: _dividerAlpha),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                0,
                0,
                _labelPaddingRight,
                0,
              ),
              child: Text(fieldDefinition.name),
            ),
          ),
          Expanded(
            flex: _valueFlex,
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
