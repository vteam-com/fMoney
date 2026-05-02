import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:money/data/models/field_filter_model.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/columns/column_header_button.dart';
import 'package:money/widgets/list/column_widths_notifier.dart';
import 'package:money/widgets/widgets_domain/field_filters_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

// Width of the visible divider line drawn inside the drag-handle zone.
const double _dragDividerWidth = 2;
// Opacity of the drag-handle divider line.
const double _dragDividerAlpha = 0.6;

/// A Row for a Table view.
///
/// When [columnWidths] is provided the header uses a pixel-aligned layout with
/// visible drag handles so columns stay synchronized with the list body. When
/// omitted the header falls back to proportional flex layout.
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
    this.columnWidths,
  });
  final Color backgroundColor;

  /// Optional shared column-width notifier for pixel-aligned resizable layout.
  final ColumnWidthsNotifier? columnWidths;
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
    if (columnWidths != null) {
      return _buildPixelLayout(context);
    }
    return _buildFlexLayout(context);
  }

  /// Builds a drag handle between two adjacent header columns.
  ///
  /// The handle shows a thin visible divider and changes the mouse cursor to
  /// [SystemMouseCursors.resizeColumn] on hover.
  Widget _buildDragHandle(
    final BuildContext context,
    final int leftColumnPos,
    final double contentWidth,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (final DragUpdateDetails details) {
          if (contentWidth > 0) {
            columnWidths!.resizeAtBoundary(
              leftColumnPos,
              details.delta.dx / contentWidth,
              minimumColumnWidth / contentWidth,
            );
          }
        },
        child: SizedBox(
          width: columnResizeHandleWidth,
          child: VerticalDivider(
            width: columnResizeHandleWidth,
            thickness: _dragDividerWidth,
            indent: 0,
            endIndent: 0,
            color: Theme.of(context).dividerColor.withValues(
              alpha: _dragDividerAlpha,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header using the legacy proportional flex layout.
  Widget _buildFlexLayout(final BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: SizeForPadding.normal),
      child: Row(children: headers),
    );
  }

  /// Builds the header using a pixel-aligned layout with visible drag handles.
  ///
  /// The cell widths mirror those used by the list body so header and body
  /// columns stay in sync after resizing.
  Widget _buildPixelLayout(final BuildContext context) {
    return ListenableBuilder(
      listenable: columnWidths!,
      builder: (final BuildContext _, final Widget? _) {
        final List<double> ratios = columnWidths!.value;

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
                  builder: (final BuildContext layoutCtx, final BoxConstraints constraints) {
                    if (ratios.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final double handlesTotalWidth = (ratios.length - 1) * columnResizeHandleWidth;
                    final double contentWidth = (constraints.maxWidth - handlesTotalWidth).clamp(
                      0,
                      double.infinity,
                    );

                    final List<Widget> rowChildren = <Widget>[];
                    int visiblePos = 0;

                    for (int i = 0; i < columns.length; i++) {
                      final Field<dynamic> col = columns[i];
                      if (col.columnWidth == ColumnWidth.hidden) {
                        continue;
                      }
                      final int pos = visiblePos;
                      rowChildren.add(
                        buildColumnHeaderButton(
                          context: layoutCtx,
                          text: col.name,
                          textAlign: col.align,
                          flex: col.columnWidth.index,
                          fixedWidth: pos < ratios.length ? contentWidth * ratios[pos] : 0,
                          sortIndicator: getSortIndicator(sortByColumn, i, sortAscending),
                          hasFilters:
                              filterOn.list.firstWhereOrNull(
                                (FieldFilter item) => item.fieldName == col.name,
                              ) !=
                              null,
                          onPressed: () => onTap(i),
                          onLongPress: () => onLongPress?.call(col),
                        ),
                      );

                      if (pos < ratios.length - 1) {
                        rowChildren.add(
                          _buildDragHandle(context, pos, contentWidth),
                        );
                      }
                      visiblePos++;
                    }

                    return IntrinsicHeight(
                      child: Row(children: rowChildren),
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
