// Imports
// The following lines import necessary libraries and packages for the file.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/helpers/transaction_types.dart';
import 'package:money/shared/domain/account.dart';
import 'package:money/shared/domain/account_aliases.dart';
import 'package:money/shared/domain/accounts.dart';
import 'package:money/shared/domain/aliases.dart';
import 'package:money/shared/domain/categories.dart';
import 'package:money/shared/domain/category.dart';
import 'package:money/shared/domain/currencies.dart';
import 'package:money/shared/domain/data_abstract.dart';
import 'package:money/shared/domain/data_collections.dart';
import 'package:money/shared/domain/event.dart';
import 'package:money/shared/domain/events.dart';
import 'package:money/shared/domain/investment.dart';
import 'package:money/shared/domain/investments.dart';
import 'package:money/shared/domain/loan_payment.dart';
import 'package:money/shared/domain/loan_payments.dart';
import 'package:money/shared/domain/money_objects.dart';
import 'package:money/shared/domain/online_accounts.dart';
import 'package:money/shared/domain/payee.dart';
import 'package:money/shared/domain/payees.dart';
import 'package:money/shared/domain/rent_buildings.dart';
import 'package:money/shared/domain/rental_units.dart';
import 'package:money/shared/domain/securities.dart';
import 'package:money/shared/domain/splits.dart';
import 'package:money/shared/domain/stock_split.dart';
import 'package:money/shared/domain/stock_splits.dart';
import 'package:money/shared/domain/transaction_extras.dart';
import 'package:money/shared/domain/transactions.dart';
import 'package:money/shared/domain/transfer.dart';
import 'package:money/widgets/pure/mutation_types.dart';
import 'package:money/widgets/pure/snack_bar.dart';
import 'package:money/widgets/widgets_domain/data_access.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';

/// Represents data.
///
/// This file used to have a single monolithic `Data` class that mixed:
/// 1) collection/table wiring & dependency injection, and
/// 2) domain operations (mutations, transfers, recalculation, queries).
///
/// It is now split into two responsibilities:
/// - [DataCollections]: owns all MoneyObjects managers + table ordering + DI wiring.
/// - [Data]: the operational facade (implements [DataAbstract]) that delegates to the collections.
class Data implements DataAbstract {
  /// singleton access
  factory Data() => _instance;

  /// private constructor
  Data._internal() {
    DataAbstract.instance = this;

    // Collection/table wiring and DI live in DataCollections.
    collections = DataCollections(data: this);

    // Wire global callbacks.
    DataAccess.notifyMutationChanged = notifyMutationChanged;
    DataAccess.getCategoryName = categories.getNameFromId;
    DataObject.onMutationChanged = notifyMutationChanged;
    DataObject.getCategoryName = categories.getNameFromId;
    DataObject.getCurrencyRatio = currencies.getRatioFromSymbol;
  }

  /// singleton
  static final Data _instance = Data._internal();

  /// Collection registry + dependency injection.
  late final DataCollections collections;

  /// Tables in the required load/recalc order.
  List<MoneyObjects<dynamic>> get tables => collections.tables;

  /// 1 Account Aliases
  AccountAliases get accountAliases => collections.accountAliases;

  /// 2 Accounts
  Accounts get accounts => collections.accounts;

  /// 3 Aliases of Payees
  Aliases get aliases => collections.aliases;

  /// 4 Categories of Transactions
  Categories get categories => collections.categories;

  /// 5 Currencies definitions used in the money files
  Currencies get currencies => collections.currencies;

  /// 16 Events
  Events get events => collections.events;

  /// 6 Investment transactions
  Investments get investments => collections.investments;

  /// 7
  LoanPayments get loanPayments => collections.loanPayments;

  /// 8
  OnlineAccounts get onlineAccounts => collections.onlineAccounts;

  /// 9
  Payees get payees => collections.payees;

  /// 10
  RentBuildings get rentBuildings => collections.rentBuildings;

