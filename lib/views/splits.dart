import 'package:money/helpers/json_helper.dart';
import 'package:money/providers/data_abstract.dart';
import 'package:money/providers/transaction.dart';
import 'package:money/providers/transaction_split.dart';
import 'package:money/views/money_objects.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';

/// Represents splits.
class Splits extends MoneyObjects<TransactionSplit> {
  Splits() {
    collectionName = 'Splits';
  }
  late DataAbstract data;

  @override
  void appendMoneyObject(final DataObject moneyObject) {
    super.appendMoneyObject(moneyObject);

    // Attach the split back to the their  container Transaction
    final TransactionSplit splitAdded = moneyObject as TransactionSplit;
    final dynamic containerTransaction = data.getTransaction(
      splitAdded.fieldTransactionId.value,
    );
    if (containerTransaction != null) {
      (containerTransaction as Transaction).splits.add(moneyObject);
    }
  }

  @override
  List<TransactionSplit> loadFromJson(final List<MyJson> rows) {
    clear();
    for (final MyJson row in rows) {
      appendMoneyObject(
        TransactionSplit(
          // 0
          transactionId: row.getInt('Transaction', -1),
          // 1
          id: row.getInt('Id', -1),
          // 2
          categoryId: row.getInt('Category', -1),
          // 3
          payeeId: row.getInt('Payee', -1),
          // 4
          amount: row.getDouble('Amount'),
          // 5
          transferId: row.getInt('Transfer', -1),
          // 6
          memo: row.getString('Memo'),
          // 7
          flags: row.getInt('Flags'),
          // 8
          budgetBalanceDate: row.getDate('BudgetBalanceDate'),
          data: data,
        ),
      );
    }
    return iterableList().toList();
  }

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }
}
