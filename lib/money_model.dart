import 'package:money/constants.dart';
import 'package:money/currencies/currency.dart';
import 'package:money/helpers/misc_helpers.dart';

export 'package:money/constants.dart';

/// Formatted text using the supplied currency code and optional the currency/country flag
class MoneyModel {
  /// Constructor
  MoneyModel({
    required double amount,
    this.iso4217 = Constants.defaultCurrency,
    this.showCurrency = false,
    this.autoColor = true,
  }) : _amount = amount;

  bool autoColor;

  /// USD | CAD | GBP
  String iso4217;

  bool showCurrency;

  /// Amount to display
  double _amount;

  /// amount formatted with currency and separators
  @override
  String toString() {
    return Currency.getAmountAsStringUsingCurrency(
      _amount,
      iso4217code: iso4217,
    );
  }

  /// Add operator
  MoneyModel operator +(final dynamic value) {
    if (value is MoneyModel) {
      _amount += value.asDouble();
    } else {
      _amount += value as double;
    }
    return this;
  }

  /// Subtracting operator
  MoneyModel operator -(final dynamic value) {
    if (value is MoneyModel) {
      _amount -= value.asDouble();
    } else {
      _amount -= value as double;
    }
    return this;
  }

  /// Sets the _amount property of the MoneyModel instance based on the provided input.
  /// If the input is a String, it attempts to parse it as a double using the attemptToGetDoubleFromText function.
  /// If the input is not a String, it calls the toDouble() method on the input to convert it to a double.
  void setAmount(final dynamic newValueToSet) {
    _amount =
        newValueToSet
            is String // Check if the input is a String
        ? attemptToGetDoubleFromText(newValueToSet) ??
              0.0 // If it's a String, attempt to parse it as a double
        : (newValueToSet as num).toDouble(); // If it's not a String, call toDouble() to convert it to a double
  }

  /// the raw value as double
  double asDouble() => _amount;

  String toShortHand() {
    return Currency.getAmountAsShortHandStringUsingCurrency(
      _amount,
      iso4217code: iso4217,
    );
  }
}

int sortByAmount(final MoneyModel a, final MoneyModel b, final bool ascending) {
  if (ascending) {
    return a.asDouble().compareTo(b.asDouble());
  } else {
    return b.asDouble().compareTo(a.asDouble());
  }
}