  /// 11
  RentUnits get rentUnits => collections.rentUnits;

  /// 12
  Securities get securities => collections.securities;

  /// 13
  Splits get splits => collections.splits;

  /// 14
  StockSplits get stockSplits => collections.stockSplits;

  /// 15
  TransactionExtras get transactionExtras => collections.transactionExtras;

  /// 16 All Transactions in the Money file
  Transactions get transactions => collections.transactions;

  /// Provider for category suggestion widgets
  /// Must be set by upper view layers (home view or main app) before use
  @override
  dynamic categorySuggestionProvider;

  /// Provider for merge payee functionality
  /// Must be set by upper view layers (home view or main app) before use
  dynamic _mergePayeeProvider;

  @override
  dynamic get mergePayeeProvider => _mergePayeeProvider;

  @override
  set mergePayeeProvider(dynamic value) => _mergePayeeProvider = value;

  /// Checks for dangling transfers and shows a warning if any are found.
  void checkTransfers() {
    final Set<Transaction> dangling = getDanglingTransfers();
    if (dangling.isNotEmpty) {
      Timer(
        const Duration(milliseconds: DurationInMs.quick),
        () => SnackBarService.displayWarning(
          message: '${dangling.length}${SharedDomainStrings.domainString001}',
          title: SharedDomainStrings.domainString043,
          autoDismiss: false,
        ),
      );
    }
  }

  /// Clears all data and resets mutations.
  void clear() {
    clearExistingData();
  }

  /// Clears all existing data from all tables.
  void clearExistingData() {
    for (final MoneyObjects<dynamic> moneyObjects in tables) {
      moneyObjects.clear();
    }

    try {
      DataAccess.trackMutations.reset();
    } catch (_) {
      // not initialized in unit tests
    }
  }

  @override
  void clearTransferToAccount(int transactionId, dynamic a) {
    final Transaction? t = transactions.get(transactionId);
    if (t == null) {
      return; // Transaction not found
    }
    // TODO
    // if (t.isSplit) {
    //   for (MoneySplit s in t.splits) {
    //     if (s.Transfer != null && s.Transfer.Transaction.Account == a) {
    //       ClearTransferToAccount(s.Transfer);
    //       s.ClearTransfer();
    //       s.Category =
    //           s.Amount < 0 ? this.Categories.TransferToDeletedAccount : this.Categories.TransferFromDeletedAccount;
    //       if (string.IsNullOrEmpty(s.Memo)) {
    //         s.Memo = a.Name;
    //       }
    //     }
    //   }
    // }

    // if (t.Transfer != null && t.Transfer.Transaction.Account == a) {
    //   ClearTransferToAccount(t.Transfer);
    //   t.Transfer = null;
    //   if (!t.IsSplit) {
    //     t.Category =
    //         t.Amount < 0 ? this.Categories.TransferToDeletedAccount : this.Categories.TransferFromDeletedAccount;
    //   }
    //   if (string.IsNullOrEmpty(t.Memo)) {
    //     t.Memo = a.Name;
    //   }
    // }
  }

  /// Close data source
  void close() {
    clearExistingData();

    try {
      DataAccess.onFileClosed();
      DataAccess.trackMutations.reset();
    } catch (_) {
      // not initialized in unit tests
    }
  }

  /// Deletes the given items and triggers mutation notifications.
  void deleteItems(final List<DataObject> itemsToDelete) {
    for (final DataObject item in itemsToDelete) {
      notifyMutationChanged(
        mutation: MutationType.deleted,
        moneyObject: item,
        recalculateBalances: false,
      );
    }
    updateAll();
  }

  /// Returns transfers that reference deleted accounts.
  Set<Transaction> getDanglingTransfers() {
    final Set<Transaction> dangling = <Transaction>{};
    final List<Account> deletedAccounts = <Account>[];
    transactions.checkTransfers(dangling, deletedAccounts);
    for (final Account a in deletedAccounts) {
      accounts.removeAccount(a);
    }
    return dangling;
  }

