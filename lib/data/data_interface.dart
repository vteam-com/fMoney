import 'package:money/data/transaction.dart';
import 'package:money/models/account.dart';
import 'package:money/widgets/mutation_types.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';

abstract class DataInterface {
  dynamic get accounts;
  dynamic get aliases;
  dynamic get categories;
  dynamic get events;
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

  bool removeTransaction(Transaction t);
  void clearTransferToAccount(Transaction t, Account a);
  void updateAll();
}
