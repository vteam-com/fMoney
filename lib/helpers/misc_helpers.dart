// ignore: fcheck_dead_code
// ignore: fcheck_one_class_per_file
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:url_launcher/url_launcher.dart';

Logger logger = Logger(
  filter: null, // Use the default LogFilter (-> only log in debug mode)
  output: null, // Use the default LogOutput (-> send everything to console)
);

const double _zeroDouble = 0.0;
const double _defaultEpsilon = 0.009;
const double _baseTen = 10.0;
const int _baseTenInt = 10;
const int _zeroInt = 0;
const int _oneInt = 1;
const int _notFoundIndex = -1;
const int _minDecimalPlaces = 0;
const int _snackBarDurationSeconds = 1;
const int _defaultDebounceSeconds = 1;
const double _fiveDecimalMultiplier = 100000.0;
const List<int> _naturalFitDivisors = <int>[
  1000000,
  100000,
  10000,
  1000,
  100,
  50,
  10,
];

/// Converts dynamic value to double if possible.
double getDoubleFromDynamic(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    return attemptToGetDoubleFromText(value) ?? _zeroDouble;
  }
  return _zeroDouble;
}

/// Matches any digit.
final RegExp _digitPattern = RegExp(r'\d');

/// Matches a standalone `DR` (debit) marker such as in `123.45 DR` or `123.45DR`.
final RegExp _debitMarkerPattern = RegExp('(?<![A-Z])DR(?![A-Z])');

/// Matches every character that is not a digit or a number separator.
final RegExp _nonNumberCharactersPattern = RegExp(r'[^0-9,.]');

/// Matches a comma followed by one or two final digits, such as `12,5` or `12,50`.
final RegExp _decimalCommaPattern = RegExp(r',\d{1,2}$');

/// Parses a money amount written in common bank, spreadsheet and statement styles.
///
/// Ignores currency symbols, codes and any text around the number, and detects
/// the decimal separator: `1,234.56` and `1.234,56` both give 1234.56, and a
/// single comma followed by one or two digits is a decimal comma (`12,50`).
/// The result is negative when a minus sign comes before or after the number
/// (`-12`, `$-12`, `12-`), when parentheses surround it (`(12.00)`), or when a
/// standalone `DR` marker is present. Returns null when [text] has no number.
double? parseAmountFlexible(String text) {
  final String upperText = text.trim().toUpperCase();
  int numberStart = upperText.indexOf(_digitPattern);
  if (numberStart == _notFoundIndex) {
    return null;
  }
  final int numberEnd = upperText.lastIndexOf(_digitPattern) + _oneInt;
  if (numberStart > _zeroInt && ',.'.contains(upperText[numberStart - _oneInt])) {
    numberStart--;
  }

  final String beforeNumber = upperText.substring(_zeroInt, numberStart);
  final String afterNumber = upperText.substring(numberEnd);
  final bool isNegative =
      beforeNumber.contains('-') ||
      afterNumber.contains('-') ||
      (beforeNumber.contains('(') && afterNumber.contains(')')) ||
      _debitMarkerPattern.hasMatch(upperText);

  final String digits = upperText.substring(numberStart, numberEnd).replaceAll(_nonNumberCharactersPattern, '');
  final double? amount = double.tryParse(_normalizeNumberSeparators(digits));
  if (amount == null) {
    return null;
  }
  return isNegative ? -amount : amount;
}

/// Rewrites [number] (digits, commas and dots only) with a dot as the decimal
/// separator and no thousands separators.
String _normalizeNumberSeparators(String number) {
  final int commaIndex = number.lastIndexOf(',');
  final int dotIndex = number.lastIndexOf('.');

  if (commaIndex != _notFoundIndex && dotIndex != _notFoundIndex) {
    return commaIndex > dotIndex ? number.replaceAll('.', '').replaceAll(',', '.') : number.replaceAll(',', '');
  }

  if (commaIndex != _notFoundIndex) {
    return _decimalCommaPattern.hasMatch(number) ? number.replaceAll(',', '.') : number.replaceAll(',', '');
  }

  final int lastDotIndex = number.lastIndexOf('.');
  if (lastDotIndex != number.indexOf('.')) {
    return '${number.substring(_zeroInt, lastDotIndex).replaceAll('.', '')}${number.substring(lastDotIndex)}';
  }
  return number;
}

