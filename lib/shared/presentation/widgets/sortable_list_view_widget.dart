import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_filters_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/presentation/entity_widgets/entity_widgets_helper.dart';
import 'package:money/widgets/list/adaptive_columns_or_rows_single_selection_widget.dart';
import 'package:money/widgets/state/selection_controller.dart';

const double _scrollRestoreTolerance = 0.5;

/// A list of [T] rows the user sorts by tapping a column header and selects one row at a time.
class SortableListView<T extends DataObject> extends StatefulWidget {
  const SortableListView({
    super.key,
    required this.columnsToInclude,
    required this.getList,
    required this.listController,
    required this.selectionController,
    this.sortFieldIndex = 0,
    this.sortAscending = true,
    this.showRightAdornment = false,
    this.onUserChoiceChanged,
    this.onItemLongPress,
  });

  /// Columns shown, the sort column indexing into them.
  final List<Field<dynamic>> columnsToInclude;

  /// Returns the rows to show; called on each build.
  final List<T> Function() getList;

  /// Scroll controller of the list, also used to restore its scroll offset.
  final ListController listController;

  /// Called on a long press of [item], after it got selected.
  final void Function(BuildContext context, T item)? onItemLongPress;

  /// Called when the user sorts or selects a row.
  final void Function(
    int sortingField,
    bool sortAscending,
    int selectedItemIndex,
  )?
  onUserChoiceChanged;

  /// Holds, and may persist, the selected row.
  final SelectionController selectionController;

  /// Controls whether right-side row adornments are rendered.
  final bool showRightAdornment;

  /// Initial sort direction.
  final bool sortAscending;

  /// Initial sort column.
  final int sortFieldIndex;

  @override
  State<SortableListView<T>> createState() => _SortableListViewState<T>();
}

class _SortableListViewState<T extends DataObject> extends State<SortableListView<T>> {
  late bool _sortAscending = widget.sortAscending;
  late int _sortBy = widget.sortFieldIndex;
  @override
  Widget build(BuildContext context) {
    // get the list sorted
    final List<T> rows = widget.getList();
    if (rows.isEmpty) {
      return Center(child: Text(AppL10n.tr(AppTranslationKeys.noTransactions)));
    }

    MoneyObjects.sortList(
      rows,
      widget.columnsToInclude,
      _sortBy,
      _sortAscending,
    );

    _restoreScrollPositionIfNeeded();

    return AdaptiveListColumnsOrRowsSingleSelection(
      list: rows,
      fieldDefinitions: widget.columnsToInclude,
      filters: FieldFilters(),
      showRightAdornment: widget.showRightAdornment,
      sortByFieldIndex: _sortBy,
      sortAscending: _sortAscending,
      selectedId: widget.selectionController.firstSelectedId,
      listController: widget.listController,
      widgetBuilders: entityWidgetBuilders,

      // Field & Columns
      displayAsColumns: true,
      backgroundColorForHeaderFooter: Colors.transparent,
      onSelectionChanged: _select,
      onColumnHeaderTap: (int index) {
        setState(() {
          _sortAscending = sortAscendingAfterColumnTap(index, _sortBy, _sortAscending);
          _sortBy = index;
          widget.onUserChoiceChanged?.call(
            _sortBy,
            _sortAscending,
            widget.selectionController.firstSelectedId,
          );
        });
      },
      onItemLongPress: (BuildContext context2, int uniqueId) {
        _select(uniqueId);
        widget.onItemLongPress?.call(context2, findObjectById(uniqueId, rows) as T);
      },
    );
  }

  /// Restores the previous scroll offset after rebuilds that recreate the list
  /// viewport, such as inline item edits.
  void _restoreScrollPositionIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.listController.scrollController.hasClients) {
        return;
      }

      final double rememberedOffset = widget.listController.scrollPosition.value > 0
          ? widget.listController.scrollPosition.value
          : widget.listController.bookmark;
      if (rememberedOffset <= 0) {
        return;
      }

      final ScrollPosition position = widget.listController.scrollController.position;
      final double clampedOffset = rememberedOffset.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );

      if ((position.pixels - clampedOffset).abs() < _scrollRestoreTolerance) {
        return;
      }

      widget.listController.scrollController.jumpTo(clampedOffset);
    });
  }

  /// Selects the row with [uniqueId] and reports the user's sort and selection.
  void _select(int uniqueId) {
    widget.selectionController.select(uniqueId);
    widget.onUserChoiceChanged?.call(_sortBy, _sortAscending, uniqueId);
  }
}
