import 'package:flutter/material.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/widgets/list/adaptive_columns_or_rows_list_widget.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_filters_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';
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
    this.showRightAdornment = true,
    this.sortByFieldIndex = 0,
    this.sortAscending = true,
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

  final List<DataObject> list;

  final ListController listController;

  final void Function(Field<dynamic> field)? onColumnHeaderLongPress;

  final void Function(int columnHeaderIndex)? onColumnHeaderTap;

  final void Function()? onContextMenu;

  final void Function(BuildContext context, int itemId)? onItemLongPress;

  final void Function(BuildContext context, int itemId)? onItemTap;

  final void Function(int uniqueId)? onSelectionChanged;

  final int selectedId;

  /// Controls whether right-side row adornments are rendered.
  final bool showRightAdornment;

  final bool sortAscending;

  final int sortByFieldIndex;

  @override
  State<AdaptiveListColumnsOrRowsSingleSelection> createState() => _AdaptiveListColumnsOrRowsSingleSelectionState();
}

class _AdaptiveListColumnsOrRowsSingleSelectionState extends State<AdaptiveListColumnsOrRowsSingleSelection> {
  final FooterAccumulators _footerAccumulators = FooterAccumulators();

  /// List instance the footer accumulators were last computed for.
  List<DataObject>? _footerAccumulatorsComputedForList;

  late final ValueNotifier<List<int>> selectionCollectionOfOnlyOneItem = ValueNotifier<List<int>>(<int>[
    widget.selectedId,
  ]);

  @override
  Widget build(BuildContext context) {
    footerAccumulators();

    return AdaptiveListColumnsOrRows(
      list: widget.list,
      fieldDefinitions: widget.fieldDefinitions,
      filters: widget.filters,
      showRightAdornment: widget.showRightAdornment,
      sortByFieldIndex: widget.sortByFieldIndex,
      sortAscending: widget.sortAscending,
      listController: widget.listController,
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

  /// Updates footer accumulators with counts from the filtered list.
  ///
  /// Recomputes only when the list instance changed; data mutations always
  /// reach this widget as a freshly built list, so unrelated rebuilds such as
  /// selection changes skip the full re-scan.
  void footerAccumulators() {
    if (identical(widget.list, _footerAccumulatorsComputedForList)) {
      return;
    }
    _footerAccumulatorsComputedForList = widget.list;

    _footerAccumulators.recompute(
      items: widget.list,
      definitions: widget.fieldDefinitions,
    );
  }

  /// Use the field FooterType to decide how to render the bottom button of each columns
  Widget getColumnFooterWidget(Field<dynamic> field) {
    return _footerAccumulators.buildWidget(field);
  }
}
