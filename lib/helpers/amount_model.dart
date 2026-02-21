import 'package:money/helpers/constants.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/misc_helpers.dart';

/// Formatted text using the supplied currency code and optional the currency/country flag
class AmountModel {
  /// Constructor
  AmountModel({
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
    return getAmountAsStringUsingCurrency(
      _amount,
      iso4217code: iso4217,
    );
  }

  /// Add operator
  AmountModel operator +(final dynamic value) {
    if (value is AmountModel) {
      _amount += value.asDouble();
    } else {
      _amount += value as double;
    }
    return this;
  }

  /// Subtracting operator
  AmountModel operator -(final dynamic value) {
    if (value is AmountModel) {
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

  /// Returns the amount as a shorthand string with currency.
  String toShortHand() {
    return getAmountAsShortHandStringUsingCurrency(
      _amount,
      iso4217code: iso4217,
    );
  }
}

/// Sorts AmountModel objects by amount value.
int sortByAmount(final AmountModel a, final AmountModel b, final bool ascending) {
  if (ascending) {
    return a.asDouble().compareTo(b.asDouble());
  } else {
    return b.asDouble().compareTo(a.asDouble());
  }
}
