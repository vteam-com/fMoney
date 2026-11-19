import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/similar_payees_helper.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/panels/dialogs/similar_payees_dialog.dart';

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

  /// Pumps a page whose button opens the similar-payees dialog for [payee], then opens it.
  Future<void> openDialog(WidgetTester tester, Payee payee) async {
    await pumpTestApp(
      tester,
      services,
      Builder(
        builder: (BuildContext context) =>
            TextButton(onPressed: () => showSimilarPayees(context, payee), child: const Text('open')),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('similarity', () {
    test('compares names without case, spaces or punctuation', () {
      expect(compactPayeeName('AT&T*Bill pay'), 'ATTBILLPAY');
      expect(arePayeeNamesSimilar('AT&T', 'ATT WIRELESS'), isTrue);
      expect(arePayeeNamesSimilar('Starbucks #123', 'STARBUCKS 456'), isTrue);
      expect(arePayeeNamesSimilar('AT&T', 'MATTRESS FIRM'), isFalse);
      expect(arePayeeNamesSimilar('Shell Oil', "Shelby's"), isFalse);
      expect(arePayeeNamesSimilar('BP', 'BP GAS'), isFalse, reason: 'two letters are too ambiguous');
    });

    test('skips the payee itself and payees an alias already maps', () {
      final Payee wireless = Data().payees.getOrCreate('ATT WIRELESS', fireNotification: false);
      final Payee bill = Data().payees.getOrCreate('ATT*BILL', fireNotification: false);
      Data().payees.getOrCreate('ATT UVERSE', fireNotification: false);
      Data().payees.getOrCreate('MATTRESS FIRM', fireNotification: false);
      final Alias alias = Alias(id: -1, pattern: 'ATT UVERSE', flags: 0, payeeId: att.uniqueId, data: Data());

      expect(findSimilarPayees(att, Data().payees.iterableList(), <Alias>[alias]), <Payee>[wireless, bill]);
    });
  });

  testWidgets('merge moves only the checked payees into the dialog payee', (WidgetTester tester) async {
    final Transaction bill = createTestTransaction(checking, 'ATT*BILL');
    final Transaction wireless = createTestTransaction(checking, 'ATT WIRELESS');
    final int wirelessPayeeId = wireless.fieldPayee.value;
    await openDialog(tester, att);

    await tester.tap(find.text('ATT WIRELESS'));
    await tester.pump();
    await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.merge)));
    await tester.pump();

    expect(bill.fieldPayee.value, att.uniqueId);
    expect(wireless.fieldPayee.value, wirelessPayeeId);
    await dismissSnackBars(tester);
    expect(find.byType(SimilarPayeesDialog), findsNothing);
  });

  testWidgets('create alias maps every checked name to the dialog payee', (WidgetTester tester) async {
    final Transaction bill = createTestTransaction(checking, 'ATT*BILL');
    final Transaction wireless = createTestTransaction(checking, 'ATT WIRELESS');
    await openDialog(tester, att);

    await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.createAlias)));
    await tester.pump();

    final Alias alias = Data().aliases.iterableList().single;
    expect(alias.fieldPayeeId.value, att.uniqueId);
    expect(alias.fieldPattern.value, '(?i)ATT.*', reason: 'one pattern for both, ready for future variants');
    expect(alias.type, AliasType.regex);
    expect(bill.fieldPayee.value, att.uniqueId);
    expect(wireless.fieldPayee.value, att.uniqueId);
    expect(Data().payees.getByName('ATT*BILL')?.isDeleted ?? true, isTrue);
    await dismissSnackBars(tester);
  });

  testWidgets('create alias leaves the unchecked payees alone', (WidgetTester tester) async {
    createTestTransaction(checking, 'ATT*BILL');
    createTestTransaction(checking, 'ATT WIRELESS');
    final Transaction uverse = createTestTransaction(checking, 'ATT UVERSE');
    final int uversePayeeId = uverse.fieldPayee.value;
    await openDialog(tester, att);

    await tester.tap(find.text('ATT UVERSE'));
    await tester.pump();
    await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.createAlias)));
    await tester.pump();

    final Alias alias = Data().aliases.iterableList().single;
    expect(alias.fieldPattern.value, r'(?i)(?:ATT WIRELESS|ATT\*BILL)', reason: 'ATT.* would take ATT UVERSE');
    expect(uverse.fieldPayee.value, uversePayeeId);
    await dismissSnackBars(tester);
  });

  testWidgets('says so when there is nothing similar', (WidgetTester tester) async {
    await openDialog(tester, att);
    expect(find.text(AppL10n.tr(AppTranslationKeys.noSimilarPayeesFound)), findsOneWidget);
  });
}
