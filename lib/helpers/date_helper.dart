// ignore: fcheck_dead_code
import 'package:intl/intl.dart';
import 'package:money/helpers/shared_strings.dart';

// Exports
export 'package:intl/intl.dart';

const int _zeroInt = 0;
const int _singularCount = 1;
const int _minValidYear = 1900;
const int _maxValidYear = 2099;
const int _minValidMonth = 1;
const int _maxValidMonth = 12;
const int _minValidDay = 1;
const int _maxValidDay = 31;
const int _daysPerYear = 365;
const int _daysPerMonthApprox = 30;
const int _qfxYearStart = 0;
const int _qfxYearEnd = 4;
const int _qfxMonthStart = 4;
const int _qfxMonthEnd = 6;
const int _qfxDayStart = 6;
const int _qfxDayEnd = 8;
const int _qfxHourStart = 8;
const int _qfxHourEnd = 10;
const int _qfxMinuteStart = 10;
const int _qfxMinuteEnd = 12;
const int _qfxSecondStart = 12;
const int _qfxSecondEnd = 14;
const int _endOfDayHour = 23;
const int _endOfDayMinute = 59;
const int _endOfDaySecond = 59;
const int _endOfDayMillisecond = 999;
const int _endOfDayMicrosecond = 999;

/// Generates all possible date format combinations.
List<String> generateAllDateFormats() {
  final List<String> separators = <String>['-', '/'];
  final List<String> yearFormats = <String>[SharedStrings.dateTokenYearFour, SharedStrings.dateTokenYearTwo];
  final List<String> monthFormats = <String>[SharedStrings.dateTokenMonthTwo, SharedStrings.dateTokenMonthOne];
  final List<String> dayFormats = <String>[SharedStrings.dateTokenDayTwo, SharedStrings.dateTokenDayOne];

  final List<String> allFormats = <String>[];

  for (String yearFormat in yearFormats) {
    for (String monthFormat in monthFormats) {
      for (String dayFormat in dayFormats) {
        for (String separator in separators) {
          allFormats.addAll(<String>[
            '$yearFormat$separator$monthFormat$separator$dayFormat',
            '$monthFormat$separator$dayFormat$separator$yearFormat',
            '$dayFormat$separator$monthFormat$separator$yearFormat',
          ]);
        }
      }
    }
  }

  return allFormats;
}

/// Returns possible date formats for a single date string.
List<String> getPossibleDateFormats(String dateString) {
  return getPossibleDateFormatsForAllValues(<String>[dateString]);
}

/// Returns possible date formats for multiple date strings.
List<String> getPossibleDateFormatsForAllValues(List<String> dateStrings) {
  final List<String> validFormats = <String>[];

  final List<String> possibleFormats = generateAllDateFormats();
  for (final String format in possibleFormats) {
    bool supportedByAll = true;
    for (final String dateString in dateStrings) {
      if (!doesDateFormatWorkOnThisString(format, dateString)) {
        supportedByAll = false;
        break;
      }
    }
    if (supportedByAll) {
      validFormats.add(format);
    }
  }

  return validFormats;
}

/// Checks if date format works on the given date string.
bool doesDateFormatWorkOnThisString(String format, String dateString) {
  final DateTime? parsedDate = DateFormat(format).tryParse(dateString);
  if (parsedDate != null) {
    final String formattedDate = DateFormat(format).format(parsedDate);
    return formattedDate == dateString;
  }
  return false;
}

/// Attempts to parse DateTime from dynamic value.
DateTime? attemptToGetDateFromDynamic(final dynamic value) {
  if (value is DateTime) {
    return value;
  } else if (value is String) {
    return attemptToGetDateFromText(value);
  }
  return null;
}

/// Attempts to parse a date string using a list of common date formats.
///
/// This function tries to parse the provided [text] string using a list of
/// predefined date formats. It returns the first valid [DateTime] object
/// found, or `null` if no valid date is found.
///
/// The supported date formats are:
/// - 'yyyy-MM-dd' (ISO8601)
/// - 'MM/dd/yyyy' (USA)
/// - 'dd/MM/yyyy' (Europe)
/// - 'dd/MM/yy' (Europe)
/// - 'dd-MM-yy' (Europe)
///
/// Example usage:
/// ```dart
/// final dateString = '2023-04-15';
/// final parsedDate = attemptToGetDateFromText(dateString);
/// if (parsedDate != null) {
///   print('Parsed date: $parsedDate');
/// } else {
///   print('Failed to parse date');
/// }
/// ```
///
/// @param text The date string to be parsed.
/// @return The parsed [DateTime] object, or `null` if no valid date is found.
DateTime? attemptToGetDateFromText(final String text) {
  // Define a list of date formats to try
  final List<String> dateFormats = <String>[
    'yyyy-MM-dd HH:mm:ss', // ISO8601
    'yyyy-MM-dd', // ISO8601
    'MM/dd/yyyy', // USA format 4 digit year
    'MM/dd/yy', // USA format 2 digit year
    'dd/MM/yyyy', // European format with full year
    'dd/MM/yy', // European format 2 digit year
    // Add more formats as needed...
  ];

  DateTime? parsedDate;
  for (String format in dateFormats) {
    parsedDate = DateFormat(format).tryParse(text);
    if (parsedDate != null &&
        parsedDate.year >= _minValidYear &&
        parsedDate.year <= _maxValidYear &&
        parsedDate.month >= _minValidMonth &&
        parsedDate.month <= _maxValidMonth &&
        parsedDate.day >= _minValidDay &&
        parsedDate.day <= _maxValidDay) {
      break; // Stop parsing if a valid date is found
    }
  }
  return parsedDate;
}

