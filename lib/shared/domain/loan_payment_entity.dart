// ignore_for_file: unnecessary_this

import 'package:money/data/models/field_type_enum.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/field_definition_cache_helper.dart';
import 'package:money/widgets/list/list_item_card.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

/// Represents loan payment.
class LoanPayment extends DataObject {
  /// Constructor from a SQLite row
  factory LoanPayment.fromJson(MyJson row, DataAbstract data) {
    return LoanPayment(
      // 0
      id: row.getInt(SharedDomainStrings.domainString057, -1),
      // 1
      accountId: row.getInt(SharedDomainStrings.domainString013, -1),
      // 2
      date: row.getDate(SharedDomainStrings.domainString044),
      // 3
      principal: row.getDouble(SharedDomainStrings.domainString110),
      // 4
      interest: row.getDouble(SharedDomainStrings.domainString059),
      // 3
      memo: row.getString(SharedDomainStrings.domainString086),
      data: data,
    );
  }
  LoanPayment({
    required int id,
    required int accountId,
    required DateTime? date,
    required String memo,
    required double principal,
    required double interest,
    String reference = '',
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
    name: SharedDomainStrings.domainString011,
    serializeName: SharedDomainStrings.domainString013,
    defaultValue: -1,
    type: FieldType.text,
    getValueForDisplay: (DataInterface instance) => Account.getName((instance as LoanPayment).accountInstance),
    getValueForSerialization: (DataInterface instance) => (instance as LoanPayment).fieldAccountId.value,
  );

  FieldMoney fieldBalance = FieldMoney(
    name: SharedDomainStrings.domainString019,
    footer: FooterType.range,
    getValueForDisplay: (DataInterface instance) => (instance as LoanPayment).fieldBalance.value.asDouble(),
    getValueForSerialization: (DataInterface instance) => (instance as LoanPayment).fieldBalance.value.asDouble(),
  );

  /// Date
  /// 2|Date|datetime|1||0
  FieldDate fieldDate = FieldDate(
    serializeName: SharedDomainStrings.domainString044,
    getValueForDisplay: (DataInterface instance) => (instance as LoanPayment).fieldDate.value,
    getValueForSerialization: (DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as LoanPayment).fieldDate.value,
    ),
  );

  /// ID
  /// 0|Id|INT|1||0
  FieldId fieldId = FieldId(
    getValueForSerialization: (DataInterface instance) => (instance as LoanPayment).uniqueId,
  );

  /// Interest
  /// 4|Interest|money|0||0
  FieldMoney fieldInterest = FieldMoney(
    name: SharedDomainStrings.domainString059,
    serializeName: SharedDomainStrings.domainString059,
    getValueForDisplay: (DataInterface instance) => (instance as LoanPayment).fieldInterest.value,
    getValueForSerialization: (DataInterface instance) => (instance as LoanPayment).fieldInterest.value.asDouble(),
  );

  // 5
  // 5|Memo|nvarchar(255)|0||0
  Field<String> fieldMemo = Field<String>(
    type: FieldType.text,
    name: SharedDomainStrings.domainString086,
    serializeName: SharedDomainStrings.domainString086,
    defaultValue: '',
    getValueForDisplay: (DataInterface instance) => (instance as LoanPayment).fieldMemo.value,
    getValueForSerialization: (DataInterface instance) => (instance as LoanPayment).fieldMemo.value,
  );

  /// 3
  /// 3|Principal|money|0||0
  FieldMoney fieldPrincipal = FieldMoney(
    name: SharedDomainStrings.domainString110,
    serializeName: SharedDomainStrings.domainString110,
    getValueForDisplay: (DataInterface instance) => (instance as LoanPayment).fieldPrincipal.value,
    getValueForSerialization: (DataInterface instance) => (instance as LoanPayment).fieldPrincipal.value.asDouble(),
  );

  FieldPercentage fieldRate = FieldPercentage(
    name: 'Rate %',
    getValueForDisplay: (DataInterface instance) => (instance as LoanPayment).getRate(),
  );

  FieldString fieldReference = FieldString(
    name: 'Reference',
    columnWidth: ColumnWidth.largest,
    getValueForDisplay: (DataInterface instance) => (instance as LoanPayment).fieldReference.value,
  );

  FieldMoney payment = FieldMoney(
    name: 'Payment',
    getValueForDisplay: (DataInterface instance) => (instance as LoanPayment)._totalPrincipalAndInterest,
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
    return '${SharedDomainStrings.domainString083}$uniqueId';
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(int value) => fieldId.value = value;

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
