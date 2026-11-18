import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/security_entity.dart';
import 'package:money/shared/domain/stock_split_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/presentation/dialogs/mutate_shared_dialog.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/views/panels/dialogs/merge_categories_dialog.dart';
import 'package:money/views/panels/dialogs/merge_payees_dialog.dart';

/// Creates and appends an account fixture.
Account _createAccount(String name) {
  final Account account = Account();
  account.fieldName.value = name;
  account.fieldCurrency.value = 'USD';
  return Data().accounts.appendNewMoneyObject(account, fireNotification: false) as Account;
}

/// Creates and appends a plain transaction fixture.
Transaction _createTransaction({required Account account, required double amount, DateTime? date}) {
  final Transaction transaction = Transaction(date: date ?? DateTime(2024, 5, 1, 10));
  transaction.fieldAccountId.value = account.uniqueId;
  transaction.fieldAmount.value.setAmount(amount);
  transaction.fieldTransfer.value = -1;
  transaction.fieldTransferSplit.value = -1;
  Data().appendNewTransaction(transaction, fireNotification: false);
  return transaction;
}

/// Creates and appends a payee fixture.
Payee _createPayee(String name) => Data().payees.getOrCreate(name, fireNotification: false);

/// Creates and appends a category fixture wired to [Data] so it can resolve its parent.
Category _createCategory(String name, {int parentId = -1}) {
  final Category category = Category(id: -1, name: name, type: CategoryType.expense, parentId: parentId, data: Data());
  return Data().categories.appendNewMoneyObject(category, fireNotification: false) as Category;
}

/// Creates and appends a split line under [transaction].
TransactionSplit _createSplit(Transaction transaction, {int categoryId = -1, int payeeId = -1}) {
  final TransactionSplit split = TransactionSplit(
    id: -1,
    transactionId: transaction.uniqueId,
    categoryId: categoryId,
    payeeId: payeeId,
    amount: 1,
    transferId: -1,
    memo: '',
    flags: 0,
    budgetBalanceDate: null,
    data: Data(),
  );
  return Data().splits.appendNewMoneyObject(split, fireNotification: false) as TransactionSplit;
}

/// Puts [items] back to the unmodified state a freshly loaded file has.
void _markLoaded(List<DataObject> items) {
  for (final DataObject item in items) {
    item.mutation = MutationType.none;
    item.valueBeforeEdit = null;
  }
}

