import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/field_definition_cache_helper.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

/*
  SQLite table definition

  0|Id|INT|0||1
  1|Building|INT|1||0
  2|Name|nvarchar(255)|1||0
  3|Renter|nvarchar(255)|0||0
  4|Note|nvarchar(255)|0||0
 */
/// Represents rent unit.
class RentUnit extends DataObject {
  RentUnit();

  factory RentUnit.fromJson(final MyJson row) {
    return RentUnit()
      ..fieldId.value = row.getInt(SharedDomainStrings.domainString057, -1)
      ..fieldName.value = row.getString(SharedDomainStrings.domainString088)
      ..fieldBuilding.value = row.getInt(SharedDomainStrings.domainString026, -1)
      ..fieldRenter.value = row.getString(SharedDomainStrings.domainString119)
      ..fieldNote.value = row.getString(SharedDomainStrings.domainString091);
  }

  double balance = 0.00;
  // not persisted field
  int count = 0;

  /// Building Id
  /// 1|Building|INT|1||0
  FieldInt fieldBuilding = FieldInt(
    name: SharedDomainStrings.domainString026,
    serializeName: SharedDomainStrings.domainString026,
    getValueForSerialization: (final DataInterface instance) => (instance as RentUnit).fieldBuilding.value,
  );

  /// Id
  /// 0|Id|INT|0||1
  FieldId fieldId = FieldId(
    getValueForSerialization: (final DataInterface instance) => instance.uniqueId,
  );

  /// 2
  /// 2|Name|nvarchar(255)|1||0
  FieldString fieldName = FieldString(
    name: SharedDomainStrings.domainString088,
    serializeName: SharedDomainStrings.domainString088,
    getValueForSerialization: (final DataInterface instance) => (instance as RentUnit).fieldName.value,
  );

  /// 4
  /// 4|Note|nvarchar(255)|0||0
  FieldString fieldNote = FieldString(
    name: SharedDomainStrings.domainString091,
    serializeName: SharedDomainStrings.domainString091,
    getValueForSerialization: (final DataInterface instance) => (instance as RentUnit).fieldNote.value,
  );

  /// 3
  /// 3|Renter|nvarchar(255)|0||0
  FieldString fieldRenter = FieldString(
    name: SharedDomainStrings.domainString119,
    serializeName: SharedDomainStrings.domainString119,
    getValueForSerialization: (final DataInterface instance) => (instance as RentUnit).fieldRenter.value,
  );

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<RentUnit> _fields = Fields<RentUnit>();

  /// Builds [RentUnit] field definitions for cache initialization.
  static FieldDefinitions _buildFieldDefinitions(final RentUnit tmp) => <Field<dynamic>>[
    tmp.fieldId,
    tmp.fieldBuilding,
    tmp.fieldName,
    tmp.fieldRenter,
    tmp.fieldNote,
  ];

  /// Returns the field definitions for RentUnit entities.
  static Fields<RentUnit> get fields => ensureCachedFieldDefinitions<RentUnit>(
    cache: _fields,
    instanceFactory: () => RentUnit.fromJson(<String, dynamic>{}),
    definitionsBuilder: _buildFieldDefinitions,
  );
}
