import 'package:money/data/models/stock_cumulative_model.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/widgets/pickers/picker_security_type.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

/// Represents investments.
class Investments extends MoneyObjects<Investment> {
  Investments() {
    collectionName = SharedDomainStrings.domainString061;
  }
  late DataAbstract data;

  @override
  void loadFromJson(List<MyJson> rows) {
    clear();
    for (final MyJson row in rows) {
      appendMoneyObject(Investment.fromJson(row, data));
    }
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

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }

  /// Applies holding shares adjusted for stock splits across investments.
  static double applyHoldingSharesAdjustedForSplits(
    List<Investment> investments,
  ) {
    // first sort by date, TradeType, Amount
    final Field<dynamic> fieldToSortBy = Investment.fields.getFieldByName(
      SharedDomainStrings.domainString044,
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

  /// Returns all investments for a given security ID.
  static List<Investment> getInvestmentsForThisSecurity(int securityId, DataAbstract data) {
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
