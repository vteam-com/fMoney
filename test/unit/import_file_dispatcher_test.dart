import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/imports/import_file_dispatcher.dart';

void main() {
  // ---------------------------------------------------------------------------
  // pickFirstPdfPath
  // ---------------------------------------------------------------------------
  group('pickFirstPdfPath', () {
    test('returns first PDF path found', () {
      final List<String> paths = <String>[
        '/files/doc.pdf',
        '/files/statement.qfx',
        '/files/other.csv',
      ];
      expect(pickFirstPdfPath(paths), '/files/doc.pdf');
    });

    test('returns null when no PDF is present', () {
      final List<String> paths = <String>[
        '/files/statement.qfx',
        '/files/transactions.csv',
        '/files/data.xlsx',
      ];
      expect(pickFirstPdfPath(paths), isNull);
    });

    test('returns null for empty list', () {
      expect(pickFirstPdfPath(<String>[]), isNull);
    });

    test('extension check is case-insensitive', () {
      expect(pickFirstPdfPath(<String>['/files/REPORT.PDF']), '/files/REPORT.PDF');
      expect(pickFirstPdfPath(<String>['/files/Report.Pdf']), '/files/Report.Pdf');
    });

    test('returns only the first PDF when multiple PDFs exist', () {
      final List<String> paths = <String>['/a/first.pdf', '/b/second.pdf'];
      expect(pickFirstPdfPath(paths), '/a/first.pdf');
    });

    test('returns PDF when it is not the first item in list', () {
      final List<String> paths = <String>['/a/data.csv', '/b/report.pdf'];
      expect(pickFirstPdfPath(paths), '/b/report.pdf');
    });
  });

  // ---------------------------------------------------------------------------
  // isInvestmentCSVFile
  // ---------------------------------------------------------------------------
  group('isInvestmentCSVFile', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('investment_csv_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('returns true for a valid investment CSV file', () async {
      final File csvFile = File('${tempDir.path}/investment.csv');
      await csvFile.writeAsString(
        'Run Date,Account,Account Number,Action,Symbol,Description,Quantity,Price,Amount\n'
        '2024-01-15,Brokerage,12345,BUY,AAPL,Apple Inc.,10,185.50,1855.00\n',
      );

      expect(await isInvestmentCSVFile(csvFile.path), isTrue);
    });

    test('returns false for a generic CSV file', () async {
      final File csvFile = File('${tempDir.path}/bank.csv');
      await csvFile.writeAsString(
        'Date,Description,Amount\n'
        '2024-01-15,Grocery Store,-50.00\n',
      );

      expect(await isInvestmentCSVFile(csvFile.path), isFalse);
    });

    test('returns false for an empty file', () async {
      final File csvFile = File('${tempDir.path}/empty.csv');
      await csvFile.writeAsString('');

      expect(await isInvestmentCSVFile(csvFile.path), isFalse);
    });

    test('returns false for a file that does not exist', () async {
      expect(
        await isInvestmentCSVFile('${tempDir.path}/nonexistent.csv'),
        isFalse,
      );
    });

    test('returns true for investment CSV with UTF-8 BOM', () async {
      final File csvFile = File('${tempDir.path}/bom.csv');
      // UTF-8 BOM prefix on first header
      await csvFile.writeAsString(
        '\uFEFFRun Date,Account,Account Number,Amount\n'
        '2024-01-15,Brokerage,12345,100.00\n',
      );

      expect(await isInvestmentCSVFile(csvFile.path), isTrue);
    });

    test('returns false for whitespace-only file', () async {
      final File csvFile = File('${tempDir.path}/whitespace.csv');
      await csvFile.writeAsString('   \n  ');

      expect(await isInvestmentCSVFile(csvFile.path), isFalse);
    });
  });
}
