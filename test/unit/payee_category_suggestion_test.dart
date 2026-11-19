import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/entity_widgets/transaction_widgets_helper.dart';
import 'package:money/widgets/pickers/category_picker_widget.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  late Account checking;
  late Payee grocer;
  late Category food;
  late Category household;

  /// Creates a transaction for [payee] in [category] (none when null).
  Transaction transactionFor(Payee payee, Category? category, {bool isTransfer = false}) =>
      createTestTransaction(checking, payee.fieldName.value, category: category, isTransfer: isTransfer);

  setUp(() {
    resetTestData();
    checking = createTestAccount();
    grocer = Data().payees.getOrCreate('Grocer', fireNotification: false);
    food = Data().categories.addNewCategory(name: 'Food');
    household = Data().categories.addNewCategory(name: 'Household');
  });

  test('categories used by a payee are ranked by use, ignoring transfers, splits and blanks', () {
    transactionFor(grocer, household);
    transactionFor(grocer, food);
    transactionFor(grocer, food);
    transactionFor(grocer, null);
    transactionFor(grocer, Data().categories.addNewCategory(name: 'Moved'), isTransfer: true);
    transactionFor(grocer, Data().categories.split);

    expect(Data().getCategoryCountsForPayee(grocer.uniqueId), <int, int>{food.uniqueId: 2, household.uniqueId: 1});
    expect(Data().getCategoryCountsForPayee(grocer.uniqueId).keys.first, food.uniqueId, reason: 'most used first');
    expect(Data().getCategoryCountsForPayee(-1), isEmpty);
  });

  group('applyCategoryFromPayeeHistory', () {
    test('applies the only category the payee uses', () {
      transactionFor(grocer, food);
      final Transaction t = transactionFor(grocer, null);

      expect(t.applyCategoryFromPayeeHistory(), isTrue);
      expect(t.fieldCategoryId.value, food.uniqueId);
    });

    test('leaves the category alone when the payee uses several or it already has one', () {
      transactionFor(grocer, food);
      transactionFor(grocer, household);
      final Transaction uncategorized = transactionFor(grocer, null);
      final Transaction categorized = transactionFor(grocer, household);

      expect(uncategorized.applyCategoryFromPayeeHistory(), isFalse);
      expect(uncategorized.fieldCategoryId.value, -1);
      expect(categorized.applyCategoryFromPayeeHistory(), isFalse);
      expect(categorized.fieldCategoryId.value, household.uniqueId);
    });
  });

  test('import and alias apply give new transactions the payee category', () {
    transactionFor(grocer, food);
    createTestAlias('GROCER.*', grocer);

    final Transaction imported = Transaction.fromDateDescriptionAmount(checking, DateTime(2024), 'GROCER #12', -9);
    expect(imported.fieldCategoryId.value, food.uniqueId);

    final Transaction existing = createTestTransaction(checking, 'GROCER #40');
    Data().applyAlias(Data().aliases.iterableList().first);
    expect(existing.fieldCategoryId.value, food.uniqueId);
  });

  test('suggested category names skip the current one and keep the top three', () {
    final List<Category> categories = <Category>[
      for (final String name in <String>['A', 'B', 'C', 'D']) Data().categories.addNewCategory(name: name),
    ];
    for (int i = 0; i < categories.length; i++) {
      for (int count = 0; count < 4 - i; count++) {
        transactionFor(grocer, categories[i]);
      }
    }

    expect(suggestedCategoryNamesForPayee(grocer.uniqueId), <String>['A', 'B', 'C']);
    expect(suggestedCategoryNamesForPayee(grocer.uniqueId, excludeCategoryId: categories[1].uniqueId), <String>[
      'A',
      'C',
      'D',
    ]);
  });

  testWidgets('suggestion chips report the tapped name and the picker shows an outside change', (
    WidgetTester tester,
  ) async {
    final List<String> tapped = <String>[];
    String selected = 'Food';
    late StateSetter setOuterState;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext _, StateSetter setState) {
              setOuterState = setState;
              return Column(
                children: <Widget>[
                  PickerEditBox(
                    title: 'Category',
                    items: const <String>['Food'],
                    initialValue: selected,
                    onChanged: (_) {},
                  ),
                  categorySuggestions(categoryNames: const <String>['Household'], onSelected: tapped.add),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Household'));
    expect(tapped, <String>['Household']);

    setOuterState(() => selected = 'Household');
    await tester.pump();
    expect(find.widgetWithText(PickerEditBox, 'Household'), findsOneWidget);
  });
}
