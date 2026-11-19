import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/data/helpers/investment_type_helper.dart';
import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transactions_collection.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  setUp(resetTestData);

  tearDown(() => Data().clearExistingData());

  test('enumFromIndex returns the value at the index, or the fallback when out of range', () {
    expect(enumFromIndex(AccountType.values, 4, AccountType.checking), AccountType.credit);
    expect(enumFromIndex(AccountType.values, -1, AccountType.checking), AccountType.checking);
    expect(enumFromIndex(AccountType.values, AccountType.values.length, AccountType.checking), AccountType.checking);
  });

  test('stored enum values out of range fall back instead of throwing', () {
    expect(CategoryTypeExtension.fromInt(99), CategoryType.none);
    expect(CategoryTypeExtension.fromInt(1), CategoryType.income);
    expect(getInvestmentTypeFromValue(99), InvestmentType.none);
    expect(getInvestmentTypeFromValue(2), InvestmentType.buy);
    expect(getInvestmentTradeTypeFromValue(99), InvestmentTradeType.none);
    expect(getInvestmentTradeTypeFromValue(5), InvestmentTradeType.sell);
    expect(Account.fromJson(<String, dynamic>{'Type': 99}).fieldType.value, AccountType.checking);
    expect(Account.fromJson(<String, dynamic>{'Type': 4}).fieldType.value, AccountType.credit);
    expect(Transaction.fromJSon(<String, dynamic>{'Status': 99}, 0).fieldStatus.value, TransactionStatus.none);
    expect(Transaction.fromJSon(<String, dynamic>{'Status': 2}, 0).fieldStatus.value, TransactionStatus.cleared);
  });

  test('loaded transactions start with a zero balance and use the collection data', () {
    Data().transactions.loadFromJson(<Map<String, dynamic>>[
      <String, dynamic>{'Id': 1, 'Amount': 10.0},
      <String, dynamic>{'Id': 2, 'Amount': 20.0},
    ]);

    final List<Transaction> loaded = Data().transactions.iterableList().toList();
    expect(loaded.map((Transaction t) => t.balance), <double>[0, 0]);
    expect(loaded.first.data, same(Data()));
  });
}
