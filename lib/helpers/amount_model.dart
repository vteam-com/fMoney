import 'package:money/helpers/constants_helper.dart';
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
  })
    // An initializing formal would rename the public `amount:` argument
    // to `_amount:`, breaking every call site.
    // ignore: prefer_initializing_formals
    : _amount = amount;

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
  AmountModel operator +(dynamic value) {
    if (value is AmountModel) {
      _amount += value.asDouble();
    } else {
      _amount += value as double;
    }
    return this;
  }

  /// Subtracting operator
  AmountModel operator -(dynamic value) {
    if (value is AmountModel) {
      _amount -= value.asDouble();
    } else {
      _amount -= value as double;
    }
    return this;
  }

  /// Sets the amount from a number, an [AmountModel] or text, as converted by [smartToDouble];
  /// anything else, including null, sets it to zero.
  void setAmount(dynamic newValueToSet) {
    _amount = smartToDouble(newValueToSet);
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
int sortByAmount(AmountModel a, AmountModel b, bool ascending) {
  if (ascending) {
    return a.asDouble().compareTo(b.asDouble());
  } else {
    return b.asDouble().compareTo(a.asDouble());
  }
}

/// Converts [value] to a double: a number as is, an [AmountModel] by its amount and text
/// through [attemptToGetDoubleFromText]. Returns [defaultValue] for null, for text without
/// a number and for any other type.
double smartToDouble(dynamic value, [double defaultValue = 0.0]) => switch (value) {
  final num number => number.toDouble(),
  final AmountModel amount => amount.asDouble(),
  final String text => attemptToGetDoubleFromText(text) ?? defaultValue,
  _ => defaultValue,
};
