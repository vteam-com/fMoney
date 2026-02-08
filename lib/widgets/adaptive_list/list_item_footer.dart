import 'package:flutter/material.dart';
import 'package:money/widgets/columns/column_footer_button.dart';
import 'package:money/widgets/widgets_domain/field.dart';

const double _hiddenCheckboxOpacity = 0;
const double _footerPaddingHorizontal = 8;
const int _footerBorderAlpha = 100;
const double _footerBorderWidth = 1;

/// A Row for a Table view
class MyListItemFooter<T> extends StatelessWidget {
  const MyListItemFooter({
    required this.columns,
    required this.multiSelectionOn,
    required this.getColumnFooterWidget,
    required this.onTap,
    super.key,
    this.backgroundColor = Colors.transparent,
    this.onLongPress,
  });

  final Color backgroundColor;

  final FieldDefinitions columns;

  final Widget? Function(Field<dynamic> field) getColumnFooterWidget;

  final bool multiSelectionOn;

  final void Function(Field<dynamic>)? onLongPress;

  final void Function(int columnIndex) onTap;

  @override
  Widget build(final BuildContext context) {
    final List<Widget> footerWidgets = <Widget>[];

    if (multiSelectionOn) {
      footerWidgets.add(
        Opacity(
          opacity: _hiddenCheckboxOpacity, // We only want to use the same width as the Header Checkbox
          child: Checkbox(value: false, onChanged: (bool? _) {}),
        ),
      );
    }
    for (int i = 0; i < columns.length; i++) {
      final Field<dynamic> columnDefinition = columns[i];
      if (columnDefinition.columnWidth != ColumnWidth.hidden) {
        footerWidgets.add(
          buildColumnFooterButton(
            context: context,
            textAlign: columnDefinition.align,
            flex: columnDefinition.columnWidth.index,
            // Press
            onPressed: () {
              onTap(i);
            },
            // Long Press
            onLongPress: () {
              onLongPress?.call(columnDefinition);
            },
            child: getColumnFooterWidget(columnDefinition),
          ),
        );
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _footerPaddingHorizontal),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withAlpha(_footerBorderAlpha),
            width: _footerBorderWidth,
          ),
        ), // Outer border
      ),
      child: Row(children: footerWidgets),
    );
  }
}
