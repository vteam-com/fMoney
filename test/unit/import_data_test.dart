import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/imports/shared/data_import_view.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ImportDiagnostics
  // ---------------------------------------------------------------------------
  group('ImportDiagnostics', () {
    test('starts with zero counts', () {
      final ImportDiagnostics diag = ImportDiagnostics();
      expect(diag.processedRows, 0);
      expect(diag.skippedRows, 0);
      expect(diag.skippedByReason, isEmpty);
    });

    test('incrementSkipped increments total and per-reason counter', () {
      final ImportDiagnostics diag = ImportDiagnostics();
      diag.incrementSkipped('invalidDate');

      expect(diag.skippedRows, 1);
      expect(diag.skippedByReason['invalidDate'], 1);
    });

    test('incrementSkipped accumulates multiple reasons independently', () {
      final ImportDiagnostics diag = ImportDiagnostics();
      diag.incrementSkipped('invalidDate');
      diag.incrementSkipped('invalidDate');
      diag.incrementSkipped('emptyDescription');

      expect(diag.skippedRows, 3);
      expect(diag.skippedByReason['invalidDate'], 2);
      expect(diag.skippedByReason['emptyDescription'], 1);
    });

    test('does not affect processedRows when incrementSkipped is called', () {
      final ImportDiagnostics diag = ImportDiagnostics()..processedRows = 10;
      diag.incrementSkipped('invalidAmount');
      expect(diag.processedRows, 10);
    });
  });

  // ---------------------------------------------------------------------------
  // ImportEntry.getDescription
  // ---------------------------------------------------------------------------
  group('ImportEntry.getDescription', () {
    test('returns name when name is non-empty', () {
      final ImportEntry entry = ImportEntry(
        type: 'CSV',
        date: DateTime(2024, 1, 1),
        amount: 10.0,
        name: 'Grocery Store',
        fitid: 'fitid-1',
        memo: 'some memo',
      );
      expect(entry.getDescription(), 'Grocery Store');
    });

    test('falls back to memo when name is empty', () {
      final ImportEntry entry = ImportEntry(
        type: 'CSV',
        date: DateTime(2024, 1, 1),
        amount: 10.0,
        name: '',
        fitid: 'fitid-2',
        memo: 'Memo only',
      );
      expect(entry.getDescription(), 'Memo only');
    });

    test('falls back to stock description when name and memo are empty', () {
      final ImportEntry entry = ImportEntry(
        type: 'investment_csv',
        date: DateTime(2024, 1, 1),
        amount: 1000.0,
        name: '',
        fitid: 'fitid-3',
        memo: '',
        stockSymbol: 'AAPL',
        stockAction: 'BUY',
        stockQuantity: 10.0,
        stockPrice: 185.50,
      );
      final String desc = entry.getDescription();
      expect(desc, contains('AAPL'));
      expect(desc, contains('BUY'));
    });

    test('blank factory entry has empty description fallback', () {
      final ImportEntry blank = ImportEntry.blank();
      // All text fields are empty; stock fields are default zero
      // getDescription() should not throw
      expect(() => blank.getDescription(), returnsNormally);
    });
  });

  // ---------------------------------------------------------------------------
  // ImportEntry.blank factory
  // ---------------------------------------------------------------------------
  group('ImportEntry.blank', () {
    test('creates entry with empty string fields', () {
      final ImportEntry blank = ImportEntry.blank();
      expect(blank.type, '');
      expect(blank.name, '');
      expect(blank.fitid, '');
      expect(blank.stockAction, '');
      expect(blank.stockSymbol, '');
    });

    test('creates entry with zero numeric fields', () {
      final ImportEntry blank = ImportEntry.blank();
      expect(blank.amount, 0.0);
      expect(blank.stockQuantity, 0.0);
      expect(blank.stockPrice, 0.0);
      expect(blank.stockCommission, 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  // ImportData
  // ---------------------------------------------------------------------------
  group('ImportData', () {
    test('starts with empty entries list', () {
      final ImportData data = ImportData();
      expect(data.entries, isEmpty);
    });

    test('starts with empty fileType', () {
      final ImportData data = ImportData();
      expect(data.fileType, '');
    });

    test('starts with null account and accountType', () {
      final ImportData data = ImportData();
      expect(data.account, isNull);
      expect(data.accountType, isNull);
    });

    test('entries can be added', () {
      final ImportData data = ImportData();
      data.entries.add(
        ImportEntry(
          type: 'CSV',
          date: DateTime(2024),
          amount: 50.0,
          name: 'Test',
          fitid: 'x',
        ),
      );
      expect(data.entries.length, 1);
    });

    test('diagnostics are accessible and mutable', () {
      final ImportData data = ImportData();
      data.diagnostics.processedRows = 5;
      data.diagnostics.incrementSkipped('test');
      expect(data.diagnostics.processedRows, 5);
      expect(data.diagnostics.skippedRows, 1);
    });
  });
}
