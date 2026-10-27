import 'package:flutter_test/flutter_test.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';

/// Creates and appends an account fixture for transfer-linkage tests.
Account _createAccount(String name) {
  final Account account = Account();
  account.fieldName.value = name;
  account.fieldCurrency.value = 'USD';
  return Data().accounts.appendNewMoneyObject(account, fireNotification: false) as Account;
}

/// Creates and appends a non-transfer transaction fixture.
Transaction _createTransaction({
  required Account account,
  required double amount,
  required DateTime date,
}) {
  final Transaction transaction = Transaction(date: date);
  transaction.fieldAccountId.value = account.uniqueId;
  transaction.fieldAmount.value.setAmount(amount);
  transaction.fieldTransfer.value = -1;
  transaction.fieldTransferSplit.value = -1;
  Data().appendNewTransaction(transaction, fireNotification: false);
  return transaction;
}

void main() {
  late Account checking;
  late Account savings;

  setUp(() {
    // Wires DataAccess.trackMutations, which mutation notifications rely on.
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
    checking = _createAccount('Checking');
    savings = _createAccount('Savings');
  });

  group('Data.makeTransferLinkage', () {
    test('creates a mirror transaction in the destination account when none exists', () {
      final Transaction source = _createTransaction(account: checking, amount: -100, date: DateTime(2024, 1, 10));
      final int countBefore = Data().transactions.length;

      final Transaction related = Data().makeTransferLinkage(transactionSource: source, destinationAccount: savings);

      expect(Data().transactions.length, countBefore + 1);
      expect(related.fieldAccountId.value, savings.uniqueId);
      expect(related.fieldAmount.value.asDouble(), 100);
      expect(related.fieldDateTime.value, source.fieldDateTime.value);
      expect(source.fieldTransfer.value, related.uniqueId);
      expect(related.fieldTransfer.value, source.uniqueId);
      expect(source.fieldPayee.value, Data().categories.transfer.uniqueId);
      expect(related.fieldPayee.value, Data().categories.transfer.uniqueId);
      // A negative source amount is the sending side of the transfer.
      expect(source.instanceOfTransfer!.source, source);
      expect(identical(source.instanceOfTransfer, related.instanceOfTransfer), isTrue);
    });

    test('reuses an existing opposite transaction on the same day', () {
      final Transaction existing = _createTransaction(account: savings, amount: 50, date: DateTime(2024, 2, 1, 15));
      final Transaction source = _createTransaction(account: checking, amount: -50, date: DateTime(2024, 2, 1, 9));
      final int countBefore = Data().transactions.length;

      final Transaction related = Data().makeTransferLinkage(transactionSource: source, destinationAccount: savings);

      expect(related, existing);
      expect(Data().transactions.length, countBefore);
      // A positive source amount is the receiving side of the transfer.
      expect(existing.instanceOfTransfer!.source, source);
      expect(existing.fieldTransfer.value, source.uniqueId);
    });
  });

  group('Data.verifyApplyTransfer', () {
    test('does nothing without a related account', () {
      final Transaction source = _createTransaction(account: checking, amount: -10, date: DateTime(2024, 3, 1));

      Data().verifyApplyTransfer(transaction: source, relatedAccount: null);

      expect(source.instanceOfTransfer, isNull);
      expect(source.fieldTransfer.value, -1);
    });

    test('links a non-transfer transaction to the related account', () {
      final Transaction source = _createTransaction(account: checking, amount: -10, date: DateTime(2024, 3, 1));

      Data().verifyApplyTransfer(transaction: source, relatedAccount: savings);

      expect(source.instanceOfTransfer, isNotNull);
      expect((source.instanceOfTransfer!.relatedTransaction as Transaction).fieldAccountId.value, savings.uniqueId);
    });
  });

  group('Data.convertDisconnectedTransactionsToTransfer', () {
    test('links two opposite transactions from different accounts', () {
      final Transaction outgoing = _createTransaction(account: checking, amount: -25, date: DateTime(2024, 4, 1));
      final Transaction incoming = _createTransaction(account: savings, amount: 25, date: DateTime(2024, 4, 2));

      final bool didConvert = Data().convertDisconnectedTransactionsToTransfer(
        transaction: incoming,
        relatedTransaction: outgoing,
      );

      expect(didConvert, isTrue);
      expect(outgoing.fieldTransfer.value, incoming.uniqueId);
      expect(incoming.fieldTransfer.value, outgoing.uniqueId);
      expect(outgoing.instanceOfTransfer!.relatedTransaction, incoming);
      expect(incoming.instanceOfTransfer!.relatedTransaction, outgoing);
    });

    test('rejects transactions from the same account', () {
      final Transaction a = _createTransaction(account: checking, amount: -25, date: DateTime(2024, 4, 1));
      final Transaction b = _createTransaction(account: checking, amount: 25, date: DateTime(2024, 4, 1));

      expect(Data().convertDisconnectedTransactionsToTransfer(transaction: a, relatedTransaction: b), isFalse);
      expect(a.instanceOfTransfer, isNull);
    });

    test('rejects amounts that do not cancel out', () {
      final Transaction a = _createTransaction(account: checking, amount: -25, date: DateTime(2024, 4, 1));
      final Transaction b = _createTransaction(account: savings, amount: 26, date: DateTime(2024, 4, 1));

      expect(Data().convertDisconnectedTransactionsToTransfer(transaction: a, relatedTransaction: b), isFalse);
    });

    test('rejects a transaction that is already a transfer', () {
      final Transaction a = _createTransaction(account: checking, amount: -25, date: DateTime(2024, 4, 1));
      final Transaction b = _createTransaction(account: savings, amount: 25, date: DateTime(2024, 4, 1));
      Data().makeTransferLinkage(transactionSource: a, destinationAccount: _createAccount('Other'));

      expect(Data().convertDisconnectedTransactionsToTransfer(transaction: a, relatedTransaction: b), isFalse);
    });
  });
}
