import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:money/data/database_interface.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/widgets/pure/diff.dart';
import 'package:money/widgets/pure/gaps.dart';
import 'package:money/widgets/pure/mutation_types.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';

const int _unsetId = -1;
const int _zeroInt = 0;
const int _nextIdIncrement = 1;
const double _diffIdOpacity = 0.5;

/// Collection of MoneyObject as both List and Map
class MoneyObjects<T> {
  /// Constructor
  MoneyObjects();

  String collectionName = '';

  final List<DataObject> _list = <DataObject>[];
  final Map<num, DataObject> _map = <num, DataObject>{};

  /// Appends an existing money object to the collection.
  void appendMoneyObject(final DataObject moneyObject) {
    // assert(moneyObject.uniqueId != -1);

    _list.add(moneyObject);
    _map[moneyObject.uniqueId] = moneyObject;
  }

  /// Appends a new money object, assigns it a unique ID, and optionally fires notifications.
  DataObject appendNewMoneyObject(
    final DataObject moneyObject, {
    bool fireNotification = true,
  }) {
    assert(moneyObject.uniqueId == _unsetId);

    // assign the next available unique ID
    moneyObject.uniqueId = getNextId();

    appendMoneyObject(moneyObject);

    DataObject.onMutationChanged?.call(
      mutation: MutationType.inserted,
      moneyObject: moneyObject,
      recalculateBalances: fireNotification,
    );
    return moneyObject;
  }

  /// Clears the collection.
  void clear() {
    _list.clear();
    _map.clear();
  }

  /// Returns true if an object with [id] exists in the collection.
  bool containsKey(final int id) {
    return _map.containsKey(id);
  }

  /// Remove/tag a Transaction instance from the list in memory
  void deleteItem(final DataObject itemToDelete) {
    DataObject.onMutationChanged?.call(
      mutation: MutationType.deleted,
      moneyObject: itemToDelete,
      recalculateBalances: false,
    );
  }

  /// Returns the first item in the collection, or null if empty.
  T? firstItem([bool includeDeleted = false]) {
    final List<T> list = iterableList(includeDeleted: includeDeleted).toList();
    if (list.isEmpty) {
      return null;
    }
    return iterableList(includeDeleted: includeDeleted).toList().first;
  }

  /// Returns the item with [id], or null if not found.
  T? get(final int id) {
    if (_map.containsKey(id)) {
      return _map[id] as T;
    }
    return null;
  }

  /// Builds a CSV document from a list of money objects.
  static String getCsvFromList(
    final List<DataObject> moneyObjects, {
    final String valueSeparator = ',',
    bool forSerialization = true,
  }) {
    final StringBuffer csv = StringBuffer();

    // Add the UTF-8 BOM for Excel
    // This does not affect clients like Google sheets
    csv.write('\uFEFF');

    if (moneyObjects.isNotEmpty) {
      final FieldDefinitions declarations = moneyObjects.first.fieldDefinitions;

      // CSV Header
      csv.writeln(getCsvHeader(declarations, forSerialization));

      // CSV Rows values
      for (final DataObject item in moneyObjects) {
        csv.writeln(
          toStringAsSeparatedValues(
            declarations,
            item,
            valueSeparator,
            forSerialization,
          ),
        );
      }
    }

    return csv.toString();
  }

  /// Returns the CSV header row for the given [declarations].
  static String getCsvHeader(
    final FieldDefinitions declarations,
    final bool forSerialization,
  ) {
    final List<String> headerList = <String>[];

    for (final Field<dynamic> field in declarations) {
      if (isFieldMatchingCondition(field, forSerialization)) {
        headerList.add('"${field.getBestFieldDescribingName()}"');
      }
    }
    return headerList.join(',');
  }

  /// Returns the internal list sorted by unique ID.
  List<DataObject> getListSortedById() {
    _list.sort((final DataObject a, final DataObject b) {
      return sortByValue(a.uniqueId, b.uniqueId, true);
    });
    return _list;
  }

  /// Returns objects that have the given mutation type.
  List<DataObject> getMutatedObjects(final MutationType typeOfMutation) {
    return _list.where((final DataObject element) => element.mutation == typeOfMutation).toList();
  }

  /// Returns the next available unique ID.
  int getNextId() {
    int nextId = _unsetId;
    for (DataObject moneyObject in _list) {
      nextId = max(nextId, moneyObject.uniqueId);
    }
    return nextId + _nextIdIncrement;
  }

  /// Must be override by derived class
  DataObject instanceFromJson(final MyJson _ /* json */) {
    assert(false, 'You must implement this in your derived class');
    return DataObject();
  }

  /// Returns true if the collection is empty.
  bool get isEmpty {
    return _list.isEmpty;
  }

  /// Returns true if [field] should be included based on serialization mode.
  static bool isFieldMatchingCondition(
    final Field<dynamic> field,
    final bool forSerialization,
  ) {
    return !forSerialization || field.serializeName.isNotEmpty;
  }

  /// Returns true if the collection is not empty.
  bool get isNotEmpty => !isEmpty;

  /// Recast list as type ```<T>```
  Iterable<T> iterableList({bool includeDeleted = false}) {
    return _iterableListOfMoneyObject(includeDeleted).whereType<T>();
  }

  /// Returns the number of items in the collection.
  int get length {
    return _list.length;
  }

