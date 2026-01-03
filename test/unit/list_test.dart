import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/accumulator.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/pairs.dart';

void main() {
  test('AccumulatorSum: empty map', () {
    final AccumulatorSum<int, int> acc = AccumulatorSum<int, int>();
    expect(acc.values, isEmpty);
  });

  test('AccumulatorSum: one element', () {
    final AccumulatorSum<int, int> acc = AccumulatorSum<int, int>();
    acc.cumulate(1, 2);
    expect(acc.values, <int, int>{1: 2});
  });

  test('AccumulatorSum: two elements', () {
    final AccumulatorSum<int, int> acc = AccumulatorSum<int, int>();
    acc.cumulate(1, 2);
    acc.cumulate(2, 3);
    expect(acc.values, <int, int>{1: 2, 2: 3});
  });

  test('AccumulatorSum: two elements with same key', () {
    final AccumulatorSum<int, int> acc = AccumulatorSum<int, int>();
    acc.cumulate(1, 2);
    acc.cumulate(1, 3);
    expect(acc.values, <int, int>{1: 5});
  });

  group('calculateSpread', () {
    test('returns correct spread for valid input', () {
      const double start = 1.0;
      const double end = 5.0;
      const int numEntries = 5;
      final List<double> expected = <double>[1.0, 2.0, 3.0, 4.0, 5.0];
      expect(calculateSpread(start, end, numEntries), expected);
    });

    test('returns empty list for numEntries <= 1', () {
      expect(calculateSpread(1.0, 5.0, 1), <double>[]);
      expect(calculateSpread(1.0, 5.0, 0), <double>[]);
    });
  });

  group('convertMapToListOfPair', () {
    test('returns empty list for empty map', () {
      expect(
        convertMapToListOfPair<String, int>(<String, int>{}).isEmpty,
        true,
      );
    });

    test('converts map to list of pairs correctly', () {
      final Map<String, int> map = <String, int>{'a': 1, 'b': 2, 'c': 3};
      final List<Pair<String, int>> expected = <Pair<String, int>>[
        Pair<String, int>('a', 1),
        Pair<String, int>('b', 2),
        Pair<String, int>('c', 3),
      ];
      expect(convertMapToListOfPair<String, int>(map), expected);
    });
  });

  group('convertToPercentages', () {
    test('handles division by zero correctly', () {
      final List<PairStringDouble> pairs = <PairStringDouble>[
        PairStringDouble(key: 'a', value: 0.0),
        PairStringDouble(key: 'b', value: 0.0),
        PairStringDouble(key: 'c', value: 0.0),
      ];
      final List<PairStringDouble> expected = <PairStringDouble>[
        PairStringDouble(key: 'a', value: 0.0),
        PairStringDouble(key: 'b', value: 0.0),
        PairStringDouble(key: 'c', value: 0.0),
      ];
      expect(convertToPercentages(pairs), expected);
    });
    test('converts key-value pairs to percentages correctly', () {
      final List<PairStringDouble> pairs = <PairStringDouble>[
        PairStringDouble(key: 'a', value: 10.0),
        PairStringDouble(key: 'b', value: 20.0),
        PairStringDouble(key: 'c', value: 30.0),
      ];

      final List<PairStringDouble> result = convertToPercentages(pairs);

      expect(roundDouble(result[0].value, 3), 16.667);
      expect(roundDouble(result[1].value, 3), 33.333);
      expect(roundDouble(result[2].value, 3), 50.0);
    });
  });

  group('getMinMaxValues', () {
    test('returns correct min and max values for non-empty list', () {
      final List<double> list = <double>[3.0, 1.0, 4.0, 1.5, 9.0, 2.6];
      expect(getMinMaxValues(list), <double>[1.0, 9.0]);
    });

    test('returns [0, 0] for empty list', () {
      expect(getMinMaxValues(<double>[]), <int>[0, 0]);
    });

    test('returns single value for list with one element', () {
      expect(getMinMaxValues(<double>[5.0]), <double>[5.0, 5.0]);
    });
  });
}
