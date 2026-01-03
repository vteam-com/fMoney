import 'package:money/data/data.dart';
import 'package:money/money_objects/accounts/account.dart';
import 'package:money/money_objects/transactions/transaction.dart';
import 'package:money/views/dialog/dialog.dart';
import 'package:money/views/dialog/dialog_button.dart';
import 'package:money/views/import_transactions_panel.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/message_box.dart';
import 'package:money/widgets/snack_bar.dart';
import 'package:money/widgets_data/value_parser.dart';

void showImportTransactionsFromTextInput(
  final BuildContext context, [
  String? initialText,
]) {
  initialText ??= '';

  Account account = Data().accounts.getMostRecentlySelectedAccount();

  final ValuesParser parser = ValuesParser(
    dateFormat: 'MM/dd/yyyy',
    currency: 'USD',
  );

  final List<Widget> actionButtons = <Widget>[
    // Button - Import
    DialogActionButton(
      text: 'Import',
      onPressed: () {
        if (parser.isEmpty) {
          messageBox(context, 'Nothing to import');
        } else {
          // Import
          final List<Transaction> transactionsToAdd = <Transaction>[];

          for (final ValuesQuality singleTransactionInput in parser.lines) {
            if (!singleTransactionInput.exist) {
              final Transaction t = Transaction.fromDateDescriptionAmount(
                account,
                singleTransactionInput.date.asDate() ?? DateTime.now(),
                singleTransactionInput.description.asString(),
                singleTransactionInput.amount.asAmount(),
              );
              transactionsToAdd.add(t);
            }
          }
          addNewTransactions(
            transactionsToAdd,
            '${transactionsToAdd.length} transactions added',
          );

          Navigator.of(context).pop(false);
        }
      },
    ),
  ];

  adaptiveScreenSizeDialog(
    context: context,
    captionForClose: 'Cancel',
    actionButtons: actionButtons,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        gapLarge(),
        Expanded(
          child: ImportTransactionsPanel(
            account: account,
            inputText: initialText,
            onAccountChanged: (Account accountSelected) {
              account = accountSelected;
              Data().accounts.setMostRecentUsedAccount(accountSelected);
            },
            onTransactionsFound: (final ValuesParser newParser) {
              parser.lines = newParser.lines;
            },
          ),
        ),
      ],
    ),
  );
}

/// Add the list of transactions "as is", then notify the user when completed
/// Note that this does not check for duplicated transaction or resolves the Payee names
void addNewTransactions(
  List<Transaction> transactionsNew,
  String messageToUserAfterAdding,
) {
  if (transactionsNew.isEmpty) {
    SnackBarService.displayWarning(
      autoDismiss: true,
      message: messageToUserAfterAdding,
    );
    return;
  }

  for (final Transaction transactionToAdd in transactionsNew) {
    Data().transactions.appendNewMoneyObject(
      transactionToAdd,
      fireNotification: false,
    );
  }
  Data().updateAll();

  SnackBarService.displaySuccess(
    autoDismiss: true,
    title: 'Import',
    message: messageToUserAfterAdding,
  );
}
