import 'dart:math';

const int monthsPerYear = 12;
const int firstDayOfMonth = 1;
const int oneMonthOffset = 1;
const int lastDayOfPreviousMonth = 0;
const int maxDaysInMonth = 31;
const int daysPerYear = 365;
const double averageDaysPerYear = 365.25;
const int currencyRoundingDecimals = 2;
const int zeroInt = 0;

/// Generates list of dates for specified years and frequency.
List<DateTime> generateListOfDates({
  required int yearInThePast,
  DateTime? stopDate,
  required int howManyPerYear,
  required int dayOfTheMonth,
}) {
  final List<DateTime> dates = <DateTime>[];
  final DateTime whenToStop = stopDate ?? DateTime.now();

  for (int i = yearInThePast * howManyPerYear; i >= zeroInt; i--) {
    dates.add(DateTime(whenToStop.year, whenToStop.month - i, dayOfTheMonth));
  }
  return dates;
}

/// Generates random list of dates for specified year and frequency.
List<DateTime> generateListOfDatesRandom({
  required int year,
  required int howManyPerMonths,
}) {
  final List<DateTime> dates = <DateTime>[];
  final DateTime today = DateTime.now();

  for (int i = year * monthsPerYear; i >= zeroInt; i--) {
    DateTime date = DateTime(today.year, today.month - i, firstDayOfMonth);
    for (int event = zeroInt; event < howManyPerMonths; event++) {
      date = DateTime(date.year, date.month, Random().nextInt(maxDaysInMonth) + 1);
      dates.add(date);
    }
  }
  return dates;
}

/// Returns a random signed amount between [minValue] and [maxValue].
double getAmount(int minValue, int maxValue) {
  final int randomValue = minValue + Random().nextInt(maxValue - minValue + 1);
  return randomValue.toDouble();
}

/// Returns a date shifted by [yearsToShift].
DateTime getDateShiftedByYears(int yearsToShift, int month, int day) {
  final DateTime now = DateTime.now();
  return DateTime(now.year + yearsToShift, month, day);
}

/// Returns the last day of the month preceding [date].
DateTime getLastDayOfPreviousMonth(DateTime date) {
  return DateTime(
    date.year,
    date.month - oneMonthOffset,
    lastDayOfPreviousMonth,
  );
}

/// Returns a random negative amount up to [maxValue].
double getRandomAmount(int maxValue) {
  return -Random().nextInt(maxValue + 1).toDouble();
}

/// Returns a year offset from now.
int getShiftedYearFromNow(int numberOfYearFromToday) {
  return DateTime.now().year + numberOfYearFromToday;
}