  /// Groups mutated objects by type for pending changes UI.
  List<MutationGroup> getMutationGroups(final MutationType typeOfMutation) {
    final List<MutationGroup> allMutationGroups = <MutationGroup>[];

    for (final MoneyObjects<dynamic> moneyObjects in tables) {
      final List<DataObject> mutatedInstances = moneyObjects.getMutatedObjects(
        typeOfMutation,
      );
      if (mutatedInstances.isNotEmpty) {
        final MutationGroup mutationGroup = MutationGroup();
        mutationGroup.title = moneyObjects.collectionName;
        mutationGroup.whatWasMutated = moneyObjects.whatWasMutated(
          mutatedInstances,
        );
        allMutationGroups.add(mutationGroup);
      }
    }
    return allMutationGroups;
  }

  /// Calculates net worth across all accounts.
  AmountModel getNetWorth() {
    final double sum = accounts.getSumOfAccountBalances();
    return AmountModel(amount: sum);
  }

  /// Finds or creates the related transfer transaction for a destination account.
  Transaction? getOrCreateRelatedTransaction({
    required Transaction transactionSource,
    required Account destinationAccount,
  }) {
    if (transactionSource.fieldAccountId.value == destinationAccount.uniqueId) {
      logger.e('Cannot transfer to same account');
      return null;
    }

    final double destinationAmount = transactionSource.fieldAmount.value.asDouble() * -1;

    Transaction? relatedTransaction;
    try {
      relatedTransaction = this.transactions.findExistingTransaction(
        accountId: destinationAccount.uniqueId,
        dateRange: DateRange(
          min: transactionSource.fieldDateTime.value!.startOfDay,
          max: transactionSource.fieldDateTime.value!.endOfDay,
        ),
        amount: destinationAmount,
      );
    } catch (_) {
      // something went wrong, assume no match found
    }

    if (relatedTransaction == null) {
      relatedTransaction = Transaction(
        accountId: destinationAccount.uniqueId,
        date: transactionSource.fieldDateTime.value,
      );

      // flip the sign on the amount
      relatedTransaction.fieldAmount.value.setAmount(destinationAmount);
      relatedTransaction.fieldCategoryId.value = transactionSource.fieldCategoryId.value;
      relatedTransaction.fieldFitid.value = transactionSource.fieldFitid.value;
      relatedTransaction.fieldNumber.value = transactionSource.fieldNumber.value;
      relatedTransaction.fieldMemo.value = transactionSource.fieldMemo.value;
      //u.Status = t.Status; no !!!
    }

    // Investment? i = relatedTransaction.investmentInstance;
    // if (i != null) {
    //   Investment j = transactionSource.getOrCreateInvestment();
    //   j.units = i.units;
    //   j.unitPrice = i.unitPrice;
    //   j.security = i.security;
    //   //   switch (i.Type) {
    //   //     case InvestmentType.Add:
    //   //       j.Type = InvestmentType.Remove;
    //   //       break;
    //   //     case InvestmentType.Remove:
    //   //       j.Type = InvestmentType.Add;
    //   //       break;
    //   //     case InvestmentType.None: // assume it's a remove
    //   //       i.Type = InvestmentType.Remove;
    //   //       j.Type = InvestmentType.Add;
    //   //       break;
    //   //     case InvestmentType.Buy:
    //   //     case InvestmentType.Sell:
    //   //       throw new MoneyException("Transfer must be of type 'Add' or 'Remove'.");
    //   //   }
    //   //   u.Investment = j;
    // }

    return relatedTransaction;
  }

