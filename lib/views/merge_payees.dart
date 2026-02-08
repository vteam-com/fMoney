import 'package:money/data/entities/data_abstract.dart';
import 'package:money/data/mergeable_item.dart';
import 'package:money/data/models/payee.dart';
import 'package:money/helpers/accumulator.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/box.dart';
import 'package:money/widgets/button_helpers.dart';
import 'package:money/widgets/dialog.dart';
import 'package:money/widgets/dialog_button.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/picker_edit_box.dart';

const int _zeroIndex = 0;
const int _countIncrement = 1;
const double _payeeLabelWidth = 100.0;
const double _categoryChoicesHeight = 400.0;

void showMergePayee<T extends MergeableItem>(
  final BuildContext context,
  Payee payee,
  Iterable<T> transactions,
  DataAbstract data,
) {
  adaptiveScreenSizeDialog(
    context: context,
    title: 'Merge ${transactions.length} transactions',
    captionForClose: null, // this will hide the close button
    child: MergeTransactionsDialog<T>(
      currentPayee: payee,
      transactions: transactions.toList(),
      data: data,
    ),
  );
}

class MergeTransactionsDialog<T extends MergeableItem> extends StatefulWidget {
  const MergeTransactionsDialog({
    required this.currentPayee,
    required this.transactions,
    required this.data,
    super.key,
  });

  final Payee currentPayee;

  final DataAbstract data;

  final List<T> transactions;

  @override
  State<MergeTransactionsDialog<T>> createState() => _MergeTransactionsDialogState<T>();
}

class _MergeTransactionsDialogState<T extends MergeableItem> extends State<MergeTransactionsDialog<T>> {
  int? _estimatedCategory;

  Payee? _selectedPayee;

  AccumulatorSum<int, int> categoryIdsFound = AccumulatorSum<int, int>();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Spacer(),
          Row(
            children: <Widget>[
              const SizedBox(width: _payeeLabelWidth, child: Text('From payee')),
              Expanded(
                child: Box(child: Text(widget.currentPayee.fieldName.value)),
              ),
            ],
          ),
          gapLarge(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(width: _payeeLabelWidth, child: Text('To payee')),
              Expanded(
                child: Box(
                  child: PickerEditBox(
                    title: 'Payee',
                    items: widget.data.getPayeeNames(),
                    initialValue: widget.currentPayee.fieldName.value,
                    onChanged: (String? name) {
                      final Payee? payee = name != null ? widget.data.getPayeeByName(name) as Payee? : null;
                      setState(() {
                        _selectedPayee = payee;
                        getAssociatedCategories();
                      });
                    },
                    onAddNew: (String newPayeeText) {
                      final Payee found = widget.data.getOrCreatePayee(newPayeeText) as Payee;
                      setState(() {
                        _selectedPayee = found;
                        getAssociatedCategories();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          gapLarge(),
          _buildCategoryChoices(),
          const Spacer(),
          dialogActionButtons(<Widget>[
            DialogActionButton(
              text: 'Cancel',
              onPressed: () => Navigator.pop(context),
            ),
            if (_selectedPayee != null && _selectedPayee != widget.currentPayee)
              DialogActionButton(
                text: 'Merge',
                onPressed: () {
                  mutateMergeableItemsToPayee<T>(
                    widget.transactions,
                    _selectedPayee!.uniqueId,
                    _estimatedCategory,
                    widget.data,
                  );
                  Navigator.pop(context);
                },
              ),
          ]),
        ],
      ),
    );
  }

  void getAssociatedCategories() {
    if (_selectedPayee != null) {
      categoryIdsFound.clear();
      for (final T t in widget.transactions) {
        if (t.payeeId == _selectedPayee!.uniqueId) {
          categoryIdsFound.cumulate(t.categoryId, _countIncrement);
        }
      }
    }
  }

  Widget _buildCategoryChoices() {
    if (categoryIdsFound.values.isEmpty) {
      return const SizedBox();
    }

    final List<Widget> radioButtonChoices = <Widget>[];
    final List<MapEntry<int, int>> sortedDescendingListOfCategories = categoryIdsFound.getEntries();
    sortedDescendingListOfCategories.sort(
      (MapEntry<int, int> a, MapEntry<int, int> b) => sortByValue(a.value, b.value, false),
    );

    for (final MapEntry<int, int> entry in sortedDescendingListOfCategories) {
      final int categoryId = entry.key;
      final int categoryCounts = entry.value;

      final String categoryName = widget.data.getCategoryNameFromId(categoryId).trim();
      if (categoryName.isNotEmpty) {
        radioButtonChoices.add(
          RadioListTile<int?>(
            value: categoryId,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  'or change to category',
                  style: getTextTheme(context).bodySmall,
                ),
                gapMedium(),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Badge(
                      textColor: getColorTheme(context).onPrimaryContainer,
                      backgroundColor: getColorTheme(context).primaryContainer,
                      label: Text(getIntAsText(categoryCounts)),
                      child: Box(
                        child: Text(
                          widget.data.getCategoryNameFromId(categoryId),
                          maxLines: 1,
                          // overflow: TextOverflow.clip, // Clip the overflow text
                          softWrap: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (radioButtonChoices.isNotEmpty) {
      radioButtonChoices.insert(
        _zeroIndex,
        const RadioListTile<int?>(
          value: null,
          title: Text(
            'Keep all transactions to their current categories',
          ),
        ),
      );
    }

    return SizedBox(
      height: _categoryChoicesHeight,
      child: SingleChildScrollView(
        child: RadioGroup<int?>(
          groupValue: _estimatedCategory,
          onChanged: (int? value) {
            setState(() {
              _estimatedCategory = value;
            });
          },
          child: Column(children: radioButtonChoices),
        ),
      ),
    );
  }
}

void mutateMergeableItemsToPayee<T extends MergeableItem>(
  final List<T> items,
  final int toPayeeId,
  final int? categoryId,
  final DataAbstract data,
) {
  final Set<int> fromPayeeIds = <int>{};

  for (final T item in items) {
    // keep track of the payeeIds that we remove transactions from
    fromPayeeIds.add(item.payeeId);

    item.payeeId = toPayeeId;
    if (categoryId != null) {
      item.categoryId = categoryId;
    }
  }
  data.removePayeesWithNoTransactions(fromPayeeIds.toList());
  data.updateAll();
}
