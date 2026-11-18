// ignore: fcheck_one_class_per_file
import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/investment_type_helper.dart';
import 'package:money/data/models/account_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/security_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/views/imports/shared/import_duplicate_helper.dart';
import 'package:money/views/imports/shared/transactions_import_list_preview_widget.dart';
import 'package:money/views/imports/shared/transactions_text_import_view.dart';
import 'package:money/widgets/columns/value_quality.dart';
import 'package:money/widgets/dialogs/confirmation_dialog.dart';
import 'package:money/widgets/pickers/picker_panel.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';

const double _previewHeight = 400.0;

/// Returns true when imported entries suggest investment/stock activity.
bool _hasInvestmentEntryHints(List<ImportEntry> entries) {
  for (final ImportEntry entry in entries) {
    if (entry.stockSymbol.isNotEmpty ||
        entry.stockAction.isNotEmpty ||
        entry.stockQuantity != 0.0 ||
        entry.stockPrice != 0.0) {
      return true;
    }
  }
  return false;
}

/// Returns true if account picker should be limited to investment-capable accounts.
bool _shouldFilterToInvestmentAccounts(ImportData importData) {
  if (isInvestmentAccountType(importData.accountType)) {
    return true;
  }
  return _hasInvestmentEntryHints(importData.entries);
}

/// Represents import data.
class ImportData {
  /// Parsed entries that are eligible for import.
  List<ImportEntry> entries = <ImportEntry>[];

  /// Source file type label (for example, CSV, QFX).
  String fileType = '';

  /// Optional account associated with the imported file.
  Account? account;

  /// Optional account type associated with the imported file.
  AccountType? accountType;

  /// Diagnostics captured while parsing source rows.
  final ImportDiagnostics diagnostics = ImportDiagnostics();

  /// Distinct source accounts named in the file; more than one cannot be imported into a single account.
  final Set<String> sourceAccounts = <String>{};
}

/// Captures import parsing counters and row skip reasons.
class ImportDiagnostics {
  /// Total number of source data rows examined (excluding header row).
  int processedRows = 0;

  /// Total number of rows skipped during parsing.
  int skippedRows = 0;

  /// Skipped-row counters grouped by a stable reason key.
  final Map<String, int> skippedByReason = <String, int>{};

