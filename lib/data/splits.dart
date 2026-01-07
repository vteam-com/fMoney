import 'package:money/data/data_interface.dart';
import 'package:money/data/money_split.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/models/money_objects.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';

class Splits extends MoneyObjects<MoneySplit> {
  Splits() {
    collectionName = 'Splits';
  }
  late DataInterface data;

  @override
  void appendMoneyObject(final DataObject moneyObject) {
    super.appendMoneyObject(moneyObject);

    // Attach the split back to the their  container Transaction
    final MoneySplit splitAdded = moneyObject as MoneySplit;
    final dynamic containerTransaction = data.transactions.get(
      splitAdded.fieldTransactionId.value,
    );
    if (containerTransaction != null) {
      containerTransaction.splits.add(moneyObject);
    }
  }

  @override
  List<MoneySplit> loadFromJson(final List<MyJson> rows) {
    clear();
    for (final MyJson row in rows) {
      appendMoneyObject(
        MoneySplit(
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
