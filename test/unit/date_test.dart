import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/date_helper.dart';

void main() {
  test('getDateAndTimeAsText returns empty string for null DateTime', () {
    // Arrange
    const DateTime? dateTime = null;

    // Act
    final String result = dateToDateTimeString(dateTime);

    // Assert
    expect(result, isEmpty);
  });

  test('getDateAndTimeAsText formats non-null DateTime correctly', () {
    // Arrange
    final DateTime dateTime = DateTime(2023, 04, 15, 10, 30, 00);

    // Act
    final String result = dateToDateTimeString(dateTime);

    // Assert
    expect(result, '2023-04-15 10:30:00.000');
  });

  test('attempt to parse date formats', () {
    void expectParsedDate(final DateTime? parsed, final int y, final int m, final int d) {
      expect(parsed, isNotNull);
      expect(parsed!.year, y);
      expect(parsed.month, m);
      expect(parsed.day, d);
    }

    // ISO
    expectParsedDate(attemptToGetDateFromText('2019-12-31'), 2019, 12, 31);

    // USA MM/dd/yyyy
    expectParsedDate(attemptToGetDateFromText('2/27/2024'), 2024, 2, 27);

    // USA MM/dd/yy
    expectParsedDate(attemptToGetDateFromText('2/3/20'), 2020, 2, 3);

    // Europe dd/MM/yyyy
    expectParsedDate(attemptToGetDateFromText('2/3/2000'), 2000, 2, 3);

    // Europe dd/MM/yyyy
    expectParsedDate(DateFormat('dd/MM/yyyy').tryParse('27/01/2024'), 2024, 1, 27);
  });

  group('getPossibleDateFormats', () {
    test('returns an empty list for an empty string', () {
      expect(getPossibleDateFormats(''), isEmpty);
      expect(getPossibleDateFormats('   '), isEmpty);
    });

    test('returns correct formats for 4-digit year dates with dashes', () {
      expect(getPossibleDateFormats('2023-05-15'), <String>[
        'yyyy-MM-dd',
        'yyyy-MM-d',
      ]);
      expect(getPossibleDateFormats('05-15-2023'), <String>[
        'MM-dd-yyyy',
        'MM-d-yyyy',
      ]);
      expect(getPossibleDateFormats('15-05-2023'), <String>[
        'dd-MM-yyyy',
        'd-MM-yyyy',
      ]);
    });

    test('returns correct formats for 4-digit year dates with slashes', () {
      expect(getPossibleDateFormats('2023/05/15'), <String>[
        'yyyy/MM/dd',
        'yyyy/MM/d',
      ]);
      expect(getPossibleDateFormats('05/15/2023'), <String>[
        'MM/dd/yyyy',
        'MM/d/yyyy',
      ]);
      expect(getPossibleDateFormats('15/05/2023'), <String>[
        'dd/MM/yyyy',
        'd/MM/yyyy',
      ]);
    });

    test('returns correct formats for 2-digit year dates with dashes', () {
      expect(getPossibleDateFormats('23-05-15'), <String>[
        'yy-MM-dd',
        'dd-MM-yy',
        'yy-MM-d',
        'd-MM-yy',
      ]);
      expect(getPossibleDateFormats('05-15-23'), <String>[
        'MM-dd-yy',
        'MM-d-yy',
      ]);
      expect(getPossibleDateFormats('15-05-23'), <String>[
        'yy-MM-dd',
        'dd-MM-yy',
        'yy-MM-d',
        'd-MM-yy',
      ]);
    });

    test('returns correct formats for 2-digit year dates with slashes', () {
      expect(getPossibleDateFormats('23/05/15'), <String>[
        'yy/MM/dd',
        'dd/MM/yy',
        'yy/MM/d',
        'd/MM/yy',
      ]);
      expect(getPossibleDateFormats('05/15/23'), <String>[
        'MM/dd/yy',
        'MM/d/yy',
      ]);
      expect(getPossibleDateFormats('15/05/23'), <String>[
        'yy/MM/dd',
        'dd/MM/yy',
        'yy/MM/d',
        'd/MM/yy',
      ]);
    });

    test(
      'returns multiple formats if the date string matches multiple formats',
      () {
        expect(getPossibleDateFormats('05/15/2023'), <String>[
          'MM/dd/yyyy',
          'MM/d/yyyy',
        ]);
        expect(getPossibleDateFormats('15/05/23'), <String>[
          'yy/MM/dd',
          'dd/MM/yy',
          'yy/MM/d',
          'd/MM/yy',
        ]);
      },
    );

    test('returns an empty list for invalid date strings', () {
      expect(getPossibleDateFormats(''), isEmpty);
      expect(getPossibleDateFormats('hello'), isEmpty);
      expect(getPossibleDateFormats('1111/1111/1111'), isEmpty);
    });

    test('Relative dates', () {
      final DateTime dateOld = DateTime(1999, 1, 1, 23, 59, 59);
      final DateTime dateRecent = DateTime(2020, 1, 1);

      expect(oldestDate(dateOld, dateRecent), dateOld);
      expect(newestDate(dateOld, dateRecent), dateRecent);

      expect(isSameDateWithoutTime(dateOld, dateRecent), false);
      expect(isSameDateWithoutTime(dateOld, dateOld), true);

      expect(dateOld.dropTime.hour, 0);
    });

    test('Elsapse time', () {
      {
        final String result = getElapsedTime(
          DateTime.now().subtract(const Duration(seconds: 10)),
        );
        expect(result, 'Just now');
      }

      final DateTime now = DateTime(2000, 1, 1);
      {
        final String result = getElapsedTime(
          relativeTo: now,
          now.subtract(const Duration(seconds: 61)),
        );
        expect(result, '1 minute ago');
      }

      {
        final String result = getElapsedTime(
          relativeTo: now,
          now.subtract(const Duration(minutes: 5)),
        );
        expect(result, '5 minutes ago');
      }

      {
        final String result = getElapsedTime(
          relativeTo: now,
          now.subtract(const Duration(minutes: 59)),
        );
        expect(result, '59 minutes ago');
      }

      {
        final String result = getElapsedTime(
          relativeTo: now,
          now.subtract(const Duration(minutes: 60)),
        );
        expect(result, '1 hour ago');
      }

      {
        final String result = getElapsedTime(
          relativeTo: now,
          now.subtract(const Duration(hours: 23, minutes: 59)),
        );
        expect(result, '23 hours ago');
      }

      {
        final String result = getElapsedTime(
          relativeTo: now,
          now.subtract(const Duration(days: 1)),
        );
        expect(result, '1 day ago');
      }

      {
        final String result = getElapsedTime(
          relativeTo: now,
          now.subtract(const Duration(days: 30)),
        );
        expect(result, '1 month ago');
      }

      {
        final String result = getElapsedTime(
          relativeTo: now,
          now.subtract(const Duration(days: 45)),
        );
        expect(result, '1 month, 15 days ago');
      }

      {
        final String result = getElapsedTime(
          relativeTo: now,
          now.subtract(const Duration(days: 365)),
        );
        expect(result, '1 year ago');
      }

      {
        final String result = getElapsedTime(
          relativeTo: now,
          now.subtract(const Duration(days: 395)),
        );
        expect(result, '1 year, 1 month ago');
      }

      {
        final String result = getElapsedTime(
          relativeTo: now,
          now.subtract(const Duration(days: 400)),
        );
        expect(result, '1 year, 1 month, 5 days ago');
      }
    });
  });
}
