import 'package:money/data/helpers/accumulator_helper.dart';
import 'package:money/data/models/mergeable_item_interface.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';
import 'package:money/widgets/pure/box_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';

const int _zeroIndex = 0;
const int _countIncrement = 1;
const double _payeeLabelWidth = 100.0;
const double _categoryChoicesHeight = 400.0;

/// Shows a dialog to merge a set of transactions from one payee to another.
void showMergePayee<T extends MergeableItem>(
  final BuildContext context,
  Payee payee,
  Iterable<T> transactions,
  DataAbstract data,
) {
  adaptiveScreenSizeDialog(
    context: context,
    title: AppL10n.tr(
      AppTranslationKeys.mergeTransactionsCount,
      params: <String, String>{
        'count': getIntAsText(transactions.length),
      },
    ),
    captionForClose: null, // this will hide the close button
    child: MergeTransactionsDialog<T>(
      currentPayee: payee,
      transactions: transactions.toList(),
      data: data,
    ),
  );
}

/// A stateful widget for merge transactions dialog.
class MergeTransactionsDialog<T extends MergeableItem> extends StatefulWidget {
  const MergeTransactionsDialog({
    required this.currentPayee,
    required this.transactions,
    required this.data,
    super.key,
  });

  /// The payee currently associated with the selected transactions.
  final Payee currentPayee;

  /// Data accessor used to resolve payees/categories and apply mutations.
  final DataAbstract data;

  /// The transactions to merge.
  final List<T> transactions;

  /// Creates state for the merge transactions dialog.
  @override
  State<MergeTransactionsDialog<T>> createState() => _MergeTransactionsDialogState<T>();
}

class _MergeTransactionsDialogState<T extends MergeableItem> extends State<MergeTransactionsDialog<T>> {
  int? _estimatedCategory;

  Payee? _selectedPayee;

  /// Tracks how often each category ID appears for the selected payee.
  AccumulatorSum<int, int> categoryIdsFound = AccumulatorSum<int, int>();

  /// Builds the dialog UI to pick a target payee and optional category changes.
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
              SizedBox(width: _payeeLabelWidth, child: Text(AppL10n.tr(AppTranslationKeys.fromPayee))),
              Expanded(
                child: Box(child: Text(widget.currentPayee.fieldName.value)),
              ),
            ],
          ),
          gapLarge(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(width: _payeeLabelWidth, child: Text(AppL10n.tr(AppTranslationKeys.toPayee))),
              Expanded(
                child: Box(
                  child: PickerEditBox(
                    title: AppL10n.tr(AppTranslationKeys.payee),
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
              text: AppL10n.tr(AppTranslationKeys.cancel),
              onPressed: () => Navigator.pop(context),
            ),
            if (_selectedPayee != null && _selectedPayee != widget.currentPayee)
              DialogActionButton(
                text: AppL10n.tr(AppTranslationKeys.merge),
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

  /// Computes category counts for transactions matching the selected payee.
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

  /// Builds the category suggestion and override radio list.
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
                  AppL10n.tr(AppTranslationKeys.orChangeToCategory),
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
        RadioListTile<int?>(
          value: null,
          title: Text(
            AppL10n.tr(AppTranslationKeys.keepAllTransactionsToTheirCurrentCategories),
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

/// Mutates a list of mergeable items to assign them to a target payee.
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
