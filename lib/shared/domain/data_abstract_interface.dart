import 'package:flutter/widgets.dart';
import 'package:money/widgets/pure/mutation_types.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';

/// Abstract base class providing core data operations and accessors.
abstract class DataAbstract {
  /// Returns the category suggestion provider.
  dynamic get categorySuggestionProvider;

  static late DataAbstract instance;

  /// Notifies listeners of a mutation to a money object.
  void notifyMutationChanged({
    required MutationType mutation,
    required DataObject moneyObject,
    bool recalculateBalances = true,
  });

  /// Removes a transaction by ID.
  bool removeTransaction(int transactionId);

  /// Clears transfer-to reference for a transaction.
  void clearTransferToAccount(int transactionId, dynamic a);

  /// Updates all data/collections after changes.
  void updateAll();

  // Accounts
  /// Returns an account by ID.
  dynamic getAccount(int id);

  /// Returns the name of an account by ID.
  String getAccountName(int id);

  /// Returns the currency symbol for an account by ID.
  String getAccountCurrency(int id);

  /// Returns true if the account is an asset type.
  bool isAccountAsset(int id);

  /// Returns an account by its name.
  dynamic getAccountByName(String name);

  /// Returns all account names sorted.
  List<String> getAccountNamesSorted();

  // Aliases
  /// Finds or creates a new payee by name.
  dynamic findOrCreateNewPayee(String name, {bool fireNotification = true});

  // Payees
  /// Returns all payee names.
  List<String> getPayeeNames();

  /// Returns a payee by ID.
  dynamic getPayee(int id);

  /// Returns a payee by name.
  dynamic getPayeeByName(String name);

  /// Finds or creates a payee by name.
  dynamic getOrCreatePayee(String name, {bool fireNotification = true});

  /// Removes payees that have no transactions.
  void removePayeesWithNoTransactions(List<int> payeeIds);

  /// Returns the name of a payee by ID.
  String getPayeeName(int id);

  /// Returns all payee names sorted.
  List<String> getPayeeNamesSorted();

  /// Returns all payees.
  List<dynamic> getPayees();

  /// Deletes a payee.
  void deletePayee(dynamic payee);

  // Categories
  /// Returns all category names.
  List<String> getCategoryNames();

  /// Returns the name of a category by ID.
  String getCategoryNameFromId(int id);

  /// Returns a category by ID.
  dynamic getCategory(int id);

  /// Returns a category widget for the given ID.
  Widget getCategoryWidget(int id);

  /// Returns all categories as strings.
  List<String> getCategoriesAsStrings();

  /// Returns a category ID from its name.
  int? getCategoryIdFromName(String name);

  /// Returns true if the category is an expense type.
  bool isCategoryExpense(int id);

  /// Returns true if the category is an income type.
  bool isCategoryIncome(int id);

  /// Returns the transfer category.
  dynamic getTransferCategory();

  /// Returns the split category.
  dynamic getSplitCategory();

  /// Returns all category tree IDs.
  List<int> getCategoryTreeIds(int categoryId);

  /// Appends a new category.
  void appendNewCategory(dynamic category);

  /// Returns the split category ID.
  int getSplitCategoryId();

  /// Returns the transfer category ID.
  int getTransferCategoryId();

  /// Deletes a category.
  void deleteCategory(dynamic category);

  /// Returns all categories.
  List<dynamic> getCategories({bool includeDeleted = false});

  // Securities
  /// Returns the security symbol for a security ID.
  String getSecuritySymbolFromId(int id);

  /// Returns a security by ID.
  dynamic getSecurity(int id);

  /// Returns a security by symbol.
  dynamic getSecurityBySymbol(String symbol);

  /// Returns all securities.
  List<dynamic> getSecurities();

  // StockSplits
  /// Returns stock splits for a security.
  List<dynamic> getStockSplitsForSecurity(dynamic security);

  /// Returns stock splits for a security ID.
  List<dynamic> getStockSplitsForSecurityId(int securityId);

  /// Returns a loan payment by ID.
  dynamic getLoanPayment(int id);

  /// Returns all loan payments.
  List<dynamic> getLoanPayments();

  /// Returns the split ratio for a security before a date.
  double getSplitRatioForSecurityBeforeDate(int securityId, DateTime date);

  // Investments
  /// Returns an investment by ID.
  dynamic getInvestment(int id);

  /// Returns all investments.
  List<dynamic> getInvestments();

  // Transactions
  /// Returns a transaction by ID.
  dynamic getTransaction(int id);

  /// Returns all transactions.
  Iterable<dynamic> getTransactions({bool includeDeleted = false});

  /// Appends a transaction.
  void appendTransaction(dynamic t);

  /// Appends a new transaction with optional notification.
  void appendNewTransaction(dynamic t, {bool fireNotification = true});

  /// Returns transactions with splits flattened.
  List<dynamic> getTransactionsFlattenSplits({bool Function(dynamic)? whereClause});

  /// Finds transfers pointing to the given account.
  Iterable<dynamic> findTransfersToAccount(dynamic account);

  /// Changes the category for a transaction.
  void changeCategory(dynamic t, int categoryId);

  /// Changes the category for a transaction by category name.
  void changeCategoryFromCategoryName(dynamic t, String categoryName);

  /// Finds likely disconnected transfer counterparts for a transaction.
  List<dynamic> findPotentialTransferMatches({
    required dynamic transaction,
    int maxDays,
    int maxResults,
  });

  /// Converts two existing disconnected transactions into a linked transfer pair.
  bool convertDisconnectedTransactionsToTransfer({
    required dynamic transaction,
    required dynamic relatedTransaction,
  });

  /// Returns the merge payee provider.
  dynamic get mergePayeeProvider;

  /// Sets the merge payee provider.
  set mergePayeeProvider(dynamic value);

  /// Returns all event dates.
  Iterable<DateTime> getEventDates();

  /// Returns rent units.
  dynamic getRentUnits();
}
