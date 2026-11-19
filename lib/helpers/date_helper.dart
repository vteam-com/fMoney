// ignore: fcheck_dead_code
import 'dart:ui' show PlatformDispatcher;

import 'package:intl/date_time_patterns.dart';
import 'package:intl/intl.dart';
import 'package:money/helpers/shared_strings_helper.dart';

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
const int _endOfDayHour = 23;
const int _endOfDayMinute = 59;
const int _endOfDaySecond = 59;
const int _endOfDayMillisecond = 999;
const int _endOfDayMicrosecond = 999;
const int _yearsPerCentury = 100;
const int _twoDigitYearFutureWindow = 20;
const int _maxTwoDigitYearLength = 2;
const int _fourDigitYearLength = 4;
const int _minDatePartCount = 2;
const int _maxDatePartCount = 3;
const int _lastDatePartIndex = _maxDatePartCount - 1;

/// Pattern letters for the year, month and day in an intl date pattern.
const String _patternYearLetter = 'y';
const String _patternMonthLetter = 'M';
const String _patternDayLetter = 'd';

/// Intl skeleton for a numeric year-month-day date (for example `M/d/y` in en_US).
const String _numericDateSkeleton = 'yMd';

/// Numeric date pattern used when the locale is unknown to intl.
const String _defaultNumericDatePattern = 'M/d/y';

/// Separators accepted between the parts of a numeric date.
final RegExp _datePartSeparators = RegExp(r'[/.\-]');

/// Year, month and day at the start of an ISO 8601 text (`2024-02-31` or `20240231`).
final RegExp _isoDatePrefix = RegExp(r'^[+-]?(\d{4,6})-?(\d{2})-?(\d{2})');
const int _isoYearGroup = 1;
const int _isoMonthGroup = 2;
const int _isoDayGroup = 3;

/// Date patterns for every locale known to intl, keyed by locale name.
final Map<String, Map<String, String>> _datePatternsByLocale = dateTimePatternMap();

/// Order of the day, month and year parts in a numeric date such as `03/04/2024`.
enum DateFieldOrder {
  /// Month first, as in the United States (`03/04/2024` is March 4).
  monthDayYear,

  /// Day first, as in most of Europe (`03/04/2024` is April 3).
  dayMonthYear,

  /// Year first, as in East Asia (`24/03/04` is March 4, 2024).
  yearMonthDay,
}

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
DateTime? attemptToGetDateFromDynamic(dynamic value) {
  if (value is DateTime) {
    return value;
  } else if (value is String) {
    return attemptToGetDateFromText(value);
  }
  return null;
}

/// Parses [text] as ISO 8601 (optionally with a time) or as a numeric date.
///
/// Delegates to [parseDateFlexible] with US month-first order, so `2/3/2000` is
/// February 3, while `27/01/2024` is read day-first because 27 cannot be a month.
/// Returns null for impossible dates (`31/02/2024`) and years outside 1900-2099.
DateTime? attemptToGetDateFromText(String text) {
  final DateTime? parsedDate = parseDateFlexible(text, order: DateFieldOrder.monthDayYear);
  if (parsedDate == null || parsedDate.year < _minValidYear || parsedDate.year > _maxValidYear) {
    return null;
  }
  return parsedDate;
}

/// Returns the numeric date order used by [localeName] (for example `en_US`
/// or `fr`), or by the operating system locale when [localeName] is omitted.
/// Unknown locales fall back to [DateFieldOrder.monthDayYear].
DateFieldOrder dateFieldOrderForLocale([String? localeName]) {
  final String? verifiedLocale = Intl.verifiedLocale(
    localeName ?? PlatformDispatcher.instance.locale.toString(),
    _datePatternsByLocale.containsKey,
    onFailure: (String _) => null,
  );
  final String pattern = _datePatternsByLocale[verifiedLocale]?[_numericDateSkeleton] ?? _defaultNumericDatePattern;
  final int monthIndex = pattern.indexOf(_patternMonthLetter);
  if (pattern.indexOf(_patternYearLetter) < monthIndex) {
    return DateFieldOrder.yearMonthDay;
  }
  if (pattern.indexOf(_patternDayLetter) < monthIndex) {
    return DateFieldOrder.dayMonthYear;
  }
  return DateFieldOrder.monthDayYear;
}

/// Expands a two-digit [year] to the century that keeps it within the window
/// of 79 years before and [_twoDigitYearFutureWindow] years after [now]
/// (default: today). In 2026, `46` becomes 2046 and `47` becomes 1947.
int expandTwoDigitYear(int year, {DateTime? now}) {
  final int currentYear = (now ?? DateTime.now()).year;
  final int windowEnd = currentYear + _twoDigitYearFutureWindow;
  final int expanded = currentYear - currentYear % _yearsPerCentury + year;
  if (expanded > windowEnd) {
    return expanded - _yearsPerCentury;
  }
  if (expanded <= windowEnd - _yearsPerCentury) {
    return expanded + _yearsPerCentury;
  }
  return expanded;
}

