import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/state/theme_controller.dart';

/// Window size that fits the list views' columns.
const Size testWindowSize = Size(1100, 700);

/// Starts each test from an empty data file.
void resetTestData() {
  DataFileController.instance = DataFileController();
  Data().clearExistingData();
  DataAbstract.instance = Data();
}

/// Creates and appends a USD account named [name].
Account createTestAccount([String name = 'Checking']) {
  final Account account = Account();
  account.fieldName.value = name;
  account.fieldCurrency.value = 'USD';
  return Data().accounts.appendNewMoneyObject(account, fireNotification: false) as Account;
}

/// Creates and appends a transaction on [account] for the payee named [payeeName], in [category]
/// (none when null), with the bank text [originalPayee]; [isTransfer] links it to another transaction.
Transaction createTestTransaction(
  Account account,
  String payeeName, {
  Category? category,
  String originalPayee = '',
  bool isTransfer = false,
}) {
  final Transaction transaction = Transaction(date: DateTime(2024, 5, 1));
  transaction.fieldAccountId.value = account.uniqueId;
  transaction.fieldPayee.value = Data().payees.getOrCreate(payeeName, fireNotification: false).uniqueId;
  transaction.fieldCategoryId.value = category?.uniqueId ?? -1;
  transaction.fieldOriginalPayee.value = originalPayee;
  transaction.fieldTransfer.value = isTransfer ? 1 : -1;
  transaction.fieldTransferSplit.value = -1;
  Data().appendNewTransaction(transaction, fireNotification: false);
  return transaction;
}

/// Appends an alias of [type] mapping [pattern] to [payee].
Alias createTestAlias(String pattern, Payee payee, {AliasType type = AliasType.regex}) =>
    Data().aliases.appendNewMoneyObject(
      Alias(id: -1, pattern: pattern, flags: type.index, payeeId: payee.uniqueId, data: Data()),
      fireNotification: false,
    ) as Alias;

/// Creates and registers the app-scoped controllers the list views need; undo with [disposeTestServices].
AppServices createTestServices() {
  final AppServices services = AppServices(
    listControllerMain: ListControllerMain(),
    listControllerSidePanel: ListControllerSidePanel(),
    preferenceController: PreferenceController(),
    themeController: ThemeController(),
  );
  AppScope.register(services);
  return services;
}

/// Releases what [createTestServices] made, along with the test data and snack bars.
void disposeTestServices(AppServices services) {
  SnackBarService.clearQueue();
  Data().clearExistingData();
  services.listControllerMain.dispose();
  services.listControllerSidePanel.dispose();
  PreferenceController.instance = null;
  ThemeController.instance = null;
  DataFileController.instance = null;
}

/// Pumps [page] in an app laid out like fMoney's, which can show dialogs, banners and snack bars.
Future<void> pumpTestApp(WidgetTester tester, AppServices services, Widget page) async {
  tester.view.physicalSize = testWindowSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppScope(
      services: services,
      child: MaterialApp(
        navigatorKey: AppRouter.navigatorKey,
        scaffoldMessengerKey: SnackBarService.scaffoldKey,
        theme: services.themeController.themeData,
        home: Scaffold(body: page),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Drops the queued snack bars and lets the shown one time out, so no timer outlives the test.
Future<void> dismissSnackBars(WidgetTester tester) async {
  SnackBarService.clearQueue();
  await tester.pumpAndSettle(const Duration(seconds: 10));
}
