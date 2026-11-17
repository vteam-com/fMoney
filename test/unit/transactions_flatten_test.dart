import 'package:flutter_test/flutter_test.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/domain/transactions_collection.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';

void main() {
  setUp(() {
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
  });

  /// Appends a split row of [amount] to transaction [transactionId], paid to [payeeId].
  void addSplit(int id, int transactionId, double amount, int payeeId) {
    Data().splits.appendMoneyObject(
      TransactionSplit(
        id: id,
        transactionId: transactionId,
        categoryId: 7,
        payeeId: payeeId,
        amount: amount,
        transferId: -1,
        memo: '',
        flags: 0,
        budgetBalanceDate: null,
        data: Data(),
      ),
    );
  }

  test('both flatten entry points agree: one row per split, split payee wins when set', () {
    final Transaction parent = Transaction(date: DateTime(2024, 1, 15))
      ..uniqueId = 10
      ..fieldPayee.value = 1;
    Data().transactions.appendMoneyObject(parent);
    addSplit(20, 10, -30, -1);
    addSplit(21, 10, -70, 2);
    final Transaction plain = Transaction(date: DateTime(2024, 1, 16))..uniqueId = 11;
    Data().transactions.appendMoneyObject(plain);

    final List<Transaction> fromCollection = Data().transactions.getListFlattenSplits();
    final List<Transaction> fromStatic = Transactions.flatTransactions(Data().transactions.iterableList());

    for (final List<Transaction> flat in <List<Transaction>>[fromCollection, fromStatic]) {
      expect(flat.length, 3);
      expect(flat.map((Transaction t) => t.fieldPayee.value), <int>[1, 2, -1]);
      expect(flat.map((Transaction t) => t.fieldAmount.value.asDouble()), <double>[-30, -70, 0]);
    }
  });
}
