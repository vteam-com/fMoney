import 'package:money/data/models/data_interface.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/field_definition_cache_helper.dart';

const int _unsetId = -1;

/*
  0    Id                 INT             0                    1
  1    Name               nvarchar(80)    1                    0
  2    Institution        nvarchar(80)    0                    0
  3    OFX                nvarchar(255)   0                    0
  4    OfxVersion         nchar(10)       0                    0
  5    FID                nvarchar(50)    0                    0
  6    UserId             nchar(20)       0                    0
  7    Password           nvarchar(50)    0                    0
  8    UserCred1          nvarchar(200)   0                    0
  9    UserCred2          nvarchar(200)   0                    0
  10   AuthToken          nvarchar(200)   0                    0
  11   BankId             nvarchar(50)    0                    0
  12   BranchId           nvarchar(50)    0                    0
  13   BrokerId           nvarchar(50)    0                    0
  14   LogoUrl            nvarchar(1000)  0                    0
  15   AppId              nchar(10)       0                    0
  16   AppVersion         nchar(10)       0                    0
  17   ClientUid          nchar(36)       0                    0
  18   AccessKey          nchar(36)       0                    0
  19   UserKey            nvarchar(64)    0                    0
  20   UserKeyExpireDate  datetime        0                    0
 */

/// Online-banking columns that fMoney does not edit: they are loaded as text and
/// written back unchanged, in schema order, so saving and CSV export keep them.
const List<String> _passThroughColumns = <String>[
  'Institution',
  'OFX',
  'OfxVersion',
  'FID',
  'UserId',
  'Password',
  'UserCred1',
  'UserCred2',
  'AuthToken',
  'BankId',
  'BranchId',
  'BrokerId',
  'LogoUrl',
  'AppId',
  'AppVersion',
  'ClientUid',
  'AccessKey',
  'UserKey',
  'UserKeyExpireDate',
];

/// Represents online account.
class OnlineAccount extends DataObject {
  OnlineAccount({required String name}) {
    this.fieldName.value = name;
  }

  /// Constructor from a SQLite row
  factory OnlineAccount.fromJson(MyJson row) {
    final OnlineAccount account = OnlineAccount(name: row.getString(SharedDomainStrings.domainString088))
      ..fieldId.value = row.getInt(SharedDomainStrings.domainString057, _unsetId);
    for (final FieldString field in account.passThroughFields) {
      field.value = row[field.serializeName]?.toString() ?? '';
    }
    return account;
  }

  // 0
  FieldId fieldId = FieldId(
    getValueForSerialization: (DataInterface instance) => (instance as OnlineAccount).uniqueId,
  );

  // 1
  FieldString fieldName = FieldString(
    serializeName: SharedDomainStrings.domainString088,
    getValueForSerialization: (DataInterface instance) => (instance as OnlineAccount).fieldName.value,
  );

  /// Columns 2 to 20, one text field per entry of [_passThroughColumns]; empty values are saved as null.
  late final List<FieldString> passThroughFields = List<FieldString>.generate(
    _passThroughColumns.length,
    (int index) => FieldString(
      serializeName: _passThroughColumns[index],
      useAsDetailPanels: defaultCallbackValueFalse,
      columnWidth: ColumnWidth.hidden,
      getValueForSerialization: (DataInterface instance) {
        final String text = (instance as OnlineAccount).passThroughFields[index].value;
        return text.isEmpty ? null : text;
      },
    ),
  );

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  static final FieldDefinitionCache<OnlineAccount> _fieldDefinitionCache = FieldDefinitionCache<OnlineAccount>(
    instanceFactory: () => OnlineAccount.fromJson(<String, dynamic>{}),
    blueprints: <FieldBlueprint<OnlineAccount>>[
      FieldBlueprint<OnlineAccount>(selector: (OnlineAccount tmp) => tmp.fieldId),
      FieldBlueprint<OnlineAccount>(selector: (OnlineAccount tmp) => tmp.fieldName),
      ...List<FieldBlueprint<OnlineAccount>>.generate(
        _passThroughColumns.length,
        (int index) => FieldBlueprint<OnlineAccount>(selector: (OnlineAccount tmp) => tmp.passThroughFields[index]),
      ),
    ],
  );

  /// Returns the field definitions for OnlineAccount entities.
  static Fields<OnlineAccount> get fields => _fieldDefinitionCache.fields;

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(int value) => fieldId.value = value;
}
