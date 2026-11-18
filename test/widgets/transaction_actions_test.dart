import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/home/transactions/transaction_actions_helper.dart';
import 'package:money/views/home/transactions/transactions_view.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/state/theme_controller.dart';

/// Creates and appends a non-transfer transaction on [account] for the payee named [payeeName].
Transaction _createTransaction(Account account, String payeeName, {Category? category}) {
  final Transaction transaction = Transaction(date: DateTime(2024, 5, 1));
  transaction.fieldAccountId.value = account.uniqueId;
  transaction.fieldPayee.value = Data().payees.getOrCreate(payeeName, fireNotification: false).uniqueId;
  transaction.fieldCategoryId.value = category?.uniqueId ?? -1;
  transaction.fieldTransfer.value = -1;
  transaction.fieldTransferSplit.value = -1;
  Data().appendNewTransaction(transaction, fireNotification: false);
  return transaction;
}

void main() {
  late ListControllerMain listControllerMain;
  late ListControllerSidePanel listControllerSidePanel;
  late AppServices services;
  late Account checking;

  setUp(() {
    Data().clearExistingData();
    listControllerMain = ListControllerMain();
    listControllerSidePanel = ListControllerSidePanel();
    DataFileController.instance = DataFileController();
    services = AppServices(
      listControllerMain: listControllerMain,
      listControllerSidePanel: listControllerSidePanel,
      preferenceController: PreferenceController(),
      themeController: ThemeController(),
    );
    AppScope.register(services);
    final Account account = Account();
    account.fieldName.value = 'Checking';
    account.fieldCurrency.value = 'USD';
    checking = Data().accounts.appendNewMoneyObject(account, fireNotification: false) as Account;
  });

  tearDown(() {
    SnackBarService.clearQueue();
    Data().clearExistingData();
    listControllerMain.dispose();
    listControllerSidePanel.dispose();
    PreferenceController.instance = null;
    ThemeController.instance = null;
    DataFileController.instance = null;
  });

  /// Pumps the transactions view in a desktop-sized window and returns its state.
  Future<ViewForMoneyObjectsState> pumpTransactions(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1100, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          navigatorKey: AppRouter.navigatorKey,
          scaffoldMessengerKey: SnackBarService.scaffoldKey,
          theme: services.themeController.themeData,
          home: const Scaffold(body: ViewTransactions()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.state<ViewForMoneyObjectsState>(find.byType(ViewTransactions));
  }

  testWidgets('right-click selects the row and offers every action with its shortcut', (WidgetTester tester) async {
    final Transaction t = _createTransaction(checking, 'Grocer');
    final ViewForMoneyObjectsState state = await pumpTransactions(tester);

    await tester.tap(find.text('Grocer').first, buttons: kSecondaryButton);
    await tester.pumpAndSettle();

    expect(state.selectedIds, <int>[t.uniqueId]);
    for (final TransactionAction action in transactionActions) {
      expect(find.text(action.label), findsOneWidget);
    }
    expect(find.text('Ctrl+Shift+C'), findsOneWidget);
  });

  testWidgets('change category applies the picked suggestion to every selected transaction', (
    WidgetTester tester,
  ) async {
    final Category food = Data().categories.addNewCategory(name: 'Food');
    _createTransaction(checking, 'Grocer', category: food);
    final Transaction first = _createTransaction(checking, 'Grocer');
    final Transaction second = _createTransaction(checking, 'Grocer');
    await pumpTransactions(tester);
    final TransactionAction changeCategory = transactionActions.firstWhere(
      (TransactionAction action) => action.label == AppL10n.tr(AppTranslationKeys.changeCategory),
    );

    changeCategory.run(tester.element(find.byType(ViewTransactions)), <Transaction>[first, second]);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'Food'));
    await tester.pump();
    await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.apply)));
    await tester.pumpAndSettle();

    expect(first.fieldCategoryId.value, food.uniqueId);
    expect(second.fieldCategoryId.value, food.uniqueId);
  });

  testWidgets('a keyboard shortcut opens the action on the selection', (WidgetTester tester) async {
    final Transaction t = _createTransaction(checking, 'Grocer');
    final ViewForMoneyObjectsState state = await pumpTransactions(tester);
    await tester.tap(find.text('Grocer').first);
    await tester.pumpAndSettle();
    expect(state.selectedIds, <int>[t.uniqueId]);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('key_pick_payee')), findsOneWidget);
  });

  testWidgets('create alias keeps the alias on apply and discards it on cancel', (WidgetTester tester) async {
    final Transaction t = _createTransaction(checking, 'ATT*BILL');
    final ViewForMoneyObjectsState state = await pumpTransactions(tester);
    state.updateListAndSelect(t.uniqueId);
    await tester.pumpAndSettle();

    Future<void> openCreateAlias() async {
      await tester.tap(find.text('ATT*BILL').first, buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.createAlias)));
      await tester.pumpAndSettle();
    }

    await openCreateAlias();
    expect(find.byKey(const Key('key_pick_alias_payee')), findsOneWidget);
    await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.cancel)));
    await tester.pumpAndSettle();
    expect(Data().aliases.iterableList(), isEmpty, reason: 'cancel discards the new alias');

    await openCreateAlias();
    await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.apply)));
    await tester.pumpAndSettle();
    final Alias alias = Data().aliases.iterableList().single;
    expect(alias.fieldPattern.value, 'ATT*BILL');
    expect(alias.fieldPayeeId.value, t.fieldPayee.value);
  });
}
