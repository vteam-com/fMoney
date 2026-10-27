// ignore: fcheck_one_class_per_file
import 'dart:ui' show Color;

import 'package:money/data/models/data_interface.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';

const Color _transparent = Color(0x00000000);

/// Represents data object.
abstract class DataObject extends DataInterface {
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

  /// Returns a color for the right-side adornment stripe of a list row.
  /// Subclasses may override to provide per-row right-edge accent colors.
  Color getRightAdornmentColor() => _transparent;

  /// Returns true when this row should display the top cap for the right
  /// adornment stripe.
  bool getShowRightAdornmentTopCap() => false;

  /// Returns true when this row should display the bottom cap for the right
  /// adornment stripe.
  bool getShowRightAdornmentBottomCap() => false;

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
    return '${SharedStrings.idPrefixReadable}$uniqueId'; // By default the ID is the best unique way
  }

  /// Return the where clause use to identify the unique storage identification of a row in the database
  /// for most table it will be " where Id='1' "
  String getWhereClause() {
    return '${SharedStrings.idPrefixWhere}$uniqueId'; // By default the ID is the best unique way
  }

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
    String fieldName,
    dynamic newValue,
    bool rebalance,
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
  ///
  /// Rolling up several items needs an entity-specific factory, so only subclasses that
  /// override this (e.g. Transaction) support it; the base version handles a single item.
  DataObject rollup(List<DataObject> moneyObjectInstances) {
    if (moneyObjectInstances.length == 1) {
      return moneyObjectInstances.first;
    }
    assert(moneyObjectInstances.isEmpty, SharedStrings.errorRollupNeedsEntityOverride);
    return EmptyDataObject();
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
      case FieldType.numeric:
      case FieldType.numericShorthand:
      case FieldType.quantity:
      case FieldType.percentage:
      case FieldType.amount:
      case FieldType.amountShorthand:
      case FieldType.date:
      case FieldType.dateRange:
      case FieldType.toggle:
        return field.getValueForDisplay(this).toString();
    }
  }
}

/// Placeholder [DataObject] with no fields, used where a concrete entity
/// cannot be built (e.g. the base [DataObject.rollup] of several instances).
class EmptyDataObject extends DataObject {
  /// Creates an empty placeholder whose [uniqueId] starts unset.
  EmptyDataObject();

  int _uniqueId = -1;

  @override
  int get uniqueId => _uniqueId;

  @override
  set uniqueId(int value) => _uniqueId = value;
}
