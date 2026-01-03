import 'package:flutter_test/flutter_test.dart';
import 'package:money/import/import_csv.dart';
import 'package:money/import/import_data.dart';

void main() {
  group('loadCSV Tests', () {
    test('Valid CSV data, standard column order', () {
      final List<String> headers = <String>['Date', 'Description', 'Amount'];
      final List<List<String>> dataRows = <List<String>>[
        <String>['2023-01-15', 'Groceries', '50.25'],
        <String>['2023-01-16', 'Gas', '30.00'],
      ];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Date',
        'description': 'Description',
        'amount': 'Amount',
      };

      final ImportData result = loadCSV(headers, dataRows, columnMapping);

      expect(result.entries.length, 2);
      expect(result.fileType, 'CSV');

      expect(result.entries[0].date, DateTime(2023, 1, 15));
      expect(result.entries[0].name, 'Groceries');
      expect(result.entries[0].amount, 50.25);

      expect(result.entries[1].date, DateTime(2023, 1, 16));
      expect(result.entries[1].name, 'Gas');
      expect(result.entries[1].amount, 30.00);
    });

    test('Valid CSV data, different column order', () {
      final List<String> headers = <String>['Amount', 'Date', 'Description'];
      final List<List<String>> dataRows = <List<String>>[
        <String>['50.25', '2023-01-15', 'Groceries'],
        <String>['30.00', '2023-01-16', 'Gas'],
      ];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Date',
        'description': 'Description',
        'amount': 'Amount',
      };

      final ImportData result = loadCSV(headers, dataRows, columnMapping);

      expect(result.entries.length, 2);
      expect(result.entries[0].date, DateTime(2023, 1, 15));
      expect(result.entries[0].name, 'Groceries');
      expect(result.entries[0].amount, 50.25);
    });

    test('CSV data with extra spaces in cells', () {
      final List<String> headers = <String>['Date', 'Description', 'Amount'];
      final List<List<String>> dataRows = <List<String>>[
        <String>[' 2023-01-15 ', ' Groceries ', ' 50.25 '],
      ];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Date',
        'description': 'Description',
        'amount': 'Amount',
      };

      final ImportData result = loadCSV(headers, dataRows, columnMapping);

      expect(result.entries.length, 1);
      expect(result.entries[0].date, DateTime(2023, 1, 15));
      expect(result.entries[0].name, 'Groceries');
      expect(result.entries[0].amount, 50.25);
    });

    test('CSV data with invalid date format', () {
      final List<String> headers = <String>['Date', 'Description', 'Amount'];
      final List<List<String>> dataRows = <List<String>>[
        <String>['15/01/2023', 'Invalid Date', '10.00'], // DateTime.parse will fail
        <String>['2023-01-16', 'Valid Entry', '20.00'],
      ];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Date',
        'description': 'Description',
        'amount': 'Amount',
      };

      final ImportData result = loadCSV(headers, dataRows, columnMapping);
      // Expects DateTime.parse to throw, so the line is skipped.
      // Note: Current implementation prints to console, test output won't show that.
      expect(result.entries.length, 1);
      expect(result.entries[0].name, 'Valid Entry');
    });

    test('CSV data with non-numeric amount', () {
      final List<String> headers = <String>['Date', 'Description', 'Amount'];
      final List<List<String>> dataRows = <List<String>>[
        <String>['2023-01-15', 'Non-numeric', 'ABC'],
        <String>['2023-01-16', 'Valid Entry', '20.00'],
      ];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Date',
        'description': 'Description',
        'amount': 'Amount',
      };
      final ImportData result = loadCSV(headers, dataRows, columnMapping);
      expect(result.entries.length, 1);
      expect(result.entries[0].name, 'Valid Entry');
    });

    test('CSV data with missing columns in a row', () {
      final List<String> headers = <String>['Date', 'Description', 'Amount', 'Extra'];
      final List<List<String>> dataRows = <List<String>>[
        <String>['2023-01-15', 'Valid Full', '10.00', 'SomeExtra'],
        <String>['2023-01-16', 'Missing Extra Column'], // Amount is effectively missing if mapped to 'Amount'
        <String>['2023-01-17', 'Valid Again', '30.00', 'MoreExtra'],
      ];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Date',
        'description': 'Description',
        'amount': 'Amount', // Mapped to 'Amount' which is index 2
      };
      final ImportData result = loadCSV(headers, dataRows, columnMapping);
      // The second row will be skipped because row.length (2) <= amountIndex (2)
      expect(result.entries.length, 2);
      expect(result.entries[0].name, 'Valid Full');
      expect(result.entries[1].name, 'Valid Again');
    });

    test('Empty dataRows input', () {
      final List<String> headers = <String>['Date', 'Description', 'Amount'];
      final List<List<String>> dataRows = <List<String>>[];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Date',
        'description': 'Description',
        'amount': 'Amount',
      };
      final ImportData result = loadCSV(headers, dataRows, columnMapping);
      expect(result.entries.isEmpty, true);
    });

    test('Mapped column name not found in headers', () {
      final List<String> headers = <String>['Fecha', 'Concepto', 'Valor']; // Different header names
      final List<List<String>> dataRows = <List<String>>[
        <String>['2023-01-15', 'Groceries', '50.25'],
      ];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Date', // This name is not in `headers`
        'description': 'Description', // This name is not in `headers`
        'amount': 'Amount', // This name is not in `headers`
      };
      final ImportData result = loadCSV(headers, dataRows, columnMapping);
      // loadCSV currently returns an empty ImportData if headers don't match.
      expect(result.entries.isEmpty, true);
    });

    test('Valid CSV data with ISO 8601 DateTime format (YYYY-MM-DDTHH:mm:ss)', () {
      final List<String> headers = <String>['Timestamp', 'Event', 'Value'];
      final List<List<String>> dataRows = <List<String>>[
        <String>['2023-01-15T10:30:00', 'Meeting', '100.00'],
      ];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Timestamp',
        'description': 'Event',
        'amount': 'Value',
      };

      final ImportData result = loadCSV(headers, dataRows, columnMapping);

      expect(result.entries.length, 1);
      expect(result.entries[0].date, DateTime(2023, 1, 15, 10, 30, 0));
      expect(result.entries[0].name, 'Meeting');
      expect(result.entries[0].amount, 100.00);
    });

    test('CSV data with empty description cell', () {
      final List<String> headers = <String>['Date', 'Description', 'Amount'];
      final List<List<String>> dataRows = <List<String>>[
        <String>['2023-01-15', '', '50.25'], // Empty description
        <String>['2023-01-16', 'Valid Description', '30.00'],
      ];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Date',
        'description': 'Description',
        'amount': 'Amount',
      };

      final ImportData result = loadCSV(headers, dataRows, columnMapping);
      // The line with empty description is skipped
      expect(result.entries.length, 1);
      expect(result.entries[0].name, 'Valid Description');
    });
  });
}