/// Extracts a number from [text], such as `123.45`, `\$1,234.56` or `€1.234,56`.
/// Plain numbers are parsed directly; anything else goes through [parseAmountFlexible].
double? attemptToGetDoubleFromText(String text) {
  final String trimmedText = text.trim();
  return double.tryParse(trimmedText) ?? parseAmountFlexible(trimmedText);
}

/// Copies the provided text to the system clipboard and displays a snackbar to inform the user.
///
/// This function is a utility for quickly copying text to the clipboard and providing feedback to the user.
///
/// @param context The [BuildContext] used to display the snackbar.
/// @param textToCopy The text to be copied to the clipboard.
void copyToClipboardAndInformUser(
  BuildContext context,
  String textToCopy,
) {
  Clipboard.setData(ClipboardData(text: textToCopy)).then((_) {
    if (context.mounted) {
      showSnackBar(
        context,
        AppL10n.tr(AppTranslationKeys.copiedToClipboard),
      );
    }
  });
}

/// Checks if value is strictly between min and max (exclusive).
bool isBetween(num value, num min, num max) {
  return value > min && value < max;
}

/// Checks if value is between or equal to min and max (inclusive).
bool isBetweenOrEqual(num value, num min, num max) {
  return value >= min && value <= max;
}

/// Returns true if running on mobile platform (iOS or Android).
bool isPlatformMobile() {
  return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  //  return defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android;
}

/// Rounds double to specified number of decimal places.
double roundDouble(double value, int places) {
  final num mod = pow(_baseTen, places);
  return (value * mod).round().toDouble() / mod;
}

/// Rounds a given value to the specified number of decimal places.
///
/// @param value The value to be rounded.
/// @param places The number of decimal places to round to.
/// @return The rounded value.
/// @throws ArgumentError If the number of decimal places is negative.
///
double roundToDecimalPlaces(double value, int places) {
  if (places < _minDecimalPlaces) {
    throw ArgumentError('Decimal places must be non-negative');
  }
  final int factor = pow(_baseTenInt, places).toInt();
  return (value * factor).round() / factor;
}

/// Round up to next divisor level
int roundToNextNaturalFit(int number, int divisor) {
  if (number % divisor == _zeroInt) {
    // already at the nature next fit
    return number;
  }
  // Calculate the remainder when dividing the number by the divisor.
  final int remainder = number % divisor;
  final int base = number - remainder;
  return base + divisor;
}

/// Next rounded upper value
/// 1912 > 2000
/// 777 > 1000
/// 34 > 100
/// 5 > 10
int roundToTheNextNaturalFit(int value) {
  for (final int divisor in _naturalFitDivisors) {
    if (value > divisor) {
      return roundToNextNaturalFit(value, divisor);
    }
  }
  return _naturalFitDivisors.last;
}

/// Shows a snackbar with the specified message.
void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: _snackBarDurationSeconds),
    ),
  );
}

/// Trims double to exactly 5 decimal places.
double trimToFiveDecimalPlaces(double value) {
  // Multiply the value by 100,000 to move the decimal point 5 places to the right
  final double multipliedValue = value * _fiveDecimalMultiplier;
  // Round the result to the nearest integer
  final double roundedValue = multipliedValue.roundToDouble();
  // Divide the rounded value by 100,000 to move the decimal point back to its original position
  return roundedValue / _fiveDecimalMultiplier;
}

/// Represents debouncer.
class Debouncer {
  Debouncer([this.duration = const Duration(seconds: _defaultDebounceSeconds)]);

  final Duration duration;

  Timer? _timer;

  /// Runs callback with debouncing.
  void run(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(duration, callback);
  }
}

/// Represents time lapse.
class TimeLapse {
  TimeLapse() {
    stopwatch = Stopwatch()..start();
  }

  Stopwatch? stopwatch;

  /// Ends stopwatch and prints elapsed time.
  void endAndPrint() {
    // print('Elapsed time: ${stopwatch?.elapsedMilliseconds} milliseconds');
  }
}

/// Returns true if value is considered zero within epsilon tolerance.
bool isConsideredZero(num value, [double epsilon = _defaultEpsilon]) {
  return value.abs() <= epsilon;
}

/// Launches Google search with the specified query.
Future<void> launchGoogleSearch(String query) async {
  final Uri url = Uri.parse('https://www.google.com/search?q=$query');
  if (!await launchUrl(url)) {
    throw Exception('Could not launch $url');
  }
}
