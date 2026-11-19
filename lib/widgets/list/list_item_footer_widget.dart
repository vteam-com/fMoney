import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/widgets/columns/column_footer_button.dart';
import 'package:money/widgets/list/column_widths_notifier.dart';

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
                    return Row(
                      children: buildVisibleColumnCells(
                        fields: columns,
                        ratios: columnWidths.value,
                        maxWidth: constraints.maxWidth,
                        buildCell: (int i, double width) {
                          final Field<dynamic> col = columns[i];
                          return buildColumnFooterButton(
                            textAlign: col.align,
                            flex: col.columnWidth.index,
                            fixedWidth: width,
                            onPressed: () => onTap(i),
                            onLongPress: () => onLongPress?.call(col),
                            child: getColumnFooterWidget(col),
                          );
                        },
                        // A spacer matching the header/body drag-handle width.
                        buildGap: (int _, double _) => const SizedBox(width: columnResizeHandleWidth),
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
