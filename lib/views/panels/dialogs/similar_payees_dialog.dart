import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/alias_pattern_suggestion_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/similar_payees_helper.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/dialogs/merge_payees_dialog.dart';
import 'package:money/shared/presentation/helpers/transactions_updated_snack_bar_helper.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';
import 'package:money/widgets/pure/center_message_widget.dart';

/// Shows the payees whose names look like [payee]'s and lets the user merge them into it or alias them to it.
void showSimilarPayees(BuildContext context, Payee payee) {
  adaptiveScreenSizeDialog(
    context: context,
    title: AppL10n.tr(AppTranslationKeys.payeesSimilarTo, params: <String, String>{'payee': payee.fieldName.value}),
    child: SimilarPayeesDialog(payee: payee),
  );
}

/// Lists the payees similar to [payee], each with a checkbox, plus Merge and Create alias actions.
class SimilarPayeesDialog extends StatefulWidget {
  const SimilarPayeesDialog({required this.payee, super.key});

  /// The payee the checked payees are merged or aliased into.
  final Payee payee;

  @override
  State<SimilarPayeesDialog> createState() => _SimilarPayeesDialogState();
}

class _SimilarPayeesDialogState extends State<SimilarPayeesDialog> {
  /// Ids of the payees the user keeps checked; all of them to start with.
  late final Set<int> _checkedIds = _similarPayees.map((Payee payee) => payee.uniqueId).toSet();

  /// Payees that look like the dialog payee and no alias maps yet.
  late final List<Payee> _similarPayees = findSimilarPayees(
    widget.payee,
    Data().payees.iterableList(),
    Data().aliases.iterableList(),
  );
  @override
  Widget build(BuildContext context) {
    if (_similarPayees.isEmpty) {
      return CenterMessage(message: AppL10n.tr(AppTranslationKeys.noSimilarPayeesFound));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
            children: <Widget>[
              for (final Payee payee in _similarPayees)
                CheckboxListTile(
                  value: _checkedIds.contains(payee.uniqueId),
                  title: Text(payee.fieldName.value),
                  secondary: Text(getIntAsText(payee.fieldCount.value)),
                  onChanged: (bool? checked) => setState(() {
                    checked == true ? _checkedIds.add(payee.uniqueId) : _checkedIds.remove(payee.uniqueId);
                  }),
                ),
            ],
          ),
        ),
        if (_checkedIds.isNotEmpty)
          dialogActionButtons(<Widget>[
            DialogActionButton(text: AppL10n.tr(AppTranslationKeys.createAlias), onPressed: _createAlias),
            DialogActionButton(text: AppL10n.tr(AppTranslationKeys.merge), onPressed: _merge),
          ]),
      ],
    );
  }

  /// Closes the dialog and tells the user how many transactions changed.
  void _close(int transactionCount) {
    Navigator.pop(context);
    displayTransactionsUpdated(transactionCount);
  }

  /// Adds one regex alias matching every checked name, applies it, then removes the emptied payees.
  /// The regex may grow to cover future variants, but not the transactions of unchecked payees.
  void _createAlias() {
    final Set<int> payeeIds = <int>{..._checkedIds, widget.payee.uniqueId};
    final Alias alias = Data().aliases.addNewAlias(
      pattern: Data().aliasPatternFor(
        _similarPayees.where((Payee p) => _checkedIds.contains(p.uniqueId)).map((Payee p) => p.fieldName.value),
        (Transaction t) => payeeIds.any(t.isForPayee),
      ),
      type: AliasType.regex,
      payeeId: widget.payee.uniqueId,
    );
    final int count = Data().applyAlias(alias);
    Data().mergePayeesWithNoTransactionsInto(_checkedIds.toList(), widget.payee.uniqueId);
    Data().updateAll();
    _close(count);
  }

  /// Moves the checked payees' transactions to the dialog payee and removes the emptied payees.
  void _merge() {
    final List<Transaction> transactions = Data().transactions
        .iterableList(includeDeleted: true)
        .where((Transaction t) => _checkedIds.any(t.isForPayee))
        .toList();
    final Set<int> payeeIdsWithTransactions = transactions.map((Transaction t) => t.fieldPayee.value).toSet();
    mutateMergeableItemsToPayee<Transaction>(transactions, widget.payee.uniqueId, null, Data());
    Data().mergePayeesWithNoTransactionsInto(
      _checkedIds.where((int id) => !payeeIdsWithTransactions.contains(id)).toList(),
      widget.payee.uniqueId,
    );
    _close(transactions.length);
  }
}
