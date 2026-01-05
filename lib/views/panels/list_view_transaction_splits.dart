import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:money/views/models/splits/money_split.dart';
import 'package:money/views/panels/adaptive_list/list_item_header.dart';
import 'package:money/views/panels/adaptive_list/list_view.dart';
import 'package:money/views/view_transactions/dialog_mutate_split.dart';
import 'package:money/widgets/field_filters.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/money_widget.dart';

class ListViewTransactionSplits extends StatefulWidget {
  const ListViewTransactionSplits({
    super.key,
    this.defaultSortingField = 0,
    required this.splits,
    required this.totalAmount,
  });

  final int defaultSortingField;
  final List<MoneySplit> splits;
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
        MyListItemHeader<MoneySplit>(
          columns: MoneySplit.fields.definitions,
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
          child: MyListView<MoneySplit>(
            fields: MoneySplit.fields.definitions,
            list: widget.splits,
            selectedItemIds: ValueNotifier<List<int>>(<int>[]),
            onSelectionChanged: (int _) {},
            onLongPress: (final BuildContext context2, final int uniqueId) {
              final MoneySplit? instance = widget.splits.firstWhereOrNull(
                (MoneySplit t) => t.uniqueId == uniqueId,
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
      (double sum, MoneySplit split) => sum + split.fieldAmount.value.asDouble(),
    );
  }

  Widget _buildTally() {
    if (isTotalMatching) {
      return Row(
        children: <Widget>[
          const Text('Amount is matching'),
          gapSmall(),
          MoneyWidget.fromDouble(sumOfSplits),
        ],
      );
    } else {
      return Row(
        children: <Widget>[
          const Text('Amount is off by'),
          gapSmall(),
          MoneyWidget.fromDouble(amountDelta),
        ],
      );
    }
  }
}

typedef FilterFunction = bool Function(Split);

bool defaultFilter(final Split element) {
  return true; // filter nothing
}
