import 'package:collection/collection.dart';
import 'package:money/data/models/stock_cumulative_model.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/investments_collection.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/security_entity.dart';
import 'package:money/shared/domain/stock_split_entity.dart';

// Exports
export 'package:money/shared/domain/security_entity.dart';

/// Represents securities.
class Securities extends MoneyObjects<Security> {
  Securities() {
    collectionName = SharedDomainStrings.domainString124;
  }
  late DataAbstract data;

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
      security.splitsHistory = data
          .getStockSplitsForSecurity(
            security,
          )
          .cast<StockSplit>();

      // Retrieves associated investments and updates various fields.
      final List<Investment> list = data
          .getInvestments()
          .cast<Investment>()
          .where((Investment item) => item.fieldSecurity.value == security.uniqueId)
          .toList();
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

  /// Retrieves a security by its symbol (case-insensitive).
  Security? getBySymbol(final String symbolToFind) {
    return iterableList().firstWhereOrNull(
      (Security item) => stringCompareIgnoreCasing(item.fieldSymbol.value, symbolToFind) == 0,
    );
  }

  /// Retrieves a security by its display name (case-insensitive).
  Security? getByName(final String nameToFind) {
    return iterableList().firstWhereOrNull(
      (Security item) => stringCompareIgnoreCasing(item.fieldName.value, nameToFind) == 0,
    );
  }

  /// Normalizes a free-form investment input into a likely stock symbol.
  ///
  /// Examples:
  /// - `Nokia (NOK)` -> `NOK`
  /// - `NASDAQ:AAPL` -> `AAPL`
  /// - `aapl` -> `AAPL`
  String normalizeSymbolCandidate(final String symbolOrName) {
    final String trimmed = symbolOrName.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final RegExp symbolInParentheses = RegExp(r'\(([A-Za-z0-9._-]{1,20})\)');
    final Match? parenthesesMatch = symbolInParentheses.firstMatch(trimmed);
    if (parenthesesMatch != null) {
      final String? insideParentheses = parenthesesMatch.group(1);
      if (insideParentheses != null && insideParentheses.isNotEmpty) {
        return insideParentheses.toUpperCase();
      }
    }

    final int exchangeSeparatorIndex = trimmed.lastIndexOf(':');
    if (exchangeSeparatorIndex > 0 && exchangeSeparatorIndex < trimmed.length - 1) {
      return trimmed.substring(exchangeSeparatorIndex + 1).trim().toUpperCase();
    }

    return trimmed.toUpperCase();
  }

  /// Finds an existing security by symbol first, then by security name.
  Security? getBySymbolOrName(final String symbolOrName) {
    final String trimmed = symbolOrName.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final String normalizedSymbol = normalizeSymbolCandidate(trimmed);
    return getBySymbol(normalizedSymbol) ?? getBySymbol(trimmed) ?? getByName(trimmed);
  }

  /// Retrieves a security by symbol or creates a new one if missing.
  ///
  /// If [name] is provided, it will be stored as the security's name field
  /// when creating a new security. Useful for preserving import descriptions.
  Security getOrCreate(final String symbolToFind, {final String? name}) {
    final String normalizedSymbol = normalizeSymbolCandidate(symbolToFind);
    Security? security = getBySymbolOrName(symbolToFind);
    if (security == null) {
      final Map<String, dynamic> json = <String, dynamic>{
        SharedDomainStrings.domainString131: normalizedSymbol,
      };

      // If a name was provided, store it in the security
      if (name != null && name.trim().isNotEmpty) {
        json[SharedDomainStrings.domainString088] = name.trim();
      }

      security = Security.fromJson(json); // Creates a new Security if not found.
      appendNewMoneyObject(
        security,
        fireNotification: false,
      ); // Appends the new Security to the collection.
    }
    return security;
  }

  // Retrieves the symbol of a Security object by its ID.
  /// Retrieves the symbol for a security by its ID; returns '(?)' if not found.
  String getSymbolFromId(final int securityId) {
    final Security? security = get(securityId);
    if (security == null) {
      return '(?)'; // Returns '(?)' if the Security is not found.
    }
    return security.fieldSymbol.value; // Returns the symbol of the Security.
  }
}
