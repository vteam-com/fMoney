import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/field_filter_model.dart';
import 'package:money/data/models/field_filters_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/columns/column_header_button.dart';
import 'package:money/widgets/list/column_resize_handle_widget.dart';
import 'package:money/widgets/list/column_widths_notifier.dart';

/// A Row for a Table view.
///
/// The header uses a pixel-aligned layout driven by [columnWidths] with visible
/// drag handles so columns stay synchronized with the list body.
class MyListItemHeader<T> extends StatelessWidget {
  const MyListItemHeader({
    required this.columns,
    required this.filterOn,
    required this.sortByColumn,
    required this.sortAscending,
    required this.onTap,
    required this.columnWidths,
    super.key,
    this.backgroundColor = Colors.transparent,
    this.itemsAreAllSelected = false,
    this.onSelectAll,
    this.onLongPress,
  });
  final Color backgroundColor;

  /// Shared column-width notifier for pixel-aligned resizable layout.
  final ColumnWidthsNotifier columnWidths;
  final FieldDefinitions columns;
  final FieldFilters filterOn;
  final bool itemsAreAllSelected;
  final void Function(Field<dynamic>)? onLongPress;
  final void Function(bool)? onSelectAll;
  final void Function(int columnIndex) onTap;
  final bool sortAscending;
  final int sortByColumn;

  /// Builds the header using a pixel-aligned layout with visible drag handles.
  ///
  /// The cell widths mirror those used by the list body so header and body
  /// columns stay in sync after resizing.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: columnWidths,
      builder: (BuildContext _, Widget? _) {
        return Container(
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: SizeForPadding.normal),
          child: Row(
            children: <Widget>[
              if (onSelectAll != null)
                Checkbox(
                  key: Constants.keyCheckboxToggleSelectAll,
                  value: itemsAreAllSelected,
                  onChanged: (bool? selected) {
                    onSelectAll!(selected == true);
                  },
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext layoutCtx, BoxConstraints constraints) {
                    return IntrinsicHeight(
                      child: Row(
                        children: buildVisibleColumnCells(
                          fields: columns,
                          ratios: columnWidths.value,
                          maxWidth: constraints.maxWidth,
                          buildCell: (int i, double width) {
                            final Field<dynamic> col = columns[i];
                            return buildColumnHeaderButton(
                              context: layoutCtx,
                              text: col.name,
                              textAlign: col.align,
                              flex: col.columnWidth.index,
                              fixedWidth: width,
                              sortIndicator: getSortIndicator(sortByColumn, i, sortAscending),
                              hasFilters:
                                  filterOn.list.firstWhereOrNull(
                                    (FieldFilter item) => item.fieldName == col.name,
                                  ) !=
                                  null,
                              onPressed: () => onTap(i),
                              onLongPress: () => onLongPress?.call(col),
                            );
                          },
                          buildGap: (int leftColumnPosition, double contentWidth) => ColumnResizeHandle(
                            columnWidths: columnWidths,
                            leftColumnPosition: leftColumnPosition,
                            contentWidth: contentWidth,
                            showDivider: true,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
