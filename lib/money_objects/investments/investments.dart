import 'package:money/money_objects/data.dart';
import 'package:money/money_objects/investments/investment.dart';
import 'package:money/money_objects/investments/stock_cumulative.dart';
import 'package:money/money_objects/securities/security.dart';
import 'package:money/money_objects/stock_splits/stock_split.dart';
import 'package:money/money_objects/transactions/transaction.dart';
import 'package:money/views/home/sub_views/view_stocks/picker_security_type.dart';
import 'package:money/widgets_data/money_objects.dart';

// Exports
export 'package:money/money_objects/investments/investment.dart';

class Investments extends MoneyObjects<Investment> {
  Investments() {
    collectionName = 'Investments';
  }

  @override
  void loadFromJson(final List<MyJson> rows) {
    clear();
    for (final MyJson row in rows) {
      appendMoneyObject(Investment.fromJson(row));
    }
  }

  @override
  void onAllDataLoaded() {
    for (final Investment investment in iterableList()) {
      // hydrate the transaction instance associated to the investments
      final Transaction? transactionFound = Data().transactions.get(
        investment.uniqueId,
      );
      investment.transactionInstance = transactionFound;

      final Security? security = Data().securities.get(
        investment.fieldSecurity.value,
      );
      if (security != null) {
        final List<StockSplit> splits = Data().stockSplits.getStockSplitsForSecurity(security);
        investment.applySplits(splits);
      }
    }
  }

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }

  static double applyHoldingSharesAdjustedForSplits(
    List<Investment> investments,
  ) {
    // first sort by date, TradeType, Amount
    final Field<dynamic> fieldToSortBy = Investment.fields.getFieldByName(
      'Date',
    );
    MoneyObjects.sortListFallbackOnIdForTieBreaker(
      investments,
      fieldToSortBy.sort!,
      true,
    );
    double runningShares = 0;

    for (final Investment investment in investments) {
      runningShares += investment.effectiveUnitsAdjusted;
      investment.fieldHoldingShares.value = runningShares;
    }

    return runningShares;
  }

  static List<Investment> getInvestmentsForThisSecurity(final int securityId) {
    return Data().investments
        .iterableList()
        .where((Investment item) => item.fieldSecurity.value == securityId)
        .toList();
  }

  static StockCumulative getSharesAndProfit(List<Investment> investments) {
    // StockCumulative sort by date, TradeType, Amount
    investments.sort(
      (Investment a, Investment b) => Investment.sortByDateAndInvestmentType(a, b, true, true),
    );

    final StockCumulative cumulative = StockCumulative();

    for (final Investment investment in investments) {
      cumulative.dateRange.inflate(investment.date);
      cumulative.quantity += investment.effectiveUnitsAdjusted;
      cumulative.amount += investment.activityAmount;

      if (investment.actionType == InvestmentType.dividend) {
        final double amount = investment.activityDividend;
        cumulative.dividends.add(Dividend(investment.date, amount));
        cumulative.dividendsSum += amount;
      }
    }
    return cumulative;
  }
}
