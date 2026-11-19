import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/dialogs/mutate_in_place_dialog.dart';

/// Shows a dialog that allows the user to mutate a transaction.
///
/// The dialog displays the transaction details and provides options to edit or confirm the transaction.
///
/// Parameters:
/// - `context`: The build context used to display the dialog.
/// - `transaction`: The transaction to be displayed and mutated in the dialog.
///
/// Returns:
/// A `Future` that completes when the dialog is closed, with the result of the user's actions.
Future<dynamic> showTransactionAndActions({
  required BuildContext context,
  required Transaction transaction,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext _) {
      return DialogMutateInPlace<Transaction>(
        moneyObject: transaction,
        nameSingular: AppL10n.tr(AppTranslationKeys.transaction),
        namePlural: AppL10n.tr(AppTranslationKeys.transactions),
        onApply: _applyTransferChange,
        onDuplicate: _appendDuplicate,
      );
    },
  );
}

/// Applies a Payee/Transfer change picked in the dialog to the counterpart transaction.
void _applyTransferChange(Transaction transaction) {
  Data().verifyApplyTransfer(
    transaction: transaction,
    relatedAccount: transaction.editingTransferAccount,
  );
  transaction.editingTransferAccount = null;
}

/// Adds a copy of [transaction] to the transactions and returns it.
Transaction _appendDuplicate(Transaction transaction) {
  final Transaction duplicate = transaction.createDuplicate();
  Data().transactions.appendNewMoneyObject(duplicate);
  return duplicate;
}
