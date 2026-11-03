import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/imports/formats/xlsx_import_view.dart';
import 'package:money/views/imports/shared/data_import_view.dart';

void main() {
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
