import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:money/data/entities/transaction_split.dart';
import 'package:money/views/dialog_mutate_split.dart';
import 'package:money/widgets/adaptive_list/list_item_header.dart';
import 'package:money/widgets/adaptive_list/list_view.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/widgets_domain/field_filters.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

class ListViewTransactionSplits extends StatefulWidget {
  const ListViewTransactionSplits({
    super.key,
    this.defaultSortingField = 0,
    required this.splits,
    required this.totalAmount,
  });

  final int defaultSortingField;
  final List<TransactionSplit> splits;
  final double totalAmount;

  @override
  State<ListViewTransactionSplits> createState() => _ListViewTransactionSplitsState();
}

class _ListViewTransactionSplitsState extends State<ListViewTransactionSplits> {
  bool _sortAscending = true;
  late int _sortBy = widget.defaultSortingField;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(final BuildContext context) {
    return Column(
      children: <Widget>[
        // Table Header
        MyListItemHeader<TransactionSplit>(
          columns: TransactionSplit.fields.definitions,
          filterOn: FieldFilters(),
          sortByColumn: _sortBy,
          sortAscending: _sortAscending,
          onTap: (final int index) {
            setState(() {
              if (_sortBy == index) {
                // same column tap/click again, change the sort order
                _sortAscending = !_sortAscending;
              } else {
                _sortBy = index;
              }
            });
          },
        ),
        // Table list of rows
        Expanded(
          child: MyListView<TransactionSplit>(
            fields: TransactionSplit.fields.definitions,
            list: widget.splits,
            selectedItemIds: ValueNotifier<List<int>>(<int>[]),
            onSelectionChanged: (int _) {},
            onLongPress: (final BuildContext context2, final int uniqueId) {
              final TransactionSplit? instance = widget.splits.firstWhereOrNull(
                (TransactionSplit t) => t.uniqueId == uniqueId,
              );
              if (instance != null) {
                showSplitAndActions(context: context2, split: instance);
              }
            },
            scrollController: ScrollController(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // update
                });
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Refresh list'),
                ],
              ),
            ),
            _buildTally(),
          ],
        ),
      ],
    );
  }

  double get amountDelta {
    return sumOfSplits - widget.totalAmount;
  }

  bool get isTotalMatching => amountDelta == 0;

  double get sumOfSplits {
    return widget.splits.fold(
      0.0,
      (double sum, TransactionSplit split) => sum + split.fieldAmount.value.asDouble(),
    );
  }

  Widget _buildTally() {
    if (isTotalMatching) {
      return Row(
        children: <Widget>[
          const Text('Amount is matching'),
          gapSmall(),
          WidgetFromData.fromDouble(sumOfSplits),
        ],
      );
    } else {
      return Row(
        children: <Widget>[
          const Text('Amount is off by'),
          gapSmall(),
          WidgetFromData.fromDouble(amountDelta),
        ],
      );
    }
  }
}
