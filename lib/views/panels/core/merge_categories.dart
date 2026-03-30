import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/shared/domain/category.dart';
import 'package:money/shared/domain/data.dart';
import 'package:money/shared/domain/transactions.dart';
import 'package:money/widgets/components/info_banner.dart';
import 'package:money/widgets/pickers/picker_category.dart';
import 'package:money/widgets/pure/box.dart';
import 'package:money/widgets/pure/gaps.dart';
import 'package:money/widgets/pure/mutation_types.dart';

const double _categoryLabelWidth = 100.0;
const double _actionPadding = 8.0;
const double _actionOfferingWidth = 250.0;

/// A stateful widget for merge categories transactions dialog.
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
            SizedBox(width: _categoryLabelWidth, child: Text(AppL10n.tr(AppTranslationKeys.fromCategory))),
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
            SizedBox(width: _categoryLabelWidth, child: Text(AppL10n.tr(AppTranslationKeys.toCategory))),
            Expanded(
              child: Box(
                child: pickerCategory(
                  categoryNames: Data().categories.getCategoriesAsStrings(),
                  selectedName: widget.categoryToMove.fieldName.value,
                  onSelected: (String? name) {
                    final Category? newSelection = name != null ? Data().categories.getByName(name) : null;
                    if (newSelection != null) {
                      setState(() {
                        _categoryPicked = newSelection;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Padding(padding: const EdgeInsets.all(_actionPadding), child: _buildActionPanel()),
        const Spacer(),
      ],
    );
  }

  /// Builds a single action offering with its button and explanatory text.
  Widget _buildActionOffering(final String text, Widget action) {
    return SizedBox(
      width: _actionOfferingWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(padding: const EdgeInsets.all(_actionPadding), child: action),
          gapMedium(),
          Text(text),
          gapMedium(),
        ],
      ),
    );
  }

  /// Builds the action panel that offers append or merge operations.
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
              child: Text(AppL10n.tr(AppTranslationKeys.append)),
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
              child: Text(AppL10n.tr(AppTranslationKeys.merge)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Moves a list of transactions to the specified category, updating data.
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
