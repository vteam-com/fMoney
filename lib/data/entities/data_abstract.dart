import 'package:flutter/widgets.dart';
import 'package:money/widgets/mutation_types.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';

abstract class DataAbstract {
  dynamic get categorySuggestionProvider;

  static late DataAbstract instance;

  void notifyMutationChanged({
    required MutationType mutation,
    required DataObject moneyObject,
    bool recalculateBalances = true,
  });

  bool removeTransaction(int transactionId);
  void clearTransferToAccount(int transactionId, dynamic a);
  void updateAll();

  // Accounts
  dynamic getAccount(int id);
  String getAccountName(int id);
  String getAccountCurrency(int id);
  bool isAccountAsset(int id);
  dynamic getAccountByName(String name);
  List<String> getAccountNamesSorted();

  // Aliases
  dynamic findOrCreateNewPayee(String name, {bool fireNotification = true});

  // Payees
  List<String> getPayeeNames();
  dynamic getPayee(int id);
  dynamic getPayeeByName(String name);
  dynamic getOrCreatePayee(String name, {bool fireNotification = true});
  void removePayeesWithNoTransactions(List<int> payeeIds);
  String getPayeeName(int id);
  List<String> getPayeeNamesSorted();
  List<dynamic> getPayees();
  void deletePayee(dynamic payee);

  // Categories
  List<String> getCategoryNames();
  String getCategoryNameFromId(int id);
  dynamic getCategory(int id);

  Widget getCategoryWidget(int id);
  List<String> getCategoriesAsStrings();
  int? getCategoryIdFromName(String name);
  bool isCategoryExpense(int id);
  bool isCategoryIncome(int id);

  dynamic getTransferCategory();
  dynamic getSplitCategory();
  List<int> getCategoryTreeIds(int categoryId);
  void appendNewCategory(dynamic category);

  int getSplitCategoryId();
  int getTransferCategoryId();
  void deleteCategory(dynamic category);
  List<dynamic> getCategories({bool includeDeleted = false});

  // Securities
  String getSecuritySymbolFromId(int id);
  dynamic getSecurity(int id);
  dynamic getSecurityBySymbol(String symbol);
  List<dynamic> getSecurities();

  // StockSplits
  List<dynamic> getStockSplitsForSecurity(dynamic security);
  List<dynamic> getStockSplitsForSecurityId(int securityId);
  dynamic getLoanPayment(int id);
  List<dynamic> getLoanPayments();
  double getSplitRatioForSecurityBeforeDate(int securityId, DateTime date);

  // Investments
  dynamic getInvestment(int id);
  List<dynamic> getInvestments();

  // Transactions
  dynamic getTransaction(int id);
  Iterable<dynamic> getTransactions({bool includeDeleted = false});
  void appendTransaction(dynamic t);
  void appendNewTransaction(dynamic t, {bool fireNotification = true});
  List<dynamic> getTransactionsFlattenSplits({bool Function(dynamic)? whereClause});
  Iterable<dynamic> findTransfersToAccount(dynamic account);
  void changeCategory(dynamic t, int categoryId);
  void changeCategoryFromCategoryName(dynamic t, String categoryName);

  dynamic get mergePayeeProvider;
  set mergePayeeProvider(dynamic value);

  Iterable<DateTime> getEventDates();

  dynamic getRentUnits();
}
