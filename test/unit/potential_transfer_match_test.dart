import 'package:flutter_test/flutter_test.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';

/// Creates and appends a transaction fixture for transfer-match tests.
Transaction _createTransaction({
  required int accountId,
  required double amount,
  required DateTime date,
  int transferId = -1,
}) {
  final Transaction transaction = Transaction(date: date);
  transaction.fieldAccountId.value = accountId;
  transaction.fieldAmount.value.setAmount(amount);
  transaction.fieldTransfer.value = transferId;
  transaction.fieldTransferSplit.value = -1;
  Data().appendNewTransaction(transaction, fireNotification: false);
  return transaction;
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
  });
}
