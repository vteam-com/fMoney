// Imports
import 'package:collection/collection.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/currency_entity.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';

/// Represents currencies.
class Currencies extends MoneyObjects<Currency> {
  Currencies() {
    collectionName = SharedDomainStrings.domainString041;
  }

  @override
  Currency instanceFromJson(MyJson json) {
    return Currency.fromJson(json);
  }

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }

  /// Finds a currency by its symbol.
  Currency? getCurrencyFromSymbol(String symbolToMatch) {
    return iterableList().firstWhereOrNull(
      (Currency currency) => currency.fieldSymbol.value == symbolToMatch,
    );
  }

  /// Returns the exchange ratio for a currency symbol; defaults to 1 if not found.
  double getRatioFromSymbol(String symbol) {
    final Currency? currency = getCurrencyFromSymbol(symbol);
    if (currency == null) {
      return 1;
    }
    return currency.fieldRatio.value;
  }
}
