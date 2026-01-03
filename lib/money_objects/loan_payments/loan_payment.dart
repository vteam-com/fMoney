// ignore_for_file: unnecessary_this

import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/money_objects/accounts/account.dart';
import 'package:money/money_objects/data.dart';
import 'package:money/views/adaptive_list/list_item_card.dart';
import 'package:money/widgets_data/money_object.dart';

class LoanPayment extends MoneyObject {
  LoanPayment({
    required final int id,
    required final int accountId,
    required final DateTime? date,
    required final String memo,
    required final double principal,
    required final double interest,
    final String reference = '',
  }) {
    this.fieldId.value = id;
    this.fieldAccountId.value = accountId;
    accountInstance = Data().accounts.get(this.fieldAccountId.value);
    this.fieldDate.value = date;
    this.fieldMemo.value = memo;
    this.fieldPrincipal.value.setAmount(principal);
    this.fieldInterest.value.setAmount(interest);
    this.fieldReference.value = reference;
  }

  /// Constructor from a SQLite row
  factory LoanPayment.fromJson(final MyJson row) {
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
    );
  }

  // Not persisted
  Account? accountInstance;

  /// 1|AccountId|INT|1||0
  Field<int> fieldAccountId = Field<int>(
    name: 'Account',
    serializeName: 'AccountId',
    defaultValue: -1,
    type: FieldType.text,
    getValueForDisplay: (final MoneyObject instance) => Account.getName((instance as LoanPayment).accountInstance),
    getValueForSerialization: (final MoneyObject instance) => (instance as LoanPayment).fieldAccountId.value,
  );

  FieldMoney fieldBalance = FieldMoney(
    name: 'Balance',
    footer: FooterType.range,
    getValueForDisplay: (final MoneyObject instance) => (instance as LoanPayment).fieldBalance.value.asDouble(),
    getValueForSerialization: (final MoneyObject instance) => (instance as LoanPayment).fieldBalance.value.asDouble(),
  );

  /// Date
  /// 2|Date|datetime|1||0
  FieldDate fieldDate = FieldDate(
    serializeName: 'Date',
    getValueForDisplay: (final MoneyObject instance) => (instance as LoanPayment).fieldDate.value,
    getValueForSerialization: (final MoneyObject instance) => dateToIso8601OrDefaultString(
      (instance as LoanPayment).fieldDate.value,
    ),
  );

  /// ID
  /// 0|Id|INT|1||0
  FieldId fieldId = FieldId(
    getValueForSerialization: (final MoneyObject instance) => (instance as LoanPayment).uniqueId,
  );

  /// Interest
  /// 4|Interest|money|0||0
  FieldMoney fieldInterest = FieldMoney(
    name: 'Interest',
    serializeName: 'Interest',
    getValueForDisplay: (final MoneyObject instance) => (instance as LoanPayment).fieldInterest.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as LoanPayment).fieldInterest.value.asDouble(),
  );

  // 5
  // 5|Memo|nvarchar(255)|0||0
  Field<String> fieldMemo = Field<String>(
    type: FieldType.text,
    name: 'Memo',
    serializeName: 'Memo',
    defaultValue: '',
    getValueForDisplay: (final MoneyObject instance) => (instance as LoanPayment).fieldMemo.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as LoanPayment).fieldMemo.value,
  );

  /// 3
  /// 3|Principal|money|0||0
  FieldMoney fieldPrincipal = FieldMoney(
    name: 'Principal',
    serializeName: 'Principal',
    getValueForDisplay: (final MoneyObject instance) => (instance as LoanPayment).fieldPrincipal.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as LoanPayment).fieldPrincipal.value.asDouble(),
  );

  FieldPercentage fieldRate = FieldPercentage(
    name: 'Rate %',
    getValueForDisplay: (final MoneyObject instance) => (instance as LoanPayment).getRate(),
  );

  FieldString fieldReference = FieldString(
    name: 'Reference',
    columnWidth: ColumnWidth.largest,
    getValueForDisplay: (final MoneyObject instance) => (instance as LoanPayment).fieldReference.value,
  );

  FieldMoney payment = FieldMoney(
    name: 'Payment',
    getValueForDisplay: (final MoneyObject instance) => (instance as LoanPayment)._totalPrincipalAndInterest,
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

  static Fields<LoanPayment> get fields {
    if (_fields.isEmpty) {
      final LoanPayment tmpInstance = LoanPayment.fromJson(<String, dynamic>{});
      _fields.setDefinitions(<Field<dynamic>>[
        tmpInstance.fieldId,
        tmpInstance.fieldDate,
        tmpInstance.fieldAccountId,
        tmpInstance.fieldMemo,
        tmpInstance.fieldReference,
        tmpInstance.fieldRate,
        tmpInstance.fieldInterest,
        tmpInstance.fieldPrincipal,
        tmpInstance.fieldBalance,
      ]);
    }
    return _fields;
  }

  static Fields<LoanPayment> get fieldsForColumnView {
    if (_fields.isEmpty) {
      final LoanPayment tmpInstance = LoanPayment.fromJson(<String, dynamic>{});
      _fields.setDefinitions(<Field<dynamic>>[
        tmpInstance.fieldDate,
        tmpInstance.fieldAccountId,
        tmpInstance.fieldMemo,
        tmpInstance.fieldReference,
        tmpInstance.payment,
        tmpInstance.fieldRate,
        tmpInstance.fieldPrincipal,
        tmpInstance.fieldInterest,
        tmpInstance.fieldBalance,
      ]);
    }
    return _fields;
  }

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
