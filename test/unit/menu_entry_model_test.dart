import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/field_filters_model.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/helpers/menu_entry_model.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferenceController preferences;
  late Account checking;
  late Account savings;
  late Category food;
  late Transaction groceries;
  late Transaction rent;

  setUp(() async {
    resetTestData();
    SharedPreferences.setMockInitialValues(<String, Object>{
      ViewId.viewTransactions.getViewPreferenceId(settingKeyFilterText): 'left over',
    });
    preferences = PreferenceController();
    await preferences.init();
    checking = createTestAccount();
    savings = createTestAccount('Savings');
    food = Data().categories.addNewCategory(name: 'Food');
    groceries = createTestTransaction(checking, 'Grocer', category: food);
    rent = createTestTransaction(savings, 'Landlord');
  });

  tearDown(() {
    Data().clearExistingData();
    PreferenceController.instance = null;
    DataFileController.instance = null;
  });

  /// Presses [entry] and returns the transactions the Transactions view then lists.
  Future<List<Transaction>> jumpAndList(MenuEntry entry) async {
    entry.onPressed();
    await pumpEventQueue();
    expect(preferences.currentView, ViewId.viewTransactions);
    expect(preferences.getString(ViewId.viewTransactions.getViewPreferenceId(settingKeyFilterText)), isEmpty);
    final FieldFilters filters = FieldFilters.fromJsonString(
      preferences.getString(ViewId.viewTransactions.getViewPreferenceId(settingKeyFiltersColumns)),
    );
    return <Transaction>[
      groceries,
      rent,
    ].where((Transaction t) => Transaction.fieldsForColumnView.isMatchingColumnFiltering(t, filters)).toList();
  }

  test('the transactions of an account jump lists only that account', () async {
    expect(await jumpAndList(MenuEntry.toTransactionsOfAccount(account: savings)), <Transaction>[rent]);
  });

  test('the transactions of a category jump lists only that category', () async {
    expect(await jumpAndList(MenuEntry.toTransactionsOfCategory(category: food)), <Transaction>[groceries]);
  });

  test('the transactions of a payee jump lists only that payee', () async {
    final Payee grocer = Data().payees.getByName('Grocer')!;
    expect(await jumpAndList(MenuEntry.toTransactionsOfPayee(payee: grocer)), <Transaction>[groceries]);
  });

  test('the category filter keeps the transactions of the categories named', () {
    final FieldFilters filters = FieldFilters()..add(transactionsOfCategoriesFilter(<String>['Food', 'Rent']));
    expect(Transaction.fieldsForColumnView.isMatchingColumnFiltering(groceries, filters), isTrue);
    expect(Transaction.fieldsForColumnView.isMatchingColumnFiltering(rent, filters), isFalse);
  });

  test('the payee jump selects the payee in the Payees view', () async {
    final Payee grocer = Data().payees.getByName('Grocer')!;
    MenuEntry.toPayee(payeeId: grocer.uniqueId).onPressed();
    await pumpEventQueue();
    expect(preferences.currentView, ViewId.viewPayees);
    expect(preferences.getInt(ViewId.viewPayees.getViewPreferenceId(settingKeySelectedListItemId)), grocer.uniqueId);
  });
}
