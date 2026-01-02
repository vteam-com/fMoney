import 'package:money/fields/field_filters.dart';
import 'package:money/fields/money_objects.dart';
import 'package:money/widgets/columns/column_header_button.dart';

// Exports
export 'package:flutter/material.dart';
export 'package:money/widgets/misc_widgets.dart';

/// A Row for a Table view
class MyListItemHeader<T> extends StatelessWidget {
  const MyListItemHeader({
    required this.columns,
    required this.filterOn,
    required this.sortByColumn,
    required this.sortAscending,
    required this.onTap,
    super.key,
    this.backgroundColor = Colors.transparent,
    this.itemsAreAllSelected = false,
    this.onSelectAll,
    this.onLongPress,
  });

  final Color backgroundColor;

  final FieldDefinitions columns;

  final FieldFilters filterOn;

  final bool itemsAreAllSelected;

  final void Function(Field<dynamic>)? onLongPress;

  final void Function(bool)? onSelectAll;

  final void Function(int columnIndex) onTap;

  final bool sortAscending;

  final int sortByColumn;

  @override
  Widget build(final BuildContext context) {
    final List<Widget> headers = <Widget>[];
    if (onSelectAll != null) {
      headers.add(
        Checkbox(
          key: Constants.keyCheckboxToggleSelectAll,
          value: itemsAreAllSelected,
          onChanged: (bool? selected) {
            onSelectAll!(selected == true);
          },
        ),
      );
    }
    for (int i = 0; i < columns.length; i++) {
      final Field<dynamic> columnDefinition = columns[i];
      if (columnDefinition.columnWidth != ColumnWidth.hidden) {
        headers.add(
          buildColumnHeaderButton(
            context: context,
            text: columnDefinition.name,
            textAlign: columnDefinition.align,
            flex: columnDefinition.columnWidth.index,
            sortIndicator: getSortIndicator(sortByColumn, i, sortAscending),
            hasFilters:
                filterOn.list.firstWhereOrNull(
                  (FieldFilter item) => item.fieldName == columnDefinition.name,
                ) !=
                null,
            onPressed: () {
              onTap(i);
            },
            onLongPress: () {
              onLongPress?.call(columnDefinition);
            },
          ),
        );
      }
    }
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(children: headers),
    );
  }
}
