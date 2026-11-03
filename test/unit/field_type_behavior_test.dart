// Characterization tests: they pin the current per-FieldType behavior of the
// domain-side switches (default display, default sort, getString, filtering,
// readable text and footer accumulation) so they can be refactored safely.
import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_filters_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/data/models/ranges_model.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/widgets/widgets_domain/footer_accumulators_helper.dart';

/// Minimal [DataObject] carrying one arbitrary value [v] for field callbacks.
class _Item extends DataObject {
  /// Creates an item holding [v].
  _Item(this.v);

  final dynamic v;
  int _id = -1;

  @override
  int get uniqueId => _id;

  @override
  set uniqueId(int value) => _id = value;
}

/// Builds a field of [type] whose display/serialization read the item value.
Field<dynamic> _fieldReadingItem(
  FieldType type, {
  dynamic Function(DataObject)? reading,
  FooterType footer = FooterType.none,
}) {
  return Field<dynamic>(
    type: type,
    name: 'f',
    defaultValue: null,
    footer: footer,
    getValueForDisplay: (dynamic i) => (i as _Item).v,
    getValueForReading: reading == null ? null : (dynamic i) => reading(i as DataObject),
  );
}

/// Returns the sign of the default sort comparing [a] and [b] ascending.
int _sortSign(FieldType type, dynamic a, dynamic b) {
  final Field<dynamic> field = _fieldReadingItem(type);
  return field.sort!(_Item(a), _Item(b), true).sign;
}

