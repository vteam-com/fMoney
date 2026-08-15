// import 'package:money/data/collections/data.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

/*
  cid  name         type      notnull  dflt_value  pk
  ---  -----------  --------  -------  ----------  --
  0    Id           bigint    0                    1
  1    Date         datetime  1                    0
  2    Security     INT       1                    0
  3    Numerator    money     1                    0
  4    Denominator  money     1                    0
 */

/// Represents stock split.
class StockSplit extends DataObject {
  /// Private constructor for static fields only
  StockSplit._static({
    required DateTime? date,
    required int security,
    required int numerator,
    required int denominator,
  }) : data = null {
    this.fieldDate.value = date;
    this.fieldSecurity.value = security;
    this.fieldNumerator.value = numerator;
    this.fieldDenominator.value = denominator;
  }

  /// Constructor from a SQLite row
  factory StockSplit.fromJson(MyJson row, DataAbstract data) {
    return StockSplit(
      date: row.getDate(SharedDomainStrings.domainString044),
      security: row.getInt(SharedDomainStrings.domainString125),
      numerator: row.getInt(SharedDomainStrings.domainString093),
      denominator: row.getInt(SharedDomainStrings.domainString045),
      data: data,
    )..fieldId.value = row.getInt(SharedDomainStrings.domainString057, -1);
  }
  StockSplit({
    required DateTime? date,
    required int security,
    required int numerator,
    required int denominator,
    required this.data,
  }) {
    this.fieldDate.value = date;
    this.fieldSecurity.value = security;
    this.fieldNumerator.value = numerator;
    this.fieldDenominator.value = denominator;
  }

  final DataAbstract? data;

  FieldDate fieldDate = FieldDate(
    name: SharedDomainStrings.domainString044,
    serializeName: SharedDomainStrings.domainString044,
    getValueForDisplay: (DataInterface instance) => (instance as StockSplit).fieldDate.value,
    getValueForSerialization: (DataInterface instance) => dateToSqliteFormat((instance as StockSplit).fieldDate.value),
  );

  FieldInt fieldDenominator = FieldInt(
    name: SharedDomainStrings.domainString045,
    serializeName: SharedDomainStrings.domainString045,
    getValueForDisplay: (DataInterface instance) => (instance as StockSplit).fieldDenominator.value,
    getValueForSerialization: (DataInterface instance) => (instance as StockSplit).fieldDenominator.value,
  );

  FieldId fieldId = FieldId(
    getValueForDisplay: (DataInterface instance) => (instance as StockSplit).uniqueId,
    getValueForSerialization: (DataInterface instance) => instance.uniqueId,
  );

  FieldInt fieldNumerator = FieldInt(
    name: SharedDomainStrings.domainString093,
    serializeName: SharedDomainStrings.domainString093,
    getValueForDisplay: (DataInterface instance) => (instance as StockSplit).fieldNumerator.value,
    getValueForSerialization: (DataInterface instance) => (instance as StockSplit).fieldNumerator.value,
  );

  FieldInt fieldSecurity = FieldInt(
    name: SharedDomainStrings.domainString125,
    serializeName: SharedDomainStrings.domainString125,
    getValueForDisplay: (DataInterface instance) => (instance as StockSplit).fieldSecurity.value,
    getValueForSerialization: (DataInterface instance) => (instance as StockSplit).fieldSecurity.value,
  );

  // Fields for this instance
  /// Returns field definitions for this instance.
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  /// Returns a short string representation used by generic data views.
  @override
  String getRepresentation() {
    return data?.getSecuritySymbolFromId(fieldSecurity.value) ?? SharedDomainStrings.domainString150;
  }

  /// Returns a debug-friendly string describing this stock split.
  @override
  String toString() {
    return '${fieldDate.value}|${fieldSecurity.value}|${fieldNumerator.value} for ${fieldDenominator.value}';
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(int value) => fieldId.value = value;

  static final Fields<StockSplit> _fields = Fields<StockSplit>();

  /// Returns the field definitions for StockSplit entities.
  static Fields<StockSplit> get fields {
    if (_fields.isEmpty) {
      // Create a temporary instance for field definitions - no data relationships needed
      final StockSplit tmp = StockSplit._static(
        date: null,
        security: -1,
        numerator: 1,
        denominator: 1,
      );
      _fields.setDefinitions(<Field<dynamic>>[
        tmp.fieldId,
        tmp.fieldDate,
        tmp.fieldSecurity,
        tmp.fieldNumerator,
        tmp.fieldDenominator,
      ]);
    }
    return _fields;
  }
}