  /// Increments the skipped counter for [reasonKey].
  void incrementSkipped(String reasonKey) {
    skippedRows = skippedRows + 1;
    skippedByReason[reasonKey] = (skippedByReason[reasonKey] ?? 0) + 1;
  }
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
  BuildContext context,
  ImportData importData,
) {
  if (importData.sourceAccounts.length > 1) {
    SnackBarService.displayWarning(
      autoDismiss: false,
      message: AppL10n.tr(
        AppTranslationKeys.importFileHasMultipleAccounts,
        params: <String, String>{
          'fileType': importData.fileType,
          'count': importData.sourceAccounts.length.toString(),
        },
      ),
    );
    return;
  }

  if (importData.account == null) {
    final bool onlyInvestmentAccounts = _shouldFilterToInvestmentAccounts(importData);
    final Iterable<Account> availableAccounts = onlyInvestmentAccounts
        ? Data().accounts.getListSorted().where((Account account) => account.isInvestmentAccount())
        : Data().accounts.getListSorted();
    final List<String> activeAccountNames = availableAccounts
        .map((Account element) => element.fieldName.value)
        .toList();

    if (activeAccountNames.isEmpty) {
      SnackBarService.displayWarning(
        autoDismiss: false,
        message: AppL10n.tr(AppTranslationKeys.aiNoOpenAccountsAvailableForImport),
      );
      return;
    }

    showPopupSelection(
      title: AppL10n.tr(AppTranslationKeys.pickAccountToImportTo),
      context: context,
      items: activeAccountNames,
      selectedItem: '',
      onSelected: (String text) {
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
  BuildContext context,
  String fileType,
  List<ImportEntry> list,
  Account account,
) {
  final List<ValuesQuality> valuesQuality = <ValuesQuality>[];

  // attempt to find or add new transactions
  for (final ImportEntry item in list) {
    valuesQuality.add(
      ValuesQuality(
        date: ValueQuality(dateToString(item.date), dateFormat: 'yyyy-MM-dd'),
        description: ValueQuality(item.getDescription()),
        amount: ValueQuality(item.amount.toString()),
        stockSymbol: item.stockSymbol,
        stockAction: item.stockAction,
        stockQuantity: item.stockQuantity,
        stockPrice: item.stockPrice,
        fitid: item.fitid,
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
    width: double.infinity,
    height: _previewHeight,
    child: ImportTransactionsListPreview(
      accountId: account.uniqueId,
      values: valuesQuality,
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
      // Re-check against the current data: another import may have been confirmed since the preview opened.
      markExistingImportValues(accountId: account.uniqueId, values: valuesQuality);

      final List<Transaction> transactionsToAdd = <Transaction>[];
      final List<({Transaction transaction, Investment investment})> investmentsToAdd =
          <({Transaction transaction, Investment investment})>[];
      for (int i = 0; i < list.length; i++) {
        final ImportEntry entry = list[i];
        final ValuesQuality singleTransactionInput = valuesQuality[i];
        if (singleTransactionInput.exist) {
          continue;
        }

        final Transaction transaction = _buildTransactionFromImportEntry(
          account: account,
          entry: entry,
        );

        final bool hasInvestmentMetadata = _isInvestmentPositionEvent(entry);
        if (hasInvestmentMetadata) {
          transaction.fieldCategoryId.value = _resolveInvestmentCategoryId(entry);
        }

        transactionsToAdd.add(transaction);

        if (hasInvestmentMetadata) {
          final Investment? investment = buildInvestmentFromImportEntry(entry);
          if (investment != null) {
            investmentsToAdd.add((transaction: transaction, investment: investment));
          }
        }
      }

      if (transactionsToAdd.isEmpty) {
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
        return;
      }

      for (final Transaction transaction in transactionsToAdd) {
        Data().transactions.appendNewMoneyObject(
          transaction,
          fireNotification: false,
        );
      }

      for (final ({Transaction transaction, Investment investment}) item in investmentsToAdd) {
        appendInvestmentForTransaction(item.investment, item.transaction);
      }

      Data().updateAll();

      SnackBarService.displaySuccess(
        autoDismiss: true,
        title: AppL10n.tr(AppTranslationKeys.importWord),
        message: AppL10n.tr(
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

/// Adds [investment] to the investments, keyed by the id of its [transaction], and counts it as an unsaved insert.
void appendInvestmentForTransaction(Investment investment, Transaction transaction) {
  // Investment rows share the id of their transaction; set it before adding so the lookup key matches.
  investment.uniqueId = transaction.uniqueId;
  Data().investments.appendMoneyObject(investment);
  DataObject.onMutationChanged?.call(
    mutation: MutationType.inserted,
    moneyObject: investment,
    recalculateBalances: false,
  );
}

/// Warns the user when rows of [importData] were skipped because they could not be read.
void showImportSkippedRowsWarning(ImportData importData) {
  if (importData.diagnostics.skippedRows == 0) {
    return;
  }
  SnackBarService.displayWarning(
    autoDismiss: true,
    message: AppL10n.tr(
      AppTranslationKeys.importRowsParsedAndSkipped,
      params: <String, String>{
        'fileType': importData.fileType,
        'imported': importData.entries.length.toString(),
        'skipped': importData.diagnostics.skippedRows.toString(),
      },
    ),
  );
}

/// Builds a transaction from an import [entry] for the selected [account].
Transaction _buildTransactionFromImportEntry({
  required Account account,
  required ImportEntry entry,
}) {
  final Transaction transaction = Transaction.fromDateDescriptionAmount(
    account,
    entry.date,
    entry.getDescription(),
    entry.amount,
  );

  if (entry.memo.isNotEmpty) {
    transaction.fieldMemo.value = entry.memo;
  }
  if (entry.number.isNotEmpty) {
    transaction.fieldNumber.value = entry.number;
  }
  if (entry.fitid.isNotEmpty) {
    transaction.fieldFitid.value = entry.fitid;
  }

  return transaction;
}

/// Returns `true` when [entry] represents a real investment position event.
bool _isInvestmentPositionEvent(ImportEntry entry) {
  final String symbol = entry.stockSymbol.trim();
  if (symbol.isEmpty) {
    return false;
  }

  final InvestmentType investmentType = _resolveInvestmentTypeFromEntry(entry);
  return investmentType != InvestmentType.none;
}

/// Resolves the category ID for an imported investment [entry].
int _resolveInvestmentCategoryId(ImportEntry entry) {
  final InvestmentType investmentType = _resolveInvestmentTypeFromEntry(entry);
  switch (investmentType) {
    case InvestmentType.buy:
    case InvestmentType.add:
      return Data().categories.investmentDebit.fieldId.value;
    case InvestmentType.sell:
    case InvestmentType.remove:
      return Data().categories.investmentCredit.fieldId.value;
    case InvestmentType.dividend:
      return Data().categories.investmentDividends.fieldId.value;
    case InvestmentType.none:
      return entry.amount >= 0
          ? Data().categories.investmentCredit.fieldId.value
          : Data().categories.investmentDebit.fieldId.value;
  }
}

/// Builds an investment object from [entry] when stock symbol metadata is available.
@visibleForTesting
Investment? buildInvestmentFromImportEntry(ImportEntry entry) {
  final String symbol = entry.stockSymbol.trim();
  if (symbol.isEmpty) {
    return null;
  }

  // Pass the CSV description as the security name for display
  final Security security = Data().securities.getOrCreate(symbol, name: entry.name);
  final InvestmentType investmentType = _resolveInvestmentTypeFromEntry(entry);
  if (investmentType == InvestmentType.none) {
    return null;
  }

  return Investment(
    id: -1,
    security: security.fieldId.value,
    // The investment type carries the direction; a sell exported as a negative quantity still removes shares.
    units: entry.stockQuantity.abs(),
    unitPrice: entry.stockPrice,
    investmentType: investmentType.index,
    tradeType: fromInvestmentType(investmentType).index,
    commission: entry.stockCommission,
    data: Data(),
  );
}

/// Maps broker action text in [entry] to a normalized [InvestmentType].
InvestmentType _resolveInvestmentTypeFromEntry(ImportEntry entry) {
  final String action = entry.stockAction.trim().toLowerCase();
  if (action.isNotEmpty) {
    if (action.contains(SharedStrings.investmentActionDividend) ||
        action == SharedStrings.investmentActionDividendShort ||
        action.contains(SharedStrings.investmentActionReinvest)) {
      return InvestmentType.dividend;
    }

    if (action.contains(SharedStrings.investmentActionBuy) ||
        action.contains(SharedStrings.investmentActionPurchase) ||
        action.contains(SharedStrings.investmentActionBought)) {
      return InvestmentType.buy;
    }

    if (action.contains(SharedStrings.investmentActionSell) ||
        action.contains(SharedStrings.investmentActionSale) ||
        action.contains(SharedStrings.investmentActionSold) ||
        action.contains(SharedStrings.investmentActionRedemption)) {
      return InvestmentType.sell;
    }
  }

  if (entry.stockQuantity > 0) {
    return InvestmentType.buy;
  }
  if (entry.stockQuantity < 0) {
    return InvestmentType.sell;
  }

  return InvestmentType.none;
}
