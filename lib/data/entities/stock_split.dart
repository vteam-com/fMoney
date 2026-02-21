// import 'package:money/data/collections/data.dart';
import 'package:money/data/entities/data_abstract.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';

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
  factory StockSplit.fromJson(final MyJson row, final DataAbstract data) {
    return StockSplit(
      date: row.getDate('Date'),
      security: row.getInt('Security'),
      numerator: row.getInt('Numerator'),
      denominator: row.getInt('Denominator'),
      data: data,
    )..fieldId.value = row.getInt('Id', -1);
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
    name: 'Date',
    serializeName: 'Date',
    getValueForDisplay: (final DataInterface instance) => (instance as StockSplit).fieldDate.value,
    getValueForSerialization: (final DataInterface instance) =>
        dateToSqliteFormat((instance as StockSplit).fieldDate.value),
  );

  FieldInt fieldDenominator = FieldInt(
    name: 'Denominator',
    serializeName: 'Denominator',
    getValueForDisplay: (final DataInterface instance) => (instance as StockSplit).fieldDenominator.value,
    getValueForSerialization: (final DataInterface instance) => (instance as StockSplit).fieldDenominator.value,
  );

  FieldId fieldId = FieldId(
    getValueForDisplay: (final DataInterface instance) => (instance as StockSplit).uniqueId,
    getValueForSerialization: (final DataInterface instance) => instance.uniqueId,
  );

  FieldInt fieldNumerator = FieldInt(
    name: 'Numerator',
    serializeName: 'Numerator',
    getValueForDisplay: (final DataInterface instance) => (instance as StockSplit).fieldNumerator.value,
    getValueForSerialization: (final DataInterface instance) => (instance as StockSplit).fieldNumerator.value,
  );

  FieldInt fieldSecurity = FieldInt(
    name: 'Security',
    serializeName: 'Security',
    getValueForDisplay: (final DataInterface instance) => (instance as StockSplit).fieldSecurity.value,
    getValueForSerialization: (final DataInterface instance) => (instance as StockSplit).fieldSecurity.value,
  );

  // Fields for this instance
  /// Returns field definitions for this instance.
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  /// Returns a short string representation used by generic data views.
  @override
  String getRepresentation() {
    return data?.getSecuritySymbolFromId(fieldSecurity.value) ?? 'Unknown';
  }

  /// Returns a debug-friendly string describing this stock split.
  @override
  String toString() {
    return '${fieldDate.value}|${fieldSecurity.value}|${fieldNumerator.value} for ${fieldDenominator.value}';
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

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
