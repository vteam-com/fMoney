import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/pairs_model.dart';
import 'package:money/shared/domain/categories_collection.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  late Categories categories;

  setUp(() {
    resetTestData();
    categories = Data().categories;
  });

  tearDown(() => Data().clearExistingData());

  test('the first category gets id 0 and still has a category tree', () {
    final Category food = categories.addNewCategory(name: 'Food');
    final Category lunch = categories.addNewCategory(parentId: food.uniqueId, name: 'Lunch');

    expect(food.uniqueId, 0);
    expect(categories.getTreeIds(food.uniqueId), <int>[food.uniqueId, lunch.uniqueId]);
    expect(categories.getTreeIds(-1), isEmpty, reason: 'the unset id names no category');
  });

  test('reparenting a category with id 0 renames its children', () {
    final Category food = categories.addNewCategory(name: 'Food');
    final Category lunch = categories.addNewCategory(parentId: food.uniqueId, name: 'Lunch');
    final Category home = categories.addNewCategory(name: 'Home');

    expect(categories.reparentCategory(food, home), isTrue);

    expect(food.fieldName.value, 'Home:Food');
    expect(lunch.fieldName.value, 'Home:Food:Lunch');
  });

  test('ancestors and descendants list each category once', () {
    final Category food = categories.addNewCategory(name: 'Food');
    final Category lunch = categories.addNewCategory(parentId: food.uniqueId, name: 'Lunch');
    final Category snack = categories.addNewCategory(parentId: lunch.uniqueId, name: 'Snack');

    expect(categories.ancestorsOf(snack), <Category>[lunch, food]);
    expect(categories.descendantIdsOf(food.uniqueId), <int>[lunch.uniqueId, snack.uniqueId]);
    expect(categories.getTopAncestor(snack), same(food));
    expect(categories.getTopAncestor(food), same(food));
    expect(categories.isSameOrDescendantOf(snack, food), isTrue);
    expect(categories.isSameOrDescendantOf(food, food), isTrue);
    expect(categories.isSameOrDescendantOf(food, snack), isFalse);

    final List<Category> descendants = <Category>[];
    food.getDescendants(descendants);
    expect(descendants, <Category>[lunch, snack]);
  });

  test('tree walks stop when the stored hierarchy loops', () {
    final Category a = categories.addNewCategory(name: 'A');
    final Category b = categories.addNewCategory(parentId: a.uniqueId, name: 'B');
    a.fieldParentId.value = b.uniqueId; // A <-> B

    expect(categories.ancestorsOf(b), <Category>[a]);
    expect(categories.descendantIdsOf(a.uniqueId), <int>[b.uniqueId]);
    expect(categories.getTopAncestor(b), same(a));
    expect(b.getColorOrAncestorsColor(), const Color(0x00000000));

    final Transaction transaction = createTestTransaction(createTestAccount(), 'Grocer', category: b);
    transaction.fieldAmount.value.setAmount(-10);
    categories.onAllDataLoaded();
    expect(a.fieldTransactionCountRollup.value, 1);
    expect(b.fieldTransactionCountRollup.value, 1);
  });

  test('descendants leave out deleted categories and the branches under them', () {
    final Category food = categories.addNewCategory(name: 'Food');
    final Category lunch = categories.addNewCategory(parentId: food.uniqueId, name: 'Lunch');
    categories.addNewCategory(parentId: lunch.uniqueId, name: 'Snack');
    final Category dinner = categories.addNewCategory(parentId: food.uniqueId, name: 'Dinner');
    lunch.mutation = MutationType.deleted;

    expect(categories.getTreeIds(food.uniqueId), <int>[food.uniqueId, dinner.uniqueId]);

    final List<Category> descendants = <Category>[];
    food.getDescendants(descendants);
    expect(descendants, <Category>[dinner]);
  });

  test('a category without a color takes the color of its nearest colored ancestor', () {
    final Category food = categories.addNewCategory(name: 'Food', color: '#FF0000');
    final Category lunch = categories.addNewCategory(parentId: food.uniqueId, name: 'Lunch');
    final Category snack = categories.addNewCategory(parentId: lunch.uniqueId, name: 'Snack');

    final Pair<Color, int> colorAndLevel = snack.getColorAndLevel(0);
    expect(colorAndLevel.first, food.getColorOrAncestorsColor());
    expect(colorAndLevel.second, 2);
    expect(food.getColorAndLevel(0).second, 0);
  });

  test('naming a category never creates the Split category', () {
    final Category food = categories.addNewCategory(name: 'Food');

    expect(categories.getNameFromId(food.uniqueId), 'Food');
    expect(categories.getNameFromId(-1), '');
    expect(categories.getNameFromId(99), '');
    expect(categories.getByName('Split'), isNull);

    final Category split = categories.split;
    expect(categories.getNameFromId(split.uniqueId), '<Split>');
  });
}
