import 'package:money/helpers/constants.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/shared_strings.dart';

/// Get the country code for flag from currency ISO code
String getCountryFromCurrencyIso4217(String iso4217code) {
  const Map<String, String> flagOverrides = <String, String>{
    // No locale available in dart-intl for these currencies.
    'BTN': 'bt',
    'CLF': 'cl',
    'COU': 'co',
    'ERN': 'er',
    'MVR': 'mv',
    'MXV': 'mx',
    'SOS': 'so',
    'UYI': 'uy',
    'WST': 'ws',
    // Locale maps to a country, but we intentionally use the EU flag for Euro.
    'EUR': 'eu',
  };

  final String code = iso4217code.toUpperCase();

  final String? overrideFlag = flagOverrides[code];
  if (overrideFlag != null) {
    return overrideFlag;
  }

  final String? locale = getLocaleFromCurrencyIso4217(code);
  if (locale == null || locale.isEmpty) {
    return SharedStrings.countryCodeUsLower;
  }

  final int separator = locale.indexOf('_');
  if (separator < 0 || separator + 1 >= locale.length) {
    return SharedStrings.countryCodeUsLower;
  }

  return locale.substring(separator + 1).toLowerCase();
}

/// Returns currency symbol string from three-letter currency code.
String getCurrencyAsString(final String threeLetterCurrencySymbol) {
  if (threeLetterCurrencySymbol.isEmpty) {
    return Constants.defaultCurrency;
  }
  return threeLetterCurrencySymbol;
}
