import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/imports/formats/csv_import_view.dart';
import 'package:money/views/imports/shared/data_import_view.dart';

void main() {
  group('loadCSV Tests', () {
    test('parseCsvContent handles quoted commas correctly', () {
      const String csvContent = 'Date,Description,Amount\n2023-01-15,"Groceries, market",50.25';

      final CsvRowsData parsed = parseCsvContent(csvContent);
      final ImportData result = loadCSV(
        parsed.headers,
        parsed.dataRows,
        <String, String>{
          'date': 'Date',
          'description': 'Description',
          'amount': 'Amount',
        },
      );

      expect(result.entries.length, 1);
      expect(result.entries[0].name, 'Groceries, market');
      expect(result.entries[0].amount, 50.25);
      expect(result.diagnostics.processedRows, 1);
      expect(result.diagnostics.skippedRows, 0);
    });

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
      expect(result.diagnostics.processedRows, 2);
      expect(result.diagnostics.skippedRows, 1);
      expect(result.diagnostics.skippedByReason['invalidDate'], 1);
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
      expect(result.diagnostics.processedRows, 2);
      expect(result.diagnostics.skippedRows, 1);
      expect(result.diagnostics.skippedByReason['invalidAmount'], 1);
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
      expect(result.diagnostics.processedRows, 3);
      expect(result.diagnostics.skippedRows, 1);
      expect(result.diagnostics.skippedByReason['insufficientColumns'], 1);
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

    test('CSV uses Action value when description is No Description', () {
      final List<String> headers = <String>['Date', 'Action', 'Description', 'Amount'];
      final List<List<String>> dataRows = <List<String>>[
        <String>['2023-06-13', 'Account Owner', 'No Description', '-150.00'],
      ];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Date',
        'description': 'Description',
        'amount': 'Amount',
      };

      final ImportData result = loadCSV(headers, dataRows, columnMapping);

      expect(result.entries.length, 1);
      expect(result.entries[0].name, 'Account Owner');
      expect(result.entries[0].memo, 'Account Owner');
      expect(result.entries[0].amount, -150.00);
    });

    test('CSV uses Action value when description placeholder has irregular spacing', () {
      final List<String> headers = <String>['Date', 'Action', 'Description', 'Amount'];
      final List<List<String>> dataRows = <List<String>>[
        <String>[
          '2025-01-28',
          'DEBIT CARD PURCHASE STREAMING SUBSCRIPTION',
          ' No   Description ',
          '-17.09',
        ],
      ];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Date',
        'description': 'Description',
        'amount': 'Amount',
      };

      final ImportData result = loadCSV(headers, dataRows, columnMapping);

      expect(result.entries.length, 1);
      expect(result.entries[0].name, 'DEBIT CARD PURCHASE STREAMING SUBSCRIPTION');
      expect(result.entries[0].memo, 'DEBIT CARD PURCHASE STREAMING SUBSCRIPTION');
      expect(result.entries[0].amount, -17.09);
    });

    test('CSV combines Action and Description when both are informative', () {
      final List<String> headers = <String>['Date', 'Action', 'Description', 'Amount'];
      final List<List<String>> dataRows = <List<String>>[
        <String>['2025-01-29', 'CARD PURCHASE', 'Coffee Shop', '-5.00'],
      ];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Date',
        'description': 'Description',
        'amount': 'Amount',
      };

      final ImportData result = loadCSV(headers, dataRows, columnMapping);

      expect(result.entries.length, 1);
      expect(result.entries[0].name, 'CARD PURCHASE | Coffee Shop');
      expect(result.entries[0].memo, 'CARD PURCHASE');
      expect(result.entries[0].amount, -5.00);
    });

    test('CSV uses Action value with Fidelity-style schema and No Description placeholder', () {
      final List<String> headers = <String>[
        'Run Date',
        'Account',
        'Account Number',
        'Action',
        'Symbol',
        'Description',
        'Type',
        'Exchange Quantity',
        'Exchange Currency',
        'Currency',
        'Price',
        'Quantity',
        'Exchange Rate',
        'Commission',
        'Fees',
        'Accrued Interest',
        'Amount',
        'Settlement Date',
      ];
      final List<List<String>> dataRows = <List<String>>[
        <String>[
          '2025-01-28',
          'Sample Account',
          'X0000000',
          'DEBIT CARD PURCHASE POS0010 STREAMING SERVICE (Cash)',
          '',
          'No Description',
          'Cash',
          '0',
          '',
          'USD',
          '',
          '0.000',
          '0',
          '',
          '',
          '',
          '-17.09',
          '',
        ],
      ];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Run Date',
        'description': 'Description',
        'amount': 'Amount',
      };

      final ImportData result = loadCSV(headers, dataRows, columnMapping);

      expect(result.entries.length, 1);
      expect(result.entries[0].name, 'DEBIT CARD PURCHASE POS0010 STREAMING SERVICE (Cash)');
      expect(result.entries[0].memo, 'DEBIT CARD PURCHASE POS0010 STREAMING SERVICE (Cash)');
      expect(result.entries[0].amount, -17.09);
    });

    test('CSV infers Action from nearby column when placeholder description has no Action header', () {
      final List<String> headers = <String>[
        'Run Date',
        'Account',
        'Account Number',
        'Details',
        'Symbol',
        'Description',
        'Amount',
      ];
      final List<List<String>> dataRows = <List<String>>[
        <String>[
          '2025-01-28',
          'Sample Account',
          'X0000000',
          'DEBIT CARD PURCHASE POS0010 STREAMING SERVICE (Cash)',
          '',
          'No Description',
          '-17.09',
        ],
      ];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Run Date',
        'description': 'Description',
        'amount': 'Amount',
      };

      final ImportData result = loadCSV(headers, dataRows, columnMapping);

      expect(result.entries.length, 1);
      expect(result.entries[0].name, 'DEBIT CARD PURCHASE POS0010 STREAMING SERVICE (Cash)');
      expect(result.entries[0].memo, 'DEBIT CARD PURCHASE POS0010 STREAMING SERVICE (Cash)');
      expect(result.entries[0].amount, -17.09);
    });

    test('CSV with stock Quantity and Price columns (sell example)', () {
      final List<String> headers = <String>['Date', 'Symbol', 'Description', 'Quantity', 'Price', 'Amount'];
      final List<List<String>> dataRows = <List<String>>[
        <String>['2023-06-14', 'FUND', 'Energy Trust Fund', '-1000', '0.61', '610'],
      ];
      final Map<String, String> columnMapping = <String, String>{
        'date': 'Date',
        'description': 'Description',
        'amount': 'Amount',
        'quantity': 'Quantity',
        'price': 'Price',
      };

      final ImportData result = loadCSV(headers, dataRows, columnMapping);

      expect(result.entries.length, 1);
      expect(result.entries[0].date, DateTime(2023, 6, 14));
      expect(result.entries[0].name, 'Energy Trust Fund');
      expect(result.entries[0].stockQuantity, -1000.0);
      expect(result.entries[0].stockPrice, 0.61);
      expect(result.entries[0].amount, 610.0);
    });

    test('parseCsvContent with stock data from raw CSV text', () {
      const String csvContent = '''Date,Symbol,Description,Quantity,Price,Amount
2023-06-14,FUND,Energy Trust Fund,-1000,0.61,610
2023-07-06,INDX,Index Trust Fund,-2000,0.48,956.2''';

      final CsvRowsData parsed = parseCsvContent(csvContent);
      final ImportData result = loadCSV(
        parsed.headers,
        parsed.dataRows,
        <String, String>{
          'date': 'Date',
          'description': 'Description',
          'amount': 'Amount',
          'quantity': 'Quantity',
          'price': 'Price',
        },
      );

      expect(result.entries.length, 2);
      expect(result.entries[0].date, DateTime(2023, 6, 14));
      expect(result.entries[0].name, 'Energy Trust Fund');
      expect(result.entries[0].stockQuantity, -1000.0);
      expect(result.entries[0].stockPrice, 0.61);

      expect(result.entries[1].date, DateTime(2023, 7, 6));
      expect(result.entries[1].name, 'Index Trust Fund');
      expect(result.entries[1].stockQuantity, -2000.0);
      expect(result.entries[1].stockPrice, 0.48);
    });
  });
}
