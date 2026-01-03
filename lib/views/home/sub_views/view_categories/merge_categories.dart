import 'package:flutter/material.dart';
import 'package:money/data/data.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/money_objects/transactions/transactions.dart';
import 'package:money/views/home/sub_views/view_categories/picker_category.dart';
import 'package:money/widgets/box.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/info_banner.dart';
import 'package:money/widgets_data/money_object/mutation_types.dart';

class MergeCategoriesTransactionsDialog extends StatefulWidget {
  const MergeCategoriesTransactionsDialog({
    required this.categoryToMove,
    super.key,
  });

  final Category categoryToMove;

  @override
  State<MergeCategoriesTransactionsDialog> createState() => _MergeCategoriesTransactionsDialogState();
}

class _MergeCategoriesTransactionsDialogState extends State<MergeCategoriesTransactionsDialog> {
  late Category _categoryPicked = widget.categoryToMove;

  final List<Transaction> _transactions = <Transaction>[];

  @override
  void initState() {
    super.initState();

    for (final Transaction t in Data().transactions.iterableList(
      includeDeleted: true,
    )) {
      if (t.fieldCategoryId.value == widget.categoryToMove.uniqueId) {
        _transactions.add(t);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(width: 100, child: Text('From category')),
            Expanded(
              child: Box(child: Text(widget.categoryToMove.fieldName.value)),
            ),
          ],
        ),
        gapLarge(),
        gapLarge(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(width: 100, child: Text('To category')),
            Expanded(
              child: Box(
                child: pickerCategory(
                  itemSelected: widget.categoryToMove,
                  onSelected: (final Category? newSelection) {
                    setState(() {
                      _categoryPicked = newSelection!;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Padding(padding: const EdgeInsets.all(8.0), child: _buildActionPanel()),
        const Spacer(),
      ],
    );
  }

  Widget _buildActionOffering(final String text, Widget action) {
    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(padding: const EdgeInsets.all(8), child: action),
          gapMedium(),
          Text(text),
          gapMedium(),
        ],
      ),
    );
  }

  Widget _buildActionPanel() {
    final String from = widget.categoryToMove.fieldName.value;
    final String to = _categoryPicked.fieldName.value;

    if (from == to) {
      return Center(
        child: InfoBanner.warning('Pick a different category then "$from".'),
      );
    }

    return Center(
      child: Wrap(
        spacing: SizeForPadding.large,
        runSpacing: SizeForPadding.large,
        children: <Widget>[
          // Append
          _buildActionOffering(
            'Use this option to move "$from" as a child of category of "$to".',
            OutlinedButton(
              onPressed: () {
                if (_categoryPicked == widget.categoryToMove) {
                  showSnackBar(
                    context,
                    'No need to merge to itself, select a different payee',
                  );
                } else {
                  // reparent Category
                  Data().categories.reparentCategory(
                    widget.categoryToMove,
                    _categoryPicked,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Append'),
            ),
          ),
          gapLarge(),
          // Merge
          _buildActionOffering(
            'Use this option to merge the transactions of "$from" in to "$to".',
            OutlinedButton(
              onPressed: () {
                if (_categoryPicked == widget.categoryToMove) {
                  showSnackBar(
                    context,
                    'No need to merge to itself, select a different category',
                  );
                } else {
                  // move to Transaction to the picked category
                  moveTransactionsToCategory(_transactions, _categoryPicked);

                  // we can now delete picked category
                  widget.categoryToMove.stashValueBeforeEditing();
                  Data().notifyMutationChanged(
                    mutation: MutationType.deleted,
                    moneyObject: widget.categoryToMove,
                    recalculateBalances: false,
                  );

                  Data().updateAll();

                  Navigator.pop(context);
                }
              },
              child: const Text('Merge'),
            ),
          ),
        ],
      ),
    );
  }
}

void moveTransactionsToCategory(
  final List<Transaction> transactions,
  final Category moveToCategory,
) {
  for (final Transaction t in transactions) {
    t.stashValueBeforeEditing();
    t.fieldCategoryId.value = moveToCategory.uniqueId;

    Data().notifyMutationChanged(
      mutation: MutationType.changed,
      moneyObject: t,
      recalculateBalances: false,
    );
  }
}
