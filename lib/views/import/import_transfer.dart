import 'package:get/get.dart';
import 'package:money/views/import/import_transfer_panel.dart';
import 'package:money/views/models/data/data.dart';
import 'package:money/views/models/dialog/dialog.dart';
import 'package:money/views/models/dialog/dialog_button.dart';
import 'package:money/views/models/transactions/transaction.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/snack_bar.dart';

void showImportTransfer({ImportFieldsForTransfer? inputData}) {
  inputData ??= ImportFieldsForTransfer(
    accountFrom: Data().accounts.getMostRecentlySelectedAccount(),
    accountTo: Data().accounts.getMostRecentlySelectedAccount(),
    date: DateTime.now(),
    category: null,
    amount: 0,
    memo: '',
  );

  final BuildContext context = Get.context!;
  adaptiveScreenSizeDialog(
    context: context,
    captionForClose: 'Cancel',
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

List<Widget> getActionButtons(
  ImportFieldsForTransfer inputData,
  BuildContext context,
) {
  final List<Widget> actionButtons = <Widget>[
    // Button - Import
    DialogActionButton(
      text: 'Record Transfer',
      onPressed: () {
        if (!inputData.validAccounts) {
          SnackBarService.display(
            message: 'Select valid accounts.',
            autoDismiss: true,
            title: 'Transfer',
            duration: 5,
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
            inputData.amount.abs() * -1,
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
