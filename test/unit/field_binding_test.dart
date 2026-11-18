import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/shared/domain/account_alias_entity.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/loan_payment_entity.dart';
import 'package:money/shared/domain/online_account_entity.dart';
import 'package:money/shared/domain/rental_unit_entity.dart';
import 'package:money/shared/domain/security_entity.dart';
import 'package:money/shared/domain/transaction_extra_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';

/// Returns the display value of the field serialized as [serializeName] on [row].
dynamic _display(DataObject row, String serializeName) =>
    row.fieldDefinitions.firstWhere((Field<dynamic> f) => f.serializeName == serializeName).getValueForDisplay(row);

void main() {
  test('fields declared without callbacks save and show each row value, not the template value', () {
    final AccountAlias alias = AccountAlias.fromJson(<String, dynamic>{
      'Id': 3,
      'Pattern': 'ACME*',
      'Flags': 2,
      'AccountId': '42',
    });

    final MyJson saved = alias.getPersistableJSon();
    expect(saved['Pattern'], 'ACME*');
    expect(saved['AccountId'], '42');
    expect(saved['Flags'], 2);
    expect(_display(alias, 'Id'), '3');
  });

  test('display reads the row for entities with hand-built field lists', () {
    final RentUnit unit = RentUnit.fromJson(<String, dynamic>{'Id': 7, 'Name': 'Unit B', 'Building': 1});
    expect(_display(unit, 'Name'), 'Unit B');

    final OnlineAccount online = OnlineAccount.fromJson(<String, dynamic>{'Id': 5, 'Name': 'My Bank'});
    expect(_display(online, 'Name'), 'My Bank');
    expect(_display(online, 'Id'), '5');
  });

  test('online accounts write back every column they were loaded with', () {
    final OnlineAccount online = OnlineAccount.fromJson(<String, dynamic>{
      'Id': 5,
      'Name': 'My Bank',
      'OFX': 'https://ofx.example',
      'FID': '1234',
      'BrokerId': 'broker',
      'UserKeyExpireDate': '2027-01-01 00:00:00',
    });

    final MyJson saved = online.getPersistableJSon();
    expect(saved['OFX'], 'https://ofx.example');
    expect(saved['FID'], '1234');
    expect(saved['BrokerId'], 'broker');
    expect(saved['UserKeyExpireDate'], '2027-01-01 00:00:00');
    expect(saved['Password'], isNull);
  });

  test('columns saved under the names they are loaded from', () {
    final Security security = Security.fromJson(<String, dynamic>{'Id': 1, 'Symbol': 'ABC', 'TAXABLE': 1});
    expect(security.taxable.value, 1);
    expect(security.getPersistableJSon()['TAXABLE'], 1);

    final Category category = Category.fromJson(<String, dynamic>{'Id': 1, 'Name': 'Food', 'Balance': 12.5});
    expect(category.getPersistableJSon()['Balance'], 12.5);
  });

  test('SyncGuid saves the GUID itself, and an empty one as null', () {
    final Account account = Account()..fieldSyncGuid.value = 'abc-123';
    expect(account.getPersistableJSon()['SyncGuid'], 'abc-123');
    account.fieldSyncGuid.value = '';
    expect(account.getPersistableJSon()['SyncGuid'], isNull);
  });

  test('TaxDate is saved as quoted SQL text', () {
    final TransactionExtra extra = TransactionExtra.fromJson(<String, dynamic>{
      'Id': 1,
      'Transaction': 2,
      'TaxDate': '2024-03-15T00:00:00.000',
    });
    final dynamic taxDate = extra.getPersistableJSon()['TaxDate'];
    expect(taxDate, isA<String>());
    expect(encodeValueWrapStringTypes(taxDate), startsWith("'2024-03-15"));
  });

  test('a loan payment links to its own account', () {
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
    addTearDown(() {
      Data().clearExistingData();
      DataFileController.instance = null;
    });
    final Account account = Data().accounts.appendNewMoneyObject(
      Account()..fieldName.value = 'Mortgage',
      fireNotification: false,
    ) as Account;

    final LoanPayment payment = LoanPayment(
      id: 1,
      accountId: account.uniqueId,
      date: DateTime(2024, 1, 1),
      memo: '',
      principal: 100,
      interest: 5,
      data: Data(),
    );
    expect(payment.accountInstance, same(account));
  });

  test("editing an investment's symbol points it at that security", () {
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
    addTearDown(() {
      Data().clearExistingData();
      DataFileController.instance = null;
    });
    final Security security = Data().securities.appendNewMoneyObject(
      Security.fromJson(<String, dynamic>{'Symbol': 'ABC', 'Name': 'Abc Corp'}),
      fireNotification: false,
    ) as Security;
    final Investment investment = Investment(
      id: 1,
      security: -1,
      unitPrice: 10,
      units: 1,
      investmentType: 0,
      tradeType: 0,
      data: Data(),
    );
    final Field<dynamic> symbolField = investment.fieldDefinitions.firstWhere(
      (Field<dynamic> f) => f.name == 'Symbol',
    );

    symbolField.setValue!(investment, 'ABC');
    expect(investment.fieldSecurity.value, security.uniqueId);
    expect(investment.symbol, 'ABC');

    symbolField.setValue!(investment, 'NOPE');
    expect(investment.fieldSecurity.value, security.uniqueId);
  });
}