  /// Ensures transfer linkage exists or updates it for the given transaction.
  void verifyApplyTransfer({
    required final Transaction transaction,
    required final Account? relatedAccount,
  }) {
    if (relatedAccount == null) {
      return; // nothing to check
    }
    if (transaction.instanceOfTransfer != null) {
      // this was already a transfer, lets see if the destination account has changed
      if (transaction.instanceOfTransfer?.receiverAccount?.uniqueId == relatedAccount.uniqueId) {
        // same account do noting
      } else {
        // use the new account destination
        final Transaction relatedTransaction = transaction.instanceOfTransfer!.relatedTransaction! as Transaction;
        transaction.instanceOfTransfer!.relatedTransaction!.instanceOfAccount = accounts.get(
          relatedAccount.uniqueId,
        );
        relatedTransaction.mutateField(
          SharedDomainStrings.domainString011,
          relatedAccount.uniqueId,
          false,
        );
      }
    } else {
      makeTransferLinkage(
        transactionSource: transaction,
        destinationAccount: relatedAccount,
      );
    }
  }

  /// Creates a transfer linkage between source and destination transactions.
  Transaction makeTransferLinkage({
    required Transaction transactionSource,
    required Account destinationAccount,
  }) {
    final Transaction? relatedTransaction = getOrCreateRelatedTransaction(
      transactionSource: transactionSource,
      destinationAccount: destinationAccount,
    );

    if (relatedTransaction != null) {
      final Transfer transfer;

      if (transactionSource.fieldAmount.value.asDouble() < 0) {
        // transfer TO
        transfer = Transfer(
          id: 0,
          source: transactionSource,
          relatedTransaction: relatedTransaction,
          isOrphan: false,
        );
      } else {
        // transfer FROM
        transfer = Transfer(
          id: 0,
          source: relatedTransaction,
          relatedTransaction: transactionSource,
          isOrphan: false,
        );
      }

      // Keep track changes done
      relatedTransaction.stashValueBeforeEditing();

      relatedTransaction.fieldPayee.value = this.categories.transfer.uniqueId;
      relatedTransaction.fieldTransfer.value = transactionSource.fieldId.value;
      relatedTransaction.instanceOfTransfer = transfer;

      if (relatedTransaction.uniqueId == -1) {
        // This is a new related transaction Append and get a new UniqueID
        transactions.appendNewMoneyObject(
          relatedTransaction,
          fireNotification: false,
        );
      } else {
        this.notifyMutationChanged(
          mutation: MutationType.changed,
          moneyObject: relatedTransaction,
          recalculateBalances: false,
        );
      }

      // this needs to happen last since the ID for a new Relation Transaction will be establish in the above
      transactionSource.fieldPayee.value = this.categories.transfer.uniqueId;
      transactionSource.fieldTransfer.value = relatedTransaction.uniqueId;
      transactionSource.instanceOfTransfer = transfer;
    }

    return relatedTransaction!;
  }

  /// let the app know that something has changed
  @override
  void notifyMutationChanged({
    required MutationType mutation,
    required DataObject moneyObject,
    bool recalculateBalances = true,
  }) {
    try {
      switch (mutation) {
        case MutationType.inserted:
          moneyObject.mutation = MutationType.inserted;
          DataAccess.trackMutations.increaseNumber(increaseAdded: 1);
        case MutationType.changed:
          // ensure that we only count editing once and discard if this was edited on a new inserted items
          if (moneyObject.mutation == MutationType.none) {
            moneyObject.mutation = MutationType.changed;
            DataAccess.trackMutations.increaseNumber(increaseChanged: 1);
          } else {
            DataAccess.trackMutations.setLastEditToNow();
          }
        case MutationType.deleted:
          if (moneyObject.mutation == MutationType.inserted) {
            // in case the delete item was a recently added item, we need to deduct it from the sum
            DataAccess.trackMutations.increaseNumber(increaseAdded: -1);
          }
          moneyObject.mutation = MutationType.deleted;
          DataAccess.trackMutations.increaseNumber(increaseDeleted: 1);
        default:
          break;
      }
    } catch (_) {
      // not initialized in unit tests
    }

    if (recalculateBalances) {
      updateAll();
    }
  }

