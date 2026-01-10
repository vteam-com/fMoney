// Imports
// The following lines import necessary libraries and packages for the file.
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:money/data/collections/account_aliases.dart';
import 'package:money/data/collections/accounts.dart';
import 'package:money/data/collections/aliases.dart';
import 'package:money/data/collections/categories.dart';
import 'package:money/data/collections/currencies.dart';
import 'package:money/data/collections/events.dart';
import 'package:money/data/collections/investments.dart';
import 'package:money/data/collections/loan_payments.dart';
import 'package:money/data/collections/online_accounts.dart';
import 'package:money/data/collections/payees.dart';
import 'package:money/data/collections/rent_buildings.dart';
import 'package:money/data/collections/rental_units.dart';
import 'package:money/data/collections/securities.dart';
import 'package:money/data/collections/splits.dart';
import 'package:money/data/collections/stock_splits.dart';
import 'package:money/data/collections/transaction_extras.dart';
import 'package:money/data/collections/transactions.dart';
import 'package:money/data/entities/category.dart';
import 'package:money/data/entities/data_abstract.dart';
import 'package:money/data/entities/event.dart';
import 'package:money/data/entities/investment.dart';
import 'package:money/data/entities/loan_payment.dart';
import 'package:money/data/entities/stock_split.dart';
import 'package:money/data/entities/transfer.dart';
import 'package:money/data/models/account.dart';
import 'package:money/data/models/payee.dart';
import 'package:money/data/money_objects.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/helpers/transaction_types.dart';
import 'package:money/widgets/data_access.dart';
import 'package:money/widgets/mutation_types.dart';
import 'package:money/widgets/snack_bar.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';

class Data implements DataAbstract {
  // private constructor

  /// singleton access
  factory Data() {
    return _instance;
  }

  /// private constructor
  Data._internal() {
    DataAbstract.instance = this;
    tables = <MoneyObjects<dynamic>>[
      accountAliases, // 1
      aliases, // 3
      categories, // 4
      currencies, // 5
      loanPayments, // 7
      onlineAccounts, // 8
      payees, // 9
      transactionExtras, // 15
      transactions, // 16
      // Keep in this order - must come after Transactions
      splits, // 13
      // Keep in this order
      stockSplits, // 14
      investments, // 6 Must be locate after [stockSplits]
      securities, // 12 Must be locate after [investments]

      accounts, // 2
      // Can be last
      rentBuildings, // 10
      rentUnits, // 11
      events,
    ];

    // Inject data interface to managers
    accounts.data = this as DataAbstract;
    aliases.data = this as DataAbstract;
    categories.data = this as DataAbstract;
    payees.data = this as DataAbstract;
    investments.data = this as DataAbstract;
    loanPayments.data = this as DataAbstract;
    securities.data = this as DataAbstract;
    rentBuildings.data = this as DataAbstract;
    splits.data = this as DataAbstract;
    events.data = this as DataAbstract;
    transactions.data = this as DataAbstract;
    stockSplits.data = this as DataAbstract;

    // Note: Some data managers use dependency injection (accounts, aliases, categories, payees, investments, loanPayments, securities, rentBuildings, splits, events, transactions)
    // while others use the global Data() singleton directly for cross-collection access

    DataAccess.notifyMutationChanged = notifyMutationChanged;
    DataAccess.getCategoryName = categories.getNameFromId;
    DataObject.onMutationChanged = notifyMutationChanged;
    DataObject.getCategoryName = categories.getNameFromId;
    DataObject.getCurrencyRatio = currencies.getRatioFromSymbol;
  }

  late final List<MoneyObjects<dynamic>> tables;

  /// 1 Account Aliases
  AccountAliases accountAliases = AccountAliases();

  /// 2 Accounts
  Accounts accounts = Accounts();

  /// 3 Aliases of Payees
  Aliases aliases = Aliases();

  /// 4 Categories of Transactions
  Categories categories = Categories();

  /// 5 Currencies definitions used in the money files
  Currencies currencies = Currencies();

  /// 16 Events
  Events events = Events();

  /// 6 Investment transactions
  Investments investments = Investments();

  /// 7
  LoanPayments loanPayments = LoanPayments();

  /// 8
  OnlineAccounts onlineAccounts = OnlineAccounts();

  /// 9
  Payees payees = Payees();

  /// 10
  RentBuildings rentBuildings = RentBuildings();

  /// 11
  RentUnits rentUnits = RentUnits();

  /// 12
  Securities securities = Securities();

  /// 13
  Splits splits = Splits();

  /// 14
  StockSplits stockSplits = StockSplits();

  /// 15
  TransactionExtras transactionExtras = TransactionExtras();

  /// 16 All Transactions in the Money file
  Transactions transactions = Transactions();

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

  /// singleton
  static final Data _instance = Data._internal();

  void checkTransfers() {
    final Set<Transaction> dangling = getDanglingTransfers();
    if (dangling.isNotEmpty) {
      Timer(
        const Duration(milliseconds: 100),
        () => SnackBarService.displayWarning(
          message: '${dangling.length} Dangling transfers have been found',
          title: 'Dangling Transfers',
          autoDismiss: false,
        ),
      );
    }
  }

  void clear() {
    clearExistingData();
  }

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

  Set<Transaction> getDanglingTransfers() {
    final Set<Transaction> dangling = <Transaction>{};
    final List<Account> deletedAccounts = <Account>[];
    transactions.checkTransfers(dangling, deletedAccounts);
    for (final Account a in deletedAccounts) {
      accounts.removeAccount(a);
    }
    return dangling;
  }

  DateTime? getLastDateTimeModified(final String fullPathToFile) {
    final File file = File(fullPathToFile);
    return file.lastModifiedSync();
  }

  List<DataObject> getMutatedInstances(final MutationType typeOfMutation) {
    final List<DataObject> mutated = <DataObject>[];
    for (final MoneyObjects<dynamic> listOfInstance in tables) {
      mutated.addAll(listOfInstance.getMutatedObjects(typeOfMutation));
    }
    return mutated;
  }

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

  AmountModel getNetWorth() {
    final double sum = accounts.getSumOfAccountBalances();
    return AmountModel(amount: sum);
  }

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
    } catch (error) {
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
          'Account',
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
