import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/entity_widgets/transaction_widgets_helper.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/widgets/pickers/category_picker_widget.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';

/// Creates and appends a transaction on [account] for [payee] in [category] (none when null).
Transaction _createTransaction(Account account, Payee payee, Category? category, {bool isTransfer = false}) {
  final Transaction transaction = Transaction(date: DateTime(2024, 5, 1));
  transaction.fieldAccountId.value = account.uniqueId;
  transaction.fieldPayee.value = payee.uniqueId;
  transaction.fieldCategoryId.value = category?.uniqueId ?? -1;
  transaction.fieldTransfer.value = isTransfer ? 1 : -1;
  transaction.fieldTransferSplit.value = -1;
  Data().appendNewTransaction(transaction, fireNotification: false);
  return transaction;
}

void main() {
  late Account checking;
  late Payee grocer;
  late Category food;
  late Category household;

  setUp(() {
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
    DataAbstract.instance = Data();
    final Account account = Account();
    account.fieldName.value = 'Checking';
    account.fieldCurrency.value = 'USD';
    checking = Data().accounts.appendNewMoneyObject(account, fireNotification: false) as Account;
    grocer = Data().payees.getOrCreate('Grocer', fireNotification: false);
    food = Data().categories.addNewCategory(name: 'Food');
    household = Data().categories.addNewCategory(name: 'Household');
  });

  test('categories used by a payee are ranked by use, ignoring transfers, splits and blanks', () {
    _createTransaction(checking, grocer, household);
    _createTransaction(checking, grocer, food);
    _createTransaction(checking, grocer, food);
    _createTransaction(checking, grocer, null);
    _createTransaction(checking, grocer, Data().categories.addNewCategory(name: 'Moved'), isTransfer: true);
    _createTransaction(checking, grocer, Data().categories.split);

    expect(Data().getCategoryIdsUsedByPayee(grocer.uniqueId), <int>[food.uniqueId, household.uniqueId]);
    expect(Data().getCategoryIdsUsedByPayee(-1), isEmpty);
  });

  group('applyCategoryFromPayeeHistory', () {
    test('applies the only category the payee uses', () {
      _createTransaction(checking, grocer, food);
      final Transaction t = _createTransaction(checking, grocer, null);

      expect(t.applyCategoryFromPayeeHistory(), isTrue);
      expect(t.fieldCategoryId.value, food.uniqueId);
    });

    test('leaves the category alone when the payee uses several or it already has one', () {
      _createTransaction(checking, grocer, food);
      _createTransaction(checking, grocer, household);
      final Transaction uncategorized = _createTransaction(checking, grocer, null);
      final Transaction categorized = _createTransaction(checking, grocer, household);

      expect(uncategorized.applyCategoryFromPayeeHistory(), isFalse);
      expect(uncategorized.fieldCategoryId.value, -1);
      expect(categorized.applyCategoryFromPayeeHistory(), isFalse);
      expect(categorized.fieldCategoryId.value, household.uniqueId);
    });
  });

  test('import and alias apply give new transactions the payee category', () {
    _createTransaction(checking, grocer, food);
    Data().aliases.appendNewMoneyObject(
      Alias(id: -1, pattern: 'GROCER.*', flags: AliasType.regex.index, payeeId: grocer.uniqueId, data: Data()),
      fireNotification: false,
    );

    final Transaction imported = Transaction.fromDateDescriptionAmount(checking, DateTime(2024), 'GROCER #12', -9);
    expect(imported.fieldCategoryId.value, food.uniqueId);

    final Transaction existing = _createTransaction(
      checking,
      Data().payees.getOrCreate('GROCER #40', fireNotification: false),
      null,
    );
    Data().applyAlias(Data().aliases.iterableList().first);
    expect(existing.fieldCategoryId.value, food.uniqueId);
  });

  test('suggested category names skip the current one and keep the top three', () {
    final List<Category> categories = <Category>[
      for (final String name in <String>['A', 'B', 'C', 'D']) Data().categories.addNewCategory(name: name),
    ];
    for (int i = 0; i < categories.length; i++) {
      for (int count = 0; count < 4 - i; count++) {
        _createTransaction(checking, grocer, categories[i]);
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
