import 'package:collection/collection.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/views/data/data.dart';
import 'package:money/views/data/investment.dart';
import 'package:money/views/data/investments.dart';
import 'package:money/views/data/security.dart';
import 'package:money/views/models/money_objects.dart';
import 'package:money/widgets/stock_cumulative.dart';

// Exports
export 'package:money/views/data/security.dart';

class Securities extends MoneyObjects<Security> {
  Securities() {
    collectionName = 'Securities';
  }

  // Loads data from a list of JSON objects into the collection of Security objects.
  @override
  void loadFromJson(final List<MyJson> rows) {
    clear(); // Clears the current collection.
    for (final MyJson row in rows) {
      appendMoneyObject(
        Security.fromJson(row),
      ); // Converts each JSON object to a Security and appends it to the collection.
    }
  }

  // Processes all Security objects after all data has been loaded.
  @override
  void onAllDataLoaded() {
    for (final Security security in iterableList()) {
      // Sets the splits history for each Security.
      security.splitsHistory = Data().stockSplits.getStockSplitsForSecurity(
        security,
      );

      // Retrieves associated investments and updates various fields.
      final List<Investment> list = security.getAssociatedInvestments();
      security.fieldNumberOfTrades.value = list.length;

      // Calculates cumulative shares and profit, and updates relevant fields.
      final StockCumulative cumulative = Investments.getSharesAndProfit(list);
      security.fieldTransactionDateRange.value = cumulative.dateRange;
      security.fieldHoldingShares.value = cumulative.quantity;
      security.fieldActivityProfit.value.setAmount(
        cumulative.amount - cumulative.dividendsSum,
      );
      security.fieldActivityDividend.value.setAmount(cumulative.dividendsSum);
      security.dividends = cumulative.dividends;
    }
  }

  // Converts the collection of Security objects to a CSV string.
  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(
      getListSortedById(), // Gets the list of Security objects sorted by ID.
    );
  }

  // Retrieves a Security object by its symbol, ignoring case.
  Security? getBySymbol(final String symbolToFind) {
    return iterableList().firstWhereOrNull(
      (Security item) => stringCompareIgnoreCasing2(item.fieldSymbol.value, symbolToFind) == 0,
    );
  }

  // Retrieves a Security object by its symbol or creates a new one if it doesn't exist.
  Security getOrCreate(final String symbolToFind) {
    Security? security = getBySymbol(symbolToFind);
    if (security == null) {
      security = Security.fromJson(<String, dynamic>{
        'Symbol': symbolToFind,
      }); // Creates a new Security if not found.
      appendNewMoneyObject(
        security,
        fireNotification: false,
      ); // Appends the new Security to the collection.
    }
    return security;
  }

  // Retrieves the symbol of a Security object by its ID.
  String getSymbolFromId(final int securityId) {
    final Security? security = get(securityId);
    if (security == null) {
      return '(?)'; // Returns '(?)' if the Security is not found.
    }
    return security.fieldSymbol.value; // Returns the symbol of the Security.
  }
}
