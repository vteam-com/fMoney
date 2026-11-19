import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/securities_collection.dart';
import 'package:money/shared/domain/transaction_entity.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  setUp(resetTestData);

  tearDown(() => Data().clearExistingData());

  test('getOrCreate with an empty name creates the blank payee only once', () {
    final Payee blank = Data().payees.getOrCreate('', fireNotification: false);

    expect(Data().payees.getOrCreate('', fireNotification: false), same(blank));
    expect(Data().payees.length, 1);
    expect(Data().payees.getByName(''), isNull, reason: 'an empty name names no payee');
  });

  test('name lookups ignore case, sort by name and keep each collection fallback for unknown ids', () {
    final Payee zoo = Data().payees.getOrCreate('Zoo', fireNotification: false);
    final Payee bakery = Data().payees.getOrCreate('bakery', fireNotification: false);
    final Account checking = createTestAccount('Checking');
    final Category food = Data().categories.addNewCategory(name: 'Food');
    final Security security = Data().securities.getOrCreate('MSFT', name: 'Microsoft');

    expect(Data().payees.getByName('ZOO'), same(zoo));
    expect(Data().accounts.getByName('checking'), same(checking));
    expect(Data().securities.getByName('microsoft'), same(security));
    expect(Data().payees.getListSorted(), <Payee>[bakery, zoo]);

    expect(Data().payees.getNameFromId(zoo.uniqueId), 'Zoo');
    expect(Data().payees.getNameFromId(-1), '');
    expect(Data().payees.getNameFromId(42), '<unknown payee 42>');
    expect(Data().accounts.getNameFromId(checking.uniqueId), 'Checking');
    expect(Data().accounts.getNameFromId(-1), '');
    expect(Data().accounts.getNameFromId(42), '42');
    expect(Data().categories.getNameFromId(food.uniqueId), 'Food');
    expect(Data().securities.getNameFromId(security.uniqueId), 'Microsoft');
  });

  test('the sorted accounts leave out category funds and, unless chosen, closed accounts', () {
    final Account savings = createTestAccount('Savings')..isOpen = true;
    final Account checking = createTestAccount('Checking')..isOpen = true;
    createTestAccount('Fund')
      ..isOpen = true
      ..fieldType.value = AccountType.categoryFund;
    createTestAccount('Old').isOpen = false;

    expect(Data().accounts.getListSorted(), <Account>[checking, savings]);
    expect(Data().accounts.getSortedAccountNames(), <String>['Checking', 'Savings']);
  });

  test('payee totals skip transfers and start over on every recalculation', () {
    final Account checking = createTestAccount();
    final Category food = Data().categories.addNewCategory(name: 'Food');
    final Transaction purchase = createTestTransaction(checking, 'Grocer', category: food);
    final Transaction transfer = createTestTransaction(checking, 'Grocer', isTransfer: true);
    final Payee grocer = Data().payees.getByName('Grocer')!;

    expect(purchase.isForPayee(grocer.uniqueId), isTrue);
    expect(transfer.isForPayee(grocer.uniqueId), isFalse, reason: 'transfers have no payee');

    Data().payees.onAllDataLoaded();
    food.fieldName.value = 'Groceries';
    Data().payees.onAllDataLoaded();

    expect(grocer.fieldCount.value, 1);
    expect(grocer.categories, <String>{'Groceries'}, reason: 'the renamed category replaces the old name');
  });

  test('a payee used only by transfers can be merged away', () {
    final Account checking = createTestAccount();
    createTestTransaction(checking, 'Old Payee', isTransfer: true);
    final Payee oldPayee = Data().payees.getByName('Old Payee')!;
    final Payee newPayee = Data().payees.getOrCreate('New Payee', fireNotification: false);

    Data().mergePayeesWithNoTransactionsInto(<int>[oldPayee.uniqueId], newPayee.uniqueId);

    expect(oldPayee.isDeleted, isTrue);
  });
}