/// Converts DateTime to ISO 8601 string format with space instead of T.
String dateToDateTimeString(final DateTime? dateTime) {
  String dateTimeAsText = '';
  if (dateTime != null) {
    dateTimeAsText += dateTime.toIso8601String().replaceAll(SharedStrings.dateTimeIsoSeparator, SharedStrings.space);
  }
  return dateTimeAsText;
}

/// Converts a nullable DateTime object to an ISO8601 string representation,
/// or returns a default value if the input is null.
///
/// This function takes a nullable DateTime object as input and returns a
/// string representation of the date and time in the ISO8601 format. If the
/// input DateTime object is null, the function returns a default value
/// specified by the `defaultValueIfNull` parameter.
///
/// Parameters:
/// - `value`: The nullable DateTime object to be converted to an ISO8601 string.
/// - `defaultValueIfNull`: The default value to be returned if the `value`
///   parameter is null. Defaults to an empty string `''`.
///
/// Returns:
/// - If `value` is not null, the ISO8601 string representation of the date and time.
/// - If `value` is null, the `defaultValueIfNull` value.
String dateToIso8601OrDefaultString(
  final DateTime? value, {
  final String defaultValueIfNull = '',
}) {
  if (value == null) {
    return defaultValueIfNull;
  }
  return value.toIso8601String();
}

/// Converts DateTime to SQLite datetime string format.
String dateToSqliteFormat(DateTime? dateTime) {
  if (dateTime != null) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }
  return '';
}

/// Converts DateTime to formatted date string.
String dateToString(final DateTime? date) {
  if (date == null) {
    return '____-__-__';
  }
  return DateFormat('yyyy-MM-dd').format(date);
}

/// Converts a nullable DateTime object to a string representation of the year.
///
/// This function takes a nullable DateTime object as input and returns a string
/// containing the year component of the DateTime object. If the input DateTime
/// object is null, the function returns a default placeholder value.
///
/// Parameters:
/// - `dateTime`: The nullable DateTime object to be converted to a year string.
///
/// Returns:
/// - If `dateTime` is not null, a string representing a date
String dateToYearString(final DateTime? dateTime) {
  if (dateTime == null) {
    return '____';
  }

  return dateTime.year.toString();
}

/// Return the newest of two given [DateTime] values.
///
/// If both [a] and [b] are `null`, this function will return `null`.
/// If one of the parameters is `null`, this function will return the non-null [DateTime] object.
/// If both parameters are non-null, this function will return the [DateTime] object that is the most recent.
///
/// @param a The first [DateTime] object to compare.
/// @param b The second [DateTime] object to compare.
/// @return The newest [DateTime] object, or `null` if both inputs are `null`.
DateTime? newestDate(final DateTime? a, final DateTime? b) {
  if (a == null) {
    return b;
  }
  if (b == null) {
    return a;
  }
  return a.isAfter(b) ? a : b;
}

/// Return the oldest of two given [DateTime] values.
///
/// If both [a] and [b] are `null`, this function will return `null`.
/// If one of the parameters is `null`, this function will return the non-null [DateTime] object.
/// If both parameters are non-null, this function will return the [DateTime] object that is the oldest.
///
/// @param a The first [DateTime] object to compare.
/// @param b The second [DateTime] object to compare.
/// @return The oldest [DateTime] object, or `null` if both inputs are `null`.
DateTime? oldestDate(final DateTime? a, final DateTime? b) {
  if (a == null) {
    return b;
  }
  if (b == null) {
    return a;
  }
  return a.isBefore(b) ? a : b;
}

/// Parses a QFX date string and returns a [DateTime] object.
///
/// The QFX date string is expected to be in the format "20240103120000.000[-5:EST]",
/// where the first 14 characters represent the date and time, and the remaining
/// characters represent the time zone offset and abbreviation.
///
/// This function will attempt to parse the date and time components and create a
/// [DateTime] object. If the parsing fails for any reason, it will return `null`.
///
/// @param qfxDate The QFX date string to parse.
/// @return The parsed [DateTime] object, or `null` if the parsing fails.
/// Input will look like this ```20240103120000.000[-5:EST]```
///                           ```01234567890123456789012345```
///                           ```0........10--------20_____```
DateTime? parseQfxDataFormat(final String qfxDate) {
  // Extract date components
  try {
    // Extract date and time components
    final int year = int.parse(qfxDate.substring(_qfxYearStart, _qfxYearEnd));
    final int month = int.parse(qfxDate.substring(_qfxMonthStart, _qfxMonthEnd));
    final int day = int.parse(qfxDate.substring(_qfxDayStart, _qfxDayEnd));
    final int hour = int.parse(qfxDate.substring(_qfxHourStart, _qfxHourEnd));
    final int minute = int.parse(qfxDate.substring(_qfxMinuteStart, _qfxMinuteEnd));
    final int second = int.parse(qfxDate.substring(_qfxSecondStart, _qfxSecondEnd));

    // Create DateTime object
    final DateTime dateTime = DateTime(year, month, day, hour, minute, second);

    // Import UTC based
    // dateTime = dateTime.toUtc();

    // // Extract time zone offset and abbreviation
    // final tokens = qfxDate.substring(19).split(':');
    // final int timeZoneOffset = int.parse(tokens[0]);
    //
    // // Adjust DateTime object with time zone offset
    // dateTime = dateTime.add(Duration(hours: timeZoneOffset));
    return dateTime;
  } catch (e) {
    return null;
  }
}

