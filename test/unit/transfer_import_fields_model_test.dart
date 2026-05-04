import 'package:flutter_test/flutter_test.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/views/imports/transfer/transfer_import_fields_model.dart';

void main() {
  group('ImportFieldsForTransfer', () {
    Account makeAccount(final String name) {
      final Account account = Account();
      account.fieldName.value = name;
      return account;
    }

    test('validAccounts returns false when both accounts are the same instance', () {
      final Account account = makeAccount('Checking');
      final ImportFieldsForTransfer fields = ImportFieldsForTransfer(
        accountFrom: account,
        accountTo: account,
        date: DateTime(2024, 1, 1),
        category: null,
        amount: 100.0,
        memo: '',
      );
      expect(fields.validAccounts, isFalse);
    });

    test('validAccounts returns true when accounts are different instances', () {
      final ImportFieldsForTransfer fields = ImportFieldsForTransfer(
        accountFrom: makeAccount('Checking'),
        accountTo: makeAccount('Savings'),
        date: DateTime(2024, 1, 1),
        category: null,
        amount: 100.0,
        memo: '',
      );
      expect(fields.validAccounts, isTrue);
    });

    test('stores all constructor parameters correctly', () {
      final Account from = makeAccount('From');
      final Account to = makeAccount('To');
      final DateTime date = DateTime(2024, 6, 15);

      final ImportFieldsForTransfer fields = ImportFieldsForTransfer(
        accountFrom: from,
        accountTo: to,
        date: date,
        category: null,
        amount: 250.0,
        memo: 'Monthly transfer',
      );

      expect(fields.accountFrom, same(from));
      expect(fields.accountTo, same(to));
      expect(fields.date, date);
      expect(fields.amount, 250.0);
      expect(fields.memo, 'Monthly transfer');
      expect(fields.category, isNull);
    });

    test('amount and memo are mutable after construction', () {
      final ImportFieldsForTransfer fields = ImportFieldsForTransfer(
        accountFrom: makeAccount('A'),
        accountTo: makeAccount('B'),
        date: DateTime(2024),
        category: null,
        amount: 0.0,
        memo: '',
      );

      fields.amount = 500.0;
      fields.memo = 'Updated memo';

      expect(fields.amount, 500.0);
      expect(fields.memo, 'Updated memo');
    });
  });
}
