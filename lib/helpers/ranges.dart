// ignore: fcheck_one_class_per_file
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/string_helper.dart';

// Exports
export 'package:money/helpers/date_helper.dart';
export 'package:money/helpers/string_helper.dart';

const int _firstMonth = DateTime.january;
const int _firstDayOfMonth = 1;
const int _oneYearOffset = 1;
const int _microsecondPadding = 1;
const int _zeroInt = 0;
const int _minDurationDays = 1;
const int _daysPerMonthApprox = 30;
const int _daysPerYear = 365;
const int _compareLess = -1;
const int _compareGreater = 1;
const int _rangeStep = 1;

/// Represents date range.
class DateRange {
  DateRange({this.min, this.max});

  factory DateRange.fromStarEndYears(final int yearStart, final int yearEnd) => DateRange(
    min: DateTime(yearStart, _firstMonth, _firstDayOfMonth),
    max: DateTime(yearEnd + _oneYearOffset).subtract(const Duration(microseconds: _microsecondPadding)),
  );

  factory DateRange.fromText(
    final String minDateAsText,
    final String maxDateAsText,
  ) => DateRange(
    min: DateTime.parse(minDateAsText),
    max: DateTime.parse(maxDateAsText),
  );

  DateTime? max;
  DateTime? min;

  @override
  bool operator ==(Object other) {
    if (other is! DateRange) {
      return false;
    }

    if (this.max == null && other.max != null) {
      return false;
    }

    if (this.max != null && other.max == null) {
      return false;
    }

    final DateTime otherMin = other.min!;

    if (this.max == null && other.max == null) {
      // Just Min
      return min!.year <= otherMin.year && min!.month <= otherMin.month && min!.day <= otherMin.day;
    }

    // Min and Max
    final DateTime otherMax = other.max!;
    return min!.year <= otherMin.year &&
        max!.year >= otherMax.year &&
        min!.month <= otherMin.month &&
        max!.month >= otherMax.month &&
        min!.day <= otherMin.day &&
        max!.day >= otherMax.day;
  }

  @override
  int get hashCode {
    if (max == null) {
      return min!.hashCode;
    } else {
      return min!.hashCode ^ max!.hashCode;
    }
  }

  @override
  String toString() => '${dateToString(min)} : ${dateToString(max)}';

  /// Clears the date range by setting min and max to null.
  void clear() {
    min = null;
    max = null;
  }

  /// Returns the duration of the date range in days.
  int get durationInDays {
    if (max == null || min == null) {
      return _zeroInt;
    }

    // Calculate the difference between the two dates
    final Duration difference = max!.difference(min!);

    // minimum 1 day
    if (difference.inDays < _minDurationDays) {
      return _minDurationDays;
    }

    // Get the number of days from the difference
    return difference.inDays;
  }

  /// Returns the duration in days as formatted text (singular/plural).
  String get durationInDaysText => getSingularPluralText(
    getIntAsText(durationInDays),
    durationInDays,
    'day',
    'days',
  );

  /// Returns the duration of the date range in months (approximate).
  int get durationInMonths {
    return durationInDays ~/ _daysPerMonthApprox; // Close enough
  }

  /// Returns the duration of the date range in years.
  int get durationInYears {
    if (hasNullDates) {
      return _zeroInt;
    }

    return (_valueOrZeroIfNull(max!.year) - _valueOrZeroIfNull(min!.year)) + _rangeStep;
  }

  /// Returns the duration in years as formatted text (singular/plural).
  String get durationInYearsText => getSingularPluralText(
    getIntAsText(durationInYears),
    durationInYears,
    'year',
    'years',
  );

  /// Ensures both min and max dates are not null, sets to current date if both null.
  void ensureNoNullDates() {
    min ??= max;
    max ??= min;

    if (min == null && max == null) {
      min = max = DateTime.now();
    }
  }

  /// Returns true if either min or max date is null.
  bool get hasNullDates => min == null || max == null;

  /// Expands the date range to include the specified date.
  void inflate(final DateTime? dateTime) {
    if (dateTime != null) {
      min ??= dateTime;
      max ??= dateTime;

      if (dateTime.compareTo(min!) == _compareLess) {
        min = dateTime;
      }

      if (dateTime.compareTo(max!) == _compareGreater) {
        max = dateTime;
      }
    }
  }

  /// Returns true if date is strictly between min and max (exclusive).
  bool isBetween(final DateTime date) => min!.isBefore(date) && max!.isAfter(date);

  /// Returns true if date is between or equal to min and max (inclusive).
  bool isBetweenEqual(final DateTime? date) {
    if (date == null) {
      return false;
    }
    if (min == date || max == date) {
      return true;
    }
    return isBetween(date);
  }

  /// Returns string representation with dates and duration in days.
  String toStringDays() => '${dateToString(min)} ($durationInDaysText) ${dateToString(max)}';

  /// Returns string representation of duration (years or days).
  String toStringDuration() {
    if (durationInDays >= _daysPerYear) {
      return durationInYearsText;
    }
    return durationInDaysText;
  }

  /// Returns string representation with years and duration in years.
  String toStringYears() => '${dateToYearString(min)} ($durationInYearsText) ${dateToYearString(max)}';

  /// Returns [value] or zero if it is null.
  int _valueOrZeroIfNull(final int? value) {
    if (value == null) {
      return _zeroInt;
    }
    return value;
  }
}

/// Helper class to encapsulate a range of integers.
class NumRange {
  NumRange({this.min = _zeroInt, this.max = _zeroInt});

  num max;
  num min;

  @override
  String toString() => descriptionAsInt;

  /// Decrements the range by one, if possible.
  void decrement(int minLimit) {
    if (min - _rangeStep >= minLimit) {
      min--;
      max--;
    }
  }

  /// Returns formatted description as integer currency.
  String get descriptionAsInt => _getDescription(validIntToCurrency(min), validIntToCurrency(max));

  /// Returns formatted description as double currency.
  String get descriptionAsMoney => _getDescription(validDoubleToCurrency(min), validDoubleToCurrency(max));

  /// Increments the range by one, if possible.
  void increment(int maxLimit) {
    if (max + _rangeStep <= maxLimit) {
      min++;
      max++;
    }
  }

  /// Expands the numeric range to include the specified value.
  void inflate(num value) {
    if (value < min) {
      min = value;
    }
    if (value > max) {
      max = value;
    }
  }

  /// Checks if the range is valid.
  bool isValid() => min > _zeroInt && max > _zeroInt && span > _zeroInt;

  /// Returns the span of the range, calculated as the difference between [max] and [min] plus one.
  num get span => max - min + _rangeStep;

  /// Updates the range with new values.
  void update(int newMin, int newMax) {
    min = newMin;
    max = newMax;
  }

  String _getDescription(final String min, final String max) => '$min min, $max max';
}

extension Range on num {
  /// Returns true if number is strictly between from and to (exclusive).
  bool isBetween(final num from, final num to) {
    return from < this && this < to;
  }

  /// Returns true if number is between or equal to from and to (inclusive).
  bool isBetweenOrEqual(final num from, final num to) {
    return from < this && this < to;
  }
}
