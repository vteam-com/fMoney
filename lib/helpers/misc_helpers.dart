// ignore: fcheck_dead_code
// ignore: fcheck_one_class_per_file
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:url_launcher/url_launcher.dart';

final Logger logger = Logger(
  filter: null, // Use the default LogFilter (-> only log in debug mode)
  output: null, // Use the default LogOutput (-> send everything to console)
);

const double _zeroDouble = 0.0;
const double _defaultEpsilon = 0.009;
const double _baseTen = 10.0;
const int _baseTenInt = 10;
const int _zeroInt = 0;
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
double getDoubleFromDynamic(final dynamic value) {
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

/// Remove non-numeric characters from the currency text
double? attemptToGetDoubleFromText(String text) {
  text = text.trim();
  final double? firstSimpleCase = double.tryParse(text);
  if (firstSimpleCase != null) {
    return firstSimpleCase;
  }

  // Remove non-numeric characters except for periods and commas
  String cleanedText = text.replaceAll(RegExp(r'[^\d.,]'), '');

  // Replace commas with periods for consistent parsing
  cleanedText = cleanedText.replaceAll(',', '.');

  // Remove any leading/trailing periods
  cleanedText = cleanedText.replaceAll(RegExp(r'^\.+|\.+$'), '');

  // If there are multiple periods, keep only the last one
  final int lastIndex = cleanedText.lastIndexOf('.');
  if (lastIndex != _notFoundIndex) {
    String beforeDecimal = cleanedText.substring(_zeroInt, lastIndex);
    beforeDecimal = beforeDecimal.replaceAll('.', '');
    cleanedText = beforeDecimal + cleanedText.substring(lastIndex);
  }

  // Parse the cleaned text into a double
  final double? amount = double.tryParse(cleanedText);
  if (amount == null) {
    return null;
  }
  if (text.startsWith('-')) {
    return -amount;
  }
  return amount;
}

/// Copies the provided text to the system clipboard and displays a snackbar to inform the user.
///
/// This function is a utility for quickly copying text to the clipboard and providing feedback to the user.
///
/// @param context The [BuildContext] used to display the snackbar.
/// @param textToCopy The text to be copied to the clipboard.
void copyToClipboardAndInformUser(
  final BuildContext context,
  final String textToCopy,
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
bool isBetween(final num value, final num min, final num max) {
  return value > min && value < max;
}

/// Checks if value is between or equal to min and max (inclusive).
bool isBetweenOrEqual(final num value, final num min, final num max) {
  return value >= min && value <= max;
}

/// Returns true if running on mobile platform (iOS or Android).
bool isPlatformMobile() {
  return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  //  return defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android;
}

/// Rounds double to specified number of decimal places.
double roundDouble(final double value, final int places) {
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
int roundToNextNaturalFit(final int number, final int divisor) {
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
int roundToTheNextNaturalFit(final int value) {
  for (final int divisor in _naturalFitDivisors) {
    if (value > divisor) {
      return roundToNextNaturalFit(value, divisor);
    }
  }
  return _naturalFitDivisors.last;
}

/// Shows a snackbar with the specified message.
void showSnackBar(final BuildContext context, final String message) {
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
