import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:money/core/helpers/misc_helpers.dart';
import 'package:path_provider/path_provider.dart';

/// Returns the count of occurrences of a single character in a given string.
///
/// @param input The input string to search for the character.
/// @param char The single character to count occurrences of.
/// @returns The number of times the character appears in the input string.
int countOccurrences(String input, String char) {
  if (char.length != 1) {
    throw ArgumentError('The character to count must be a single character.');
  }

  int count = 0;
  for (int i = 0; i < input.length; i++) {
    if (input[i] == char) {
      count++;
    }
  }
  return count;
}

String doubleToCurrency(
  final double value, {
  final String symbol = '\$',
  final bool showPlusSign = false,
}) {
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: symbol,
  );
  // Format the double value as currency text
  return (showPlusSign ? getPlusSignIfPositive(value) : '') + currencyFormatter.format(value);
}

String getPlusSignIfPositive(final num value) {
  if (value > 0) {
    return '+';
  }
  return '';
}

String escapeString(String input) => input.replaceAll("'", "''");

String formatDoubleUpToFiveZero(double value, {bool showPlusSign = false}) {
  final NumberFormat formatter = NumberFormat('#,##0.#####', 'en_US');
  return getPrefixPlusSignIfNeeded(value, showPlusSign: showPlusSign) + formatter.format(value);
}

String formatDoubleTrimZeros(double value) {
  final NumberFormat formatter = NumberFormat('#,##0.##', 'en_US');
  return formatter.format(value);
}

String getAmountAsShorthandText(
  final num value, {
  final int decimalDigits = 0,
  final String symbol = '',
}) => NumberFormat.compactCurrency(
  decimalDigits: decimalDigits,
  symbol: symbol, // if you want to add currency symbol then pass that in this else leave it empty.
).format(value);

List<String> getColumnInCsvLine(final String csvLine) {
  List<String> items = csvLine.split(RegExp(r',|;(?=(?:[^"]*"[^"]*")*[^"]*$)'));
  // remove quotes around elements
  items = items.map((String item) => item.replaceAll('"', '')).toList();
  return items;
}

/// return a ISO 3166-1 Alpha2  US | CA | ES
String getCountryFromLocale(final String locale) {
  if (locale.isEmpty) {
    return 'US'; // default to US
  }
  final List<String> tokens = locale.replaceAll('-', '_').split('_');
  return tokens.last;
}

