import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/field_definition_cache_helper.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

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

  factory TransactionExtra.fromJson(MyJson row) {
    final TransactionExtra t = TransactionExtra(
      // id
      id: row.getInt(SharedDomainStrings.domainString057, -1),
      // Transaction Id
      transaction: row.getInt(SharedDomainStrings.domainString141, -1),
      // Tax Year
      taxYear: row.getInt(SharedDomainStrings.domainString136),
      // Tax Date
      taxDate: row.getDate(SharedDomainStrings.domainString133),
    );

    return t;
  }

  /// ID
  /// SQLite  0|Id|bigint|0||1
  FieldId fieldId = FieldId(
    getValueForSerialization: (DataInterface instance) => (instance as TransactionExtra).uniqueId,
  );

  // 4
  FieldDate fieldTaxDate = FieldDate(
    serializeName: SharedDomainStrings.domainString133,
    getValueForSerialization: (DataInterface instance) => (instance as TransactionExtra).fieldTaxDate.value,
  );

  // 2
  FieldInt fieldTaxYear = FieldInt(
    serializeName: SharedDomainStrings.domainString136,
    getValueForSerialization: (DataInterface instance) => (instance as TransactionExtra).fieldTaxYear.value,
  );

  // 1
  FieldInt fieldTransaction = FieldInt(
    serializeName: SharedDomainStrings.domainString141,
    getValueForSerialization: (DataInterface instance) => (instance as TransactionExtra).fieldTransaction.value,
  );

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(int value) => fieldId.value = value;

  static final Fields<TransactionExtra> _fields = Fields<TransactionExtra>();

  /// Builds [TransactionExtra] field definitions for cache initialization.
  static FieldDefinitions _buildFieldDefinitions(TransactionExtra tmp) => <Field<dynamic>>[
    tmp.fieldId,
    tmp.fieldTaxDate,
    tmp.fieldTaxYear,
    tmp.fieldTransaction,
  ];

  /// Returns the field definitions for TransactionExtra entities.
  static Fields<TransactionExtra> get fields => ensureCachedFieldDefinitions<TransactionExtra>(
    cache: _fields,
    instanceFactory: () => TransactionExtra.fromJson(<String, dynamic>{}),
    definitionsBuilder: _buildFieldDefinitions,
  );
}
