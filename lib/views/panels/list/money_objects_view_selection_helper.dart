import 'package:collection/collection.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_filters_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

/// Returns the first selected item ID from [selectedIds], or null when empty.
int? getFirstSelectedMoneyObjectId(final List<int> selectedIds) {
  return selectedIds.firstOrNull;
}

/// Returns the first selected data object from [list] for the given [selectedIds].
T? getFirstSelectedMoneyObject<T extends DataObject>(
  final List<int> selectedIds,
  final List<DataObject> list,
) {
  final int? firstId = getFirstSelectedMoneyObjectId(selectedIds);
  if (firstId == null) {
    return null;
  }

  return list.firstWhereOrNull(
        (final DataObject moneyObject) => moneyObject.uniqueId == firstId,
      )
      as T?;
}

/// Returns selected data objects from [list] matching [selectedIds].
List<DataObject> getSelectedMoneyObjectsFromIds(
  final List<int> selectedIds,
  final List<DataObject> list,
) {
  if (selectedIds.isEmpty) {
    return <DataObject>[];
  }

  final Set<int> selectedIdsSet = selectedIds.toSet();
  return list
      .where(
        (final DataObject moneyObject) => selectedIdsSet.contains(moneyObject.uniqueId),
      )
      .toList();
}

/// Returns true if [instance] matches the current text and column filters.
bool isMoneyObjectMatchingFilters({
  required final bool areFiltersOn,
  required final Fields<DataObject> fieldToDisplay,
  required final DataInterface instance,
  required final String filterByText,
  required final FieldFilters filterByFieldsValue,
}) {
  if (areFiltersOn) {
    return fieldToDisplay.applyFilters(
      instance,
      filterByText,
      filterByFieldsValue,
    );
  }
  return true;
}

/// Returns the first element of type [T] in [listOfItems] matching the first selected ID.
T? getMoneyObjectFromFirstSelectedIdInList<T>(
  final List<int> selectedIds,
  final List<dynamic> listOfItems,
) {
  if (selectedIds.isEmpty) {
    return null;
  }

  final int id = selectedIds.first;
  return listOfItems.firstWhereOrNull(
        (final dynamic element) => (element as DataObject).uniqueId == id,
      )
      as T?;
}
