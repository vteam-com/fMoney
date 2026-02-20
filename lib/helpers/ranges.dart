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

  void clear() {
    min = null;
    max = null;
  }

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

  String get durationInDaysText => getSingularPluralText(
    getIntAsText(durationInDays),
    durationInDays,
    'day',
    'days',
  );

  int get durationInMonths {
    return durationInDays ~/ _daysPerMonthApprox; // Close enough
  }

  int get durationInYears {
    if (hasNullDates) {
      return _zeroInt;
    }

    return (_valueOrZeroIfNull(max!.year) - _valueOrZeroIfNull(min!.year)) + _rangeStep;
  }

  String get durationInYearsText => getSingularPluralText(
    getIntAsText(durationInYears),
    durationInYears,
    'year',
    'years',
  );

  void ensureNoNullDates() {
    min ??= max;
    max ??= min;

    if (min == null && max == null) {
      min = max = DateTime.now();
    }
  }

  bool get hasNullDates => min == null || max == null;

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

  bool isBetween(final DateTime date) => min!.isBefore(date) && max!.isAfter(date);

  bool isBetweenEqual(final DateTime? date) {
    if (date == null) {
      return false;
    }
    if (min == date || max == date) {
      return true;
    }
    return isBetween(date);
  }

  String toStringDays() => '${dateToString(min)} ($durationInDaysText) ${dateToString(max)}';

  String toStringDuration() {
    if (durationInDays >= _daysPerYear) {
      return durationInYearsText;
    }
    return durationInDaysText;
  }

  String toStringYears() => '${dateToYearString(min)} ($durationInYearsText) ${dateToYearString(max)}';

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

  String get descriptionAsInt => _getDescription(validIntToCurrency(min), validIntToCurrency(max));

  String get descriptionAsMoney => _getDescription(validDoubleToCurrency(min), validDoubleToCurrency(max));

  /// Increments the range by one, if possible.
  void increment(int maxLimit) {
    if (max + _rangeStep <= maxLimit) {
      min++;
      max++;
    }
  }

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
  bool isBetween(final num from, final num to) {
    return from < this && this < to;
  }

  bool isBetweenOrEqual(final num from, final num to) {
    return from < this && this < to;
  }
}
