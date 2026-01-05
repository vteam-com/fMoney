import 'package:flutter_test/flutter_test.dart';
import 'package:money/import/import_data.dart';
import 'package:money/import/import_qif.dart';
import 'package:money/models/accounts/account_types_enum.dart';

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
        'P100.00',
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
      expect(entry1.name, 'Expense Transaction');

      final ImportEntry entry2 = importData.entries[1];
      expect(entry2.date, DateTime(2023, 2, 15));
      expect(entry2.amount, 500.00);
      expect(entry2.stockAction, 'Invest');
      expect(entry2.stockQuantity, 0.0);
      expect(entry2.stockSymbol, 'Stock Symbol');
      expect(entry2.stockPrice, 100.00);
    });

    test('should handle invalid QIF data', () {
      // Arrange
      final List<String> qifLines = <String>['Invalid line', '^'];

      // Act
      final ImportData importData = loadQIF(qifLines);

      // Assert
      expect(importData.entries.length, 1);
    });
  });
}