  /// When Changes are done we can force a reevaluation of the balances
  void recalculateBalances() {
    for (final MoneyObjects<dynamic> moneyObjects in tables) {
      moneyObjects.onAllDataLoaded();
    }

    // one last thing, Transfer are complex and we try to confirm or clean up any problem found
    checkTransfers();
  }

  @override
  bool removeTransaction(int transactionId) {
    final Transaction? t = transactions.get(transactionId);
    if (t == null) {
      return false; // Transaction not found
    }
    if (t.fieldStatus.value == TransactionStatus.reconciled && t.fieldAmount.value.asDouble() != 0) {
      throw Exception('Cannot removed reconciled transaction');
    }
    // TODO
    // this.removeTransfer(t);

    // this.transactions.RemoveTransaction(t);
    // if (t.Unaccepted) {
    //   if (t.Account != null) {
    //     t.Account.Unaccepted--;
    //   }
    //   if (t.Payee != null) {
    //     t.Payee.UnacceptedTransactions--;
    //   }
    // }

    // if (t.Category == null && t.Transfer == null && !t.IsSplit) {
    //   if (t.Payee != null) {
    //     t.Payee.UnCategorizedTransactions--;
    //   }
    // }

    // this.Rebalance(t);
    return true;
  }

  /// ReBalance all objects values
  /// and Rebuild the UI
  @override
  void updateAll() {
    recalculateBalances();
    DataAccess.onDataChanged();
  }

  @override
  List<String> getPayeeNames() => payees.getSortedPayeeNames();

  @override
  Payee? getPayee(int id) => payees.get(id);

  @override
  Payee? getPayeeByName(String name) => payees.getByName(name);

  @override
  Payee getOrCreatePayee(String name, {bool fireNotification = true}) =>
      payees.getOrCreate(name, fireNotification: fireNotification);

  @override
  void removePayeesWithNoTransactions(List<int> payeeIds) => Payees.removePayeesThatHaveNoTransactions(payeeIds, this);

  @override
  List<Payee> getPayees() => payees.iterableList().toList();

  @override
  String getPayeeName(int id) => payees.getNameFromId(id);

  @override
  List<String> getPayeeNamesSorted() => payees.getSortedPayeeNames();

  @override
  void deletePayee(dynamic payee) => payees.deleteItem(payee as Payee);

  // Accounts
  @override
  Account? getAccount(int id) => accounts.get(id);

  @override
  String getAccountName(int id) => accounts.getNameFromId(id);

  @override
  Account? getAccountByName(String name) => accounts.getByName(name);

  @override
  List<String> getAccountNamesSorted() => accounts.getSortedAccountNames();

  @override
  String getAccountCurrency(int id) {
    final Account? a = accounts.get(id);
    if (a != null) {
      return a.fieldCurrency.value;
    }
    return '';
  }

  @override
  bool isAccountAsset(int id) {
    final Account? a = accounts.get(id);
    if (a != null) {
      return a.isAssetAccount;
    }
    return false;
  }

  // Aliases
  @override
  Payee? findOrCreateNewPayee(String name, {bool fireNotification = true}) =>
      aliases.findOrCreateNewPayee(name, fireNotification: fireNotification);

  @override
  List<String> getCategoryNames() => categories.getCategoriesAsStrings();

  @override
  String getCategoryNameFromId(int id) => categories.getNameFromId(id);

  @override
  Category? getCategory(int id) => categories.get(id);

  @override
  bool isCategoryExpense(int id) {
    final Category? c = categories.get(id);
    return c?.isExpense ?? false;
  }

  @override
  bool isCategoryIncome(int id) {
    final Category? c = categories.get(id);
    return c?.isIncome ?? false;
  }

  @override
  String getSecuritySymbolFromId(int id) => securities.getSymbolFromId(id);

  @override
  Security? getSecurity(int id) => securities.get(id);

  @override
  Security? getSecurityBySymbol(String symbol) => securities.getBySymbol(symbol);

