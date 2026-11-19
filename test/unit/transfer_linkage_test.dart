import 'package:flutter_test/flutter_test.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
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
      expect(source.fieldPayee.value, -1, reason: 'a transfer has no payee');
      expect(related.fieldPayee.value, -1);
      // Each side gets its own Transfer: itself as source, the other side as related.
      expect(source.instanceOfTransfer!.source, source);
      expect(source.instanceOfTransfer!.relatedTransaction, related);
      expect(related.instanceOfTransfer!.source, related);
      expect(related.instanceOfTransfer!.relatedTransaction, source);
    });

    test('the receiving side names the sending account right after linking', () {
      final Transaction source = _createTransaction(account: checking, amount: -100, date: DateTime(2024, 1, 10));

      final Transaction related = Data().makeTransferLinkage(transactionSource: source, destinationAccount: savings);

      // Regression: the receiving side used to share the sender's Transfer and named its own account.
      expect(related.relatedAccount, checking);
      expect(related.getPayeeOrTransferCaption(), allOf(contains(' <- '), endsWith(checking.fieldName.value)));
      expect(source.relatedAccount, savings);
      expect(source.getPayeeOrTransferCaption(), allOf(contains(' -> '), endsWith(savings.fieldName.value)));
    });

    test('reuses an existing opposite transaction on the same day', () {
      final Transaction existing = _createTransaction(account: savings, amount: 50, date: DateTime(2024, 2, 1, 15));
      final Transaction source = _createTransaction(account: checking, amount: -50, date: DateTime(2024, 2, 1, 9));
      final int countBefore = Data().transactions.length;

      final Transaction related = Data().makeTransferLinkage(transactionSource: source, destinationAccount: savings);

      expect(related, existing);
      expect(Data().transactions.length, countBefore);
      expect(existing.instanceOfTransfer!.source, existing);
      expect(existing.instanceOfTransfer!.relatedTransaction, source);
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

  test('a payee is not credited with transfers saved with a payee id', () {
    final Payee payee =
        Data().payees.appendNewMoneyObject(Payee()..fieldName.value = 'Grocer', fireNotification: false) as Payee;
    final Transaction outgoing = _createTransaction(account: checking, amount: -25, date: DateTime(2024, 4, 1));
    final Transaction incoming = _createTransaction(account: savings, amount: 25, date: DateTime(2024, 4, 1));
    final Transaction purchase = _createTransaction(account: checking, amount: -10, date: DateTime(2024, 4, 2));
    // older files stored the Transfer category id as payee, which can equal a real payee id
    outgoing.fieldPayee.value = payee.uniqueId;
    outgoing.fieldTransfer.value = incoming.uniqueId;
    purchase.fieldPayee.value = payee.uniqueId;

    Data().payees.onAllDataLoaded();

    expect(payee.fieldCount.value, 1);
    expect(payee.fieldSum.value.asDouble(), -10);
  });
}
