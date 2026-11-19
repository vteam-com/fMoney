import 'package:material_ui/material_ui.dart';
import 'package:money/widgets/list/column_widths_notifier.dart';

// Width of the visible divider line drawn inside the drag-handle zone.
const double _dragDividerWidth = 2;
// Opacity of the drag-handle divider line.
const double _dragDividerAlpha = 0.6;

/// The draggable gap between two resizable columns; dragging it moves their shared boundary.
///
/// The header shows a thin divider line in the gap ([showDivider]); the list
/// body leaves it blank. Either way the mouse cursor changes to
/// [SystemMouseCursors.resizeColumn] on hover.
class ColumnResizeHandle extends StatelessWidget {
  /// Creates the handle between the visible column at [leftColumnPosition] and the next one.
  const ColumnResizeHandle({
    required this.columnWidths,
    required this.leftColumnPosition,
    required this.contentWidth,
    super.key,
    this.showDivider = false,
  });

  /// Shared column-width notifier updated while dragging.
  final ColumnWidthsNotifier columnWidths;

  /// Pixel width shared by the columns, used to turn a drag distance into a ratio.
  final double contentWidth;

  /// Visible position of the column on the left of this handle.
  final int leftColumnPosition;

  /// Draws a thin divider line inside the gap.
  final bool showDivider;

  /// Builds the gap and its drag detector.
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (DragUpdateDetails details) {
          if (contentWidth > 0) {
            columnWidths.resizeAtBoundary(
              leftColumnPosition,
              details.delta.dx / contentWidth,
              minimumColumnWidth / contentWidth,
            );
          }
        },
        child: SizedBox(
          width: columnResizeHandleWidth,
          child: showDivider
              ? VerticalDivider(
                  width: columnResizeHandleWidth,
                  thickness: _dragDividerWidth,
                  indent: 0,
                  endIndent: 0,
                  color: Theme.of(context).dividerColor.withValues(alpha: _dragDividerAlpha),
                )
              : null,
        ),
      ),
    );
  }
}
