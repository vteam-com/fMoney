import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/views/imports/shared/transactions_import_panel.dart';
import 'package:money/widgets/columns/value_parser.dart';
import 'package:money/widgets/columns/value_quality.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';
import 'package:money/widgets/dialogs/message_box_dialog.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';

/// Shows dialog for importing transactions from text input.
void showImportTransactionsFromTextInput(
  final BuildContext context, [
  String? initialText,
]) {
  initialText ??= '';

  Account account = Data().accounts.getMostRecentlySelectedAccount();

  final ValuesParser parser = ValuesParser(
    dateFormat: 'MM/dd/yyyy',
    currency: SharedStrings.currencyUsd,
  );

  final List<Widget> actionButtons = <Widget>[
    // Button - Import
    DialogActionButton(
      text: AppL10n.tr(AppTranslationKeys.importWord),
      onPressed: () {
        if (parser.isEmpty) {
          messageBox(context, AppL10n.tr(AppTranslationKeys.nothingToImport));
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
            AppL10n.tr(
              AppTranslationKeys.transactionsAddedCount,
              params: <String, String>{'count': transactionsToAdd.length.toString()},
            ),
          );

          Navigator.of(context).pop(false);
        }
      },
    ),
  ];

  adaptiveScreenSizeDialog(
    context: context,
    captionForClose: AppL10n.tr(AppTranslationKeys.cancel),
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
    title: AppL10n.tr(AppTranslationKeys.importWord),
    message: messageToUserAfterAdding,
  );
}
