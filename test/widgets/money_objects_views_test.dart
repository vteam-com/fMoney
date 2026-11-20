import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/rent_building_entity.dart';
import 'package:money/shared/domain/rental_unit_entity.dart';
import 'package:money/shared/domain/security_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/home/accounts/accounts_view.dart';
import 'package:money/views/home/categories/categories_view.dart';
import 'package:money/views/home/events/events_view.dart';
import 'package:money/views/home/payees/payees_view.dart';
import 'package:money/views/home/rentals/rentals_view.dart';
import 'package:money/views/home/stocks/stocks_view.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/views/panels/list/side_panel_lists_helper.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';
import 'package:money/widgets/pure/center_message_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_fixtures_helper.dart';

/// Returns the state of the list view of type [T] pumped in [tester].
ViewForMoneyObjectsState _stateOf<T>(WidgetTester tester) => tester.state<ViewForMoneyObjectsState>(find.byType(T));

/// Appends a security with [symbol].
Security _createSecurity(String symbol) => Data().securities.appendNewMoneyObject(
  Security(
    id: -1,
    name: symbol,
    symbol: symbol,
    price: 1,
    lastPrice: 1,
    cuspid: '',
    securityType: 0,
    taxable: 0,
    priceDate: null,
  ),
  fireNotification: false,
) as Security;

/// Returns the title of the dialog editing a new item of the kind named by [itemKey].
String _newItemTitle(String itemKey) =>
    AppL10n.tr(AppTranslationKeys.newItemLabel, params: <String, String>{'item': AppL10n.tr(itemKey)});

/// Returns the message of an empty details box titled by [titleKey].
String _noItems(String titleKey) => '${AppL10n.tr(AppTranslationKeys.noItems)} ${AppL10n.tr(titleKey)}';