Future<String> getDocumentDirectory() async {
  if (kIsWeb) {
    return '';
  }
  final Directory directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

String getInitials(String fullName) => fullName.split(' ').map((String word) => word[0].toUpperCase()).join('');

String getIntAsText(final int value, {final bool showPlusSign = false}) =>
    getPrefixPlusSignIfNeeded(value, showPlusSign: showPlusSign) + NumberFormat.decimalPattern().format(value);

String getPrefixPlusSignIfNeeded(
  final num value, {
  final bool showPlusSign = false,
}) => (showPlusSign ? getPlusSignIfPositive(value) : '');

/// Parses a raw text string and splits it into rows and columns based on a specified separator character.
///
/// The function handles quoted fields and escaped quotes within the text. It returns a list of rows,
/// where each row is represented as a list of strings (fields).
///
/// [content] The raw text string to be parsed.
/// [separator] The character used to separate fields within a row. Defaults to a comma `,`.
///
/// Returns a `List<List<String>>` representing the parsed rows and fields.
List<List<String>> getLinesFromRawTextWithSeparator(
  final String content, [
  final String separator = ',',
]) {
  final List<List<String>> rows = <List<String>>[];
  List<String> currentRow = <String>[];
  StringBuffer currentField = StringBuffer();
  bool inQuotes = false;

  for (int i = 0; i < content.length; i++) {
    final String char = content[i];

    if (char == '"' && (i + 1 < content.length && content[i + 1] == '"')) {
      // Handle escaped quotes
      currentField.write('"');
      i++; // Skip the next quote
    } else if (char == '"') {
      inQuotes = !inQuotes; // Toggle the inQuotes state
    } else if ((char == separator) && !inQuotes) {
      // End of a field
      currentRow.add(currentField.toString());
      currentField = StringBuffer();
    } else if ((char == '\n' || char == '\r') && !inQuotes) {
      // End of a row (handle both \n and \r\n)
      if (currentField.isNotEmpty || currentRow.isNotEmpty) {
        currentRow.add(currentField.toString());
        rows.add(currentRow);
        currentRow = <String>[];
        currentField = StringBuffer();
      }
    } else {
      // Normal character
      currentField.write(char);
    }
  }

  // Add the last row if it exists
  if (currentField.isNotEmpty || currentRow.isNotEmpty) {
    currentRow.add(currentField.toString());
    rows.add(currentRow);
  }

  return rows;
}

/// Clean up input string by removing "white noise"
String getNormalizedValue(final String? s) {
  if (s == null) {
    return '';
  }

  return s.replaceAll('\r\n', ' ').replaceAll('\r', ' ').replaceAll('\n', ' ').trim();
}

String getNumberShorthandText(final num value) => NumberFormat.compact().format(value);

String getSingularPluralText(
  final String title,
  final int quantity,
  final String singular,
  final String plural,
) => '$title ${quantity == 1 ? singular : plural}';

String getStringContentBetweenTwoTokens(
  final String input,
  final String start,
  final String end,
) {
  final int indexStart = input.indexOf(start);
  if (indexStart != -1) {
    final int indexEnd = input.indexOf(end);
    if (indexEnd != -1) {
      return input.substring(indexStart + start.length, indexEnd);
    }
  }
  return '';
}

String getStringDelimitedStartEndTokens(
  final String input,
  final String start,
  final String end,
) {
  final String content = getStringContentBetweenTwoTokens(input, start, end);
  return start + content + end;
}

int getLineCount(final String text) {
  if (text.trim().isEmpty) {
    return 0;
  }
  return text.trim().split('\n').length;
}

/// Split the text into lines
List<String> getLinesOfText(
  final String inputText, {
  bool includeEmptyLines = true,
}) {
  final List<String> lines = inputText.split('\n');
  if (includeEmptyLines == false) {
    // Filter out the empty lines
    return lines.where((String line) => line.trim().isNotEmpty).toList();
  }
  return lines;
}

String removeEmptyLines(String text) {
  // Filter out the empty lines
  final List<String> nonEmptyLines = getLinesOfText(
    text,
    includeEmptyLines: false,
  );

  // Join the non-empty lines back together
  final String result = nonEmptyLines.join('\n');

  return result;
}

String shortenLongText(String fullName, [int maxLength = 5]) {
  assert(maxLength >= 0);
  if (fullName.length <= maxLength) {
    // No need to shorten
    return fullName;
  }

  final List<String> words = fullName.split(' ');
  if (words.length >= 2) {
    return words.map((String word) => word[0].toUpperCase()).join('.');
  }
  return fullName.substring(0, maxLength);
}

int stringCompareIgnoreCasing1(final String textA, final String textB) =>
    textA.toUpperCase().compareTo(textB.toUpperCase());

int stringCompareIgnoreCasing2(final String str1, final String str2) {
  if (str1 == str2) {
    return 0;
  }

  final int length1 = str1.length;
  final int length2 = str2.length;

  final int minLength = min(length1, length2);

  for (int i = 0; i < minLength; i++) {
    final int result = str1[i].toLowerCase().compareTo(str2[i].toLowerCase());
    if (result != 0) {
      return result;
    }
  }

  return length1.compareTo(length2);
}

int compareStringsAsNumbers(final String a, final String b) {
  if (a.length == b.length) {
    return a.compareTo(b);
  }
  return a.length.compareTo(b.length);
}

int compareStringsAsAmount(final String a, final String b) {
  final double valueA = attemptToGetDoubleFromText(a) ?? 0.00;
  final double valueB = attemptToGetDoubleFromText(b) ?? 0.00;

  return valueA.compareTo(valueB);
}

String concat(
  final String existingValue,
  final String valueToConcat, [
  final String separatorIfNeeded = '; ',
  bool doNotConcatIfPresent = false,
]) {
  if (valueToConcat.isEmpty) {
    // Nothing to concat
    return existingValue;
  }

  if (existingValue.isEmpty) {
    return valueToConcat;
  } else {
    if (doNotConcatIfPresent && existingValue.contains(separatorIfNeeded)) {
      return existingValue;
    }
    return existingValue + separatorIfNeeded + valueToConcat;
  }
}

String removeUtf8Bom(String text) {
  const String bom = '\u{FEFF}';
  if (text.startsWith(bom)) {
    return text.substring(1);
  }
  return text;
}

double? parseUSDAmount(String input) {
  input = input.replaceAll('\$', '');
  input = input.replaceAll('USD', '');
  final RegExp usdPattern = RegExp(
    r'^[+-]?(\d+(\,\d{3})*(\.\d+)?|\.\d+)(\s*USD)?$',
  );
  final RegExpMatch? match = usdPattern.firstMatch(input);

  if (match != null) {
    final String? numericPart = match.group(1)?.replaceAll(',', '');
    if (numericPart != null) {
      final double sign = input.startsWith('-') ? -1.0 : 1.0;
      return double.parse(numericPart) * sign;
    }
  }

  return null;
}

double? parseEuroAmount(String input) {
  final RegExp euroPattern = RegExp(
    r'^([+-]?(?:\d+(?:\.\d{3})*|\d+))(,\d+)?\s*€?$',
  );
  final RegExpMatch? match = euroPattern.firstMatch(input);

  if (match != null) {
    final String? integerPart = match.group(1)?.replaceAll('.', '');
    final String? decimalPart = match.group(2)?.replaceAll(',', '.');

    if (integerPart != null) {
      final String numericPart = integerPart + (decimalPart ?? '');
      return double.parse(numericPart);
    }
  }

  return null;
}

String convertParenthesesToNegativeString(String amountText) {
  amountText = amountText.trim();
  if (amountText.contains('(') && amountText.contains(')')) {
    amountText = amountText.replaceAll('(', '');
    amountText = amountText.replaceAll(')', '');
    amountText = '-$amountText';
  }
  return amountText;
}

double? parseAmount(String amountAsText, final String currency) {
  amountAsText = convertParenthesesToNegativeString(amountAsText);
  switch (currency.toLowerCase()) {
    case 'eur':
      return parseEuroAmount(amountAsText);
    case 'usd':
    case 'cad':
    default:
      return parseUSDAmount(amountAsText);
  }
}

/// Remove any characters not in the allowedChars argument
String cleanString(String inputStr, String allowedChars) =>
    inputStr.split('').where((String char) => allowedChars.contains(char)).join();

String validIntToCurrency(final num value) => getIntAsText(isNumber(value) ? value.toInt() : 0, showPlusSign: true);

String validDoubleToCurrency(final num value) => doubleToCurrency(
  isNumber(value) ? value.toDouble() : 0.0,
  showPlusSign: true,
);

bool isNumber(num value) => value.isFinite && !value.isNaN;

String formatByteSize(final int bytes) {
  if (bytes >= 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  } else if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  } else if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  } else {
    return '$bytes B';
  }
}
