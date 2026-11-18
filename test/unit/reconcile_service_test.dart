import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/reconcile_service.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';

/// Statement closing date used by every test.
final DateTime _statementDate = DateTime(2024, 5, 31);

/// Creates and appends an account fixture of [type] with [openingBalance].
Account _createAccount(String name, {double openingBalance = 0, AccountType type = AccountType.checking}) {
  final Account account = Account();
  account.fieldName.value = name;
  account.fieldCurrency.value = 'USD';
  account.fieldType.value = type;
  account.fieldOpeningBalance.value.setAmount(openingBalance);
  return Data().accounts.appendNewMoneyObject(account, fireNotification: false) as Account;
}

/// Creates and appends a transaction fixture of [amount] with [status] on [date] in [account].
Transaction _createTransaction(Account account, double amount, TransactionStatus status, DateTime date) {
  final Transaction transaction = Transaction(date: date, status: status, accountId: account.uniqueId);
  transaction.fieldAmount.value.setAmount(amount);
  Data().appendNewTransaction(transaction, fireNotification: false);
  return transaction;
}

/// Puts [items] back to the unmodified state a freshly loaded file has.
void _markLoaded(List<DataObject> items) {
  for (final DataObject item in items) {
    item.mutation = MutationType.none;
    item.valueBeforeEdit = null;
  }
  DataFileController.to.trackMutations.reset();
}

void main() {
  late Account checking;

  setUp(() {
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
    checking = _createAccount('Checking', openingBalance: 100);
  });

  /// Returns a reconciliation of the checking account against a statement ending at [statementBalance].
  ReconcileService reconcile(double statementBalance) {
    return ReconcileService(
      account: checking,
      data: Data(),
      statementDate: _statementDate,
      statementBalance: statementBalance,
    );
  }

  test('balances start from the opening balance plus the reconciled transactions', () {
    _createTransaction(checking, 50, TransactionStatus.reconciled, DateTime(2024, 4, 10));
    // Later in the day of the statement still belongs to the statement
    _createTransaction(checking, 20, TransactionStatus.cleared, DateTime(2024, 5, 31, 18));
    _createTransaction(checking, 5, TransactionStatus.cleared, DateTime(2024, 6, 1));
    _createTransaction(checking, -10, TransactionStatus.none, DateTime(2024, 5, 2));
    final Transaction deleted = _createTransaction(checking, 1000, TransactionStatus.reconciled, DateTime(2024, 4, 1));
    Data().deleteItems(<DataObject>[deleted]);
    _createTransaction(_createAccount('Savings'), 7, TransactionStatus.cleared, DateTime(2024, 5, 3));

    final ReconcileService balanced = reconcile(170);
    expect(balanced.reconciledBalance, 150);
    expect(balanced.clearedBalance, 170);
    expect(balanced.difference, 0);
    expect(balanced.isBalanced, isTrue);

    final ReconcileService offByOne = reconcile(169);
    expect(offByOne.difference, closeTo(-1, 0.001));
    expect(offByOne.isBalanced, isFalse);
  });

  test('isPending keeps transactions not yet reconciled or void up to the statement date', () {
    final ReconcileService session = reconcile(0);

    expect(session.isPending(_createTransaction(checking, 1, TransactionStatus.none, DateTime(2024, 5, 1))), isTrue);
    expect(session.isPending(_createTransaction(checking, 1, TransactionStatus.cleared, _statementDate)), isTrue);
    expect(
      session.isPending(_createTransaction(checking, 1, TransactionStatus.electronic, DateTime(2024, 5, 31, 23))),
      isTrue,
    );
    expect(
      session.isPending(_createTransaction(checking, 1, TransactionStatus.reconciled, DateTime(2024, 5, 1))),
      isFalse,
    );
    expect(session.isPending(_createTransaction(checking, 1, TransactionStatus.voided, DateTime(2024, 5, 1))), isFalse);
    expect(session.isPending(_createTransaction(checking, 1, TransactionStatus.none, DateTime(2024, 6, 1))), isFalse);
  });

  test('finish changes nothing while the difference is not zero', () {
    final Transaction cleared = _createTransaction(checking, 20, TransactionStatus.cleared, DateTime(2024, 5, 10));
    _markLoaded(<DataObject>[cleared, checking]);

    expect(reconcile(999).finish(), 0);

    expect(cleared.fieldStatus.value, TransactionStatus.cleared);
    expect(cleared.fieldReconciledDate.value, isNull);
    expect(checking.fieldLastBalance.value, isNull);
    expect(DataFileController.to.trackMutations.numberOfChanges(), 0);
  });

  test('finish reconciles the cleared transactions on the statement and records the statement date', () {
    final Transaction onStatement = _createTransaction(checking, 20, TransactionStatus.cleared, DateTime(2024, 5, 10));
    final Transaction afterStatement = _createTransaction(checking, 5, TransactionStatus.cleared, DateTime(2024, 6, 2));
    final Transaction notCleared = _createTransaction(checking, -3, TransactionStatus.none, DateTime(2024, 5, 11));
    _markLoaded(<DataObject>[onStatement, afterStatement, notCleared, checking]);

    expect(reconcile(120).finish(), 1);

    expect(onStatement.fieldStatus.value, TransactionStatus.reconciled);
    expect(onStatement.fieldReconciledDate.value, _statementDate);
    expect(onStatement.mutation, MutationType.changed);
    expect(afterStatement.fieldStatus.value, TransactionStatus.cleared);
    expect(notCleared.fieldStatus.value, TransactionStatus.none);
    expect(checking.fieldLastBalance.value, _statementDate);
    expect(checking.mutation, MutationType.changed);
    expect(DataFileController.to.trackMutations.changed, 2);
    expect(ReconcileService.reconciledBalanceOf(checking, Data()), 120);
  });

  test('investment and loan accounts cannot be reconciled', () {
    expect(ReconcileService.supportsAccount(checking), isTrue);
    expect(ReconcileService.supportsAccount(_createAccount('Card', type: AccountType.credit)), isTrue);
    expect(ReconcileService.supportsAccount(_createAccount('Broker', type: AccountType.investment)), isFalse);
    expect(ReconcileService.supportsAccount(_createAccount('401k', type: AccountType.retirement)), isFalse);
    expect(ReconcileService.supportsAccount(_createAccount('Mortgage', type: AccountType.loan)), isFalse);
  });
}
