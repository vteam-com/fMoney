import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/home/transactions/transactions_view.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/views/panels/list/transaction_aliases_panel.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/state/theme_controller.dart';

/// Creates and appends a transaction for the payee named [payeeName], with the bank text [originalPayee].
Transaction _createTransaction(Account account, String payeeName, {String originalPayee = ''}) {
  final Transaction transaction = Transaction(date: DateTime(2024, 5, 1));
  transaction.fieldAccountId.value = account.uniqueId;
  transaction.fieldPayee.value = Data().payees.getOrCreate(payeeName, fireNotification: false).uniqueId;
  transaction.fieldOriginalPayee.value = originalPayee;
  transaction.fieldTransfer.value = -1;
  transaction.fieldTransferSplit.value = -1;
  Data().appendNewTransaction(transaction, fireNotification: false);
  return transaction;
}

/// Appends a regex alias mapping [pattern] to [payee].
Alias _createAlias(String pattern, Payee payee) => Data().aliases.appendNewMoneyObject(
  Alias(id: -1, pattern: pattern, flags: AliasType.regex.index, payeeId: payee.uniqueId, data: Data()),
  fireNotification: false,
) as Alias;

void main() {
  late ListControllerMain listControllerMain;
  late ListControllerSidePanel listControllerSidePanel;
  late AppServices services;
  late Account checking;
  late Payee att;

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
    att = Data().payees.getOrCreate('AT&T', fireNotification: false);
  });

  tearDown(() {
    Data().clearExistingData();
    listControllerMain.dispose();
    listControllerSidePanel.dispose();
    PreferenceController.instance = null;
    ThemeController.instance = null;
    DataFileController.instance = null;
  });

  /// Pumps [child] inside an app that can show dialogs.
  Future<void> pumpHost(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1100, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          navigatorKey: AppRouter.navigatorKey,
          theme: services.themeController.themeData,
          home: Scaffold(body: SizedBox(height: 700, width: 1100, child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('related aliases match the bank text, the payee name or the payee itself', () {
    final Alias byOriginal = _createAlias('ATT\\*BILL', Data().payees.getOrCreate('Phone'));
    final Alias byPayee = _createAlias('NEVER', att);
    final Alias byName = _createAlias('AT&T', Data().payees.getOrCreate('Other'));
    _createAlias('UNRELATED', Data().payees.getOrCreate('Unrelated'));
    final Alias emptyAlias = Data().aliases.addNewAlias();
    final Transaction t = _createTransaction(checking, 'AT&T', originalPayee: 'ATT*BILL');
    final Transaction transfer = _createTransaction(checking, 'Transfer');
    transfer.fieldPayee.value = -1;

    expect(Data().aliases.relatedTo(<Transaction>[t]), <Alias>[byOriginal, byPayee, byName]);
    expect(Data().aliases.relatedTo(<Transaction>[transfer]), isNot(contains(emptyAlias)));
  });

  test('the side panel offers an aliases tab only when the view provides it', () {
    expect(
      SidePanelSupport(onDetails: ({required List<int> selectedIds}) => const SizedBox()).supportedSubViews,
      <SidePanelSubViewEnum>[SidePanelSubViewEnum.details],
    );
    final SidePanelSupport support = SidePanelSupport(onAliases: ({required List<int> selectedIds}) => const Text('A'));
    expect(support.supportedSubViews, <SidePanelSubViewEnum>[SidePanelSubViewEnum.aliases]);
    expect(support.getSidePanelContent(SidePanelSubViewEnum.aliases, <int>[]), isA<Text>());
  });

  testWidgets('the transactions view shows the related aliases, and tapping one edits it', (WidgetTester tester) async {
    _createAlias('ATT.*', att);
    final Transaction t = _createTransaction(checking, 'AT&T', originalPayee: 'ATT*BILL');
    await pumpHost(tester, const ViewTransactions());
    final ViewForMoneyObjectsState state = tester.state<ViewForMoneyObjectsState>(find.byType(ViewTransactions));

    final Widget panel = state.getSidePanelSupport().onAliases!(selectedIds: <int>[t.uniqueId]);
    expect(panel, isA<TransactionAliasesPanel>());

    await pumpHost(tester, panel);
    await tester.tap(find.text('ATT.*'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('key_pick_alias_payee')), findsOneWidget);
  });

  testWidgets('the panel says so when no alias is related', (WidgetTester tester) async {
    final Transaction t = _createTransaction(checking, 'Starbucks');
    await pumpHost(tester, TransactionAliasesPanel(transactions: <Transaction>[t]));
    expect(find.text(AppL10n.tr(AppTranslationKeys.noMatchingAliases)), findsOneWidget);
  });
}
