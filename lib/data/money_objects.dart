import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:money/data/database_interface.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/widgets/diff.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/mutation_types.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';

/// Collection of MoneyObject as both List and Map
class MoneyObjects<T> {
  /// Constructor
  MoneyObjects();

  String collectionName = '';

  final List<DataObject> _list = <DataObject>[];
  final Map<num, DataObject> _map = <num, DataObject>{};

  void appendMoneyObject(final DataObject moneyObject) {
    // assert(moneyObject.uniqueId != -1);

    _list.add(moneyObject);
    _map[moneyObject.uniqueId] = moneyObject;
  }

  DataObject appendNewMoneyObject(
    final DataObject moneyObject, {
    bool fireNotification = true,
  }) {
    assert(moneyObject.uniqueId == -1);

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

  void clear() {
    _list.clear();
    _map.clear();
  }

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

  T? firstItem([bool includeDeleted = false]) {
    final List<T> list = iterableList(includeDeleted: includeDeleted).toList();
    if (list.isEmpty) {
      return null;
    }
    return iterableList(includeDeleted: includeDeleted).toList().first;
  }

  T? get(final int id) {
    if (_map.containsKey(id)) {
      return _map[id] as T;
    }
    return null;
  }

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

  List<DataObject> getListSortedById() {
    _list.sort((final DataObject a, final DataObject b) {
      return sortByValue(a.uniqueId, b.uniqueId, true);
    });
    return _list;
  }

  List<DataObject> getMutatedObjects(final MutationType typeOfMutation) {
    return _list.where((final DataObject element) => element.mutation == typeOfMutation).toList();
  }

  int getNextId() {
    int nextId = -1;
    for (DataObject moneyObject in _list) {
      nextId = max(nextId, moneyObject.uniqueId);
    }
    return nextId + 1;
  }

  /// Must be override by derived class
  DataObject instanceFromJson(final MyJson json) {
    assert(false, 'You must implement this in your derived class');
    return DataObject();
  }

  bool get isEmpty {
    return _list.isEmpty;
  }

  static bool isFieldMatchingCondition(
    final Field<dynamic> field,
    final bool forSerialization,
  ) {
    return !forSerialization || field.serializeName.isNotEmpty;
  }

  bool get isNotEmpty => !isEmpty;

  /// Recast list as type ```<T>```
  Iterable<T> iterableList({bool includeDeleted = false}) {
    return _iterableListOfMoneyObject(includeDeleted).whereType<T>();
  }

  int get length {
    return _list.length;
  }

  void loadFromJson(final List<MyJson> rows) {
    clear();
    for (final MyJson row in rows) {
      final DataObject moneyObject = instanceFromJson(row);
      appendMoneyObject(moneyObject);
    }
  }

  void mutationUpdateItem(final DataObject item) {
    DataObject.onMutationChanged?.call(
      mutation: MutationType.changed,
      moneyObject: item,
    );
  }

  /// Override in derived classes
  void onAllDataLoaded() {
    // implement in the override derived classes
  }

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

  static void sortListFallbackOnIdForTieBreaker(
    List<DataObject> list,
    int Function(DataObject, DataObject, bool) sortWith,
    bool ascending,
  ) {
    list.sort((final DataObject a, final DataObject b) {
      int result = sortWith(a, b, ascending);
      if (result == 0) {
        result = a.uniqueId.compareTo(b.uniqueId);
      }
      return result;
    });
  }

  String toCSV() {
    return getCsvFromList(getListSortedById());
  }

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

  List<Widget> whatWasMutated(List<DataObject> objects) {
    final List<Widget> widgets = <Widget>[];
    for (final DataObject moneyObject in objects) {
      final MyJson jsonDelta = moneyObject.getMutatedDiff<T>();

      final List<Widget> diffWidgets = <Widget>[];

      jsonDelta.forEach((String key, dynamic value) {
        // Field Name
        final Widget instanceName = Text(
          key,
          style: const TextStyle(fontSize: 10),
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
                  opacity: 0.5,
                  child: SelectableText(
                    moneyObject.uniqueId.toString(),
                    style: const TextStyle(fontSize: 8),
                  ),
                ),
              ],
            ),
            gapSmall(),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
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
