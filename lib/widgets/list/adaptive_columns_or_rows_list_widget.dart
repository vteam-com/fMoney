import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_filters_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/widgets/list/column_widths_notifier.dart';
import 'package:money/widgets/list/list_item_footer_widget.dart';
import 'package:money/widgets/list/list_item_header_widget.dart';
import 'package:money/widgets/list/list_jump_bar_widget.dart';
import 'package:money/widgets/list/list_view.dart';
import 'package:money/widgets/pure/scale_down_widget.dart';
import 'package:money/widgets/widgets_domain/data_object_widget_builders_model.dart';

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
    required this.widgetBuilders,
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
  final ListItemContextMenuCallback? onContextMenu;
  final void Function(BuildContext context, int itemId)? onItemLongPress;
  final void Function(BuildContext context, int itemId)? onItemTap;
  final void Function(int uniqueId)? onSelectionChanged;
  final ValueNotifier<List<int>> selectedItemsByUniqueId;

  /// Controls whether right-side row adornments are rendered.
  final bool showRightAdornment;
  final bool sortAscending;
  final int sortByFieldIndex;

  /// Entity-specific cell and small-screen widget builders.
  final DataObjectWidgetBuilders widgetBuilders;
  @override
  State<AdaptiveListColumnsOrRows> createState() => _AdaptiveListColumnsOrRowsState();
}

/// State for [AdaptiveListColumnsOrRows].
class _AdaptiveListColumnsOrRowsState extends State<AdaptiveListColumnsOrRows> {
  late ColumnWidthsNotifier _columnWidths;

  /// Cached first row index of each initial letter of the sorted column.
  Map<String, int> _jumpLetterIndexes = <String, int>{};

  /// Inputs [_jumpLetterIndexes] was computed from: the list, the sorted field and the direction.
  (List<DataObject>, Field<dynamic>, bool)? _jumpLetterIndexesKey;

  /// Gives the jump bar access to the list body so it can scroll a row to the top.
  final GlobalKey<MyListViewState<DataObject>> _listViewKey = GlobalKey<MyListViewState<DataObject>>();
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
            key: _listViewKey,
            fields: widget.fieldDefinitions,
            list: widget.list,
            selectedItemIds: widget.selectedItemsByUniqueId,
            isMultiSelectionOn: widget.isMultiSelectionOn,
            showRightAdornment: widget.showRightAdornment,
            onSelectionChanged: widget.onSelectionChanged,
            displayAsColumn: widget.displayAsColumns,
            onTap: widget.onItemTap,
            onLongPress: widget.onItemLongPress,
            onContextMenu: widget.onContextMenu,
            scrollController: widget.listController.scrollController,
            columnWidths: _columnWidths,
            widgetBuilders: widget.widgetBuilders,
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

    final Widget content = widget.displayAsColumns && !context.isWidthLarge
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: _minColumnLayoutWidth, child: theContent),
          )
        : theContent;

    // The jump bar sits outside the horizontal scroll so it stays visible,
    // and beside header, body and footer alike so their columns stay aligned.
    final Field<dynamic>? jumpField = _sortedJumpBarField();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: content),
        if (jumpField != null)
          ListJumpBar(
            firstIndexByLetter: _firstIndexByLetter(jumpField),
            onJump: (int index) => _listViewKey.currentState?.scrollIndexToTop(index),
          ),
      ],
    );
  }

  /// Returns the first row index of each initial letter of [field], recomputed only when the list, field or direction changes.
  Map<String, int> _firstIndexByLetter(Field<dynamic> field) {
    final (List<DataObject>, Field<dynamic>, bool) key = (widget.list, field, widget.sortAscending);
    if (_jumpLetterIndexesKey != key) {
      _jumpLetterIndexesKey = key;
      _jumpLetterIndexes = firstIndexByJumpLetter(
        widget.list.map(
          (DataObject row) => field.getJumpBarText?.call(row) ?? field.getValueForDisplay(row)?.toString() ?? '',
        ),
      );
    }
    return _jumpLetterIndexes;
  }

  /// Returns the field the list is sorted on when it supports the jump bar: a text column, or one with [Field.getJumpBarText].
  Field<dynamic>? _sortedJumpBarField() {
    if (!isIndexInRange(widget.fieldDefinitions, widget.sortByFieldIndex)) {
      return null;
    }
    final Field<dynamic> field = widget.fieldDefinitions[widget.sortByFieldIndex];
    return field.getJumpBarText != null || field.type == FieldType.text ? field : null;
  }
}
