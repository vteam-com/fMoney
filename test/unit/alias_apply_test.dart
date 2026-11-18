import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';

/// Creates and appends a non-transfer transaction on [account] with the payee named [payeeName].
Transaction _createTransaction(Account account, String payeeName, {String originalPayee = ''}) {
  final Transaction transaction = Transaction(date: DateTime(2024, 5, 1));
  transaction.fieldAccountId.value = account.uniqueId;
  transaction.fieldPayee.value = Data().payees.getOrCreate(payeeName, fireNotification: false).uniqueId;
  transaction.fieldOriginalPayee.value = originalPayee;
  transaction.fieldTransfer.value = -1;
  transaction.fieldTransferSplit.value = -1;
  Data().appendNewTransaction(transaction, fireNotification: false);
  transaction.mutation = MutationType.none;
  return transaction;
}

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

/// Appends a regex alias mapping [pattern] to [payee].
Alias _createRegexAlias(String pattern, int payeeId) => Data().aliases.appendNewMoneyObject(
  Alias(id: -1, pattern: pattern, flags: AliasType.regex.index, payeeId: payeeId, data: Data()),
  fireNotification: false,
) as Alias;

void main() {
  late Account checking;
  late Payee att;

  setUp(() {
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
    final Account account = Account();
    account.fieldName.value = 'Checking';
    account.fieldCurrency.value = 'USD';
    checking = Data().accounts.appendNewMoneyObject(account, fireNotification: false) as Account;
    att = Data().payees.getOrCreate('AT&T', fireNotification: false);
  });

  group('import', () {
    test('keeps the bank text as the original payee when an alias renames it', () {
      _createRegexAlias('(?i)ATT.*', att.uniqueId);

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
      final Alias alias = _createRegexAlias('ATT.*', att.uniqueId);
      final Transaction byPayeeName = _createTransaction(checking, 'ATT*BILL');
      final Transaction byOriginal = _createTransaction(checking, 'Phone', originalPayee: 'ATT WIRELESS');
      final Transaction other = _createTransaction(checking, 'MATTRESS FIRM');
      final Transaction already = _createTransaction(checking, 'AT&T');
      final Transaction transfer = _createTransaction(checking, 'ATT TRANSFER');
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
      final Transaction t = _createTransaction(checking, 'ATT*BILL');

      expect(Data().applyAlias(alias), 0);
      expect(t.payeeName, 'ATT*BILL');
    });
  });
}
