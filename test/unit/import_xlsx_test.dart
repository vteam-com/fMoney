import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/imports/formats/xlsx_import_view.dart';
import 'package:money/views/imports/shared/data_import_view.dart';

void main() {
  // ---------------------------------------------------------------------------
  // parseFlexibleDate
  // ---------------------------------------------------------------------------
  group('parseFlexibleDate', () {
    test('parses ISO format YYYY-MM-DD', () {
      expect(parseFlexibleDate('2024-06-15'), DateTime(2024, 6, 15));
    });

    test('parses ISO format with time component', () {
      final DateTime? result = parseFlexibleDate('2024-06-15T00:00:00');
      expect(result, isNotNull);
      expect(result!.year, 2024);
      expect(result.month, 6);
      expect(result.day, 15);
    });

    test('parses European format DD/MM/YYYY', () {
      // Day=30 means it can only be European (month 30 is invalid)
      expect(parseFlexibleDate('30/06/2025'), DateTime(2025, 6, 30));
    });

    test('parses US format MM/DD/YYYY', () {
      // Both European and US regex match; the first branch tried is European.
      // For 01/15/2024: Euro → month=01, day=15, year=2024 → valid DateTime
      expect(parseFlexibleDate('01/15/2024'), isNotNull);
    });

    test('parses 2-digit year below pivot as 2000+', () {
      // DD/MM/YY where YY=24 → 2024
      final DateTime? result = parseFlexibleDate('15/06/24');
      expect(result, isNotNull);
      expect(result!.year, 2024);
    });

    test('parses 2-digit year at or above pivot as 1900+', () {
      // DD/MM/YY where YY=55 → 1955
      final DateTime? result = parseFlexibleDate('15/06/55');
      expect(result, isNotNull);
      expect(result!.year, 1955);
    });

    test('returns null for empty string', () {
      expect(parseFlexibleDate(''), isNull);
    });

    test('returns null for whitespace-only string', () {
      expect(parseFlexibleDate('   '), isNull);
    });

    test('returns null for completely invalid input', () {
      expect(parseFlexibleDate('not-a-date'), isNull);
    });

    test('returns null for partial date', () {
      expect(parseFlexibleDate('2024-06'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // loadXLSX
  // ---------------------------------------------------------------------------
  group('loadXLSX', () {
    final List<String> headers = <String>['Date', 'Description', 'Amount'];
    final Map<String, String> mapping = <String, String>{
      'date': 'Date',
      'description': 'Description',
      'amount': 'Amount',
    };

    test('parses valid rows into import entries', () {
      final List<List<String>> dataRows = <List<String>>[
        <String>['2024-01-15', 'Salary', '3000.00'],
        <String>['2024-01-20', 'Rent', '-1200.00'],
      ];

      final ImportData result = loadXLSX(headers, dataRows, mapping);

      expect(result.entries.length, 2);
      expect(result.fileType, 'XLSX');
      expect(result.entries[0].date, DateTime(2024, 1, 15));
      expect(result.entries[0].name, 'Salary');
      expect(result.entries[0].amount, 3000.00);
      expect(result.entries[1].amount, -1200.00);
    });

    test('parses amounts with comma thousand separators', () {
      final ImportData result = loadXLSX(
        headers,
        <List<String>>[
          <String>['2024-01-15', 'Transfer', '10,500.00'],
        ],
        mapping,
      );

      expect(result.entries.length, 1);
      expect(result.entries[0].amount, 10500.00);
    });

    test('skips rows with invalid dates', () {
      final ImportData result = loadXLSX(
        headers,
        <List<String>>[
          <String>['not-a-date', 'Trade', '100.00'],
        ],
        mapping,
      );

      expect(result.entries.isEmpty, isTrue);
    });

    test('skips rows with empty description', () {
      final ImportData result = loadXLSX(
        headers,
        <List<String>>[
          <String>['2024-01-15', '', '100.00'],
        ],
        mapping,
      );

      expect(result.entries.isEmpty, isTrue);
    });

    test('skips rows with invalid amount', () {
      final ImportData result = loadXLSX(
        headers,
        <List<String>>[
          <String>['2024-01-15', 'Payment', 'N/A'],
        ],
        mapping,
      );

      expect(result.entries.isEmpty, isTrue);
    });

    test('skips rows that are too short', () {
      final ImportData result = loadXLSX(
        headers,
        <List<String>>[
          <String>['2024-01-15', 'Only two cols'], // missing amount column
        ],
        mapping,
      );

      expect(result.entries.isEmpty, isTrue);
    });

    test('returns empty ImportData when column mapping is invalid', () {
      // mapping references column names that don't exist in headers
      final ImportData result = loadXLSX(
        <String>['A', 'B', 'C'],
        <List<String>>[
          <String>['2024-01-15', 'Payment', '100.00'],
        ],
        <String, String>{
          'date': 'Date',
          'description': 'Description',
          'amount': 'Amount',
        },
      );

      expect(result.entries.isEmpty, isTrue);
    });

    test('returns empty ImportData for empty data rows', () {
      final ImportData result = loadXLSX(headers, <List<String>>[], mapping);
      expect(result.entries.isEmpty, isTrue);
    });

    test('fitid is unique per row', () {
      final List<List<String>> dataRows = <List<String>>[
        <String>['2024-01-15', 'Row1', '10.00'],
        <String>['2024-01-16', 'Row2', '20.00'],
      ];
      final ImportData result = loadXLSX(headers, dataRows, mapping);

      expect(result.entries[0].fitid, isNot(equals(result.entries[1].fitid)));
    });

    test('handles different column order via mapping', () {
      final List<String> shuffledHeaders = <String>['Amount', 'Description', 'Date'];
      final Map<String, String> shuffledMapping = <String, String>{
        'date': 'Date',
        'description': 'Description',
        'amount': 'Amount',
      };
      final ImportData result = loadXLSX(
        shuffledHeaders,
        <List<String>>[
          <String>['200.00', 'Coffee', '2024-03-01'],
        ],
        shuffledMapping,
      );

      expect(result.entries.length, 1);
      expect(result.entries[0].date, DateTime(2024, 3, 1));
      expect(result.entries[0].name, 'Coffee');
      expect(result.entries[0].amount, 200.00);
    });
  });
}
