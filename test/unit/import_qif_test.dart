import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/views/imports/formats/qif_import_view.dart';
import 'package:money/views/imports/shared/data_import_view.dart';

void main() {
  group('loadQIF', () {
    test('should parse QIF data correctly', () {
      // Arrange
      final List<String> qifLines = <String>[
        '!Type:Invst',
        'D01/30/2023',
        'T-100.00',
        'MExpense Transaction',
        '^',
        'D02/15/2023',
        'T500.00',
        'NInvest',
        'QSome Quantity',
        'YStock Symbol',
        'I100.00',
        'PBroker Inc',
        '^',
      ];

      // Act
      final ImportData importData = loadQIF(qifLines);

      // Assert
      expect(importData.accountType, AccountType.investment);
      expect(importData.entries.length, 2);

      final ImportEntry entry1 = importData.entries[0];
      expect(entry1.date, DateTime(2023, 1, 30));
      expect(entry1.amount, -100.00);
      expect(entry1.name, '');
      expect(entry1.memo, 'Expense Transaction');
      expect(entry1.getDescription(), 'Expense Transaction');

      final ImportEntry entry2 = importData.entries[1];
      expect(entry2.date, DateTime(2023, 2, 15));
      expect(entry2.amount, 500.00);
      expect(entry2.stockAction, 'Invest');
      expect(entry2.stockQuantity, 0.0);
      expect(entry2.stockSymbol, 'Stock Symbol');
      expect(entry2.stockPrice, 100.00);
      expect(entry2.name, 'Broker Inc');
    });

    test('should handle invalid QIF data', () {
      // Arrange
      final List<String> qifLines = <String>['Invalid line', '^'];

      // Act
      final ImportData importData = loadQIF(qifLines);

      // Assert: an entry without a readable date is skipped, not imported dated today
      expect(importData.entries.length, 0);
      expect(importData.diagnostics.skippedRows, 1);
    });
  });
}
