import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/rental_unit_entity.dart';
import 'package:money/shared/domain/transaction_extra_entity.dart';

/// Numeric columns with a custom serializer but no custom display value must
/// persist the instance value, not the field default.
void main() {
  test('Account persists OnlineAccount and ReconcileWarning', () {
    final Account account = Account()
      ..fieldOnlineAccount.value = 5
      ..fieldReconcileWarning.value = 7;
    final MyJson json = account.getPersistableJSon();
    expect(json['OnlineAccount'], 5);
    expect(json['ReconcileWarning'], 7);
  });

  test('Category persists Frequency and TaxRefNum', () {
    final Category category = Category(id: 1, name: 'c', type: CategoryType.expense)
      ..fieldFrequency.value = 3
      ..fieldTaxRefNum.value = 9;
    final MyJson json = category.getPersistableJSon();
    expect(json['Frequency'], 3);
    expect(json['TaxRefNum'], 9);
  });

  test('RentUnit persists Building', () {
    final RentUnit unit = RentUnit()..fieldBuilding.value = 4;
    expect(unit.getPersistableJSon()['Building'], 4);
  });

  test('TransactionExtra persists Transaction and TaxYear', () {
    final TransactionExtra extra = TransactionExtra(id: 1, transaction: 11, taxYear: 2024, taxDate: null);
    final MyJson json = extra.getPersistableJSon();
    expect(json['Transaction'], 11);
    expect(json['TaxYear'], 2024);
  });
}
