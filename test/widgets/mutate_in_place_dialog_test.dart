import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/presentation/dialogs/delete_money_objects_dialog.dart';
import 'package:money/shared/presentation/dialogs/mutate_split_dialog.dart';
import 'package:money/shared/presentation/dialogs/mutate_transaction_dialog.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  late AppServices services;
  late Transaction transaction;

  setUp(() {
    resetTestData();
    services = createTestServices();
    transaction = createTestTransaction(createTestAccount(), 'Grocer');
  });

  tearDown(() => disposeTestServices(services));

  /// Pumps an empty page and returns a context that can show dialogs.
  Future<BuildContext> pumpPage(WidgetTester tester) async {
    await pumpTestApp(tester, services, const SizedBox());
    return tester.element(find.byType(SizedBox));
  }

  /// Appends a split of [transaction] whose memo is [memo].
  TransactionSplit createSplit(String memo) {
    final TransactionSplit split = TransactionSplit(
      id: -1,
      transactionId: transaction.uniqueId,
      categoryId: -1,
      payeeId: -1,
      amount: 10,
      transferId: -1,
      memo: memo,
      flags: 0,
      budgetBalanceDate: null,
      data: Data(),
    );
    return Data().splits.appendNewMoneyObject(split, fireNotification: false) as TransactionSplit;
  }

  testWidgets('dismissing the split dialog mid-edit rolls the split back', (WidgetTester tester) async {
    final TransactionSplit split = createSplit('before');
    final BuildContext context = await pumpPage(tester);
    showSplitAndActions(context: context, split: split);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Constants.keyButtonEdit));
    await tester.pumpAndSettle();
    split.fieldMemo.value = 'after';
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.byKey(Constants.keyButtonApplyOrDone), findsNothing);
    expect(split.fieldMemo.value, 'before');
  });

  testWidgets('deleting from the split dialog confirms with the split name and closes both dialogs', (
    WidgetTester tester,
  ) async {
    final TransactionSplit split = createSplit('memo');
    final BuildContext context = await pumpPage(tester);
    showSplitAndActions(context: context, split: split);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.delete)));
    await tester.pumpAndSettle();
    final String splitName = AppL10n.tr(AppTranslationKeys.split);
    expect(find.text('${AppL10n.tr(AppTranslationKeys.delete)} $splitName'), findsOneWidget);
    expect(
      find.text(AppL10n.tr(AppTranslationKeys.deleteThisItemQuestion, params: <String, String>{'item': splitName})),
      findsOneWidget,
    );

    await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.delete)).last);
    await tester.pumpAndSettle();

    expect(split.isDeleted, isTrue);
    expect(find.byKey(Constants.keyButtonEdit), findsNothing);
  });

  testWidgets('duplicating a transaction adds the copy and edits it, offering Done until it changes', (
    WidgetTester tester,
  ) async {
    final BuildContext context = await pumpPage(tester);
    showTransactionAndActions(context: context, transaction: transaction);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.duplicate)));
    await tester.pumpAndSettle();

    expect(Data().transactions.iterableList().length, 2);
    expect(
      find.descendant(
        of: find.byKey(Constants.keyButtonApplyOrDone),
        matching: find.text(AppL10n.tr(AppTranslationKeys.done)),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(Constants.keyButtonApplyOrDone));
    await tester.pumpAndSettle();
    expect(find.byKey(Constants.keyButtonApplyOrDone), findsNothing);
  });

  testWidgets('the delete confirmation says so when nothing is selected or the items are still in use', (
    WidgetTester tester,
  ) async {
    final BuildContext context = await pumpPage(tester);
    final Payee grocer = Data().payees.getByName('Grocer')!;

    confirmAndDeleteMoneyObjects(
      context: context,
      moneyObjects: <DataObject>[],
      nameSingular: 'payee',
      namePlural: 'payees',
    );
    await tester.pumpAndSettle();
    expect(find.text(AppL10n.tr(AppTranslationKeys.noItemsToDelete)), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    confirmAndDeleteMoneyObjects(
      context: context,
      moneyObjects: <DataObject>[grocer],
      nameSingular: 'payee',
      namePlural: 'payees',
    );
    await tester.pump();
    expect(
      find.text(AppL10n.tr(AppTranslationKeys.deleteBlockedByReferences, params: <String, String>{'count': '1'})),
      findsOneWidget,
    );
    expect(grocer.isDeleted, isFalse);
    await dismissSnackBars(tester);
  });
}
