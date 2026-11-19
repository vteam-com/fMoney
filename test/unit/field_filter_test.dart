import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/data_interface.dart';
import 'package:money/data/models/field_filter_model.dart';
import 'package:money/data/models/field_filters_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/shared/domain/payee_entity.dart';

void main() {
  test('free-text search matches widget columns case-insensitively', () {
    final Fields<Payee> fields = Fields<Payee>()
      ..setDefinitions(<Field<dynamic>>[
        Field<String>(
          defaultValue: '',
          name: 'Currency',
          type: FieldType.widget,
          getValueForDisplay: (DataInterface _) => 'USD',
          getValueForReading: (DataInterface _) => 'USD',
        ),
      ]);

    // the view lowercases what the user typed before searching
    expect(fields.isMatchingFreeStyleText(Payee(), 'usd'), isTrue);
  });

  test('a column filter saved for a column that no longer exists is ignored, not a crash', () {
    final Fields<Payee> fields = Fields<Payee>()
      ..setDefinitions(<Field<dynamic>>[
        Field<String>(
          defaultValue: '',
          name: 'Currency',
          getValueForDisplay: (DataInterface _) => 'USD',
          getValueForReading: (DataInterface _) => 'USD',
        ),
      ]);
    final FieldFilters savedFilters = FieldFilters(<FieldFilter>[
      FieldFilter(fieldName: 'Renamed column', strings: <String>['x']),
    ]);

    expect(fields.isMatchingColumnFiltering(Payee(), savedFilters), isTrue);
  });
}
