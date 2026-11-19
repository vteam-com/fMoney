import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/home/transactions/transactions_view.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/views/panels/list/transaction_aliases_panel.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  late AppServices services;
  late Account checking;
  late Payee att;

  setUp(() {
    resetTestData();
    services = createTestServices();
    checking = createTestAccount();
    att = Data().payees.getOrCreate('AT&T', fireNotification: false);
  });

  tearDown(() => disposeTestServices(services));

  test('related aliases match the bank text, the payee name or the payee itself', () {
    final Alias byOriginal = createTestAlias('ATT\\*BILL', Data().payees.getOrCreate('Phone'));
    final Alias byPayee = createTestAlias('NEVER', att);
    final Alias byName = createTestAlias('AT&T', Data().payees.getOrCreate('Other'));
    createTestAlias('UNRELATED', Data().payees.getOrCreate('Unrelated'));
    final Alias emptyAlias = Data().aliases.addNewAlias();
    final Transaction t = createTestTransaction(checking, 'AT&T', originalPayee: 'ATT*BILL');
    final Transaction transfer = createTestTransaction(checking, 'Transfer');
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
    createTestAlias('ATT.*', att);
    final Transaction t = createTestTransaction(checking, 'AT&T', originalPayee: 'ATT*BILL');
    await pumpTestApp(tester, services, const ViewTransactions());
    final ViewForMoneyObjectsState state = tester.state<ViewForMoneyObjectsState>(find.byType(ViewTransactions));

    final Widget panel = state.getSidePanelSupport().onAliases!(selectedIds: <int>[t.uniqueId]);
    expect(panel, isA<TransactionAliasesPanel>());

    await pumpTestApp(tester, services, panel);
    await tester.tap(find.text('ATT.*'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('key_pick_alias_payee')), findsOneWidget);
  });

  testWidgets('saving an alias from the panel moves the transactions it now matches', (WidgetTester tester) async {
    createTestAlias(r'ATT\*BILL', att);
    final Transaction bill = createTestTransaction(checking, 'ATT*BILL');
    final Transaction wireless = createTestTransaction(checking, 'ATT WIRELESS');
    await pumpTestApp(tester, services, TransactionAliasesPanel(transactions: <Transaction>[bill]));

    await tester.tap(find.text(r'ATT\*BILL'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('key_alias_pattern')), 'ATT.*');
    await tester.pump();
    await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.apply)));
    await tester.pump();

    expect(bill.fieldPayee.value, att.uniqueId);
    expect(wireless.fieldPayee.value, att.uniqueId, reason: 'the edited pattern is the one applied');
    expect(
      find.text(AppL10n.tr(AppTranslationKeys.transactionsUpdatedCount, params: <String, String>{'count': '2'})),
      findsOneWidget,
    );
    await dismissSnackBars(tester);
  });

  testWidgets('the panel says so when no alias is related', (WidgetTester tester) async {
    final Transaction t = createTestTransaction(checking, 'Starbucks');
    await pumpTestApp(tester, services, TransactionAliasesPanel(transactions: <Transaction>[t]));
    expect(find.text(AppL10n.tr(AppTranslationKeys.noMatchingAliases)), findsOneWidget);
  });
}
