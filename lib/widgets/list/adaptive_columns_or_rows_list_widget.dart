import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/widgets/list/column_widths_notifier.dart';
import 'package:money/widgets/list/list_item_footer_widget.dart';
import 'package:money/widgets/list/list_item_header_widget.dart';
import 'package:money/widgets/list/list_view.dart';
import 'package:money/widgets/pure/scale_down_widget.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_filters_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

const double _minColumnLayoutWidth = 1500;

/// A stateful widget for adaptive list columns or rows.
///
/// Creates a [ColumnWidthsNotifier] from [fieldDefinitions] and passes it to
/// the header, body, and footer so all three sections resize in lock-step.
class AdaptiveListColumnsOrRows extends StatefulWidget {
  const AdaptiveListColumnsOrRows({
    super.key,
    required this.list,
    required this.fieldDefinitions,
    required this.filters,
    required this.selectedItemsByUniqueId,
    required this.displayAsColumns,
    required this.listController,
    this.showRightAdornment = true,
    this.sortByFieldIndex = 0,
    this.sortAscending = true,
    this.isMultiSelectionOn = false,
    this.onSelectionChanged,
    this.onContextMenu,
    this.onColumnHeaderTap,
    this.onColumnHeaderLongPress,
    this.onItemTap,
    this.onItemLongPress,
    this.getColumnFooterWidget,
    this.backgroundColorForHeaderFooter,
  });
  final Color? backgroundColorForHeaderFooter;
  final bool displayAsColumns;
  final FieldDefinitions fieldDefinitions;
  final FieldFilters filters;
  final Widget? Function(Field<dynamic> field)? getColumnFooterWidget;
  final bool isMultiSelectionOn;
  final List<DataObject> list;
  final ListController listController;
  final void Function(Field<dynamic> field)? onColumnHeaderLongPress;
  final void Function(int columnHeaderIndex)? onColumnHeaderTap;
  final void Function()? onContextMenu;
  final void Function(BuildContext context, int itemId)? onItemLongPress;
  final void Function(BuildContext context, int itemId)? onItemTap;
  final void Function(int uniqueId)? onSelectionChanged;
  final ValueNotifier<List<int>> selectedItemsByUniqueId;

  /// Controls whether right-side row adornments are rendered.
  final bool showRightAdornment;
  final bool sortAscending;
  final int sortByFieldIndex;
  @override
  State<AdaptiveListColumnsOrRows> createState() => _AdaptiveListColumnsOrRowsState();
}

/// State for [AdaptiveListColumnsOrRows].
class _AdaptiveListColumnsOrRowsState extends State<AdaptiveListColumnsOrRows> {
  late ColumnWidthsNotifier _columnWidths;
  @override
  void initState() {
    super.initState();
    _columnWidths = ColumnWidthsNotifier.fromFields(widget.fieldDefinitions);
  }

  @override
  void dispose() {
    _columnWidths.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AdaptiveListColumnsOrRows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fieldDefinitions != widget.fieldDefinitions) {
      _columnWidths.dispose();
      _columnWidths = ColumnWidthsNotifier.fromFields(widget.fieldDefinitions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Column theContent = Column(
      children: <Widget>[
        // Header
        if (widget.displayAsColumns)
          MyListItemHeader<DataObject>(
            backgroundColor: widget.backgroundColorForHeaderFooter ?? getColorTheme(context).surfaceContainerLow,
            columns: widget.fieldDefinitions,
            filterOn: widget.filters,
            sortByColumn: widget.sortByFieldIndex,
            sortAscending: widget.sortAscending,
            columnWidths: _columnWidths,
            itemsAreAllSelected: widget.list.length == widget.selectedItemsByUniqueId.value.length,
            onSelectAll: widget.isMultiSelectionOn
                ? (bool selectAllRequested) {
                    widget.selectedItemsByUniqueId.value.clear();
                    if (selectAllRequested) {
                      for (final DataObject item in widget.list) {
                        widget.selectedItemsByUniqueId.value.add(item.uniqueId);
                      }
                    }
                    widget.onSelectionChanged?.call(-1);
                  }
                : null,
            onTap: (int index) => widget.onColumnHeaderTap?.call(index),
            onLongPress: (Field<dynamic> field) => widget.onColumnHeaderLongPress?.call(field),
          ),

        // The actual List
        Expanded(
          flex: 1,
          child: MyListView<DataObject>(
            fields: widget.fieldDefinitions,
            list: widget.list,
            selectedItemIds: widget.selectedItemsByUniqueId,
            isMultiSelectionOn: widget.isMultiSelectionOn,
            showRightAdornment: widget.showRightAdornment,
            onSelectionChanged: widget.onSelectionChanged,
            displayAsColumn: widget.displayAsColumns,
            onTap: widget.onItemTap,
            onLongPress: widget.onItemLongPress,
            scrollController: widget.listController.scrollController,
            columnWidths: _columnWidths,
          ),
        ),

        // Footer
        if (widget.displayAsColumns && widget.getColumnFooterWidget != null)
          MyListItemFooter<DataObject>(
            backgroundColor: widget.backgroundColorForHeaderFooter ?? getColorTheme(context).surfaceContainerLow,
            columns: widget.fieldDefinitions,
            multiSelectionOn: widget.isMultiSelectionOn,
            columnWidths: _columnWidths,
            getColumnFooterWidget: widget.getColumnFooterWidget!,
            onTap: (int _) => () {},
            onLongPress: (Field<dynamic> _) => () {},
          ),
      ],
    );

    if (widget.displayAsColumns && !context.isWidthLarge) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: _minColumnLayoutWidth, child: theContent),
      );
    } else {
      return theContent;
    }
  }
}
