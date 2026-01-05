import 'package:flutter/material.dart';
import 'package:money/helpers/account_types_enum.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/import/import_transactions_from_text.dart';
import 'package:money/import/import_transactions_list_preview.dart';
import 'package:money/models/accounts/account.dart';
import 'package:money/models/transactions/transaction.dart';
import 'package:money/views/data/data.dart';
import 'package:money/views/dialog/confirmation_dialog.dart';
import 'package:money/views/dialog/picker_panel.dart';
import 'package:money/widgets/snack_bar.dart';
import 'package:money/widgets/value_parser.dart';

class ImportData {
  List<ImportEntry> entries = <ImportEntry>[];
  String fileType = '';

  Account? account;
  AccountType? accountType;
}

class ImportEntry {
  ImportEntry({
    required this.type,
    required this.date,
    required this.amount,
    required this.name,
    required this.fitid,
    this.memo = '',
    this.number = '',
    this.stockAction = '',
    this.stockSymbol = '',
    this.stockQuantity = 0.00,
    this.stockPrice = 0.00,
    this.stockCommission = 0.00,
  });

  factory ImportEntry.blank() {
    return ImportEntry(
      type: '',
      date: DateTime.now(),
      amount: 0.00,
      name: '',
      fitid: '',
      stockAction: '',
      stockSymbol: '',
    );
  }

  late double amount;
  late DateTime date;
  late String fitid;
  late String memo;
  late String name;
  late String number;
  late String stockAction;
  late double stockCommission;
  late double stockPrice;
  late double stockQuantity;
  late String stockSymbol;
  late String type;

  /// when there's no 'name' then fallback to 'memo'
  String getDescription() {
    if (name.isNotEmpty) {
      return name;
    }
    if (memo.isNotEmpty) {
      return memo;
    }
    return '$stockSymbol $stockAction ${formatDoubleTrimZeros(stockQuantity)} x ${stockPrice.toString()}';
  }
}

void showAndConfirmTransactionToImport(
  final BuildContext context,
  final ImportData importData,
) {
  if (importData.account == null) {
    final List<String> activeAccountNames = Data().accounts
        .getListSorted()
        .map((Account element) => element.fieldName.value)
        .toList();

    showPopupSelection(
      title: 'Pick account to import to',
      context: context,
      items: activeAccountNames,
      selectedItem: '',
      onSelected: (final String text) {
        final Account? accountSelected = Data().accounts.getByName(text);
        if (accountSelected != null) {
          _showAndConfirmTransactionToImport(
            context,
            importData.fileType,
            importData.entries,
            accountSelected,
          );
        } else {
          SnackBarService.displayWarning(
            autoDismiss: false,
            message:
                'Import - No matching "${importData.fileType}" accounts with ID "${importData.account?.uniqueId.toString() ?? '-1'}"',
          );
          return;
        }
      },
    );
  } else {
    _showAndConfirmTransactionToImport(
      context,
      importData.fileType,
      importData.entries,
      importData.account!,
    );
  }
}

void _showAndConfirmTransactionToImport(
  final BuildContext context,
  final String fileType,
  final List<ImportEntry> list,
  final Account account,
) {
  final List<ValuesQuality> valuesQuality = <ValuesQuality>[];

  // attempt to find or add new transactions
  for (final ImportEntry item in list) {
    valuesQuality.add(
      ValuesQuality(
        date: ValueQuality(dateToString(item.date), dateFormat: 'yyyy-MM-dd'),
        description: ValueQuality(item.getDescription()),
        amount: ValueQuality(item.amount.toString()),
      ),
    );
  }

  final String messageToUser =
      '${list.length} transactions found in $fileType file, to be imported into "${account.fieldName.value}"';

  final Widget questionContent = SizedBox(
    height: 400,
    child: Center(
      child: ImportTransactionsListPreview(
        accountId: account.uniqueId,
        values: valuesQuality,
      ),
    ),
  );

  showConfirmationDialog(
    context: context,
    title: 'Import QFX',
    question: messageToUser,
    content: questionContent,
    buttonText: 'Import',
    onConfirmation: () {
      final List<Transaction> transactionsToAdd = <Transaction>[];
      for (final ValuesQuality singleTransactionInput in valuesQuality) {
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
        'Imported - ${transactionsToAdd.length} transactions into "${account.fieldName.value}"',
      );
    },
  );
}
