// ignore: fcheck_one_class_per_file
import 'package:flutter/material.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/views/imports/shared/transactions_import_list_preview_widget.dart';
import 'package:money/views/imports/shared/transactions_text_import_view.dart';
import 'package:money/widgets/columns/value_quality.dart';
import 'package:money/widgets/dialogs/confirmation_dialog.dart';
import 'package:money/widgets/pickers/picker_panel.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';

const double _previewHeight = 400.0;

/// Represents import data.
class ImportData {
  List<ImportEntry> entries = <ImportEntry>[];
  String fileType = '';

  Account? account;
  AccountType? accountType;
}

/// Represents import entry.
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
    return '$stockSymbol $stockAction ${formatDoubleTrimZeros(stockQuantity)}${SharedStrings.multiplierX}${stockPrice.toString()}';
  }
}

/// Shows confirmation dialog for importing transactions from ImportData.
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
      title: AppL10n.tr(AppTranslationKeys.pickAccountToImportTo),
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
            message: AppL10n.tr(
              AppTranslationKeys.importNoMatchingAccountsWithId,
              params: <String, String>{
                'fileType': importData.fileType,
                'id': importData.account?.uniqueId.toString() ?? '-1',
              },
            ),
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

/// Shows a preview dialog for imported entries and adds new transactions on confirmation.
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

  final String messageToUser = AppL10n.tr(
    AppTranslationKeys.transactionsFoundInFileToImport,
    params: <String, String>{
      'count': list.length.toString(),
      'fileType': fileType,
      'account': account.fieldName.value,
    },
  );

  final Widget questionContent = SizedBox(
    height: _previewHeight,
    child: Center(
      child: ImportTransactionsListPreview(
        accountId: account.uniqueId,
        values: valuesQuality,
      ),
    ),
  );

  showConfirmationDialog(
    context: context,
    title: AppL10n.tr(
      AppTranslationKeys.importFileType,
      params: <String, String>{'fileType': fileType},
    ),
    question: messageToUser,
    content: questionContent,
    buttonText: AppL10n.tr(AppTranslationKeys.importWord),
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
        AppL10n.tr(
          AppTranslationKeys.importedTransactionsIntoAccount,
          params: <String, String>{
            'count': transactionsToAdd.length.toString(),
            'account': account.fieldName.value,
          },
        ),
      );
    },
  );
}