void main() {
  group('default getValueForDisplay', () {
    test('numeric and quantity return the field value as num', () {
      expect(Field<dynamic>(type: FieldType.numeric, defaultValue: 3).getValueForDisplay(_Item(null)), 3);
      expect(Field<dynamic>(type: FieldType.quantity, defaultValue: 1.5).getValueForDisplay(_Item(null)), 1.5);
    });

    test('text returns the value as string', () {
      expect(Field<dynamic>(type: FieldType.text, defaultValue: 42).getValueForDisplay(_Item(null)), '42');
    });

    test('amount returns the AmountModel value', () {
      final AmountModel amount = AmountModel(amount: 12.5);
      expect(Field<dynamic>(type: FieldType.amount, defaultValue: amount).getValueForDisplay(_Item(null)), amount);
    });

    test('date returns the formatted date text', () {
      expect(
        Field<dynamic>(type: FieldType.date, defaultValue: DateTime(2024, 3, 9)).getValueForDisplay(_Item(null)),
        '2024-03-09',
      );
    });

    test('other types have no default and return empty string', () {
      for (final FieldType type in <FieldType>[
        FieldType.numericShorthand,
        FieldType.percentage,
        FieldType.amountShorthand,
        FieldType.dateRange,
        FieldType.toggle,
        FieldType.widget,
      ]) {
        expect(Field<dynamic>(type: type, defaultValue: 7).getValueForDisplay(_Item(null)), '', reason: '$type');
      }
    });

    test('numeric and quantity default serialization follows display', () {
      final Field<dynamic> field = Field<dynamic>(type: FieldType.numeric, defaultValue: 5);
      expect(field.getValueForSerialization(_Item(null)), 5);
    });
  });

  group('default sort', () {
    test('numeric-like types sort by numeric value', () {
      for (final FieldType type in <FieldType>[
        FieldType.numeric,
        FieldType.numericShorthand,
        FieldType.quantity,
        FieldType.amountShorthand,
      ]) {
        expect(_sortSign(type, 9, 10), -1, reason: '$type');
        expect(_sortSign(type, null, 1), -1, reason: '$type null counts as 0');
      }
    });

    test('amount sorts by AmountModel', () {
      expect(_sortSign(FieldType.amount, AmountModel(amount: 1), AmountModel(amount: 2)), -1);
    });

    test('amount sorts raw numeric display values', () {
      expect(_sortSign(FieldType.amount, 3.0, 2.0), 1);
      expect(_sortSign(FieldType.amount, AmountModel(amount: 1), 2.0), -1);
    });

    test('date sorts by date', () {
      expect(_sortSign(FieldType.date, DateTime(2024), DateTime(2023)), 1);
    });

    test('other types sort by string, so 9 > 10', () {
      for (final FieldType type in <FieldType>[
        FieldType.text,
        FieldType.percentage,
        FieldType.dateRange,
        FieldType.toggle,
        FieldType.widget,
      ]) {
        expect(_sortSign(type, 9, 10), 1, reason: '$type');
      }
    });
  });

  group('getString', () {
    String getString(FieldType type, dynamic value) => Field<dynamic>(type: type, defaultValue: null).getString(value);

    test('formats each type', () {
      expect(getString(FieldType.numeric, 1234), '1234');
      expect(getString(FieldType.numericShorthand, 1234567), '1.23M');
      expect(getString(FieldType.quantity, 1.5), '1.5');
      expect(getString(FieldType.percentage, 0.25), '0.25');
      expect(getString(FieldType.amount, 1234.5), r'$1,234.50');
      expect(getString(FieldType.amount, 'x'), 'x');
      expect(getString(FieldType.amountShorthand, 1234567.0), '1.23M');
      expect(getString(FieldType.widget, 'abc'), 'abc');
      expect(getString(FieldType.text, 12), '12');
      expect(getString(FieldType.date, 12), '12');
      expect(getString(FieldType.dateRange, 12), '12');
      expect(getString(FieldType.toggle, true), 'true');
    });
  });

  group('free-text filtering', () {
    bool matches(Field<dynamic> field, dynamic value, String text) {
      final Fields<_Item> fields = Fields<_Item>()..setDefinitions(<Field<dynamic>>[field]);
      return fields.applyFilters(_Item(value), text, FieldFilters());
    }

    test('text-like types match on lower-cased display text', () {
      for (final FieldType type in <FieldType>[
        FieldType.text,
        FieldType.numeric,
        FieldType.numericShorthand,
        FieldType.percentage,
        FieldType.amountShorthand,
        FieldType.dateRange,
        FieldType.toggle,
      ]) {
        expect(matches(_fieldReadingItem(type), 'HeLLo', 'hello'), isTrue, reason: '$type');
      }
      expect(matches(_fieldReadingItem(FieldType.amount), AmountModel(amount: 3), '3.00'), isTrue);
    });

    test('date matches on the formatted date', () {
      expect(matches(_fieldReadingItem(FieldType.date), DateTime(2024, 3, 9), '2024-03-09'), isTrue);
    });

    test('quantity matches on trimmed decimals', () {
      expect(matches(_fieldReadingItem(FieldType.quantity), 1.50, '1.5'), isTrue);
      expect(matches(_fieldReadingItem(FieldType.quantity), 1.50, '1.50'), isFalse);
    });

    test('widget uses the reading text as-is, or the lower-cased serialization', () {
      final Field<dynamic> withReading = _fieldReadingItem(FieldType.widget, reading: (DataObject _) => 'MiXed');
      expect(matches(withReading, null, 'mixed'), isFalse);
      expect(matches(withReading, null, 'MiXed'), isTrue);
      expect(matches(_fieldReadingItem(FieldType.widget), 'ABC', 'abc'), isTrue);
    });
  });

  group('toReadableString', () {
    test('widget uses reading text, or serialization when there is none', () {
      final _Item item = _Item('display');
      expect(item.toReadableString(_fieldReadingItem(FieldType.widget, reading: (DataObject _) => 'read')), 'read');
      expect(item.toReadableString(_fieldReadingItem(FieldType.widget)), 'display');
    });

    test('every other type uses the display value', () {
      for (final FieldType type in FieldType.values.where((FieldType t) => t != FieldType.widget)) {
        expect(_Item(5).toReadableString(_fieldReadingItem(type)), '5', reason: '$type');
      }
    });
  });

  group('footer accumulation', () {
    FooterAccumulators accumulate(Field<dynamic> field, List<dynamic> values) {
      return FooterAccumulators()..recompute(
        items: values.map((dynamic v) => _Item(v)).toList(),
        definitions: <Field<dynamic>>[field],
      );
    }

    test('text collects the display text', () {
      final Field<dynamic> field = _fieldReadingItem(FieldType.text);
      expect(accumulate(field, <dynamic>['a', 'b']).accumulatorListOfText.getList(field), <String>['a', 'b']);
    });

    test('date collects a date range', () {
      final Field<dynamic> field = _fieldReadingItem(FieldType.date);
      final DateRange? range = accumulate(field, <dynamic>[
        DateTime(2024),
        DateTime(2022),
      ]).accumulatorDateRange.getValue(field);
      expect(range?.min, DateTime(2022));
      expect(range?.max, DateTime(2024));
    });

    test('dateRange collects min and max from getValue', () {
      final Field<dynamic> field = Field<dynamic>(
        type: FieldType.dateRange,
        defaultValue: null,
        getValue: (dynamic i) => (i as _Item).v,
      );
      final DateRange? range = accumulate(field, <dynamic>[
        DateRange(min: DateTime(2020), max: DateTime(2021)),
      ]).accumulatorDateRange.getValue(field);
      expect(range?.min, DateTime(2020));
      expect(range?.max, DateTime(2021));
    });

    test('widget collects reading text only when available', () {
      final Field<dynamic> withReading = _fieldReadingItem(FieldType.widget, reading: (DataObject _) => 'r');
      expect(accumulate(withReading, <dynamic>[1]).accumulatorListOfText.getList(withReading), <String>['r']);
      final Field<dynamic> noReading = _fieldReadingItem(FieldType.widget);
      expect(accumulate(noReading, <dynamic>[1]).accumulatorListOfText.containsKey(noReading), isFalse);
    });

    test('amount sums into the amount accumulator', () {
      final Field<dynamic> field = _fieldReadingItem(FieldType.amount, footer: FooterType.sum);
      expect(accumulate(field, <dynamic>[1.5, 2.0]).accumulatorSumAmount.getValue(field), 3.5);
    });

    test('numeric-like types sum into the number accumulator, or list ints for count footers', () {
      for (final FieldType type in <FieldType>[
        FieldType.numeric,
        FieldType.amountShorthand,
        FieldType.numericShorthand,
        FieldType.quantity,
      ]) {
        final Field<dynamic> sumField = _fieldReadingItem(type, footer: FooterType.sum);
        expect(accumulate(sumField, <dynamic>[1, 2]).accumulatorSumNumber.getValue(sumField), 3.0, reason: '$type');
        final Field<dynamic> countField = _fieldReadingItem(type, footer: FooterType.count);
        expect(
          accumulate(countField, <dynamic>[1, 2]).accumulatorListOfText.getList(countField),
          <String>['1', '2'],
          reason: '$type',
        );
      }
    });

    test('percentage and toggle are not accumulated', () {
      for (final FieldType type in <FieldType>[FieldType.percentage, FieldType.toggle]) {
        final Field<dynamic> field = _fieldReadingItem(type, footer: FooterType.sum);
        final FooterAccumulators accumulators = accumulate(field, <dynamic>[1]);
        expect(accumulators.accumulatorSumNumber.getValue(field), 0, reason: '$type');
        expect(accumulators.accumulatorListOfText.containsKey(field), isFalse, reason: '$type');
      }
    });
  });
}
