import 'package:money/helpers/date_helper.dart';
import 'package:money/widgets_data/data/data.dart';
import 'package:money/widgets_data/money_object/fields.dart';
import 'package:money/widgets_data/money_object/money_object.dart';

/*
  cid  name         type      notnull  dflt_value  pk
  ---  -----------  --------  -------  ----------  --
  0    Id           bigint    0                    1
  1    Date         datetime  1                    0
  2    Security     INT       1                    0
  3    Numerator    money     1                    0
  4    Denominator  money     1                    0
 */

class StockSplit extends MoneyObject {
  StockSplit({
    required DateTime? date,
    required int security,
    required int numerator,
    required int denominator,
  }) {
    this.fieldDate.value = date;
    this.fieldSecurity.value = security;
    this.fieldNumerator.value = numerator;
    this.fieldDenominator.value = denominator;
  }

  /// Constructor from a SQLite row
  factory StockSplit.fromJson(final MyJson row) {
    return StockSplit(
      date: row.getDate('Date'),
      security: row.getInt('Security'),
      numerator: row.getInt('Numerator'),
      denominator: row.getInt('Denominator'),
    )..fieldId.value = row.getInt('Id', -1);
  }

  FieldDate fieldDate = FieldDate(
    name: 'Date',
    serializeName: 'Date',
    getValueForDisplay: (final MoneyObject instance) => (instance as StockSplit).fieldDate.value,
    getValueForSerialization: (final MoneyObject instance) =>
        dateToSqliteFormat((instance as StockSplit).fieldDate.value),
  );

  FieldInt fieldDenominator = FieldInt(
    name: 'Denominator',
    serializeName: 'Denominator',
    getValueForDisplay: (final MoneyObject instance) => (instance as StockSplit).fieldDenominator.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as StockSplit).fieldDenominator.value,
  );

  FieldId fieldId = FieldId(
    getValueForDisplay: (final MoneyObject instance) => (instance as StockSplit).uniqueId,
    getValueForSerialization: (final MoneyObject instance) => instance.uniqueId,
  );

  FieldInt fieldNumerator = FieldInt(
    name: 'Numerator',
    serializeName: 'Numerator',
    getValueForDisplay: (final MoneyObject instance) => (instance as StockSplit).fieldNumerator.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as StockSplit).fieldNumerator.value,
  );

  FieldInt fieldSecurity = FieldInt(
    name: 'Security',
    serializeName: 'Security',
    getValueForDisplay: (final MoneyObject instance) => (instance as StockSplit).fieldSecurity.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as StockSplit).fieldSecurity.value,
  );

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  String getRepresentation() {
    return Data().securities.getSymbolFromId(fieldSecurity.value);
  }

  @override
  String toString() {
    return '${fieldDate.value}|${fieldSecurity.value}|${fieldNumerator.value} for ${fieldDenominator.value}';
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<StockSplit> _fields = Fields<StockSplit>();

  static Fields<StockSplit> get fields {
    if (_fields.isEmpty) {
      final StockSplit tmp = StockSplit.fromJson(<String, dynamic>{});
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
