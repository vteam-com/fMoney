import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets/fields/field_filters.dart';

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
}
