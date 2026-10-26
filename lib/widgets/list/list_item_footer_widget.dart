import 'package:flutter/material.dart';
import 'package:money/widgets/columns/column_footer_button.dart';
import 'package:money/widgets/list/column_widths_notifier.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

const double _hiddenCheckboxOpacity = 0;
const double _footerPaddingHorizontal = 8;
const int _footerBorderAlpha = 100;
const double _footerBorderWidth = 1;

/// A Row for a Table view.
///
/// The footer uses a pixel-aligned layout driven by [columnWidths] that matches
/// the list body and header widths.
class MyListItemFooter<T> extends StatelessWidget {
  const MyListItemFooter({
    required this.columns,
    required this.multiSelectionOn,
    required this.getColumnFooterWidget,
    required this.onTap,
    required this.columnWidths,
    super.key,
    this.backgroundColor = Colors.transparent,
    this.onLongPress,
  });
  final Color backgroundColor;

  /// Shared column-width notifier for pixel-aligned layout.
  final ColumnWidthsNotifier columnWidths;
  final FieldDefinitions columns;
  final Widget? Function(Field<dynamic> field) getColumnFooterWidget;
  final bool multiSelectionOn;
  final void Function(Field<dynamic>)? onLongPress;
  final void Function(int columnIndex) onTap;

  /// Builds the footer using a pixel-aligned layout that matches the body.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: columnWidths,
      builder: (BuildContext _, Widget? _) {
        final List<double> ratios = columnWidths.value;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: _footerPaddingHorizontal),
          decoration: _decoration,
          child: Row(
            children: <Widget>[
              if (multiSelectionOn)
                Opacity(
                  opacity: _hiddenCheckboxOpacity,
                  child: Checkbox(value: false, onChanged: (bool? _) {}),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext _, BoxConstraints constraints) {
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
                        buildColumnFooterButton(
                          context: context,
                          textAlign: col.align,
                          flex: col.columnWidth.index,
                          fixedWidth: pos < ratios.length ? contentWidth * ratios[pos] : 0,
                          onPressed: () => onTap(i),
                          onLongPress: () => onLongPress?.call(col),
                          child: getColumnFooterWidget(col),
                        ),
                      );

                      // Insert a spacer matching the header/body drag-handle width.
                      if (pos < ratios.length - 1) {
                        rowChildren.add(
                          const SizedBox(width: columnResizeHandleWidth),
                        );
                      }
                      visiblePos++;
                    }

                    return Row(children: rowChildren);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Decoration for the footer container.
  BoxDecoration get _decoration => BoxDecoration(
    color: backgroundColor,
    border: Border(
      top: BorderSide(
        color: Colors.grey.withAlpha(_footerBorderAlpha),
        width: _footerBorderWidth,
      ),
    ),
  );
}
