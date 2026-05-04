import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/imports/formats/investment_csv_import_view.dart';
import 'package:money/views/imports/shared/data_import_view.dart';

// Shared header fixtures used across multiple tests.
const List<String> _fullHeaders = <String>[
  'Run Date',
  'Account',
  'Account Number',
  'Action',
  'Symbol',
  'Description',
  'Quantity',
  'Price',
  'Amount',
  'Commission',
];

const List<String> _minimalHeaders = <String>[
  'Run Date',
  'Account',
  'Account Number',
  'Description',
  'Amount',
];

void main() {
  // ---------------------------------------------------------------------------
  // isInvestmentCSV
  // ---------------------------------------------------------------------------
  group('isInvestmentCSV', () {
    test('returns true for full Fidelity-style header set', () {
      expect(isInvestmentCSV(_fullHeaders), isTrue);
    });

    test('returns true for minimal required headers only', () {
      expect(isInvestmentCSV(<String>['Run Date', 'Account Number', 'Amount']), isTrue);
    });

    test('returns false when Run Date is missing', () {
      expect(isInvestmentCSV(<String>['Account Number', 'Amount', 'Description']), isFalse);
    });

    test('returns false when Account Number is missing', () {
      expect(isInvestmentCSV(<String>['Run Date', 'Amount', 'Description']), isFalse);
    });

    test('returns false when Amount is missing', () {
      expect(isInvestmentCSV(<String>['Run Date', 'Account Number', 'Description']), isFalse);
    });

    test('returns false for generic bank CSV headers', () {
      expect(isInvestmentCSV(<String>['Date', 'Description', 'Amount']), isFalse);
    });

    test('returns false for empty header list', () {
      expect(isInvestmentCSV(<String>[]), isFalse);
    });

    test('handles headers with surrounding whitespace', () {
      expect(
        isInvestmentCSV(<String>[' Run Date ', ' Account Number ', ' Amount ']),
        isTrue,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // loadInvestmentCSV
  // ---------------------------------------------------------------------------
  group('loadInvestmentCSV', () {
    test('parses a single valid row with ISO date', () {
      final ImportData result = loadInvestmentCSV(
        _minimalHeaders,
        <List<String>>[
          <String>['2024-01-15', 'Brokerage', '12345678', 'Dividend payment', '100.00'],
        ],
      );

      expect(result.entries.length, 1);
      final ImportEntry e = result.entries[0];
      expect(e.date, DateTime(2024, 1, 15));
      expect(e.name, 'Dividend payment');
      expect(e.amount, 100.00);
      expect(result.fileType, 'CSV');
      expect(result.diagnostics.processedRows, 1);
      expect(result.diagnostics.skippedRows, 0);
    });

    test('parses date in US broker format MM/DD/YYYY', () {
      final ImportData result = loadInvestmentCSV(
        _minimalHeaders,
        <List<String>>[
          <String>['01/15/2024', 'Brokerage', '12345678', 'Dividend', '50.00'],
        ],
      );

      expect(result.entries.length, 1);
      expect(result.entries[0].date, DateTime(2024, 1, 15));
    });

    test('parses amount with dollar sign and commas', () {
      final ImportData result = loadInvestmentCSV(
        _minimalHeaders,
        <List<String>>[
          <String>['2024-03-01', 'Brokerage', '12345678', 'Buy AAPL', r'$1,250.75'],
        ],
      );

      expect(result.entries.length, 1);
      expect(result.entries[0].amount, 1250.75);
    });

    test('parses negative amount in parentheses notation', () {
      final ImportData result = loadInvestmentCSV(
        _minimalHeaders,
        <List<String>>[
          <String>['2024-03-01', 'Brokerage', '12345678', 'Fee', r'($9.95)'],
        ],
      );

      expect(result.entries.length, 1);
      expect(result.entries[0].amount, -9.95);
    });

    test('parses all optional investment fields', () {
      final ImportData result = loadInvestmentCSV(
        _fullHeaders,
        <List<String>>[
          <String>['2024-06-01', 'Acct', '99999', 'BUY', 'AAPL', 'Apple Inc.', '10', '185.50', '1855.00', '0.00'],
        ],
      );

      expect(result.entries.length, 1);
      final ImportEntry e = result.entries[0];
      expect(e.stockAction, 'BUY');
      expect(e.stockSymbol, 'AAPL');
      expect(e.stockQuantity, 10.0);
      expect(e.stockPrice, 185.50);
      expect(e.stockCommission, 0.0);
    });

    test('parses stock commission correctly', () {
      final ImportData result = loadInvestmentCSV(
        _fullHeaders,
        <List<String>>[
          <String>['2024-06-01', 'Acct', '99999', 'BUY', 'TSLA', 'Tesla Inc.', '5', '250.00', '1250.00', '4.95'],
        ],
      );

      expect(result.entries[0].stockCommission, 4.95);
    });

    test('parses multiple rows and updates diagnostics', () {
      final ImportData result = loadInvestmentCSV(
        _minimalHeaders,
        <List<String>>[
          <String>['2024-01-01', 'Acct', '111', 'Dividend', '10.00'],
          <String>['2024-01-02', 'Acct', '111', 'Interest', '5.00'],
        ],
      );

      expect(result.entries.length, 2);
      expect(result.diagnostics.processedRows, 2);
      expect(result.diagnostics.skippedRows, 0);
    });

    test('skips row with invalid date and records skip reason', () {
      final ImportData result = loadInvestmentCSV(
        _minimalHeaders,
        <List<String>>[
          <String>['not-a-date', 'Acct', '111', 'Trade', '100.00'],
        ],
      );

      expect(result.entries.isEmpty, isTrue);
      expect(result.diagnostics.skippedRows, 1);
      expect(result.diagnostics.skippedByReason['invalidDate'], 1);
    });

    test('skips row with empty description', () {
      final ImportData result = loadInvestmentCSV(
        _minimalHeaders,
        <List<String>>[
          <String>['2024-01-01', 'Acct', '111', '', '100.00'],
        ],
      );

      expect(result.entries.isEmpty, isTrue);
      expect(result.diagnostics.skippedByReason['emptyDescription'], 1);
    });

    test('skips row with invalid amount', () {
      final ImportData result = loadInvestmentCSV(
        _minimalHeaders,
        <List<String>>[
          <String>['2024-01-01', 'Acct', '111', 'Trade', 'N/A'],
        ],
      );

      expect(result.entries.isEmpty, isTrue);
      expect(result.diagnostics.skippedByReason['invalidAmount'], 1);
    });

    test('skips row with too few columns', () {
      final ImportData result = loadInvestmentCSV(
        _minimalHeaders,
        <List<String>>[
          <String>['2024-01-01', 'Acct'], // only 2 of 5 required columns
        ],
      );

      expect(result.entries.isEmpty, isTrue);
      expect(result.diagnostics.skippedRows, 1);
    });

    test('returns empty ImportData when Description column is missing from headers', () {
      final ImportData result = loadInvestmentCSV(
        <String>['Run Date', 'Account', 'Account Number', 'Amount'],
        <List<String>>[
          <String>['2024-01-01', 'Acct', '111', '100.00'],
        ],
      );

      expect(result.entries.isEmpty, isTrue);
    });

    test('returns empty ImportData for empty data rows', () {
      final ImportData result = loadInvestmentCSV(_minimalHeaders, <List<String>>[]);

      expect(result.entries.isEmpty, isTrue);
      expect(result.diagnostics.processedRows, 0);
    });

    test('mixed valid and invalid rows keeps only valid ones', () {
      final ImportData result = loadInvestmentCSV(
        _minimalHeaders,
        <List<String>>[
          <String>['2024-01-01', 'Acct', '111', 'Dividend', '10.00'], // valid
          <String>['bad-date', 'Acct', '111', 'Trade', '100.00'], // invalid date
          <String>['2024-01-03', 'Acct', '111', 'Interest', '5.00'], // valid
          <String>['2024-01-04', 'Acct', '111', '', '5.00'], // empty description
        ],
      );

      expect(result.entries.length, 2);
      expect(result.diagnostics.processedRows, 4);
      expect(result.diagnostics.skippedRows, 2);
    });

    test('fitid is unique per row', () {
      final ImportData result = loadInvestmentCSV(
        _minimalHeaders,
        <List<String>>[
          <String>['2024-01-01', 'Acct', '111', 'Div', '10.00'],
          <String>['2024-01-02', 'Acct', '111', 'Int', '5.00'],
        ],
      );

      expect(result.entries[0].fitid, isNot(equals(result.entries[1].fitid)));
    });

    test('entry type is set to investment_csv', () {
      final ImportData result = loadInvestmentCSV(
        _minimalHeaders,
        <List<String>>[
          <String>['2024-01-01', 'Acct', '111', 'Div', '10.00'],
        ],
      );

      expect(result.entries[0].type, 'investment_csv');
    });
  });
}
