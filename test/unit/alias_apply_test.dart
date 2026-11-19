import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';

import '../helpers/test_fixtures_helper.dart';

/// Creates and appends a split line under [transaction] with the payee named [payeeName].
TransactionSplit _createSplit(Transaction transaction, String payeeName) {
  final TransactionSplit split = TransactionSplit(
    id: -1,
    transactionId: transaction.uniqueId,
    categoryId: -1,
    payeeId: Data().payees.getOrCreate(payeeName, fireNotification: false).uniqueId,
    amount: 1,
    transferId: -1,
    memo: '',
    flags: 0,
    budgetBalanceDate: null,
    data: Data(),
  );
  return Data().splits.appendNewMoneyObject(split, fireNotification: false) as TransactionSplit;
}

void main() {
  late Account checking;
  late Payee att;

  setUp(() {
    resetTestData();
    checking = createTestAccount();
    att = Data().payees.getOrCreate('AT&T', fireNotification: false);
  });

  /// A saved transaction for the payee named [payeeName], with the bank text [originalPayee].
  Transaction savedTransaction(String payeeName, {String originalPayee = ''}) =>
      createTestTransaction(checking, payeeName, originalPayee: originalPayee)..mutation = MutationType.none;

  group('import', () {
    test('keeps the bank text as the original payee when an alias renames it', () {
      createTestAlias('(?i)ATT.*', att);

      final Transaction t = Transaction.fromDateDescriptionAmount(checking, DateTime(2024), 'ATT*BILL PAYMENT', -50);

      expect(t.payeeName, 'AT&T');
      expect(t.fieldOriginalPayee.value, 'ATT*BILL PAYMENT');
    });

    test('leaves the original payee empty when no alias renames it', () {
      final Transaction t = Transaction.fromDateDescriptionAmount(checking, DateTime(2024), 'Starbucks', -5);

      expect(t.payeeName, 'Starbucks');
      expect(t.fieldOriginalPayee.value, isEmpty);
    });
  });

  group('applyAlias', () {
    test('moves matching transactions and splits to the alias payee', () {
      final Alias alias = createTestAlias('ATT.*', att);
      final Transaction byPayeeName = savedTransaction('ATT*BILL');
      final Transaction byOriginal = savedTransaction('Phone', originalPayee: 'ATT WIRELESS');
      final Transaction other = savedTransaction('MATTRESS FIRM');
      final Transaction already = savedTransaction('AT&T');
      final Transaction transfer = savedTransaction('ATT TRANSFER');
      transfer.fieldTransfer.value = other.uniqueId;
      final TransactionSplit split = _createSplit(other, 'ATT SPLIT');

      expect(Data().applyAlias(alias), 3);

      expect(byPayeeName.fieldPayee.value, att.uniqueId);
      expect(byPayeeName.fieldOriginalPayee.value, 'ATT*BILL', reason: 'the name before the alias is kept');
      expect(byPayeeName.mutation, MutationType.changed);
      expect(byOriginal.fieldPayee.value, att.uniqueId);
      expect(byOriginal.fieldOriginalPayee.value, 'ATT WIRELESS');
      expect(split.fieldPayeeId.value, att.uniqueId);
      expect(other.payeeName, 'MATTRESS FIRM');
      expect(already.mutation, MutationType.none);
      expect(transfer.payeeName, 'ATT TRANSFER');
    });

    test('does nothing for an alias without a payee', () {
      final Alias alias = Data().aliases.addNewAlias();
      alias.fieldPattern.value = 'ATT*BILL';
      final Transaction t = savedTransaction('ATT*BILL');

      expect(Data().applyAlias(alias), 0);
      expect(t.payeeName, 'ATT*BILL');
    });
  });
}