void main() {
  late AppServices services;

  setUp(() async {
    resetTestData();
    services = createTestServices();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await services.preferenceController.init();
  });

  tearDown(() => disposeTestServices(services));

  testWidgets('the events view keeps its own preferences', (WidgetTester tester) async {
    await pumpTestApp(tester, services, const ViewEvents());
    expect(_stateOf<ViewEvents>(tester).viewId, ViewId.viewEvents);
  });

  testWidgets('the side panel transactions tab asks for a selection instead of failing', (WidgetTester tester) async {
    await pumpTestApp(tester, services, const ViewRentals());
    final Widget tab = _stateOf<ViewRentals>(tester).getSidePanelSupport().onTransactions!(
      selectedIds: <int>[],
      showAsNativeCurrency: true,
    );
    expect(tab, isA<CenterMessage>());
  });

  testWidgets('the side panel transactions list remembers the row selected and the sort, per view', (
    WidgetTester tester,
  ) async {
    final Account checking = createTestAccount();
    createTestTransaction(checking, 'Grocer').fieldMemo.value = 'second';
    final Transaction first = createTestTransaction(checking, 'Grocer')..fieldMemo.value = 'first';
    final Payee grocer = Data().payees.getByName('Grocer')!;
    await pumpTestApp(tester, services, const ViewPayees());
    final ViewForMoneyObjectsState state = _stateOf<ViewPayees>(tester);
    state.updateListAndSelect(grocer.uniqueId);
    await tester.pumpAndSettle();

    await pumpTestApp(
      tester,
      services,
      state.getSidePanelSupport().onTransactions!(selectedIds: <int>[grocer.uniqueId], showAsNativeCurrency: true),
    );
    expect(find.text(grocer.fieldName.value), findsNothing, reason: 'the payee view leaves the payee column out');
    await tester.tap(find.text('first'));
    await tester.tap(find.text(columnIdDate));
    await tester.pump();

    expect(state.getSidePanelLastSelectedItemId(), first.uniqueId);
    // Tapping the sorted Date column flips it to descending, for the payees only
    final String sidePanelSortAscending = '$settingKeySidePanel$settingKeySortAscending';
    expect(
      services.preferenceController.getBool(ViewId.viewPayees.getViewPreferenceId(sidePanelSortAscending), true),
      false,
    );
    expect(
      services.preferenceController.getBool(ViewId.viewCategories.getViewPreferenceId(sidePanelSortAscending), true),
      true,
    );
  });

  testWidgets('the account pivots filter by type and show up-to-date totals', (WidgetTester tester) async {
    final Account checking = createTestAccount()
      ..fieldType.value = AccountType.checking
      ..isOpen = true;
    createTestAccount('Visa')
      ..fieldType.value = AccountType.credit
      ..isOpen = true;
    await pumpTestApp(tester, services, const ViewAccounts());
    final ViewForMoneyObjectsState state = _stateOf<ViewAccounts>(tester);

    checking.balance = 250;
    await tester.tap(find.byKey(const Key('key_toggle_show_bank')));
    await tester.pumpAndSettle();

    expect(state.list, <Account>[checking]);
    expect(
      find.descendant(
        of: find.byKey(const Key('key_toggle_show_bank')),
        matching: find.text(getAmountAsStringUsingCurrency(250.0)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the account add button opens the new account for editing', (WidgetTester tester) async {
    await pumpTestApp(tester, services, const ViewAccounts());

    await tester.tap(find.byKey(Constants.keyAddNewItem));
    await tester.pumpAndSettle();

    expect(Data().accounts.length, 1);
    expect(find.text(_newItemTitle(AppTranslationKeys.account)), findsOneWidget);
  });

  testWidgets('the category add button adds the new category under the selected one', (WidgetTester tester) async {
    final Category food = Data().categories.addNewCategory(name: 'Food');
    await pumpTestApp(tester, services, const ViewCategories());
    _stateOf<ViewCategories>(tester).updateListAndSelect(food.uniqueId);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Constants.keyAddNewItem));
    await tester.pumpAndSettle();

    expect(Data().categories.iterableList().last.fieldParentId.value, food.uniqueId);
    // The dialog title "New Category" is also the new category's default name, so check the title itself.
    expect(tester.widget<MyAlertDialog>(find.byType(MyAlertDialog)).title, _newItemTitle(AppTranslationKeys.category));
  });

  testWidgets('the stocks side panel copy has no investments to copy when no security is selected', (
    WidgetTester tester,
  ) async {
    _createSecurity('ACME');
    await pumpTestApp(tester, services, const ViewStocks());
    expect(_stateOf<ViewStocks>(tester).getSidePanelTransactions(), isEmpty);
  });

  testWidgets('the stock details add the splits and dividends to the editable card', (WidgetTester tester) async {
    final Security acme = _createSecurity('ACME');
    await pumpTestApp(tester, services, const ViewStocks());

    await pumpTestApp(
      tester,
      services,
      _stateOf<ViewStocks>(tester).getSidePanelSupport().onDetails!(selectedIds: <int>[acme.uniqueId]),
    );

    expect(find.text(_noItems(AppTranslationKeys.splits)), findsOneWidget);
    expect(find.text(_noItems(AppTranslationKeys.dividend)), findsOneWidget);
    expect(find.byKey(Constants.keyEditSelectedItems), findsOneWidget);
  });

  testWidgets('the rental details list the renters next to the card', (WidgetTester tester) async {
    final RentBuilding building = Data().rentBuildings.appendNewMoneyObject(
      RentBuilding()..fieldName.value = 'Duplex',
      fireNotification: false,
    ) as RentBuilding;
    building.data = Data();
    for (final String unit in <String>['Upstairs', 'Downstairs']) {
      Data().rentUnits.appendNewMoneyObject(
        RentUnit()
          ..fieldName.value = unit
          ..fieldBuilding.value = building.uniqueId,
        fireNotification: false,
      );
    }
    await pumpTestApp(tester, services, const ViewRentals());

    await pumpTestApp(
      tester,
      services,
      _stateOf<ViewRentals>(tester).getSidePanelSupport().onDetails!(selectedIds: <int>[building.uniqueId]),
    );

    expect(find.text('Upstairs'), findsOneWidget);
    expect(find.text('Downstairs'), findsOneWidget);
  });
}
