import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';

/*
  cid  name         type          notnull  default  pk
  ---  -----------  ------------  -------  -------  --
  0    Id           INT           0                 1 
  1    Symbol       nchar(20)     1                 0 
  2    Name         nvarchar(80)  1                 0 
  3    Ratio        money         0                 0 
  4    LastRatio    money         0                 0 
  5    CultureCode  nvarchar(80)  0                 0 
 */
/// Represents currency.
class Currency extends DataObject {
  Currency({
    required final int id, // 0
    required final String symbol, // 1
    required final String name, // 2
    required final double ratio, // 3
    required final String cultureCode, // 4
    required final double lastRatio, // 5
  }) {
    this.fieldId.value = id;
    this.fieldName.value = name;
    this.fieldSymbol.value = symbol;
    this.fieldRatio.value = ratio;
    this.fieldCultureCode.value = cultureCode;
    this.fieldLastRatio.value = lastRatio;
  }

  /// Constructor from a SQLite row
  factory Currency.fromJson(final MyJson row) {
    return Currency(
      // 0
      id: row.getInt(SharedDomainStrings.domainString057, -1),
      // 1
      symbol: row.getString(SharedDomainStrings.domainString131),
      // 2
      name: row.getString(SharedDomainStrings.domainString088),
      // 3
      ratio: row.getDouble(SharedDomainStrings.domainString113),
      // 4
      lastRatio: row.getDouble(SharedDomainStrings.domainString080),
      // 5
      cultureCode: row.getString(SharedDomainStrings.domainString040),
    );
  }

  /// 5
  /// 5    CultureCode  nvarchar(80)
  FieldString fieldCultureCode = FieldString(
    name: 'Culture Code',
    serializeName: SharedDomainStrings.domainString040,
    getValueForDisplay: (final DataInterface instance) => (instance as Currency).fieldCultureCode.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Currency).fieldCultureCode.value,
  );

  // 0
  FieldId fieldId = FieldId(
    getValueForSerialization: (final DataInterface instance) => instance.uniqueId,
  );

  // 4
  FieldDouble fieldLastRatio = FieldDouble(
    name: SharedDomainStrings.domainString080,
    serializeName: SharedDomainStrings.domainString080,
    getValueForDisplay: (final DataInterface instance) => (instance as Currency).fieldLastRatio.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Currency).fieldLastRatio.value,
  );

  /// 2
  /// 2    name       nchar(20)
  FieldString fieldName = FieldString(
    name: SharedDomainStrings.domainString088,
    serializeName: SharedDomainStrings.domainString088,
    getValueForDisplay: (final DataInterface instance) => (instance as Currency).fieldName.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Currency).fieldName.value,
  );

  /// 3    Ratio        money
  FieldDouble fieldRatio = FieldDouble(
    name: SharedDomainStrings.domainString113,
    serializeName: SharedDomainStrings.domainString113,
    getValueForDisplay: (final DataInterface instance) => (instance as Currency).fieldRatio.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Currency).fieldRatio.value,
  );

  /// 1    Symbol       nchar(20)
  FieldString fieldSymbol = FieldString(
    name: SharedDomainStrings.domainString131,
    serializeName: SharedDomainStrings.domainString131,
    getValueForDisplay: (final DataInterface instance) => (instance as Currency).fieldSymbol.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Currency).fieldSymbol.value,
  );

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  String getRepresentation() {
    return fieldName.value;
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<Currency> _fields = Fields<Currency>();

  /// Returns the field definitions for Currency entities.
  static Fields<Currency> get fields {
    if (_fields.isEmpty) {
      final Currency tmp = Currency.fromJson(<String, dynamic>{});
      _fields.setDefinitions(<Field<dynamic>>[
        tmp.fieldId,
        tmp.fieldSymbol,
        tmp.fieldName,
        tmp.fieldRatio,
        tmp.fieldLastRatio,
        tmp.fieldCultureCode,
      ]);
    }
    return _fields;
  }
}
