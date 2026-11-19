import 'package:collection/collection.dart';
import 'package:money/data/helpers/investment_type_helper.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/stock_cumulative_model.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/investment_operations_interface.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/transaction_entity.dart';

/// Represents investments.
class Investments extends MoneyObjects<Investment> {
  Investments() {
    collectionName = SharedDomainStrings.domainString061;
  }
  late DataAbstract data;

  @override
  Investment instanceFromJson(MyJson json) {
    return Investment.fromJson(json, data);
  }

  @override
  void onAllDataLoaded() {
    for (final Investment investment in iterableList()) {
      // hydrate the transaction instance associated to the investments
      final dynamic transactionFound = data.getTransaction(
        investment.uniqueId,
      );
      investment.transactionInstance = transactionFound as Transaction?;

      investment.applySplits();
    }
  }

  /// Sorts [investments] by date then trade type, and sets each one's holding to the running
  /// split-adjusted share count; returns the final count. Pass the trades of a single position.
  static double applyHoldingSharesAdjustedForSplits(
    List<Investment> investments,
  ) {
    MoneyObjects.sortListFallbackOnIdForTieBreaker(
      investments,
      (DataObject a, DataObject b, bool ascending) =>
          Investment.sortByDateAndInvestmentType(a as Investment, b as Investment, ascending),
      true,
    );
    double runningShares = 0;

    for (final Investment investment in investments) {
      runningShares += investment.effectiveUnitsAdjusted;
      investment.fieldHoldingShares.value = runningShares;
    }

    return runningShares;
  }

  /// Sets each of [investments]' holding to the running share count of its own position
  /// (same security in the same account), so trades of other securities or accounts don't add up.
  static void applyHoldingSharesPerPosition(Iterable<Investment> investments) {
    groupBy(
      investments,
      (Investment investment) => (investment.fieldSecurity.value, investment.transactionInstance?.fieldAccountId.value),
    ).values.forEach(applyHoldingSharesAdjustedForSplits);
  }

  /// Returns all investments for a given security ID.
  static List<Investment> getInvestmentsForThisSecurity(int securityId, InvestmentOperations data) {
    return data
        .getInvestments()
        .cast<Investment>()
        .where((Investment item) => item.fieldSecurity.value == securityId)
        .toList();
  }

  /// Computes cumulative shares, profit, and dividends for investments.
  static StockCumulative getSharesAndProfit(List<Investment> investments) {
    // StockCumulative sort by date, TradeType, Amount
    investments.sort(
      (Investment a, Investment b) => Investment.sortByDateAndInvestmentType(a, b, true),
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
