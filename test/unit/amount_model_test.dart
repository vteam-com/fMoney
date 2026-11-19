import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/data_facade.dart';

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

    test('parses bank styles the old USD/EUR regexes rejected', () {
      expect(parseAmount('12-', 'USD'), -12);
      expect(parseAmount(r'$ 1,234.56', 'USD'), 1234.56);
      expect(parseAmount('CAD 5.00', 'CAD'), 5);
      expect(parseAmount('1.234,56', 'USD'), 1234.56);
      expect(parseAmount('1 234,56', 'EUR'), 1234.56);
    });

    test('EUR keeps a lone comma as the decimal separator', () {
      expect(parseAmount('1,234', 'EUR'), 1.234);
      expect(parseAmount('1.234', 'EUR'), 1234);
      expect(parseAmount('1,234', 'USD'), 1234);
    });
  });

  test('TransactionExtra', () {
    Data().transactionExtras.loadFromJson(<MyJson>[
      <String, dynamic>{'Id': 0, 'Transaction': 0},
      <String, dynamic>{'Id': 1, 'Transaction': 1},
    ]);
    expect(Data().transactionExtras.isEmpty, false);
  });

  group('smartToDouble', () {
    test('converts numbers, amounts and text', () {
      expect(smartToDouble(12.5), 12.5);
      expect(smartToDouble(3), 3.0);
      expect(smartToDouble(AmountModel(amount: -4.25)), -4.25);
      expect(smartToDouble('\$1,234.56'), 1234.56);
    });

    test('returns the default for null, text without a number and other types', () {
      expect(smartToDouble(null), 0.0);
      expect(smartToDouble('abc'), 0.0);
      expect(smartToDouble(true), 0.0);
      expect(smartToDouble(null, 9.5), 9.5);
      expect(smartToDouble('abc', 9.5), 9.5);
    });

    test('setAmount and MyJson.getDouble convert through it', () {
      final AmountModel amount = AmountModel(amount: 1)..setAmount(null);
      expect(amount.asDouble(), 0.0);
      amount.setAmount(AmountModel(amount: 7));
      expect(amount.asDouble(), 7.0);
      amount.setAmount('2.5');
      expect(amount.asDouble(), 2.5);

      final MyJson json = <String, dynamic>{'text': 'n/a', 'int': 4, 'missing': null};
      expect(json.getDouble('text', 9.5), 9.5);
      expect(json.getDouble('int'), 4.0);
      expect(json.getDouble('missing', 1.5), 1.5);
    });
  });
}
