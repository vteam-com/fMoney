import 'package:money/helpers/json_helper.dart';
import 'package:money/widgets_data/money_object.dart';
import 'package:money/widgets_data/money_objects.dart';

/*

  0    Id         INT            0                    1
  1    Pattern    nvarchar(255)  1                    0
  2    Flags      INT            1                    0
  3    AccountId  nchar(20)      1                    0

 */
class AccountAlias extends MoneyObject {
  /// Constructor
  AccountAlias() {
    // body
  }

  /// Constructor from a SQLite row
  @override
  factory AccountAlias.fromJson(final MyJson row) {
    return AccountAlias()
      ..fieldId.value = row.getInt('Id', -1)
      ..fieldPattern.value = row.getString('Pattern')
      ..fieldFlags.value = row.getInt('Flag', 0)
      ..fieldAccountId.value = row.getString('AccountId');
  }

  FieldString fieldAccountId = FieldString(serializeName: 'AccountId');

  FieldInt fieldFlags = FieldInt(serializeName: 'Flags', defaultValue: 0);

  FieldId fieldId = FieldId(
    getValueForSerialization: (final MoneyObject instance) => (instance as AccountAlias).uniqueId,
  );

  FieldString fieldPattern = FieldString(serializeName: 'Pattern');

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

  static Fields<AccountAlias> get fields {
    if (_fields.isEmpty) {
      final AccountAlias tmp = AccountAlias.fromJson(<String, dynamic>{});
      _fields.setDefinitions(<Field<dynamic>>[
        tmp.fieldId,
        tmp.fieldPattern,
        tmp.fieldFlags,
        tmp.fieldAccountId,
      ]);
    }
    return _fields;
  }
}
