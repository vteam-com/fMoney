import 'package:money/controller/selection_controller.dart';
import 'package:money/data/data.dart';
import 'package:money/data/transactions.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/views/adaptive_list/adaptive_columns_or_rows_single_selection.dart';
import 'package:money/views/home/sub_views/view_transactions/dialog_mutate_transaction.dart';
import 'package:money/widgets_data/field_filters.dart';
import 'package:money/widgets_data/money_objects.dart';

// Exports
export 'package:money/views/home/sub_views/adaptive_view/view_money_objects.dart';

class ListViewTransactions extends StatefulWidget {
  const ListViewTransactions({
    super.key,
    required this.columnsToInclude,
    required this.getList,
    required this.listController,
    required this.selectionController,
    this.sortFieldIndex = 0,
    this.sortAscending = true,
    this.onUserChoiceChanged,
  });

  final List<Field<dynamic>> columnsToInclude;

  final List<Transaction> Function() getList;

  final ListController listController;

  final void Function(
    int sortingField,
    bool sortAscending,
    int selectedItemIndex,
  )?
  onUserChoiceChanged;

  final SelectionController selectionController;

  final bool sortAscending;

  final int sortFieldIndex;

  @override
  State<ListViewTransactions> createState() => _ListViewTransactionsState();
}

class _ListViewTransactionsState extends State<ListViewTransactions> {
  late bool _sortAscending = widget.sortAscending;
  late int _sortBy = widget.sortFieldIndex;

  @override
  Widget build(final BuildContext context) {
    // get the list sorted
    final List<Transaction> transactions = widget.getList();
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions'));
    }

    MoneyObjects.sortList(
      transactions,
      widget.columnsToInclude,
      _sortBy,
      _sortAscending,
    );

    return AdaptiveListColumnsOrRowsSingleSelection(
      list: transactions,
      fieldDefinitions: widget.columnsToInclude,
      filters: FieldFilters(),
      sortByFieldIndex: _sortBy,
      sortAscending: _sortAscending,
      selectedId: widget.selectionController.firstSelectedId,
      listController: widget.listController,

      // Field & Columns
      displayAsColumns: true,
      backgroundColorForHeaderFooter: Colors.transparent,
      onSelectionChanged: (int uniqueId) {
        widget.onUserChoiceChanged?.call(_sortBy, _sortAscending, uniqueId);
        widget.selectionController.select(uniqueId);
      },
      onColumnHeaderTap: (final int index) {
        setState(() {
          if (_sortBy == index) {
            // same column tap/click again, change the sort order
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = index;
          }
          widget.onUserChoiceChanged?.call(
            _sortBy,
            _sortAscending,
            widget.selectionController.firstSelectedId,
          );
        });
      },
      onItemLongPress: (final BuildContext context2, final int uniqueId) {
        final Transaction instance = findObjectById(uniqueId, transactions) as Transaction;
        showTransactionAndActions(
          context: context2,
          transaction: instance,
        ).then((final dynamic _) {
          widget.selectionController.select(uniqueId);
          widget.onUserChoiceChanged?.call(
            _sortBy,
            _sortAscending,
            widget.selectionController.firstSelectedId,
          );
        });
      },
    );
  }
}

List<Transaction> getTransactions({
  bool Function(Transaction)? filter,
  bool flattenSplits = false,
}) {
  filter ??= (Transaction transaction) => true;

  List<Transaction> list = <Transaction>[];

  if (flattenSplits) {
    // Flatten the splits
    list = Transactions.flatTransactions(
      Data().transactions.iterableList(),
    ).where((final Transaction transaction) => filter!(transaction)).toList();
  } else {
    // No flattening of splits
    list = Data().transactions.iterableList().where((final Transaction transaction) => filter!(transaction)).toList();
  }

  list.sort(
    (Transaction a, Transaction b) => Transaction.sortByDateTime(a, b, true),
  );

  double runningBalance = 0.0;
  for (Transaction transaction in list) {
    runningBalance += transaction.fieldAmount.value.asDouble();
    transaction.balance = runningBalance;
  }
  return list;
}