  /// Loads objects from JSON rows, replacing any existing content.
  void loadFromJson(final List<MyJson> rows) {
    clear();
    for (final MyJson row in rows) {
      final DataObject moneyObject = instanceFromJson(row);
      appendMoneyObject(moneyObject);
    }
  }

  /// Override in derived classes
  void onAllDataLoaded() {
    // implement in the override derived classes
  }

  /// Saves mutated objects to SQL via the provided database interface.
  bool saveSql(final DatabaseInterface db, final String tableName) {
    for (final DataObject item in _iterableListOfMoneyObject(true)) {
      switch (item.mutation) {
        case MutationType.none:
          break;
        case MutationType.inserted:
          db.itemInsert(tableName, item.getPersistableJSon());

        case MutationType.changed:
          db.itemUpdate(
            tableName,
            item.getPersistableJSon(),
            item.getWhereClause(),
          );

        case MutationType.deleted:
          db.itemDelete(tableName, item.getWhereClause());

        default:
          debugPrint('Unhandled change ${item.mutation}');
      }
      item.mutation = MutationType.none;
    }
    return true;
  }

  /// If the field is found and has a sort function then use it, else default to sortByString
  static List<DataObject> sortList(
    List<DataObject> list,
    final FieldDefinitions fieldDefinitions,
    final int sortBy,
    final bool sortAscending,
  ) {
    final Field<dynamic>? fieldDefinition = isIndexInRange(fieldDefinitions, sortBy) ? fieldDefinitions[sortBy] : null;

    sortListFallbackOnIdForTieBreaker(
      list,
      fieldDefinition?.sort ?? sortByString,
      sortAscending,
    );

    return list;
  }

  /// Sorts [list] using [sortWith] and falls back to unique ID for stable ordering.
  static void sortListFallbackOnIdForTieBreaker(
    List<DataObject> list,
    int Function(DataObject, DataObject, bool) sortWith,
    bool ascending,
  ) {
    list.sort((final DataObject a, final DataObject b) {
      int result = sortWith(a, b, ascending);
      if (result == _zeroInt) {
        result = a.uniqueId.compareTo(b.uniqueId);
      }
      return result;
    });
  }

  /// Returns a CSV representation of the collection.
  String toCSV() {
    return getCsvFromList(getListSortedById());
  }

  /// Returns the field values for [item] as a single separated-values row.
  static String toStringAsSeparatedValues(
    final FieldDefinitions fieldDefinitions,
    final DataObject item, [
    final String valueSeparator = ',',
    final bool forSerialization = true,
  ]) {
    return fieldDefinitions
        .where((final Field<dynamic> field) => isFieldMatchingCondition(field, forSerialization))
        .map((final Field<dynamic> field) {
          final dynamic value = field.getValueForSerialization == defaultCallbackValue || !forSerialization
              ? item.toReadableString(field)
              : field.getValueForSerialization(item);
          return '"$value"';
        })
        .join(valueSeparator);
  }

  /// Builds UI widgets describing what fields changed for the given objects.
  List<Widget> whatWasMutated(List<DataObject> objects) {
    final List<Widget> widgets = <Widget>[];
    for (final DataObject moneyObject in objects) {
      final MyJson jsonDelta = moneyObject.getMutatedDiff<T>();

      final List<Widget> diffWidgets = <Widget>[];

      jsonDelta.forEach((String key, dynamic value) {
        // Field Name
        final Widget instanceName = Text(
          key,
          style: const TextStyle(fontSize: SizeForText.small),
        );

        switch (moneyObject.mutation) {
          case MutationType.inserted:
            final String valueToAddAsString = value['after'].toString();
            if (valueToAddAsString.isNotEmpty) {
              diffWidgets.add(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    instanceName,
                    diffTextNewValue(valueToAddAsString),
                  ],
                ),
              );
            }

          case MutationType.deleted:
            diffWidgets.add(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  instanceName,
                  diffTextOldValue(value['after'].toString()),
                ],
              ),
            );
          case MutationType.changed:
          default:
            diffWidgets.add(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  instanceName,
                  diffTextOldValue(value['before'].toString()),
                  diffTextNewValue(value['after'].toString()),
                ],
              ),
            );
        }
      });

      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  moneyObject.getRepresentation(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Opacity(
                  opacity: _diffIdOpacity,
                  child: SelectableText(
                    moneyObject.uniqueId.toString(),
                    style: const TextStyle(fontSize: SizeForText.nano),
                  ),
                ),
              ],
            ),
            gapSmall(),
            Padding(
              padding: const EdgeInsets.only(left: SizeForPadding.normal),
              child: Wrap(
                spacing: SizeForPadding.large,
                runSpacing: SizeForPadding.large,
                children: diffWidgets,
              ),
            ),
          ],
        ),
      );
    }
    return widgets;
  }

  /// Returns an iterable view of the collection, optionally including deleted items.
  Iterable<DataObject> _iterableListOfMoneyObject([
    bool includeDeleted = false,
  ]) {
    if (includeDeleted) {
      // No filtering needed
      return _list;
    }
    return _list.where(
      (final DataObject item) => item.mutation != MutationType.deleted,
    );
  }
}

/// Finds the first object with [uniqueId] in [listToSearch].
DataObject? findObjectById(
  final int? uniqueId,
  final List<DataObject> listToSearch,
) {
  if (uniqueId == null) {
    return null;
  }
  return listToSearch.firstWhereOrNull(
    (DataObject element) => element.uniqueId == uniqueId,
  );
}
