// ignore_for_file: unnecessary_this

import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/views/providers/account.dart';
import 'package:money/views/providers/data_abstract.dart';
import 'package:money/views/providers/field_definition_cache.dart';
import 'package:money/widgets/adaptive_list/list_item_card.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/field_type.dart';

/// Represents loan payment.
class LoanPayment extends DataObject {
  /// Constructor from a SQLite row
  factory LoanPayment.fromJson(final MyJson row, final DataAbstract data) {
    return LoanPayment(
      // 0
      id: row.getInt('Id', -1),
      // 1
      accountId: row.getInt('AccountId', -1),
      // 2
      date: row.getDate('Date'),
      // 3
      principal: row.getDouble('Principal'),
      // 4
      interest: row.getDouble('Interest'),
      // 3
      memo: row.getString('Memo'),
      data: data,
    );
  }
  LoanPayment({
    required final int id,
    required final int accountId,
    required final DateTime? date,
    required final String memo,
    required final double principal,
    required final double interest,
    final String reference = '',
    DataAbstract? data,
  }) {
    if (data != null) {
      this.data = data;
      accountInstance = data.getAccount(this.fieldAccountId.value) as Account?;
    }
    this.fieldId.value = id;
    this.fieldAccountId.value = accountId;
    this.fieldDate.value = date;
    this.fieldMemo.value = memo;
    this.fieldPrincipal.value.setAmount(principal);
    this.fieldInterest.value.setAmount(interest);
    this.fieldReference.value = reference;
  }

  late DataAbstract data;

  // Not persisted
  Account? accountInstance;

  /// 1|AccountId|INT|1||0
  Field<int> fieldAccountId = Field<int>(
    name: 'Account',
    serializeName: 'AccountId',
    defaultValue: -1,
    type: FieldType.text,
    getValueForDisplay: (final DataInterface instance) => Account.getName((instance as LoanPayment).accountInstance),
    getValueForSerialization: (final DataInterface instance) => (instance as LoanPayment).fieldAccountId.value,
  );

  FieldMoney fieldBalance = FieldMoney(
    name: 'Balance',
    footer: FooterType.range,
    getValueForDisplay: (final DataInterface instance) => (instance as LoanPayment).fieldBalance.value.asDouble(),
    getValueForSerialization: (final DataInterface instance) => (instance as LoanPayment).fieldBalance.value.asDouble(),
  );