/// Parses [text] written as ISO 8601 or as numbers separated by `/`, `-` or `.`.
///
/// Numeric dates follow [order] (default: the operating system locale, see
/// [dateFieldOrderForLocale]), except that a four-digit first part is always the
/// year and a part greater than 12 is always the day. Two-digit years are
/// expanded with [expandTwoDigitYear]. Text with only a day and a month uses
/// [fallbackYear], and is rejected when it is null.
/// Returns null for empty, malformed or impossible dates such as `31/02/2024`.
DateTime? parseDateFlexible(String text, {DateFieldOrder? order, int? fallbackYear}) {
  final String trimmed = text.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final DateTime? isoDate = DateTime.tryParse(trimmed);
  if (isoDate != null) {
    return _isExistingIsoCalendarDate(trimmed) ? isoDate : null;
  }

  final List<String> parts = trimmed.split(_datePartSeparators);
  if (parts.length < _minDatePartCount || parts.length > _maxDatePartCount) {
    return null;
  }
  final List<int?> numbers = parts.map(int.tryParse).toList();
  if (numbers.contains(null)) {
    return null;
  }

  final DateFieldOrder effectiveOrder = order ?? dateFieldOrderForLocale();
  final bool hasYear = parts.length == _maxDatePartCount;
  final bool isYearFirst =
      hasYear &&
      (parts.first.length == _fourDigitYearLength ||
          (effectiveOrder == DateFieldOrder.yearMonthDay && parts.last.length <= _maxTwoDigitYearLength));

  int year;
  int month;
  int day;
  if (isYearFirst) {
    year = numbers[0]!;
    month = numbers[1]!;
    day = numbers[_lastDatePartIndex]!;
  } else {
    final int? yearOrFallback = hasYear ? numbers[_lastDatePartIndex] : fallbackYear;
    if (yearOrFallback == null) {
      return null;
    }
    year = yearOrFallback;
    final int first = numbers[0]!;
    final int second = numbers[1]!;
    final bool isDayFirst =
        first > _maxValidMonth || (second <= _maxValidMonth && effectiveOrder == DateFieldOrder.dayMonthYear);
    day = isDayFirst ? first : second;
    month = isDayFirst ? second : first;
  }

  final String yearText = isYearFirst ? parts.first : (hasYear ? parts.last : '');
  if (hasYear && yearText.length <= _maxTwoDigitYearLength) {
    year = expandTwoDigitYear(year);
  }

  if (month < _minValidMonth || month > _maxValidMonth || day < _minValidDay || day > _maxValidDay) {
    return null;
  }
  final DateTime candidate = DateTime(year, month, day);
  if (candidate.year != year || candidate.month != month || candidate.day != day) {
    return null;
  }
  return candidate;
}

/// Returns false when the calendar date written at the start of ISO [text] does not exist,
/// such as `2024-02-31`, which [DateTime.tryParse] silently rolls over to March 2.
bool _isExistingIsoCalendarDate(String text) {
  final RegExpMatch? match = _isoDatePrefix.firstMatch(text);
  if (match == null) {
    return true;
  }
  final int month = int.parse(match.group(_isoMonthGroup)!);
  final int day = int.parse(match.group(_isoDayGroup)!);
  final DateTime date = DateTime(int.parse(match.group(_isoYearGroup)!), month, day);
  return date.month == month && date.day == day;
}

/// Converts DateTime to ISO 8601 string format with space instead of T.
String dateToDateTimeString(DateTime? dateTime) {
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
  DateTime? value, {
  String defaultValueIfNull = '',
}) {
  if (value == null) {
    return defaultValueIfNull;
  }
  return value.toIso8601String();
}

/// Converts DateTime to SQLite datetime string format.
String? dateToSqliteFormat(DateTime? dateTime) {
  if (dateTime != null) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }
  return null; // stored as NULL, like MyMoney.Net does for a missing date
}

/// Converts DateTime to formatted date string.
String dateToString(DateTime? date) {
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
String dateToYearString(DateTime? dateTime) {
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
DateTime? newestDate(DateTime? a, DateTime? b) {
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
DateTime? oldestDate(DateTime? a, DateTime? b) {
  if (a == null) {
    return b;
  }
  if (b == null) {
    return a;
  }
  return a.isBefore(b) ? a : b;
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

String _formatElapsedUnit(int value, String unit) {
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
bool isSameDateWithoutTime(DateTime? a, DateTime? b) {
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

/// Matches the leading `YYYYMMDD[HHMM[SS]]` digits of an OFX/QFX date.
final RegExp _ofxDatePattern = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:(\d{2})(\d{2})(\d{2})?)?');

/// Parses an OFX/QFX date such as `20240103`, `20240103120000` or
/// `20240103120000.000[-5:EST]`. Fractional seconds and the time zone suffix
/// are ignored. Returns null for malformed or impossible dates.
DateTime? parseOfxDate(String text) {
  final RegExpMatch? match = _ofxDatePattern.firstMatch(text.trim());
  if (match == null) {
    return null;
  }

  /// Reads capture group [index] as an int, defaulting to zero when absent.
  int groupAsInt(int index) => int.tryParse(match.group(index) ?? '') ?? _zeroInt;

  final int year = groupAsInt(_ofxGroupYear);
  final int month = groupAsInt(_ofxGroupMonth);
  final int day = groupAsInt(_ofxGroupDay);
  final DateTime candidate = DateTime(
    year,
    month,
    day,
    groupAsInt(_ofxGroupHour),
    groupAsInt(_ofxGroupMinute),
    groupAsInt(_ofxGroupSecond),
  );
  if (candidate.year != year || candidate.month != month || candidate.day != day) {
    return null;
  }
  return candidate;
}

const int _ofxGroupYear = 1;
const int _ofxGroupMonth = 2;
const int _ofxGroupDay = 3;
const int _ofxGroupHour = 4;
const int _ofxGroupMinute = 5;
const int _ofxGroupSecond = 6;

/// Parses a QIF date such as `01/30/2024`, `1/ 5'24` or `12/31'99`, where an
/// apostrophe may separate the year and spaces may pad the parts.
/// Numeric dates are read month first (see [parseDateFlexible]).
/// Returns null when [text] is not a valid date.
DateTime? parseQifDate(String text) {
  final String normalized = text.replaceAll(' ', '').replaceAll("'", '/');
  return parseDateFlexible(normalized, order: DateFieldOrder.monthDayYear);
}
