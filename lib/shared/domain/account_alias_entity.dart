import 'package:money/data/models/data_interface.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/field_definition_cache_helper.dart';

/*

  0    Id         INT            0                    1
  1    Pattern    nvarchar(255)  1                    0
  2    Flags      INT            1                    0
  3    AccountId  nchar(20)      1                    0

 */
/// Represents account alias.
class AccountAlias extends DataObject {
  /// Constructor
  AccountAlias() {
    // body
  }

  /// Constructor from a SQLite row
  factory AccountAlias.fromJson(MyJson row) {
    return AccountAlias()
      ..fieldId.value = row.getInt(SharedDomainStrings.domainString057, -1)
      ..fieldPattern.value = row.getString(SharedDomainStrings.domainString104)
      ..fieldFlags.value = row.getInt(SharedDomainStrings.domainString055, 0)
      ..fieldAccountId.value = row.getString(SharedDomainStrings.domainString013);
  }

  FieldString fieldAccountId = FieldString(serializeName: SharedDomainStrings.domainString013);

  FieldInt fieldFlags = FieldInt(serializeName: SharedDomainStrings.domainString055, defaultValue: 0);

  FieldId fieldId = FieldId(
    getValueForSerialization: (DataInterface instance) => (instance as AccountAlias).uniqueId,
  );

  FieldString fieldPattern = FieldString(serializeName: SharedDomainStrings.domainString104);

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  String getRepresentation() {
    return '${fieldPattern.value} ${fieldAccountId.value}';
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(int value) => fieldId.value = value;

  static final FieldDefinitionCache<AccountAlias> _fieldDefinitionCache = FieldDefinitionCache<AccountAlias>(
    instanceFactory: () => AccountAlias.fromJson(<String, dynamic>{}),
    blueprints: <FieldBlueprint<AccountAlias>>[
      FieldBlueprint<AccountAlias>(selector: (AccountAlias tmp) => tmp.fieldId),
      FieldBlueprint<AccountAlias>(selector: (AccountAlias tmp) => tmp.fieldPattern),
      FieldBlueprint<AccountAlias>(selector: (AccountAlias tmp) => tmp.fieldFlags),
      FieldBlueprint<AccountAlias>(selector: (AccountAlias tmp) => tmp.fieldAccountId),
    ],
  );

  /// Returns the field definitions for AccountAlias entities.
  static Fields<AccountAlias> get fields => _fieldDefinitionCache.fields;
}
