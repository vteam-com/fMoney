import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/widgets/diff.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets_data/data/database.dart';
import 'package:money/widgets_data/money_object/money_object.dart';

// Exports
export 'package:collection/collection.dart';
export 'package:money/widgets_data/money_object/fields.dart';
export 'package:money/widgets_data/money_object/money_object.dart';

/// Collection of MoneyObject as both List and Map
class MoneyObjects<T> {
  /// Constructor
  MoneyObjects();

  String collectionName = '';

  final List<MoneyObject> _list = <MoneyObject>[];
  final Map<num, MoneyObject> _map = <num, MoneyObject>{};

  void appendMoneyObject(final MoneyObject moneyObject) {
    // assert(moneyObject.uniqueId != -1);

    _list.add(moneyObject);
    _map[moneyObject.uniqueId] = moneyObject;
  }

  MoneyObject appendNewMoneyObject(
    final MoneyObject moneyObject, {
    bool fireNotification = true,
  }) {
    assert(moneyObject.uniqueId == -1);

    // assign the next available unique ID
    moneyObject.uniqueId = getNextId();

    appendMoneyObject(moneyObject);

    MoneyObject.onMutationChanged?.call(
      mutation: MutationType.inserted,
      moneyObject: moneyObject,
      recalculateBalances: fireNotification,
    );
    return moneyObject;
  }

  void clear() {
    _list.clear();
  }

  bool containsKey(final int id) {
    return _map.containsKey(id);
  }

  /// Remove/tag a Transaction instance from the list in memory
  void deleteItem(final MoneyObject itemToDelete) {
    MoneyObject.onMutationChanged?.call(
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
    final List<MoneyObject> moneyObjects, {
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
      for (final MoneyObject item in moneyObjects) {
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

  List<MoneyObject> getListSortedById() {
    _list.sort((final MoneyObject a, final MoneyObject b) {
      return sortByValue(a.uniqueId, b.uniqueId, true);
    });
    return _list;
  }

  List<MoneyObject> getMutatedObjects(final MutationType typeOfMutation) {
    return _list.where((final MoneyObject element) => element.mutation == typeOfMutation).toList();
  }

  int getNextId() {
    int nextId = -1;
    for (MoneyObject moneyObject in _list) {
      nextId = max(nextId, moneyObject.uniqueId);
    }
    return nextId + 1;
  }

  /// Must be override by derived class
  MoneyObject instanceFromJson(final MyJson json) {
    assert(false, 'You must implement this in your derived class');
    return MoneyObject();
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
      final MoneyObject moneyObject = instanceFromJson(row);
      appendMoneyObject(moneyObject);
    }
  }

  void mutationUpdateItem(final MoneyObject item) {
    MoneyObject.onMutationChanged?.call(
      mutation: MutationType.changed,
      moneyObject: item,
    );
  }

  /// Override in derived classes
  void onAllDataLoaded() {
    // implement in the override derived classes
  }

  bool saveSql(final MyDatabase db, final String tableName) {
    for (final MoneyObject item in _iterableListOfMoneyObject(true)) {
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
  static List<MoneyObject> sortList(
    List<MoneyObject> list,
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
    List<MoneyObject> list,
    int Function(MoneyObject, MoneyObject, bool) sortWith,
    bool ascending,
  ) {
    list.sort((final MoneyObject a, final MoneyObject b) {
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
    final MoneyObject item, [
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

  List<Widget> whatWasMutated(List<MoneyObject> objects) {
    final List<Widget> widgets = <Widget>[];
    for (final MoneyObject moneyObject in objects) {
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

  Iterable<MoneyObject> _iterableListOfMoneyObject([
    bool includeDeleted = false,
  ]) {
    if (includeDeleted) {
      // No filtering needed
      return _list;
    }
    return _list.where(
      (final MoneyObject item) => item.mutation != MutationType.deleted,
    );
  }
}

MoneyObject? findObjectById(
  final int? uniqueId,
  final List<MoneyObject> listToSearch,
) {
  if (uniqueId == null) {
    return null;
  }
  return listToSearch.firstWhereOrNull(
    (MoneyObject element) => element.uniqueId == uniqueId,
  );
}
