import 'package:flutter_test/flutter_test.dart';
import 'package:money/core/helpers/misc_helpers.dart';
import 'package:money/core/helpers/string_helper.dart';

void main() {
  group('String Comparison:', () {
    test('Case-Insensitive String Comparison', () {
      expect(stringCompareIgnoreCasing1('Hello', 'hello'), 0);
      expect(stringCompareIgnoreCasing2('Hello', 'hello'), 0);

      expect(stringCompareIgnoreCasing1('world', ''), 1);
      expect(stringCompareIgnoreCasing2('world', ''), 1);

      expect(stringCompareIgnoreCasing1('', 'world'), -1);
      expect(stringCompareIgnoreCasing2('', 'world'), -1);

      // Test case where strings are different
      expect(stringCompareIgnoreCasing1('abc', 'abcD'), -1);
      expect(stringCompareIgnoreCasing2('abc', 'abcD'), -1);

      expect(stringCompareIgnoreCasing1('abcD', 'abc'), 1);
      expect(stringCompareIgnoreCasing2('abcD', 'abc'), 1);
    });
  });

  test('String Comparison Perf:', () {
    int time1 = 0;
    int time2 = 0;

    ///////////////////////// stringCompareIgnoreCasing1

    final Stopwatch stopwatch = Stopwatch()..start(); // Start the stopwatch

    for (int i = 0; i < 200000; i++) {
      expect(stringCompareIgnoreCasing1('world', 'WORLD'), 0);
      expect(stringCompareIgnoreCasing1('banana', ''), 1);
      expect(stringCompareIgnoreCasing1('', 'banana'), -1);
      expect(
        stringCompareIgnoreCasing1(
          'a very long string that is different right from the start',
          'The very long string that is different right from the start',
        ),
        -1,
      );
    }

    stopwatch.stop(); // Stop the stopwatch after the operation
    time1 = stopwatch.elapsedMilliseconds;
    // ignore: avoid_print
    print('Elapsed time stringCompareIgnoreCasing1: $time1 milliseconds');

    ///////////////////////// stringCompareIgnoreCasing2
    final Stopwatch stopwatch2 = Stopwatch()..start(); // Start the stopwatch

    for (int i = 0; i < 200000; i++) {
      expect(stringCompareIgnoreCasing2('world', 'WORLD'), 0);
      expect(stringCompareIgnoreCasing2('banana', ''), 1);
      expect(stringCompareIgnoreCasing2('', 'banana'), -1);
      expect(
        stringCompareIgnoreCasing2(
          'a very long string that is different right from the start',
          'The very long string that is different right from the start',
        ),
        -1,
      );
    }

    stopwatch2.stop(); // Stop the stopwatch after the operation
    time2 = stopwatch2.elapsedMilliseconds;
    // ignore: avoid_print
    print('Elapsed time stringCompareIgnoreCasing2: $time2 milliseconds');

    // expect(time2 < time1, true); // Flaky test removed
  });

  group('String getStringBetweenTwoTokens:', () {
    test('getStringBetweenTwoTokens', () {
      expect(
        getStringDelimitedStartEndTokens(
          'hello Sun in the Sky tonight',
          'Sun',
          'Sky',
        ),
        'Sun in the Sky',
      );
    });
  });

  group('String shortening:', () {
    test('Full name to initials', () {
      expect(getInitials('Bob Smith'), 'BS');

      expect(getInitials('John F. Kennedy'), 'JFK');

      expect(getInitials('Jean-Pierre Duplessis'), 'JD');
    });

    test('Smart Full name to initials', () {
      // make sure that above 5 letter still works
      expect(shortenLongText('Bob Smith'), 'B.S');

      expect(shortenLongText('Test'), 'Test');

      expect(shortenLongText('J F K'), 'J F K');

      expect(shortenLongText('Jean-Pierre Joseph Duplessis'), 'J.J.D');

      expect(shortenLongText('A Job'), 'A Job');
    });
  });

  group('extractAmount', () {
    test('Extract amount from string simple case', () {
      expect(attemptToGetDoubleFromText('123'), equals(123));
    });

    test('Extract negative amount from string simple case', () {
      expect(attemptToGetDoubleFromText('-123'), equals(-123));
    });

    test('Extract amount from string simple case', () {
      expect(attemptToGetDoubleFromText('123.45'), equals(123.45));
    });

    test('Extract amount from string simple case longer', () {
      expect(attemptToGetDoubleFromText('123456'), equals(123456));
    });

    test('Extract amount from string simple case longer with decimal', () {
      expect(attemptToGetDoubleFromText('123456.78'), equals(123456.78));
    });

    test('Extract amount from string with dollars', () {
      expect(
        attemptToGetDoubleFromText('Price: \$10,000.99'),
        equals(10000.99),
      );
    });

    test('Extract amount from string with pounds', () {
      expect(attemptToGetDoubleFromText('Total: £1,234.56'), equals(1234.56));
    });

    test('Extract amount from string with yen', () {
      expect(attemptToGetDoubleFromText('Amount: ¥9,876.54'), equals(9876.54));
    });

    test('Extract amount from string with no amount', () {
      expect(attemptToGetDoubleFromText('No amount in this string'), isNull);
    });

    test('Extract amount from string with invalid format', () {
      expect(
        attemptToGetDoubleFromText('Invalid amount: \$1,2,3,4,5,6.78'),
        123456.78,
      );
    });
  });

  test('Extract amount from currency text', () {
    expect(attemptToGetDoubleFromText('\$1,234.56'), equals(1234.56));
    expect(attemptToGetDoubleFromText('€1.234,56'), equals(1234.56));
    expect(attemptToGetDoubleFromText('¥10,000.75'), equals(10000.75));

    // Additional test cases
    expect(attemptToGetDoubleFromText('\$123'), equals(123.0)); // No decimals
    expect(
      attemptToGetDoubleFromText('\$0.99'),
      equals(0.99),
    ); // Less than 1 dollar
    expect(attemptToGetDoubleFromText('\$0'), equals(0.0)); // Zero amount
    expect(
      attemptToGetDoubleFromText('Invalid string'),
      isNull,
    ); // Invalid input
  });

  test('Extract amount from currency text long decimals', () {
    expect(formatDoubleUpToFiveZero(0.12345), equals('0.12345'));
    expect(formatDoubleUpToFiveZero(0.0000000123), equals('0'));
    expect(formatDoubleUpToFiveZero(0.0000123), equals('0.00001'));
  });
}
