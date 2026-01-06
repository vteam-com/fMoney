import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/views/data/data.dart';

void main() {
  test('test_should_round_positive_decimal_value', () {
    AmountModel mm = AmountModel(amount: 12345.67);

    // To String
    expect(mm.asDouble(), equals(12345.67));
    expect(mm.toString(), equals('\$12,345.67'));

    // Add
    mm += 10000.00;
    expect(mm.asDouble().toStringAsFixed(2), equals('22345.67'));

    // Subtract
    mm -= 10000.00;
    expect(mm.asDouble().toStringAsFixed(2), equals('12345.67'));

    mm.setAmount(9876543.21);
    expect(mm.asDouble().toStringAsFixed(2), equals('9876543.21'));
    expect(mm.toString(), equals('\$9,876,543.21'));

    mm.setAmount('123.45');
    expect(mm.asDouble(), equals(123.45));
    expect(mm.toString(), equals('\$123.45'));
  });

  group('parseAmount', () {
    test('parses valid USD amounts', () {
      expect(parseAmount('  +123.45  ', 'USD'), 123.45);
      expect(parseAmount('  -456.78  ', 'USD'), -456.78);
      expect(parseAmount('  (789.01)  ', 'USD'), -789.01);
    });

    test('parses valid EUR amounts', () {
      expect(parseAmount('  +123,45  ', 'EUR'), 123.45);
      expect(parseAmount('  -456,78  ', 'EUR'), -456.78);
      expect(parseAmount('  (789,01)  ', 'EUR'), -789.01);
    });

    test('returns null for invalid formats', () {
      expect(parseAmount('hello', 'USD'), isNull);
    });
  });

  test('TransactionExtra', () {
    Data().transactionExtras.loadFromJson(<MyJson>[
      <String, dynamic>{'Id': 0, 'Transaction': 0},
      <String, dynamic>{'Id': 1, 'Transaction': 1},
    ]);
    expect(Data().transactionExtras.isEmpty, false);
  });
}
