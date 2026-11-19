import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/potential_transfer_match_service.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/domain/transfer_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';

/// Creates and appends a transaction fixture for transfer-match tests.
Transaction _createTransaction({
  required int accountId,
  required double amount,
  required DateTime date,
  int transferId = -1,
  int categoryId = -1,
}) {
  final Transaction transaction = Transaction(date: date);
  transaction.fieldAccountId.value = accountId;
  transaction.fieldAmount.value.setAmount(amount);
  transaction.fieldTransfer.value = transferId;
  transaction.fieldTransferSplit.value = -1;
  transaction.fieldCategoryId.value = categoryId;
  Data().appendNewTransaction(transaction, fireNotification: false);
  return transaction;
}

/// Creates and appends an open account fixture of [type].
Account _createAccount(AccountType type) {
  final Account account = Account();
  account.fieldName.value = type.name;
  account.fieldType.value = type;
  account.isOpen = true;
  return Data().accounts.appendNewMoneyObject(account, fireNotification: false) as Account;
}

/// Creates and appends a category fixture of [type].
Category _createCategory(String name, CategoryType type) {
  final Category category = Category(id: -1, name: name, type: type, data: Data());
  return Data().categories.appendNewMoneyObject(category, fireNotification: false) as Category;
}

void main() {
  setUp(() {
    // Wires DataAccess.trackMutations, which the cached lookup relies on.
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
  });

  group('Data.hasPotentialTransferMatch', () {
    test('detects opposite amounts in different accounts within the date window', () {
      final Transaction outgoing = _createTransaction(
        accountId: 1,
        amount: -100.0,
        date: DateTime(2024, 1, 10),
      );
      final Transaction incoming = _createTransaction(
        accountId: 2,
        amount: 100.0,
        date: DateTime(2024, 1, 11),
      );

      expect(Data().hasPotentialTransferMatch(outgoing), isTrue);
      expect(Data().hasPotentialTransferMatch(incoming), isTrue);

      // The cached hint must agree with the full candidate search.
      expect(
        Data().findPotentialTransferMatches(transaction: outgoing),
        isNotEmpty,
      );
      expect(
        Data().findPotentialTransferMatches(transaction: incoming),
        isNotEmpty,
      );
    });

    test('returns false when no counterpart exists', () {
      final Transaction lone = _createTransaction(
        accountId: 1,
        amount: -55.55,
        date: DateTime(2024, 3, 1),
      );

      expect(Data().hasPotentialTransferMatch(lone), isFalse);
      expect(
        Data().findPotentialTransferMatches(transaction: lone),
        isEmpty,
      );
    });

    test('excludes pairs already explained by a same-account opposite match', () {
      final Transaction sameAccountOut = _createTransaction(
        accountId: 1,
        amount: -200.0,
        date: DateTime(2024, 5, 10),
      );
      final Transaction sameAccountIn = _createTransaction(
        accountId: 1,
        amount: 200.0,
        date: DateTime(2024, 5, 11),
      );
      final Transaction otherAccountIn = _createTransaction(
        accountId: 2,
        amount: 200.0,
        date: DateTime(2024, 5, 10),
      );

      expect(Data().hasPotentialTransferMatch(sameAccountOut), isFalse);
      expect(Data().hasPotentialTransferMatch(sameAccountIn), isFalse);
      expect(Data().hasPotentialTransferMatch(otherAccountIn), isFalse);
      expect(
        Data().findPotentialTransferMatches(transaction: sameAccountOut),
        isEmpty,
      );
      expect(
        Data().findPotentialTransferMatches(transaction: otherAccountIn),
        isEmpty,
      );
    });

    test('returns false for transactions already linked as transfers', () {
      final Transaction transfer = _createTransaction(
        accountId: 1,
        amount: -75.0,
        date: DateTime(2024, 6, 1),
        transferId: 999,
      );
      _createTransaction(
        accountId: 2,
        amount: 75.0,
        date: DateTime(2024, 6, 1),
      );

      expect(Data().hasPotentialTransferMatch(transfer), isFalse);
    });

    test('refreshes the cached result after data mutates', () {
      final Transaction outgoing = _createTransaction(
        accountId: 1,
        amount: -300.0,
        date: DateTime(2024, 7, 1),
      );

      // First call caches "no match".
      expect(Data().hasPotentialTransferMatch(outgoing), isFalse);

      // Adding a counterpart mutates the data version and must invalidate
      // the cache.
      _createTransaction(
        accountId: 2,
        amount: 300.0,
        date: DateTime(2024, 7, 2),
      );

      expect(Data().hasPotentialTransferMatch(outgoing), isTrue);
    });

    test('rejects an expense paired with an income, like a refund', () {
      final Category groceries = _createCategory('Groceries', CategoryType.expense);
      final Category salary = _createCategory('Salary', CategoryType.income);
      final Transaction purchase = _createTransaction(
        accountId: 1,
        amount: -40.0,
        date: DateTime(2024, 8, 1),
        categoryId: groceries.uniqueId,
      );
      final Transaction pay = _createTransaction(
        accountId: 2,
        amount: 40.0,
        date: DateTime(2024, 8, 1),
        categoryId: salary.uniqueId,
      );

      expect(Data().hasPotentialTransferMatch(purchase), isFalse);
      expect(Data().hasPotentialTransferMatch(pay), isFalse);
      expect(Data().findPotentialTransferMatches(transaction: purchase), isEmpty);
    });

    test('rejects a credit-card charge paired with a deposit but accepts a card payment', () {
      final Account card = _createAccount(AccountType.credit);
      final Account bank = _createAccount(AccountType.checking);
      final Transaction charge = _createTransaction(
        accountId: card.uniqueId,
        amount: -60.0,
        date: DateTime(2024, 9, 1),
      );
      final Transaction deposit = _createTransaction(
        accountId: bank.uniqueId,
        amount: 60.0,
        date: DateTime(2024, 9, 1),
      );
      final Transaction payment = _createTransaction(
        accountId: bank.uniqueId,
        amount: -70.0,
        date: DateTime(2024, 9, 5),
      );
      final Transaction received = _createTransaction(
        accountId: card.uniqueId,
        amount: 70.0,
        date: DateTime(2024, 9, 6),
      );

      expect(Data().hasPotentialTransferMatch(charge), isFalse);
      expect(Data().hasPotentialTransferMatch(deposit), isFalse);
      expect(Data().hasPotentialTransferMatch(payment), isTrue);
      expect(Data().findPotentialTransferMatches(transaction: received), <Transaction>[payment]);
    });

    test('never matches zero amounts', () {
      final Transaction zero = _createTransaction(accountId: 1, amount: 0.0, date: DateTime(2024, 10, 1));
      _createTransaction(accountId: 2, amount: 0.004, date: DateTime(2024, 10, 1));

      expect(Data().hasPotentialTransferMatch(zero), isFalse);
    });

    test('ignores split transactions', () {
      final Transaction split = _createTransaction(accountId: 1, amount: -80.0, date: DateTime(2024, 11, 1));
      Data().splits.appendNewMoneyObject(
        TransactionSplit(
          id: -1,
          transactionId: split.uniqueId,
          categoryId: -1,
          payeeId: -1,
          amount: -80,
          transferId: -1,
          memo: '',
          flags: 0,
          budgetBalanceDate: null,
          data: Data(),
        ),
        fireNotification: false,
      );
      final Transaction incoming = _createTransaction(accountId: 2, amount: 80.0, date: DateTime(2024, 11, 1));

      expect(split.isSplit, isTrue);
      expect(Data().hasPotentialTransferMatch(split), isFalse);
      expect(Data().hasPotentialTransferMatch(incoming), isFalse);
    });
  });

  group('isTransferMatchEligible', () {
    test('excludes closed accounts unless asked to include them', () {
      final Account closed = _createAccount(AccountType.savings)..isOpen = false;
      final Transaction transaction = _createTransaction(
        accountId: closed.uniqueId,
        amount: -10.0,
        date: DateTime(2024, 1, 1),
      );

      expect(isTransferMatchEligible(transaction, includeClosedAccounts: false), isFalse);
      expect(isTransferMatchEligible(transaction, includeClosedAccounts: true), isTrue);
    });

    test('excludes transactions already linked as transfers', () {
      final Transaction transfer = _createTransaction(
        accountId: 1,
        amount: -10.0,
        date: DateTime(2024, 1, 1),
        transferId: 999,
      );

      expect(isTransferMatchEligible(transfer, includeClosedAccounts: true), isFalse);
    });
  });

  group('buildTransferPreview', () {
    test('uses the negative leg as the sender whatever the argument order', () {
      final Transaction outgoing = _createTransaction(accountId: 1, amount: -15.0, date: DateTime(2024, 2, 1));
      final Transaction incoming = _createTransaction(accountId: 2, amount: 15.0, date: DateTime(2024, 2, 1));

      for (final Transfer preview in <Transfer>[
        buildTransferPreview(outgoing, incoming),
        buildTransferPreview(incoming, outgoing),
      ]) {
        expect(preview.source, outgoing);
        expect(preview.relatedTransaction, incoming);
      }
    });
  });

  group('findPotentialTransferPairs', () {
    test('pairs each transaction once with its closest-dated counterpart', () {
      final Transaction outgoing = _createTransaction(accountId: 1, amount: -100.0, date: DateTime(2024, 3, 10));
      _createTransaction(accountId: 2, amount: 100.0, date: DateTime(2024, 3, 12));
      final Transaction sameDay = _createTransaction(accountId: 3, amount: 100.0, date: DateTime(2024, 3, 10));

      final List<Transfer> pairs = findPotentialTransferPairs(
        eligibleTransactions: Data().transactions.iterableList().toList(),
      );

      expect(pairs, hasLength(1));
      expect(pairs.single.source, outgoing);
      expect(pairs.single.relatedTransaction, sameDay);
    });
  });
}
