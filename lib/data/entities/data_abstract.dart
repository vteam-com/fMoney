import 'package:flutter/widgets.dart';
import 'package:money/data/models/account.dart';
import 'package:money/data/models/payee.dart';
import 'package:money/widgets/mutation_types.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';

abstract class DataAbstract {
  dynamic get accounts;
  dynamic get categories;
  dynamic get investments;
  dynamic get loanPayments;
  dynamic get payees;
  dynamic get rentBuildings;
  dynamic get securities;
  dynamic get splits;
  dynamic get stockSplits;
  dynamic get transactions;

  void notifyMutationChanged({
    required MutationType mutation,
    required DataObject moneyObject,
    bool recalculateBalances = true,
  });

  bool removeTransaction(int transactionId);
  void clearTransferToAccount(int transactionId, Account a);
  void updateAll();

  List<String> getPayeeNames();
  Payee? getPayeeByName(String name);
  Payee getOrCreatePayee(String name);
  void removePayeesWithNoTransactions(List<int> payeeIds);
  String getPayeeNameFromId(int id);

  List<String> getCategoryNames();
  String getCategoryNameFromId(int id);
  dynamic getCategoryByName(String name);

  Widget getCategoryWidget(int id);
  List<String> getCategoriesAsStrings();
  int? getCategoryIdByName(String name);

  String getSecuritySymbolFromId(int id);

  dynamic get mergePayeeProvider;
  set mergePayeeProvider(dynamic value);

  double getSplitRatioForSecurityBeforeDate(int securityId, DateTime date);

  Iterable<DateTime> getEventDates();
}
