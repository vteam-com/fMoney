import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/presentation/dialogs/mutate_split_dialog.dart';
import 'package:money/widgets/list/list_item_header_widget.dart';
import 'package:money/widgets/list/list_view.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/widgets_domain/field_filters_model.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

/// A stateful widget for list view transaction splits.
class ListViewTransactionSplits extends StatefulWidget {
  const ListViewTransactionSplits({
    super.key,
    this.defaultSortingField = 0,
    required this.splits,
    required this.totalAmount,
  });

  final int defaultSortingField;
  final
  /// Returns a list of transaction splits with optional filtering and sorting.
  List<TransactionSplit>
  splits;
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.refresh),
                  const SizedBox(width: SizeForPadding.normal),
                  Text(AppL10n.tr(AppTranslationKeys.refreshList)),
                ],
              ),
            ),
            _buildTally(),
          ],
        ),
      ],
    );
  }

  /// Returns the difference between sum of splits and total amount.
  double get amountDelta {
    return sumOfSplits - widget.totalAmount;
  }

  /// Returns true if the sum of splits matches the total amount.
  bool get isTotalMatching => amountDelta == 0;

  /// Returns the sum of all split amounts.
  double get sumOfSplits {
    return widget.splits.fold(
      0.0,
      (double sum, TransactionSplit split) => sum + split.fieldAmount.value.asDouble(),
    );
  }

  /// Builds a tally row indicating whether the split amounts match the transaction total.
  Widget _buildTally() {
    if (isTotalMatching) {
      return Row(
        children: <Widget>[
          Text(AppL10n.tr(AppTranslationKeys.amountIsMatching)),
          gapSmall(),
          WidgetFromData.fromDouble(sumOfSplits),
        ],
      );
    } else {
      return Row(
        children: <Widget>[
          Text(AppL10n.tr(AppTranslationKeys.amountIsOffBy)),
          gapSmall(),
          WidgetFromData.fromDouble(amountDelta),
        ],
      );
    }
  }
}