  /// Date
  /// 2|Date|datetime|1||0
  FieldDate fieldDate = FieldDate(
    serializeName: 'Date',
    getValueForDisplay: (final DataInterface instance) => (instance as LoanPayment).fieldDate.value,
    getValueForSerialization: (final DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as LoanPayment).fieldDate.value,
    ),
  );

  /// ID
  /// 0|Id|INT|1||0
  FieldId fieldId = FieldId(
    getValueForSerialization: (final DataInterface instance) => (instance as LoanPayment).uniqueId,
  );

  /// Interest
  /// 4|Interest|money|0||0
  FieldMoney fieldInterest = FieldMoney(
    name: 'Interest',
    serializeName: 'Interest',
    getValueForDisplay: (final DataInterface instance) => (instance as LoanPayment).fieldInterest.value,
    getValueForSerialization: (final DataInterface instance) =>
        (instance as LoanPayment).fieldInterest.value.asDouble(),
  );

  // 5
  // 5|Memo|nvarchar(255)|0||0
  Field<String> fieldMemo = Field<String>(
    type: FieldType.text,
    name: 'Memo',
    serializeName: 'Memo',
    defaultValue: '',
    getValueForDisplay: (final DataInterface instance) => (instance as LoanPayment).fieldMemo.value,
    getValueForSerialization: (final DataInterface instance) => (instance as LoanPayment).fieldMemo.value,
  );

  /// 3
  /// 3|Principal|money|0||0
  FieldMoney fieldPrincipal = FieldMoney(
    name: 'Principal',
    serializeName: 'Principal',
    getValueForDisplay: (final DataInterface instance) => (instance as LoanPayment).fieldPrincipal.value,
    getValueForSerialization: (final DataInterface instance) =>
        (instance as LoanPayment).fieldPrincipal.value.asDouble(),
  );

  FieldPercentage fieldRate = FieldPercentage(
    name: 'Rate %',
    getValueForDisplay: (final DataInterface instance) => (instance as LoanPayment).getRate(),
  );

  FieldString fieldReference = FieldString(
    name: 'Reference',
    columnWidth: ColumnWidth.largest,
    getValueForDisplay: (final DataInterface instance) => (instance as LoanPayment).fieldReference.value,
  );

  FieldMoney payment = FieldMoney(
    name: 'Payment',
    getValueForDisplay: (final DataInterface instance) => (instance as LoanPayment)._totalPrincipalAndInterest,
  );

  @override
  Widget buildFieldsAsWidgetForSmallScreen() {
    return MyListItemAsCard(
      leftTopAsString: Account.getName(accountInstance),
      rightTopAsString: getAmountAsStringUsingCurrency(fieldPrincipal),
      rightBottomAsString: getAmountAsStringUsingCurrency(
        fieldInterest,
      ),
    );
  }

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  String getRepresentation() {
    // This can be improved
    return 'Loan $uniqueId';
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<LoanPayment> _fields = Fields<LoanPayment>();
  static final Fields<LoanPayment> _fieldsForColumns = Fields<LoanPayment>();
  static final List<FieldBlueprint<LoanPayment>> _fieldBlueprints = <FieldBlueprint<LoanPayment>>[
    FieldBlueprint<LoanPayment>(selector: (LoanPayment tmpInstance) => tmpInstance.fieldId),
    FieldBlueprint<LoanPayment>(
      selector: (LoanPayment tmpInstance) => tmpInstance.fieldDate,
      includeInColumnView: true,
    ),
    FieldBlueprint<LoanPayment>(
      selector: (LoanPayment tmpInstance) => tmpInstance.fieldAccountId,
      includeInColumnView: true,
    ),
    FieldBlueprint<LoanPayment>(
      selector: (LoanPayment tmpInstance) => tmpInstance.fieldMemo,
      includeInColumnView: true,
    ),
    FieldBlueprint<LoanPayment>(
      selector: (LoanPayment tmpInstance) => tmpInstance.fieldReference,
      includeInColumnView: true,
    ),
    FieldBlueprint<LoanPayment>(
      selector: (LoanPayment tmpInstance) => tmpInstance.payment,
      includeInEntity: false,
      includeInColumnView: true,
    ),
    FieldBlueprint<LoanPayment>(
      selector: (LoanPayment tmpInstance) => tmpInstance.fieldRate,
      includeInColumnView: true,
    ),
    FieldBlueprint<LoanPayment>(selector: (LoanPayment tmpInstance) => tmpInstance.fieldInterest),
    FieldBlueprint<LoanPayment>(
      selector: (LoanPayment tmpInstance) => tmpInstance.fieldPrincipal,
      includeInColumnView: true,
    ),
    FieldBlueprint<LoanPayment>(
      selector: (LoanPayment tmpInstance) => tmpInstance.fieldInterest,
      includeInEntity: false,
      includeInColumnView: true,
    ),
    FieldBlueprint<LoanPayment>(
      selector: (LoanPayment tmpInstance) => tmpInstance.fieldBalance,
      includeInColumnView: true,
    ),
  ];

  /// Creates a lightweight static [LoanPayment] used only for field list assembly.
  static LoanPayment _createStaticFieldInstance() {
    return LoanPayment(
      id: -1,
      accountId: -1,
      date: null,
      memo: '',
      principal: 0.0,
      interest: 0.0,
      data: null, // Not used in static context
    );
  }

  /// Returns the field definitions for LoanPayment entities.
  static Fields<LoanPayment> get fields => ensureCachedFieldDefinitionsFromBlueprints<LoanPayment>(
    cache: _fields,
    instanceFactory: _createStaticFieldInstance,
    blueprints: _fieldBlueprints,
    forColumnView: false,
  );

  /// Returns the field definitions for LoanPayment column view.
  static Fields<LoanPayment> get fieldsForColumnView => ensureCachedFieldDefinitionsFromBlueprints<LoanPayment>(
    cache: _fieldsForColumns,
    instanceFactory: _createStaticFieldInstance,
    blueprints: _fieldBlueprints,
    forColumnView: true,
  );

  /// Calculates the annualized interest rate based on interest and principal change.
  double getRate() {
    final double previousBalance = this.fieldBalance.value.asDouble() - this.fieldPrincipal.value.asDouble();
    if (previousBalance == 0) {
      return 0.00;
    }

    // Calculate the monthly interest rate
    final double annualInterestRate =
        (this.fieldInterest.value.asDouble() * 12) // Convert to annual interest rate
        /
        previousBalance;

    return annualInterestRate.abs();
  }

  double get _totalPrincipalAndInterest => this.fieldPrincipal.value.asDouble() + this.fieldInterest.value.asDouble();
}