/// Returns elapsed time string between two dates.
String getElapsedTime(DateTime? dateTime, {DateTime? relativeTo}) {
  if (dateTime == null) {
    return '';
  }

  final DateTime now = relativeTo ?? DateTime.now();
  final Duration difference = now.difference(dateTime);

  if (difference.inDays >= _daysPerYear) {
    final int years = difference.inDays ~/ _daysPerYear;
    final int remainingDays = difference.inDays % _daysPerYear;
    final int months = remainingDays ~/ _daysPerMonthApprox;
    final int days = remainingDays % _daysPerMonthApprox;

    if (months == _zeroInt && days == _zeroInt) {
      return '${_formatElapsedUnit(years, SharedStrings.elapsedYear)} ${SharedStrings.elapsedAgo}';
    } else if (days == _zeroInt) {
      return '${_formatElapsedUnit(years, SharedStrings.elapsedYear)}'
          '${SharedStrings.commaSpace}'
          '${_formatElapsedUnit(months, SharedStrings.elapsedMonth)}'
          ' ${SharedStrings.elapsedAgo}';
    } else {
      return '${_formatElapsedUnit(years, SharedStrings.elapsedYear)}'
          '${SharedStrings.commaSpace}'
          '${_formatElapsedUnit(months, SharedStrings.elapsedMonth)}'
          '${SharedStrings.commaSpace}'
          '${_formatElapsedUnit(days, SharedStrings.elapsedDay)}'
          ' ${SharedStrings.elapsedAgo}';
    }
  } else if (difference.inDays >= _daysPerMonthApprox) {
    final int months = difference.inDays ~/ _daysPerMonthApprox;
    final int remainingDays = difference.inDays % _daysPerMonthApprox;
    if (remainingDays == _zeroInt) {
      return '${_formatElapsedUnit(months, SharedStrings.elapsedMonth)} ${SharedStrings.elapsedAgo}';
    } else {
      return '${_formatElapsedUnit(months, SharedStrings.elapsedMonth)}'
          '${SharedStrings.commaSpace}'
          '${_formatElapsedUnit(remainingDays, SharedStrings.elapsedDay)}'
          ' ${SharedStrings.elapsedAgo}';
    }
  } else if (difference.inDays >= _singularCount) {
    return '${_formatElapsedUnit(difference.inDays, SharedStrings.elapsedDay)} ${SharedStrings.elapsedAgo}';
  } else if (difference.inHours >= _singularCount) {
    return '${_formatElapsedUnit(difference.inHours, SharedStrings.elapsedHour)} ${SharedStrings.elapsedAgo}';
  } else if (difference.inMinutes >= _singularCount) {
    return '${_formatElapsedUnit(difference.inMinutes, SharedStrings.elapsedMinute)} ${SharedStrings.elapsedAgo}';
  } else {
    return SharedStrings.elapsedJustNow;
  }
}

String _formatElapsedUnit(final int value, final String unit) {
  return '$value $unit${value > _singularCount ? 's' : SharedStrings.empty}';
}

/// Extension methods for [DateTime] class.
extension DateTimeExtension on DateTime {
  /// Returns start of a day.
  /// DateTime.now() -> 2019-09-30 17:15:20.294
  /// DateTime.now().startOfDay -> 2019-09-30 00:00:00.000
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns DateTime with time component set to start of day.
  DateTime get dropTime => startOfDay;

  /// Returns end of a day.
  /// DateTime.now() -> 2019-09-30 17:15:20.294
  /// DateTime.now().endOfDay -> 2019-09-30 23:59:59.999
  DateTime get endOfDay => DateTime(
    year,
    month,
    day,
    _endOfDayHour,
    _endOfDayMinute,
    _endOfDaySecond,
    _endOfDayMillisecond,
    _endOfDayMicrosecond,
  );
}

/// Compares two DateTime objects ignoring time component.
bool isSameDateWithoutTime(final DateTime? a, final DateTime? b) {
  if (a == null && b == null) {
    return true;
  }
  if (a == null && b != null) {
    return false;
  }
  if (b == null && a != null) {
    return false;
  }
  return a!.year == b!.year && a.month == b.month && a.day == b.day;
}
