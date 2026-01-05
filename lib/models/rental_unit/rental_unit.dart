import 'package:money/helpers/json_helper.dart';
import 'package:money/widgets/field.dart';
import 'package:money/widgets/money_object.dart';

/*
  SQLite table definition

  0|Id|INT|0||1
  1|Building|INT|1||0
  2|Name|nvarchar(255)|1||0
  3|Renter|nvarchar(255)|0||0
  4|Note|nvarchar(255)|0||0
 */
class RentUnit extends MoneyObject {
  RentUnit();

  factory RentUnit.fromJson(final MyJson row) {
    return RentUnit()
      ..fieldId.value = row.getInt('Id', -1)
      ..fieldName.value = row.getString('Name')
      ..fieldBuilding.value = row.getInt('Building', -1)
      ..fieldRenter.value = row.getString('Renter')
      ..fieldNote.value = row.getString('Note');
  }

  double balance = 0.00;
  // not persisted field
  int count = 0;

  /// Building Id
  /// 1|Building|INT|1||0
  FieldInt fieldBuilding = FieldInt(
    name: 'Building',
    serializeName: 'Building',
    getValueForSerialization: (final MoneyObject instance) => (instance as RentUnit).fieldBuilding.value,
  );

  /// Id
  /// 0|Id|INT|0||1
  FieldId fieldId = FieldId(
    getValueForSerialization: (final MoneyObject instance) => instance.uniqueId,
  );

  /// 2
  /// 2|Name|nvarchar(255)|1||0
  FieldString fieldName = FieldString(
    name: 'Name',
    serializeName: 'Name',
    getValueForSerialization: (final MoneyObject instance) => (instance as RentUnit).fieldName.value,
  );

  /// 4
  /// 4|Note|nvarchar(255)|0||0
  FieldString fieldNote = FieldString(
    name: 'Note',
    serializeName: 'Note',
    getValueForSerialization: (final MoneyObject instance) => (instance as RentUnit).fieldNote.value,
  );

  /// 3
  /// 3|Renter|nvarchar(255)|0||0
  FieldString fieldRenter = FieldString(
    name: 'Renter',
    serializeName: 'Renter',
    getValueForSerialization: (final MoneyObject instance) => (instance as RentUnit).fieldRenter.value,
  );

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<RentUnit> _fields = Fields<RentUnit>();

  static Fields<RentUnit> get fields {
    if (_fields.isEmpty) {
      final RentUnit tmp = RentUnit.fromJson(<String, dynamic>{});
      _fields.setDefinitions(<Field<dynamic>>[
        tmp.fieldId,
        tmp.fieldBuilding,
        tmp.fieldName,
        tmp.fieldRenter,
        tmp.fieldNote,
      ]);
    }
    return _fields;
  }
}
