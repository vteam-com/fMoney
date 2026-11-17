import 'package:flutter_test/flutter_test.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';

void main() {
  setUp(() {
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
  });

  test('addNewCategory keeps the parent prefix when the child name is already taken', () {
    final Category parent = Data().categories.addNewCategory(name: 'Food');
    final Category first = Data().categories.addNewCategory(parentId: parent.uniqueId, name: 'Lunch');
    final Category second = Data().categories.addNewCategory(parentId: parent.uniqueId, name: 'Lunch');

    expect(first.fieldName.value, 'Food:Lunch');
    expect(second.fieldName.value, 'Food:Lunch 1');
  });

  test('category and payee name lookups ignore case, like accounts and securities', () {
    final Category food = Data().categories.addNewCategory(name: 'Food');
    expect(Data().categories.getByName('FOOD'), same(food));
    expect(Data().categories.getIdByName('food'), food.uniqueId);

    final Payee amazon = Data().payees.getOrCreate('Amazon');
    expect(Data().payees.getOrCreate('AMAZON'), same(amazon));
    expect(Data().payees.length, 1);
  });
}