  @override
  List<Security> getSecurities() => securities.iterableList().toList();

  @override
  int? getCategoryIdFromName(String name) => categories.getIdByName(name);

  @override
  Widget getCategoryWidget(int id) => categories.getCategoryWidget(id);

  @override
  List<String> getCategoriesAsStrings() => categories.getCategoriesAsStrings();

  @override
  int getSplitCategoryId() => categories.splitCategoryId();

  @override
  int getTransferCategoryId() => categories.transferCategoryId();

  @override
  Category getTransferCategory() => categories.transfer;

  @override
  Category getSplitCategory() => categories.split;

  @override
  List<int> getCategoryTreeIds(int categoryId) => categories.getTreeIds(categoryId);

  @override
  void appendNewCategory(dynamic category) => categories.appendNewMoneyObject(category as Category);

  @override
  void deleteCategory(dynamic category) => categories.deleteItem(category as Category);

  @override
  List<Category> getCategories({bool includeDeleted = false}) =>
      categories.iterableList(includeDeleted: includeDeleted).toList();

  @override
  List<StockSplit> getStockSplitsForSecurity(dynamic security) =>
      stockSplits.getStockSplitsForSecurity(security as Security);

  @override
  List<StockSplit> getStockSplitsForSecurityId(int securityId) {
    final Security? security = securities.get(securityId);
    if (security != null) {
      return stockSplits.getStockSplitsForSecurity(security);
    }
    return <StockSplit>[];
  }

  @override
  LoanPayment? getLoanPayment(int id) => loanPayments.get(id);

  @override
  List<LoanPayment> getLoanPayments() => loanPayments.iterableList().toList();

  @override
  Investment? getInvestment(int id) => investments.get(id);

  @override
  List<Investment> getInvestments() => investments.iterableList().toList();

  @override
  Transaction? getTransaction(int id) => transactions.get(id);

  @override
  Iterable<Transaction> getTransactions({bool includeDeleted = false}) =>
      transactions.iterableList(includeDeleted: includeDeleted);

  @override
  void appendTransaction(dynamic t) => transactions.appendMoneyObject(t as Transaction);

  @override
  void appendNewTransaction(dynamic t, {bool fireNotification = true}) =>
      transactions.appendNewMoneyObject(t as Transaction, fireNotification: fireNotification);

  @override
  List<Transaction> getTransactionsFlattenSplits({bool Function(dynamic)? whereClause}) =>
      transactions.getListFlattenSplits(whereClause: (Transaction t) => whereClause == null || whereClause(t));

  @override
  Iterable<Transaction> findTransfersToAccount(dynamic account) =>
      transactions.findTransfersToAccount(account as Account);

  @override
  void changeCategory(dynamic t, int categoryId) => Transaction.changeCategory(t as Transaction, categoryId);

  @override
  void changeCategoryFromCategoryName(dynamic t, String categoryName) {
    final int categoryId = getCategoryIdFromName(categoryName) ?? -1;
    if (categoryId != -1) {
      Transaction.changeCategory(t as Transaction, categoryId);
    }
  }

  @override
  double getSplitRatioForSecurityBeforeDate(int securityId, DateTime date) {
    final Security? security = securities.get(securityId);
    if (security == null || security.isDeleted) {
      return 1.0;
    }
    final List<StockSplit> splits = stockSplits.getStockSplitsForSecurity(security);
    double ratio = 1.0;
    for (final StockSplit split in splits) {
      if (date.isBefore(split.fieldDate.value!) &&
          split.fieldDenominator.value != 0 &&
          split.fieldNumerator.value != 0) {
        ratio *= split.fieldNumerator.value / split.fieldDenominator.value;
      }
    }
    return ratio;
  }

  @override
  dynamic getRentUnits() => rentUnits;

  @override
  Iterable<DateTime> getEventDates() {
    return events.iterableList().map((Event event) => event.fieldDateBegin.value!);
  }
}
