import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/views/imports/transfer/transfer_import_fields_model.dart';
import 'package:money/views/imports/transfer/transfer_import_panel.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';

const double _transferAmountSign = -1.0;
const int _snackDurationSeconds = 5;

/// Shows dialog for importing transfer transactions.
void showImportTransfer({ImportFieldsForTransfer? inputData}) {
  inputData ??= ImportFieldsForTransfer(
    accountFrom: Data().accounts.getMostRecentlySelectedAccount(),
    accountTo: Data().accounts.getMostRecentlySelectedAccount(),
    date: DateTime.now(),
    category: null,
    amount: 0,
    memo: '',
  );

  final BuildContext context = AppRouter.context!;
  adaptiveScreenSizeDialog(
    context: context,
    captionForClose: AppL10n.tr(AppTranslationKeys.cancel),
    actionButtons: getActionButtons(inputData, context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        gapLarge(),
        Expanded(child: ImportFieldsForTransferPanel(inputFields: inputData)),
      ],
    ),
  );
}

/// Builds action buttons for transfer import dialog.
List<Widget> getActionButtons(
  ImportFieldsForTransfer inputData,
  BuildContext context,
) {
  final List<Widget> actionButtons = <Widget>[
    // Button - Import
    DialogActionButton(
      text: AppL10n.tr(AppTranslationKeys.recordTransfer),
      onPressed: () {
        if (!inputData.validAccounts) {
          SnackBarService.display(
            message: AppL10n.tr(AppTranslationKeys.selectValidAccounts),
            autoDismiss: true,
            title: AppL10n.tr(AppTranslationKeys.transfer),
            duration: _snackDurationSeconds,
          );
        } else {
          // Add the main Transaction of the transfer
          final Transaction newTransactionFromAccount = Transaction(
            date: inputData.date,
          );
          newTransactionFromAccount.fieldAccountId.value = inputData.accountFrom.uniqueId;
          newTransactionFromAccount.fieldMemo.value = inputData.memo;
          if (inputData.category != null) {
            newTransactionFromAccount.fieldCategoryId.value = inputData.category!.uniqueId;
          }
          newTransactionFromAccount.fieldAmount.value.setAmount(
            inputData.amount.abs() * _transferAmountSign,
          ); // From account must be negative

          Data().transactions.appendNewMoneyObject(
            newTransactionFromAccount,
            fireNotification: false,
          );

          // add the receiving account transaction and link them
          Data().makeTransferLinkage(
            transactionSource: newTransactionFromAccount,
            destinationAccount: inputData.accountTo,
          );

          // update the app
          Data().updateAll();
          Navigator.of(context).pop(false);
        }
      },
    ),
  ];
  return actionButtons;
}
