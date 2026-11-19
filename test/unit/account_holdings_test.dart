import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/investment_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/data/models/stock_summary_model.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/investments_collection.dart';
import 'package:money/shared/domain/securities_collection.dart';
import 'package:money/shared/domain/transaction_entity.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  late Account brokerage;

  /// Records a purchase of [units] shares of [security] at [unitPrice] in the brokerage account.
  void buy(Security security, double units, double unitPrice) {
    final Transaction transaction = Transaction(date: DateTime(2024, 1, 15))..fieldAccountId.value = brokerage.uniqueId;
    Data().appendNewTransaction(transaction, fireNotification: false);
    Data().investments.appendMoneyObject(
      Investment(
        id: transaction.uniqueId,
        security: security.uniqueId,
        unitPrice: unitPrice,
        units: units,
        investmentType: InvestmentType.buy.index,
        tradeType: InvestmentTradeType.buy.index,
        data: Data(),
      ),
    );
  }

  setUp(() {
    resetTestData();
    brokerage = createTestAccount('Brokerage')..fieldType.value = AccountType.investment;
  });

  tearDown(() => Data().clearExistingData());

  test('holdings give each symbol its shares, price and average cost, and add their value to the balance', () {
    final Security msft = Data().securities.getOrCreate('MSFT')..fieldPrice.value.setAmount(10);
    final Security aapl = Data().securities.getOrCreate('AAPL')..fieldPrice.value.setAmount(20);
    final Security gone = Data().securities.getOrCreate('GONE')..fieldPrice.value.setAmount(50);
    buy(msft, 2, 5);
    buy(msft, 3, 7);
    buy(aapl, 1, 15);
    buy(gone, 4, 1);
    gone.mutation = MutationType.deleted;
    Data().investments.onAllDataLoaded();

    final Map<String, StockSummary> holdings = <String, StockSummary>{
      for (final StockSummary holding in Data().accounts.holdingsOf(brokerage)) holding.symbol: holding,
    };

    expect(holdings.keys, unorderedEquals(<String>['MSFT', 'AAPL', 'GONE']));
    expect(holdings['MSFT']!.shares, 5);
    expect(holdings['MSFT']!.sharePrice, 10);
    expect(holdings['MSFT']!.averageCost, (2 * 5 + 3 * 7) / 5);
    expect(holdings['GONE']!.sharePrice, 0, reason: 'a security that can no longer be found has no price');

    Data().accounts.onAllDataLoaded();

    expect(brokerage.fieldStockHoldingEstimation.value.asDouble(), 5 * 10 + 1 * 20, reason: 'every symbol counts');
    expect(brokerage.balance, 5 * 10 + 1 * 20);
  });

  test('credit card transactions get their running balance in date order', () {
    final Account card = createTestAccount('Card')..fieldType.value = AccountType.credit;
    final Transaction later = Transaction(date: DateTime(2024, 2, 1))
      ..fieldAccountId.value = card.uniqueId
      ..fieldAmount.value.setAmount(-30);
    final Transaction earlier = Transaction(date: DateTime(2024, 1, 1))
      ..fieldAccountId.value = card.uniqueId
      ..fieldAmount.value.setAmount(-10);
    Data().appendNewTransaction(later, fireNotification: false);
    Data().appendNewTransaction(earlier, fireNotification: false);

    Data().accounts.onAllDataLoaded();

    expect(earlier.balance, -10);
    expect(later.balance, -40);
    expect(Data().accounts.getTransactions(card), unorderedEquals(<Transaction>[earlier, later]));
  });

  test('each trade holds the running shares of its own position, not of every security', () {
    final Security msft = Data().securities.getOrCreate('MSFT');
    final Security aapl = Data().securities.getOrCreate('AAPL');
    buy(aapl, 10, 1);
    buy(msft, 5, 1);
    buy(aapl, 2, 1);
    Data().investments.onAllDataLoaded();

    Investments.applyHoldingSharesPerPosition(Data().investments.iterableList());

    final Investment msftTrade = Data().investments.iterableList().firstWhere(
      (Investment i) => i.fieldSecurity.value == msft.uniqueId,
    );
    expect(msftTrade.fieldHoldingShares.value, 5, reason: 'AAPL shares must not add up into the MSFT position');
    expect(
      Data().investments
          .iterableList()
          .where((Investment i) => i.fieldSecurity.value == aapl.uniqueId)
          .map((Investment i) => i.fieldHoldingShares.value),
      unorderedEquals(<double>[10, 12]),
    );
  });
}
