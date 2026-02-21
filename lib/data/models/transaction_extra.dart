import 'package:money/helpers/json_helper.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';

/*
  SQLite table definition
  0    Id           INT       0                    1
  1    Transaction  bigint    1                    0
  2    TaxYear      INT       1                    0
  3    TaxDate      datetime  0                    0
 */

/// Represents transaction extra.
class TransactionExtra extends DataObject {
  /// Constructor
  TransactionExtra({
    // 0
    required int id,
    // 1
    required int transaction,
    // 2
    required int taxYear,
    // 3
    required DateTime? taxDate,
  }) {
    this.fieldId.value = id;
    this.fieldTransaction.value = transaction;
    this.fieldTaxYear.value = taxYear;
    this.fieldTaxDate.value = taxDate;
  }

  factory TransactionExtra.fromJson(final MyJson row) {
    final TransactionExtra t = TransactionExtra(
      // id
      id: row.getInt('Id', -1),
      // Transaction Id
      transaction: row.getInt('Transaction', -1),
      // Tax Year
      taxYear: row.getInt('TaxYear'),
      // Tax Date
      taxDate: row.getDate('TaxDate'),
    );

    return t;
  }

  /// ID
  /// SQLite  0|Id|bigint|0||1
  FieldId fieldId = FieldId(
    getValueForSerialization: (final DataInterface instance) => (instance as TransactionExtra).uniqueId,
  );

  // 4
  FieldDate fieldTaxDate = FieldDate(
    serializeName: 'TaxDate',
    getValueForSerialization: (final DataInterface instance) => (instance as TransactionExtra).fieldTaxDate.value,
  );

  // 2
  FieldInt fieldTaxYear = FieldInt(
    serializeName: 'TaxYear',
    getValueForSerialization: (final DataInterface instance) => (instance as TransactionExtra).fieldTaxYear.value,
  );

  // 1
  FieldInt fieldTransaction = FieldInt(
    serializeName: 'Transaction',
    getValueForSerialization: (final DataInterface instance) => (instance as TransactionExtra).fieldTransaction.value,
  );

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<TransactionExtra> _fields = Fields<TransactionExtra>();

  /// Returns the field definitions for TransactionExtra entities.
  static Fields<TransactionExtra> get fields {
    if (_fields.isEmpty) {
      final TransactionExtra tmp = TransactionExtra.fromJson(
        <String, dynamic>{},
      );
      _fields.setDefinitions(<Field<dynamic>>[
        tmp.fieldId,
        tmp.fieldTaxDate,
        tmp.fieldTaxYear,
        tmp.fieldTransaction,
      ]);
    }
    return _fields;
  }
}
