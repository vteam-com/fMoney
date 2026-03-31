import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/shared/domain/field_definition_cache.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';

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
  @override
  factory AccountAlias.fromJson(final MyJson row) {
    return AccountAlias()
      ..fieldId.value = row.getInt(SharedDomainStrings.domainString057, -1)
      ..fieldPattern.value = row.getString(SharedDomainStrings.domainString104)
      ..fieldFlags.value = row.getInt(SharedDomainStrings.domainString054, 0)
      ..fieldAccountId.value = row.getString(SharedDomainStrings.domainString013);
  }

  FieldString fieldAccountId = FieldString(serializeName: SharedDomainStrings.domainString013);

  FieldInt fieldFlags = FieldInt(serializeName: SharedDomainStrings.domainString055, defaultValue: 0);

  FieldId fieldId = FieldId(
    getValueForSerialization: (final DataInterface instance) => (instance as AccountAlias).uniqueId,
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
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<AccountAlias> _fields = Fields<AccountAlias>();

  /// Builds [AccountAlias] field definitions for cache initialization.
  static FieldDefinitions _buildFieldDefinitions(final AccountAlias tmp) => <Field<dynamic>>[
    tmp.fieldId,
    tmp.fieldPattern,
    tmp.fieldFlags,
    tmp.fieldAccountId,
  ];

  /// Returns the field definitions for AccountAlias entities.
  static Fields<AccountAlias> get fields => ensureCachedFieldDefinitions<AccountAlias>(
    cache: _fields,
    instanceFactory: () => AccountAlias.fromJson(<String, dynamic>{}),
    definitionsBuilder: _buildFieldDefinitions,
  );
}
