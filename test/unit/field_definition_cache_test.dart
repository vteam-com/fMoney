import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/shared/domain/field_definition_cache_helper.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/rental_unit_entity.dart';

void main() {
  test('the cache builds the entity and column definitions once, each bound to its row', () {
    final FieldDefinitionCache<Payee> cache = FieldDefinitionCache<Payee>(
      instanceFactory: Payee.new,
      blueprints: <FieldBlueprint<Payee>>[
        FieldBlueprint<Payee>(selector: (Payee tmp) => tmp.fieldId),
        FieldBlueprint<Payee>(selector: (Payee tmp) => tmp.fieldName, includeInColumnView: true),
        FieldBlueprint<Payee>(
          selector: (Payee tmp) => tmp.fieldCount,
          includeInEntity: false,
          includeInColumnView: true,
        ),
      ],
    );

    final Fields<Payee> fields = cache.fields;
    final Fields<Payee> columns = cache.fieldsForColumnView;

    expect(fields.definitions.length, 2);
    expect(columns.definitions.length, 2);
    expect(cache.fields, same(fields));
    expect(cache.fieldsForColumnView, same(columns));
    expect(columns.definitions.first.getValueForDisplay(Payee()..fieldName.value = 'Grocer'), 'Grocer');
  });

  test('entities declared without a column view list their entity fields', () {
    final RentUnit unit = RentUnit()..fieldName.value = 'Room A';

    expect(RentUnit.fields.definitions.length, 5);
    expect(unit.getPersistableJSon()['Name'], 'Room A');
  });
}
