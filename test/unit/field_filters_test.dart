import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/field_filter_model.dart';
import 'package:money/data/models/field_filters_model.dart';

void main() {
  group('FieldFilters', () {
    test('should convert empty FieldFilters to string', () {
      final FieldFilters filters = FieldFilters();
      expect(filters.isEmpty, true);
      expect(filters.length, 0);
      expect(filters.toString(), '{"filters":[]}');
    });

    test('should create filters list with provided filters', () {
      final FieldFilter filter = FieldFilter(
        fieldName: 'color',
        strings: <String>['blue', 'red'],
      );
      final FieldFilters filters = FieldFilters(<FieldFilter>[filter]);
      expect(filters.isNotEmpty, true);
      expect(filters.length, 1);
      expect(filters.list.first, filter);

      final String jsonString = filters.toJsonString();
      expect(
        jsonString,
        '{"filters":[{"fieldName":"color","strings":["blue","red"],"byDateRange":false}]}',
      );

      // Test the clear all filters
      filters.clear();
      expect(filters.isEmpty, true);

      final String input =
          '{"filters":[{"fieldName":"temperature","strings":["32f","0c","100c"],"byDateRange":false}]}';
      final FieldFilters filters2 = FieldFilters.fromJsonString(input);
      final String output = filters2.toJsonString();
      expect(output, input);
    });
  });

  test('should create filters with byDateRange', () {
    final FieldFilter filter = FieldFilter(
      fieldName: 'date',
      strings: <String>['2023-01-01', '2023-12-31'],
      byDateRange: true,
    );
    final FieldFilters filters = FieldFilters(<FieldFilter>[filter]);
    expect(filters.isNotEmpty, true);
    expect(filters.length, 1);
    expect(filters.list.first, filter);
    expect(filters.list.first.byDateRange, true);

    final String jsonString = filters.toJsonString();
    expect(
      jsonString,
      '{"filters":[{"fieldName":"date","strings":["2023-01-01","2023-12-31"],"byDateRange":true}]}',
    );
  });

  test('removeByFieldName drops only the filters of that column', () {
    final FieldFilters filters = FieldFilters(<FieldFilter>[
      FieldFilter(fieldName: 'color', strings: <String>['blue']),
      FieldFilter(fieldName: 'size', strings: <String>['small']),
      FieldFilter(fieldName: 'color', strings: <String>['red']),
    ]);

    filters.removeByFieldName('color');

    expect(filters.list.map((FieldFilter filter) => filter.fieldName), <String>['size']);
  });

  test('isValueSelected follows the column filter, ignoring case, and keeps unfiltered columns selected', () {
    final FieldFilters filters = FieldFilters(<FieldFilter>[
      FieldFilter(fieldName: 'color', strings: <String>['Blue']),
      FieldFilter(fieldName: 'date', strings: <String>['2023-01-01', '2023-12-31'], byDateRange: true),
    ]);

    expect(filters.isValueSelected('color', 'blue'), isTrue);
    expect(filters.isValueSelected('color', 'red'), isFalse);
    expect(filters.isValueSelected('size', 'small'), isTrue);
    expect(filters.isValueSelected('date', '2023-12-31'), isTrue);
    expect(filters.isValueSelected('date', '2024-01-01'), isFalse);
  });
}
