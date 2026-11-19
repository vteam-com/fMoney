import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';

import '../helpers/test_fixtures_helper.dart';

/// Appends a transaction of [amount] on [day] of May 2024 to [account]; [isTransfer] marks a card payment.
Transaction _addTransaction(Account account, int day, double amount, {bool isTransfer = false}) {
  final Transaction transaction = createTestTransaction(account, 'Shop', isTransfer: isTransfer);
  transaction.fieldDateTime.value = DateTime(2024, 5, day);
  transaction.fieldAmount.value.setAmount(amount);
  return transaction;
}

void main() {
  setUp(resetTestData);

  test('a payment that misses the statement balance shows the gap in the card currency', () {
    final Account card = createTestAccount('Visa');
    card.fieldType.value = AccountType.credit;
    card.fieldCurrency.value = 'EUR';
    final Transaction purchase = _addTransaction(card, 1, -100);
    _addTransaction(card, 10, 90, isTransfer: true);

    Data().accounts.onAllDataLoaded();

    expect(purchase.fieldPaidOn.value, endsWith('-€10,00'));
  });
}