void main() {
  late Account checking;
  late Account savings;
  late Account brokerage;

  setUp(() {
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
    checking = _createAccount('Checking');
    savings = _createAccount('Savings');
    brokerage = _createAccount('Brokerage');
  });

  group('transfer creation does not hijack existing rows', () {
    test('skips deleted, transfer and split-parent candidates', () {
      final Transaction deleted = _createTransaction(account: savings, amount: 40);
      Data().deleteItems(<DataObject>[deleted]);
      final Transaction alreadyTransfer = _createTransaction(account: savings, amount: 40);
      Data().makeTransferLinkage(transactionSource: alreadyTransfer, destinationAccount: brokerage);
      final Transaction splitParent = _createTransaction(account: savings, amount: 40);
      _createSplit(splitParent);
      final int alreadyTransferLink = alreadyTransfer.fieldTransfer.value;

      final Transaction source = _createTransaction(account: checking, amount: -40);
      final Transaction related = Data().makeTransferLinkage(transactionSource: source, destinationAccount: savings);

      expect(<Transaction>[deleted, alreadyTransfer, splitParent], isNot(contains(related)));
      expect(related.isInserted, isTrue);
      expect(alreadyTransfer.fieldTransfer.value, alreadyTransferLink);
      expect(splitParent.isTransfer, isFalse);
    });
  });

  group('breaking a transfer', () {
    test('choosing a payee unlinks the counterpart', () {
      final Transaction source = _createTransaction(account: checking, amount: -10);
      final Transaction related = Data().makeTransferLinkage(transactionSource: source, destinationAccount: savings);
      _markLoaded(<DataObject>[source, related]);
      // Payee ids equal to the Transfer category id are read as "transfer" by the Payee setter; avoid id 0.
      _createPayee('Placeholder');
      final Payee payee = _createPayee('Grocer');

      source.mutateField('Payee', payee.uniqueId, false);

      expect(source.fieldPayee.value, payee.uniqueId);
      expect(source.isTransfer, isFalse);
      expect(related.isTransfer, isFalse);
      expect(related.instanceOfTransfer, isNull);
      expect(related.mutation, MutationType.changed);
    });

    test('verifyApplyTransfer without account unlinks a counterpart left pointing back', () {
      final Transaction source = _createTransaction(account: checking, amount: -10);
      final Transaction related = Data().makeTransferLinkage(transactionSource: source, destinationAccount: savings);
      _markLoaded(<DataObject>[source, related]);
      source.stashValueBeforeEditing();
      // What the payee picker does: the row is no longer a transfer, the counterpart is untouched.
      source.fieldTransfer.value = -1;

      Data().verifyApplyTransfer(transaction: source, relatedAccount: null);

      expect(related.fieldTransfer.value, -1);
      expect(related.mutation, MutationType.changed);
    });
  });

  group('changing a transfer destination', () {
    test('moves the counterpart to the new account and restores the link', () {
      final Transaction source = _createTransaction(account: checking, amount: -10);
      final Transaction related = Data().makeTransferLinkage(transactionSource: source, destinationAccount: savings);
      _markLoaded(<DataObject>[source, related]);
      source.fieldTransfer.value = -1; // what the transfer picker does

      Data().verifyApplyTransfer(transaction: source, relatedAccount: brokerage);

      expect(related.fieldAccountId.value, brokerage.uniqueId);
      expect(related.instanceOfAccount, brokerage);
      expect(related.mutation, MutationType.changed);
      expect(source.fieldTransfer.value, related.uniqueId);
    });

    test('restores the link when the same account is picked again', () {
      final Transaction source = _createTransaction(account: checking, amount: 10);
      final Transaction related = Data().makeTransferLinkage(transactionSource: source, destinationAccount: savings);
      source.fieldTransfer.value = -1;

      Data().verifyApplyTransfer(transaction: source, relatedAccount: savings);

      expect(source.fieldTransfer.value, related.uniqueId);
      expect(related.fieldAccountId.value, savings.uniqueId);
    });
  });

  test('createDuplicate copies values but not the transfer link', () {
    final Transaction source = _createTransaction(account: checking, amount: -12.5);
    source.fieldMemo.value = 'memo';
    Data().makeTransferLinkage(transactionSource: source, destinationAccount: savings);

    final Transaction duplicate = source.createDuplicate();
    duplicate.fieldAmount.value.setAmount(99);

    expect(duplicate.uniqueId, -1);
    expect(duplicate.isTransfer, isFalse);
    expect(duplicate.cachedTransfer, isNull);
    expect(duplicate.fieldPayee.value, -1);
    expect(duplicate.fieldMemo.value, 'memo');
    expect(duplicate.fieldAccountId.value, checking.uniqueId);
    expect(source.fieldAmount.value.asDouble(), -12.5);
  });

  group('abandoned edit', () {
    test('restores a transaction and drops the changed mark', () {
      final Category category = _createCategory('Food');
      final Transaction transaction = _createTransaction(account: checking, amount: -5);
      _markLoaded(<DataObject>[transaction]);
      final EditSnapshot snapshot = EditSnapshot(transaction);
      transaction.stashValueBeforeEditing();

      Data().changeCategory(transaction, category.uniqueId);
      transaction.fieldMemo.value = 'typed';
      transaction.fieldDateTime.value = DateTime(2030);
      snapshot.restore();

      expect(transaction.fieldCategoryId.value, -1);
      expect(transaction.fieldMemo.value, '');
      expect(transaction.fieldDateTime.value, DateTime(2024, 5, 1, 10));
      expect(transaction.mutation, MutationType.none);
      expect(transaction.valueBeforeEdit, isNull);
    });

    test('restores a non-transaction object through its setters', () {
      final Payee payee = _createPayee('Original');
      _markLoaded(<DataObject>[payee]);
      final EditSnapshot snapshot = EditSnapshot(payee);
      payee.stashValueBeforeEditing();

      payee.fieldName.value = 'Typed';
      snapshot.restore();

      expect(payee.fieldName.value, 'Original');
      expect(payee.mutation, MutationType.none);
    });
  });

  group('deleting a transaction', () {
    test('also deletes its investment and splits and unlinks its counterpart', () {
      final Transaction source = _createTransaction(account: checking, amount: -10);
      final Transaction related = Data().makeTransferLinkage(transactionSource: source, destinationAccount: savings);
      final Investment investment = Investment(
        id: source.uniqueId,
        security: -1,
        unitPrice: 0,
        units: 0,
        investmentType: 0,
        tradeType: 0,
        data: Data(),
      );
      Data().investments.appendMoneyObject(investment);
      final TransactionSplit split = _createSplit(source);

      expect(Data().deleteItems(<DataObject>[source]), 0);

      expect(source.isDeleted, isTrue);
      expect(investment.isDeleted, isTrue);
      expect(split.isDeleted, isTrue);
      expect(related.isDeleted, isFalse);
      expect(related.isTransfer, isFalse);
    });

    test('a deleted split leaves its parent list', () {
      final Transaction parent = _createTransaction(account: checking, amount: -10);
      final TransactionSplit first = _createSplit(parent);
      final TransactionSplit second = _createSplit(parent);

      Data().deleteItems(<DataObject>[first]);

      expect(parent.splits, <TransactionSplit>[second]);
    });
  });

  group('deleting a referenced item is blocked', () {
    test('account with transactions', () {
      _createTransaction(account: checking, amount: 1);

      expect(Data().deleteItems(<DataObject>[checking]), 1);
      expect(checking.isDeleted, isFalse);
      expect(Data().deleteItems(<DataObject>[brokerage]), 0);
      expect(brokerage.isDeleted, isTrue);
    });

    test('category used by a split and a child category', () {
      final Category parent = _createCategory('Home');
      _createCategory('Home:Repairs', parentId: parent.uniqueId);
      final Transaction t = _createTransaction(account: checking, amount: 1);
      _createSplit(t, categoryId: parent.uniqueId);

      expect(Data().deleteItems(<DataObject>[parent]), 2);
      expect(parent.isDeleted, isFalse);
    });

    test('payee used by an alias, security used by an investment and a stock split', () {
      final Payee payee = _createPayee('Store');
      Data().aliases.appendNewMoneyObject(
        Alias(id: -1, pattern: 'STORE*', flags: 0, payeeId: payee.uniqueId, data: Data()),
        fireNotification: false,
      );
      final Security security = Data().securities.appendNewMoneyObject(
        Security(
          id: -1,
          name: 'Acme',
          symbol: 'ACME',
          price: 1,
          lastPrice: 1,
          cuspid: '',
          securityType: 0,
          taxable: 0,
          priceDate: null,
        ),
        fireNotification: false,
      ) as Security;
      final Transaction t = _createTransaction(account: brokerage, amount: -1);
      Data().investments.appendMoneyObject(
        Investment(
          id: t.uniqueId,
          security: security.uniqueId,
          unitPrice: 1,
          units: 1,
          investmentType: 0,
          tradeType: 0,
          data: Data(),
        ),
      );
      Data().stockSplits.appendNewMoneyObject(
        StockSplit(date: DateTime(2024), security: security.uniqueId, numerator: 2, denominator: 1, data: Data()),
        fireNotification: false,
      );

      expect(Data().deleteItems(<DataObject>[payee]), 1);
      expect(Data().deleteItems(<DataObject>[security]), 2);
    });
  });

  group('merging', () {
    test('payee merge marks transactions changed and moves splits and aliases', () {
      final Payee from = _createPayee('From');
      final Payee to = _createPayee('To');
      final Transaction t = _createTransaction(account: checking, amount: -3);
      t.fieldPayee.value = from.uniqueId;
      final TransactionSplit split = _createSplit(t, payeeId: from.uniqueId);
      final Alias alias = Data().aliases.appendNewMoneyObject(
        Alias(id: -1, pattern: 'FROM', flags: 0, payeeId: from.uniqueId, data: Data()),
        fireNotification: false,
      ) as Alias;
      _markLoaded(<DataObject>[from, to, t, split, alias]);

      mutateMergeableItemsToPayee<Transaction>(<Transaction>[t], to.uniqueId, null, Data());

      expect(t.fieldPayee.value, to.uniqueId);
      expect(t.mutation, MutationType.changed);
      expect(split.fieldPayeeId.value, to.uniqueId);
      expect(split.mutation, MutationType.changed);
      expect(alias.fieldPayeeId.value, to.uniqueId);
      expect(from.isDeleted, isTrue);
    });

    test('category merge moves splits and child categories', () {
      final Category from = _createCategory('Auto');
      final Category child = _createCategory('Auto:Fuel', parentId: from.uniqueId);
      final Category to = _createCategory('Car');
      final Transaction t = _createTransaction(account: checking, amount: -3);
      final TransactionSplit split = _createSplit(t, categoryId: from.uniqueId);
      _markLoaded(<DataObject>[from, child, to, t, split]);

      expect(mergeCategoryInto(from, to), isTrue);

      expect(split.fieldCategoryId.value, to.uniqueId);
      expect(split.mutation, MutationType.changed);
      expect(child.fieldParentId.value, to.uniqueId);
      expect(child.fieldName.value, 'Car:Fuel');
      expect(child.mutation, MutationType.changed);
      expect(from.isDeleted, isTrue);
    });

    test('category merge into its own subcategory is rejected', () {
      final Category from = _createCategory('Auto');
      final Category child = _createCategory('Auto:Fuel', parentId: from.uniqueId);

      expect(mergeCategoryInto(from, child), isFalse);
      expect(from.isDeleted, isFalse);
    });
  });

  test('reparenting a category under itself or a descendant is rejected', () {
    final Category root = _createCategory('A');
    final Category child = _createCategory('A:B', parentId: root.uniqueId);
    final Category grandChild = _createCategory('A:B:C', parentId: child.uniqueId);

    expect(Data().categories.reparentCategory(root, root), isFalse);
    expect(Data().categories.reparentCategory(root, grandChild), isFalse);
    expect(root.fieldParentId.value, -1);
  });

  test('clearing categories forgets the cached Split category', () {
    Data().categories.splitCategoryId(); // caches the Split category of the first "file"
    Data().clearExistingData();
    _createCategory('Something');

    expect(Data().categories.get(Data().categories.splitCategoryId()), same(Data().categories.split));
  });

  test('new split ids are unique within their transaction', () {
    final Transaction a = _createTransaction(account: checking, amount: -1);
    final Transaction b = _createTransaction(account: checking, amount: -1);
    _createSplit(a);
    _createSplit(a);

    expect(_createSplit(b).uniqueId, 0);
    expect(_createSplit(a).uniqueId, 2);
  });
}
