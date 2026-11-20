import 'package:money/data/models/account_types_enum.dart';
import 'package:money/data/models/data_access_model.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/shared/domain/account_aliases_collection.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/accounts_collection.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/aliases_collection.dart';
import 'package:money/shared/domain/categories_collection.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/currencies_collection.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/data_collections_registry_model.dart';
import 'package:money/shared/domain/event_entity.dart';
import 'package:money/shared/domain/events_collection.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/investments_collection.dart';
import 'package:money/shared/domain/loan_payment_entity.dart';
import 'package:money/shared/domain/loan_payments_collection.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/online_accounts_collection.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/payees_collection.dart';
import 'package:money/shared/domain/potential_transfer_match_service.dart';
import 'package:money/shared/domain/rent_building_entity.dart';
import 'package:money/shared/domain/rent_buildings_collection.dart';
import 'package:money/shared/domain/rental_category_role_enum.dart';
import 'package:money/shared/domain/rental_unit_entity.dart';
import 'package:money/shared/domain/rental_units_collection.dart';
import 'package:money/shared/domain/securities_collection.dart';
import 'package:money/shared/domain/splits_collection.dart';
import 'package:money/shared/domain/stock_split_entity.dart';
import 'package:money/shared/domain/stock_splits_collection.dart';
import 'package:money/shared/domain/transaction_extras_collection.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/domain/transactions_collection.dart';
import 'package:money/shared/domain/transfer_linkage_service.dart';

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
    _transferLinkage = TransferLinkageService(
      collections: collections,
      notifyMutationChanged: notifyMutationChanged,
      updateAll: updateAll,
    );

    // Wire global callbacks.
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

  /// Transfer linking and potential-match lookups, delegated to keep this facade thin.
  late final TransferLinkageService _transferLinkage;

  /// Called with the number of dangling transfers found by [checkTransfers]; bound by the presentation layer.
  void Function(int danglingCount)? onDanglingTransfersFound;

  /// Checks for dangling transfers and reports them through [onDanglingTransfersFound].
  void checkTransfers() {
    final Set<Transaction> dangling = getDanglingTransfers();
    if (dangling.isNotEmpty) {
      onDanglingTransfersFound?.call(dangling.length);
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

  /// Deletes [itemsToDelete] unless some are still referenced by rows outside the batch.
  ///
  /// Returns the number of blocking references; when it is not zero nothing is deleted.
  /// Deleting a [Transaction] also deletes its investment row and splits and unlinks its
  /// transfer counterpart (the counterpart itself is kept). Deleted splits leave their parent's list.
  int deleteItems(List<DataObject> itemsToDelete) {
    final int blockingReferences = countBlockingReferences(itemsToDelete);
    if (blockingReferences > 0) {
      return blockingReferences;
    }

    for (final DataObject item in itemsToDelete) {
      if (item is Transaction) {
        _deleteTransactionDependents(item);
      }
      if (item is TransactionSplit) {
        splits.detachFromTransaction(item);
      }
      notifyMutationChanged(
        mutation: MutationType.deleted,
        moneyObject: item,
        recalculateBalances: false,
      );
    }
    updateAll();
    return 0;
  }

  /// Deletes the investment row and splits owned by [transaction] and unlinks its transfer counterpart.
  void _deleteTransactionDependents(Transaction transaction) {
    final Investment? investment = investments.get(transaction.uniqueId);
    if (investment != null && !investment.isDeleted) {
      notifyMutationChanged(mutation: MutationType.deleted, moneyObject: investment, recalculateBalances: false);
    }
    for (final TransactionSplit split in List<TransactionSplit>.of(transaction.splits)) {
      splits.detachFromTransaction(split);
      notifyMutationChanged(mutation: MutationType.deleted, moneyObject: split, recalculateBalances: false);
    }
    _transferLinkage.unlinkTransfer(transaction);
  }

  /// Counts live rows outside [itemsToDelete] that still reference accounts, categories, payees
  /// or securities in [itemsToDelete]; other item types never block a delete.
  int countBlockingReferences(List<DataObject> itemsToDelete) {
    final Set<DataObject> batch = itemsToDelete.toSet();
    final Set<int> accountIds = _idsOf<Account>(itemsToDelete);
    final Set<int> categoryIds = _idsOf<Category>(itemsToDelete);
    final Set<int> payeeIds = _idsOf<Payee>(itemsToDelete);
    final Set<int> securityIds = _idsOf<Security>(itemsToDelete);

    int count = 0;

    /// Adds one reference when [referrer] is live, outside the batch, and one of [ids] matches.
    void tally(DataObject referrer, Set<int> ids, Iterable<int> referencedIds) {
      if (ids.isEmpty || referrer.isDeleted || batch.contains(referrer)) {
        return;
      }
      if (referencedIds.any(ids.contains)) {
        count++;
      }
    }

    if (accountIds.isNotEmpty || categoryIds.isNotEmpty || payeeIds.isNotEmpty) {
      for (final Transaction t in transactions.iterableList()) {
        tally(t, accountIds, <int>[t.fieldAccountId.value]);
        tally(t, categoryIds, <int>[t.fieldCategoryId.value]);
        tally(t, payeeIds, <int>[t.fieldPayee.value]);
      }
      for (final TransactionSplit split in splits.iterableList()) {
        tally(split, categoryIds, <int>[split.fieldCategoryId.value]);
        tally(split, payeeIds, <int>[split.fieldPayeeId.value]);
      }
    }
    for (final LoanPayment payment in loanPayments.iterableList()) {
      tally(payment, accountIds, <int>[payment.fieldAccountId.value]);
    }
    for (final Investment investment in investments.iterableList()) {
      tally(investment, securityIds, <int>[investment.fieldSecurity.value]);
      final Transaction? owner = transactions.get(investment.uniqueId);
      // Investments of live transactions are already counted through those transactions.
      if (owner != null && owner.isDeleted) {
        tally(investment, accountIds, <int>[owner.fieldAccountId.value]);
      }
    }
    for (final StockSplit stockSplit in stockSplits.iterableList()) {
      tally(stockSplit, securityIds, <int>[stockSplit.fieldSecurity.value]);
    }
    for (final Category category in categories.iterableList()) {
      tally(category, categoryIds, <int>[category.fieldParentId.value]);
    }
    // Only loan accounts use these; other accounts carry the 0 default, which is not a real reference.
    for (final Account account in accounts.iterableList().where((Account a) => a.fieldType.value == AccountType.loan)) {
      tally(account, categoryIds, <int>[
        account.fieldCategoryIdForPrincipal.value,
        account.fieldCategoryIdForInterest.value,
      ]);
    }
    for (final RentBuilding building in rentBuildings.iterableList()) {
      tally(
        building,
        categoryIds,
        RentalCategoryRole.values.map((RentalCategoryRole role) => building.categoryFieldOf(role).value),
      );
    }
    for (final Alias alias in aliases.iterableList()) {
      tally(alias, payeeIds, <int>[alias.fieldPayeeId.value]);
    }
    return count;
  }

  /// Returns the ids of the items of type [T] in [items].
  static Set<int> _idsOf<T extends DataObject>(List<DataObject> items) =>
      items.whereType<T>().map((T item) => item.uniqueId).toSet();

  /// Breaks the transfer link of [transaction], unlinking a counterpart that still points back at it.
  @override
  void unlinkTransfer(DataObject transaction) => _transferLinkage.unlinkTransfer(transaction as Transaction);

  /// Returns transfers that reference deleted accounts.
  Set<Transaction> getDanglingTransfers() {
    final Set<Transaction> dangling = <Transaction>{};
    transactions.checkTransfers(dangling);
    return dangling;
  }

  /// Calculates net worth across all accounts.
  AmountModel getNetWorth() {
    final double sum = accounts.getSumOfAccountBalances();
    return AmountModel(amount: sum);
  }

  /// Finds likely disconnected transactions that could be linked as a transfer
  /// counterpart for [transaction].
  @override
  List<Transaction> findPotentialTransferMatches({
    required DataObject transaction,
    int maxDays = potentialTransferDefaultMaxDays,
    int maxResults = potentialTransferDefaultMaxResults,
  }) => _transferLinkage.findPotentialTransferMatches(
    transaction: transaction as Transaction,
    maxDays: maxDays,
    maxResults: maxResults,
  );

  /// Returns true when [transaction] has at least one likely disconnected
  /// counterpart that could be linked as a transfer (cached, O(1) per call).
  @override
  bool hasPotentialTransferMatch(DataObject transaction) =>
      _transferLinkage.hasPotentialTransferMatch(transaction as Transaction);

  /// Converts two existing disconnected transactions into one linked transfer pair.
  @override
  bool convertDisconnectedTransactionsToTransfer({
    required DataObject transaction,
    required DataObject relatedTransaction,
  }) => _transferLinkage.convertDisconnectedTransactionsToTransfer(
    sourceTransaction: transaction as Transaction,
    targetTransaction: relatedTransaction as Transaction,
  );

  /// Ensures transfer linkage exists or updates it for the given transaction.
  void verifyApplyTransfer({
    required Transaction transaction,
    required Account? relatedAccount,
  }) => _transferLinkage.verifyApplyTransfer(transaction: transaction, relatedAccount: relatedAccount);

  /// Creates a transfer linkage between source and destination transactions.
  Transaction makeTransferLinkage({
    required Transaction transactionSource,
    required Account destinationAccount,
  }) => _transferLinkage.makeTransferLinkage(
    transactionSource: transactionSource,
    destinationAccount: destinationAccount,
  );

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

  /// Recalculates every table, then reports dangling transfers; used after loading and on Rebalance.
  void recalculateBalances() {
    _recalculateTables();
    checkTransfers();
  }

  /// Recalculates every table's derived values (balances, totals, cross references) in load order.
  void _recalculateTables() {
    for (final MoneyObjects<dynamic> moneyObjects in tables) {
      moneyObjects.onAllDataLoaded();
    }
  }

  /// ReBalance all objects values
  /// and Rebuild the UI
  @override
  void updateAll() {
    // Edits don't re-run the dangling-transfer check: its warning stays up until dismissed, so it would pile up.
    _recalculateTables();
    DataAccess.onDataChanged();
  }

  @override
  Payee? getPayee(int id) => payees.get(id);

  @override
  Payee? getPayeeByName(String name) => payees.getByName(name);

  @override
  Payee getOrCreatePayee(String name, {bool fireNotification = true}) =>
      payees.getOrCreate(name, fireNotification: fireNotification);

  /// Re-points everything that uses [source] to [target]: transactions, split lines, child categories,
  /// loan accounts, events and rental buildings; then deletes [source].
  ///
  /// Returns false, changing nothing, when [target] is [source] or one of its subcategories.
  bool mergeCategoryInto(Category source, Category target) {
    if (categories.isSameOrDescendantOf(target, source)) {
      return false;
    }

    /// Moves [field] of [item] from [source] to [target] as a pending edit.
    void repoint(DataObject item, Field<int> field) {
      if (field.value == source.uniqueId) {
        item.stashValueBeforeEditing();
        field.value = target.uniqueId;
        notifyMutationChanged(mutation: MutationType.changed, moneyObject: item, recalculateBalances: false);
      }
    }

    for (final Transaction t in transactions.iterableList(includeDeleted: true)) {
      repoint(t, t.fieldCategoryId);
    }
    for (final TransactionSplit split in splits.iterableList()) {
      repoint(split, split.fieldCategoryId);
    }
    // Only loan accounts use these; other accounts carry the 0 default, which is not a real reference.
    for (final Account account in accounts.iterableList().where((Account a) => a.fieldType.value == AccountType.loan)) {
      repoint(account, account.fieldCategoryIdForPrincipal);
      repoint(account, account.fieldCategoryIdForInterest);
    }
    for (final Event event in events.iterableList()) {
      repoint(event, event.fieldCategoryId);
    }
    for (final RentBuilding building in rentBuildings.iterableList()) {
      for (final RentalCategoryRole role in RentalCategoryRole.values) {
        repoint(building, building.categoryFieldOf(role));
      }
    }
    // Children keep their own subtree; reparenting renames them and marks them changed.
    for (final Category child in categories.getCategoriesWithThisParent(source.uniqueId)) {
      categories.reparentCategory(child, target);
    }

    source.stashValueBeforeEditing();
    notifyMutationChanged(mutation: MutationType.deleted, moneyObject: source, recalculateBalances: false);
    updateAll();
    return true;
  }

  /// Re-points the split lines and aliases of each payee in [fromPayeeIds] that no longer has
  /// transactions to [toPayeeId], then deletes that payee.
  @override
  void mergePayeesWithNoTransactionsInto(List<int> fromPayeeIds, int toPayeeId) {
    for (final int payeeId in fromPayeeIds) {
      final Payee? payee = payees.get(payeeId);
      if (payee == null || payeeId == toPayeeId) {
        continue;
      }
      if (transactions.iterableList().any((Transaction t) => t.isForPayee(payeeId))) {
        continue; // still in use: a partial merge keeps this payee and its references
      }
      for (final TransactionSplit split in splits.iterableList()) {
        if (split.fieldPayeeId.value == payeeId) {
          split.stashValueBeforeEditing();
          split.fieldPayeeId.value = toPayeeId;
          notifyMutationChanged(mutation: MutationType.changed, moneyObject: split, recalculateBalances: false);
        }
      }
      for (final Alias alias in aliases.iterableList()) {
        if (alias.fieldPayeeId.value == payeeId) {
          alias.stashValueBeforeEditing();
          alias.fieldPayeeId.value = toPayeeId;
          notifyMutationChanged(mutation: MutationType.changed, moneyObject: alias, recalculateBalances: false);
        }
      }
      payees.deleteItem(payee);
    }
  }

  /// The transactions an alias can rename: all but transfers, which aliases leave alone.
  Iterable<Transaction> aliasableTransactions() =>
      transactions.iterableList().where((Transaction transaction) => !transaction.isTransfer);

  /// The transactions [applyAlias] would point at [alias]'s payee: the non-transfers it matches that
  /// have another payee.
  Iterable<Transaction> transactionsRenamedBy(Alias alias) => aliasableTransactions().where(
    (Transaction t) => t.fieldPayee.value != alias.fieldPayeeId.value && Aliases.matchesTransaction(alias, t),
  );

  /// Points every non-transfer transaction and split line that [alias] matches at the alias payee,
  /// and returns how many changed. A transaction matches on its original bank text or its payee name.
  int applyAlias(Alias alias) {
    final int toPayeeId = alias.fieldPayeeId.value;
    if (payees.get(toPayeeId) == null) {
      return 0;
    }
    int count = 0;
    for (final Transaction t in transactionsRenamedBy(alias).toList()) {
      t.stashValueBeforeEditing();
      t.stashOriginalPayee();
      t.fieldPayee.value = toPayeeId;
      t.applyCategoryFromPayeeHistory();
      notifyMutationChanged(mutation: MutationType.changed, moneyObject: t, recalculateBalances: false);
      count++;
    }
    for (final TransactionSplit split in splits.iterableList()) {
      if (split.fieldPayeeId.value != toPayeeId &&
          split.fieldTransferId.value == -1 &&
          alias.isMatch(getPayeeName(split.fieldPayeeId.value))) {
        split.stashValueBeforeEditing();
        split.fieldPayeeId.value = toPayeeId;
        notifyMutationChanged(mutation: MutationType.changed, moneyObject: split, recalculateBalances: false);
        count++;
      }
    }
    return count;
  }

  @override
  String getPayeeName(int id) => payees.getNameFromId(id);

  @override
  List<String> getPayeeNamesSorted() => payees.getSortedPayeeNames();

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
  int? getCategoryIdFromName(String name) => categories.getIdByName(name);

  @override
  List<String> getCategoriesAsStrings() => categories.getCategoriesAsStrings();

  @override
  int getSplitCategoryId() => categories.splitCategoryId();

  @override
  Map<int, int> getCategoryCountsForPayee(int payeeId) {
    final Map<int, int> countByCategoryId = <int, int>{};
    if (payeeId == -1) {
      return countByCategoryId;
    }
    final int splitCategoryId = categories.splitCategoryId();
    for (final Transaction t in transactions.iterableList()) {
      final int categoryId = t.fieldCategoryId.value;
      if (t.isForPayee(payeeId) && categoryId != -1 && categoryId != splitCategoryId) {
        countByCategoryId[categoryId] = (countByCategoryId[categoryId] ?? 0) + 1;
      }
    }
    final List<int> mostUsedFirst = countByCategoryId.keys.toList()
      ..sort((int a, int b) => countByCategoryId[b]!.compareTo(countByCategoryId[a]!));
    return <int, int>{for (final int id in mostUsedFirst) id: countByCategoryId[id]!};
  }

  @override
  List<int> getCategoryTreeIds(int categoryId) => categories.getTreeIds(categoryId);

  @override
  List<Category> getCategoryAncestors(DataObject category) => categories.ancestorsOf(category as Category);

  @override
  void appendNewCategory(DataObject category) => categories.appendNewMoneyObject(category as Category);

  @override
  List<StockSplit> getStockSplitsForSecurity(DataObject security) =>
      stockSplits.getStockSplitsForSecurity(security as Security);

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
  void appendNewTransaction(DataObject t, {bool fireNotification = true}) =>
      transactions.appendNewMoneyObject(t as Transaction, fireNotification: fireNotification);

  @override
  List<Transaction> getTransactionsFlattenSplits({bool Function(Transaction)? whereClause}) =>
      transactions.getListFlattenSplits(whereClause: (Transaction t) => whereClause == null || whereClause(t));

  @override
  void changeCategory(DataObject t, int categoryId) => Transaction.changeCategory(t as Transaction, categoryId);

  @override
  void changeCategoryFromCategoryName(DataObject t, String categoryName) {
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
  List<RentUnit> getRentUnits() => rentUnits.iterableList().toList();

  @override
  Iterable<DateTime> getEventDates() {
    return events.iterableList().map((Event event) => event.fieldDateBegin.value!);
  }
}
