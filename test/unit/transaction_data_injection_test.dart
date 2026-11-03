import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/transaction_entity.dart';

/// Minimal [DataAbstract] fake answering only the lookups these tests exercise.
class _FakeData implements DataAbstract {
  @override
  DataObject? getAccount(int id) => null;

  @override
  String getPayeeName(int id) => 'payee-$id';

  @override
  String getCategoryNameFromId(int id) => 'category-$id';

  @override
  bool isCategoryExpense(int id) => id == 42;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('Transaction resolves lookups through injected data', () {
    final Transaction transaction = Transaction(date: DateTime(2024), data: _FakeData());
    transaction.fieldPayee.value = 7;
    transaction.fieldCategoryId.value = 42;

    expect(transaction.payeeName, 'payee-7');
    expect(transaction.categoryName, 'category-42');
    expect(transaction.isExpense, isTrue);
  });

  test('Transaction.fromJSon forwards injected data', () {
    final DataAbstract fake = _FakeData();
    final Transaction source = Transaction(date: DateTime(2024), data: fake);
    source.fieldPayee.value = 3;

    final Transaction transaction = Transaction.fromJSon(source.getPersistableJSon(), 0, data: fake);

    expect(transaction.data, same(fake));
    expect(transaction.payeeName, 'payee-3');
  });
}
