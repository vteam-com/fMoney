import 'package:flutter/material.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/widgets/adaptive_list/adaptive_columns_or_rows_list.dart';
import 'package:money/widgets/default_values.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/field_filters.dart';
import 'package:money/widgets/widgets_domain/field_type.dart';
import 'package:money/widgets/widgets_domain/footer_accumulators.dart';

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

  final bool sortAscending;

  final int sortByFieldIndex;

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
    footerAccumulators();

    return AdaptiveListColumnsOrRows(
      list: widget.list,
      fieldDefinitions: widget.fieldDefinitions,
      filters: widget.filters,
      sortByFieldIndex: widget.sortByFieldIndex,
      sortAscending: widget.sortAscending,
      listController: widget.listController,
      isMultiSelectionOn: false,
      selectedItemsByUniqueId: selectionCollectionOfOnlyOneItem,
      onSelectionChanged: (final int selectedId) {
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

  void footerAccumulators() {
    _footerAccumulators.clear();

    for (final DataObject item in widget.list) {
      for (final Field<dynamic> field in widget.fieldDefinitions) {
        switch (field.type) {
          case FieldType.text:
            _footerAccumulators.accumulatorListOfText.cumulate(
              field,
              field.getValueForDisplay(item) as String,
            );

          case FieldType.date:
            _footerAccumulators.accumulatorDateRange.cumulate(
              field,
              field.getValueForDisplay(item) as DateTime,
            );

          case FieldType.dateRange:
            if (field.value.min != null) {
              _footerAccumulators.accumulatorDateRange.cumulate(
                field,
                field.value.min as DateTime,
              );
            }
            if (field.value.max != null) {
              _footerAccumulators.accumulatorDateRange.cumulate(
                field,
                field.value.max as DateTime,
              );
            }

          case FieldType.amount:
            final double value = smartToDouble(field.getValueForDisplay(item));
            _footerAccumulators.accumulatorSumAmount.cumulate(field, value);
            if (field.footer == FooterType.average) {
              _footerAccumulators.accumulatorForAverage.cumulate(
                field,
                value as num,
              );
            }
            if (field.footer == FooterType.range) {
              _footerAccumulators.accumulatorNumericRange.cumulate(
                field,
                value as num,
              );
            }

          case FieldType.widget:
            if (field.getValueForReading != null) {
              _footerAccumulators.accumulatorListOfText.cumulate(
                field,
                field.getValueForReading?.call(item)!.toString() ?? '',
              );
            }

          case FieldType.numeric:
          case FieldType.amountShorthand:
          case FieldType.numericShorthand:
          case FieldType.quantity:
            final dynamic value = field.getValueForDisplay(item);
            if (value is num) {
              _footerAccumulators.accumulatorSumNumber.cumulate(
                field,
                value.toDouble(),
              );
              if (field.footer == FooterType.average) {
                _footerAccumulators.accumulatorForAverage.cumulate(
                  field,
                  value,
                );
              }
              if (field.footer == FooterType.range) {
                _footerAccumulators.accumulatorNumericRange.cumulate(
                  field,
                  value,
                );
              }
            }
          default:
            break;
        }
      }
    }
  }

  /// Use the field FooterType to decide how to render the bottom button of each columns
  Widget getColumnFooterWidget(final Field<dynamic> field) {
    return _footerAccumulators.buildWidget(field);
  }
}
