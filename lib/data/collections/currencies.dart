// Imports
import 'package:collection/collection.dart';
import 'package:money/data/models/currency.dart';
import 'package:money/data/money_objects.dart';
import 'package:money/helpers/json_helper.dart';

/// Represents currencies.
class Currencies extends MoneyObjects<Currency> {
  Currencies() {
    collectionName = 'Currencies';
  }

  @override
  Currency instanceFromJson(final MyJson json) {
    return Currency.fromJson(json);
  }

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }

  Currency? getCurrencyFromSymbol(final String symbolToMatch) {
    return iterableList().firstWhereOrNull(
      (Currency currency) => currency.fieldSymbol.value == symbolToMatch,
    );
  }

  double getRatioFromSymbol(final String symbol) {
    final Currency? currency = getCurrencyFromSymbol(symbol);
    if (currency == null) {
      return 1;
    }
    return currency.fieldRatio.value;
  }
}
