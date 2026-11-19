import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_filters_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/widgets/list/adaptive_columns_or_rows_list_widget.dart';
import 'package:money/widgets/list/list_view.dart';
import 'package:money/widgets/widgets_domain/data_object_widget_builders_model.dart';
import 'package:money/widgets/widgets_domain/footer_accumulators_helper.dart';

/// A stateful widget for adaptive list columns or rows single selection.
class AdaptiveListColumnsOrRowsSingleSelection extends StatefulWidget {
  const AdaptiveListColumnsOrRowsSingleSelection({
    super.key,
    required this.list,
    required this.fieldDefinitions,
    required this.filters,
    required this.selectedId,
    required this.displayAsColumns,
    required this.listController,
    required this.widgetBuilders,
    this.showRightAdornment = true,
    this.sortByFieldIndex = 0,
    this.sortAscending = true,
    this.onSelectionChanged,
    this.onContextMenu,
    this.onColumnHeaderTap,
    this.onColumnHeaderLongPress,
    this.onItemTap,
    this.onItemLongPress,
    this.backgroundColorForHeaderFooter,
  });

  final Color? backgroundColorForHeaderFooter;

  final bool displayAsColumns;

  final FieldDefinitions fieldDefinitions;

  final FieldFilters filters;

  final List<DataObject> list;

  final ListController listController;

  final void Function(Field<dynamic> field)? onColumnHeaderLongPress;

  final void Function(int columnHeaderIndex)? onColumnHeaderTap;

  final ListItemContextMenuCallback? onContextMenu;

  final void Function(BuildContext context, int itemId)? onItemLongPress;

  final void Function(BuildContext context, int itemId)? onItemTap;

  final void Function(int uniqueId)? onSelectionChanged;

  final int selectedId;

  /// Controls whether right-side row adornments are rendered.
  final bool showRightAdornment;

  final bool sortAscending;

  final int sortByFieldIndex;

  /// Entity-specific cell and small-screen widget builders.
  final DataObjectWidgetBuilders widgetBuilders;

  @override
  State<AdaptiveListColumnsOrRowsSingleSelection> createState() => _AdaptiveListColumnsOrRowsSingleSelectionState();
}

class _AdaptiveListColumnsOrRowsSingleSelectionState extends State<AdaptiveListColumnsOrRowsSingleSelection> {
  final FooterAccumulators _footerAccumulators = FooterAccumulators();

  late final ValueNotifier<List<int>> selectionCollectionOfOnlyOneItem = ValueNotifier<List<int>>(<int>[
    widget.selectedId,
  ]);

  @override
  Widget build(BuildContext context) {
    // Data mutations always reach this widget as a freshly built list, so the list identity is enough to
    // decide when to re-scan.
    _footerAccumulators.recomputeIfChanged(items: widget.list, definitions: widget.fieldDefinitions);

    return AdaptiveListColumnsOrRows(
      list: widget.list,
      fieldDefinitions: widget.fieldDefinitions,
      filters: widget.filters,
      showRightAdornment: widget.showRightAdornment,
      sortByFieldIndex: widget.sortByFieldIndex,
      sortAscending: widget.sortAscending,
      listController: widget.listController,
      widgetBuilders: widget.widgetBuilders,
      isMultiSelectionOn: false,
      selectedItemsByUniqueId: selectionCollectionOfOnlyOneItem,
      onSelectionChanged: (int selectedId) {
        widget.listController.bookmark = widget.listController.scrollController.offset;
        setState(() {
          selectionCollectionOfOnlyOneItem.value = <int>[selectedId];
          widget.onSelectionChanged?.call(selectedId);
        });
      },
      onContextMenu: widget.onContextMenu,
      displayAsColumns: widget.displayAsColumns,
      onColumnHeaderTap: widget.onColumnHeaderTap,
      onColumnHeaderLongPress: widget.onColumnHeaderLongPress,
      onItemTap: widget.onItemTap,
      onItemLongPress: widget.onItemLongPress,
      getColumnFooterWidget: getColumnFooterWidget,
      backgroundColorForHeaderFooter: widget.backgroundColorForHeaderFooter,
    );
  }

  /// Use the field FooterType to decide how to render the bottom button of each columns
  Widget getColumnFooterWidget(Field<dynamic> field) {
    return _footerAccumulators.buildWidget(field);
  }
}
