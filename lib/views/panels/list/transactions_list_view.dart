import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transactions_collection.dart';

/// Returns a list of transactions with optional filtering and flattening.
List<Transaction> getTransactions({
  bool Function(Transaction)? filter,
  bool flattenSplits = false,
}) {
  filter ??= (Transaction _) => true;

  List<Transaction> list = <Transaction>[];

  if (flattenSplits) {
    // Flatten the splits
    list = Transactions.flatTransactions(
      Data().transactions.iterableList(),
    ).where((Transaction transaction) => filter!(transaction)).toList();
  } else {
    // No flattening of splits
    list = Data().transactions.iterableList().where((Transaction transaction) => filter!(transaction)).toList();
  }

  Transactions.applyRunningBalance(list);
  return list;
}
