import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/dialogs/mutate_money_object_dialog.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/home/transactions/transaction_actions_helper.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  late AppServices services;
  late Account checking;
  late Payee amazon;

  setUp(() {
    resetTestData();
    services = createTestServices();
    checking = createTestAccount();
    amazon = Data().payees.getOrCreate('Amazon', fireNotification: false);
  });

  tearDown(() => disposeTestServices(services));

  /// Adds an Amazon transaction for each of [texts], the bank text it was imported with.
  List<Transaction> amazonTransactions(List<String> texts) => <Transaction>[
    for (final String text in texts) createTestTransaction(checking, 'Amazon', originalPayee: text),
  ];

  /// Pumps the app and opens the editor of [alias].
  Future<void> editAlias(WidgetTester tester, Alias alias) async {
    await pumpTestApp(tester, services, const Text('home'));
    myShowDialogAndActionsForMoneyObject(title: 'Alias', moneyObject: alias);
    await tester.pumpAndSettle();
  }

  testWidgets('create alias on several transactions makes one regex for their bank texts', (WidgetTester tester) async {
    final List<Transaction> selection = amazonTransactions(<String>['AMAZON.COM*AB12', 'AMAZON.COM*CD34']);
    final Transaction other = createTestTransaction(checking, 'Prime', originalPayee: 'AMAZON.COM*PRIME');
    await pumpTestApp(tester, services, const Text('home'));

    transactionActions
        .firstWhere((TransactionAction action) => action.label == AppL10n.tr(AppTranslationKeys.createAlias))
        .run(tester.element(find.text('home')), selection);
    await tester.pumpAndSettle();

    final Alias alias = Data().aliases.iterableList().single;
    expect(alias.type, AliasType.regex);
    expect(alias.isMatch('AMAZON.COM*AB12') && alias.isMatch('AMAZON.COM*CD34'), isTrue);
    expect(alias.isMatch('AMAZON.COM*PRIME'), isFalse, reason: "it must not take another payee's transaction");
    expect(alias.fieldPayeeId.value, amazon.uniqueId);
    expect(find.text(AppL10n.tr(AppTranslationKeys.aliasPatternIgnoreCase)), findsOneWidget);

    await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.apply)));
    await tester.pumpAndSettle();
    expect(other.payeeName, 'Prime');
    await dismissSnackBars(tester);
  });

  testWidgets('Optimize suggests a pattern for all the payee bank texts, and Use takes it', (
    WidgetTester tester,
  ) async {
    amazonTransactions(<String>['AMAZON.COM*AB12', 'AMAZON.COM*CD34', 'AMAZON.COM*EF56']);
    final Alias alias = Data().aliases.addNewAlias(pattern: 'AMAZON.COM*AB12', payeeId: amazon.uniqueId);
    await editAlias(tester, alias);

    expect(
      find.text(
        AppL10n.tr(AppTranslationKeys.aliasPatternExactText, params: <String, String>{'text': 'AMAZON.COM*AB12'}),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('key_alias_optimize')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        AppL10n.tr(
          AppTranslationKeys.aliasPatternSuggested,
          params: <String, String>{'count': '3', 'current': '1'},
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('key_alias_use_suggestion')));
    await tester.pumpAndSettle();
    expect(alias.fieldPattern.value, r'(?i)AMAZON\.COM\*.*');
    expect(alias.type, AliasType.regex);
    expect(
      tester.widget<TextField>(find.byKey(const Key('key_alias_pattern'))).controller!.text,
      alias.fieldPattern.value,
    );
    expect(find.text(AppL10n.tr(AppTranslationKeys.aliasPatternAnyTextOrNothing)), findsOneWidget);
    expect(find.byKey(const Key('key_alias_optimize')), findsOneWidget, reason: 'the suggestion is used up');
  });

  testWidgets('Optimize says when the pattern is already the best, and editing explains the new one', (
    WidgetTester tester,
  ) async {
    amazonTransactions(<String>['AMAZON.COM*AB12', 'AMAZON.COM*CD34']);
    final Alias alias = Data().aliases.addNewAlias(
      pattern: r'(?i)AMAZON\.COM\*.*',
      type: AliasType.regex,
      payeeId: amazon.uniqueId,
    );
    await editAlias(tester, alias);

    await tester.tap(find.byKey(const Key('key_alias_optimize')));
    await tester.pumpAndSettle();
    expect(
      find.text(AppL10n.tr(AppTranslationKeys.aliasPatternNoBetter, params: <String, String>{'count': '2'})),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('key_alias_pattern')), r'AMAZON\d+');
    await tester.pumpAndSettle();
    expect(alias.fieldPattern.value, r'AMAZON\d+');
    expect(find.text(AppL10n.tr(AppTranslationKeys.aliasPatternMatchCase)), findsOneWidget);
    expect(find.text(AppL10n.tr(AppTranslationKeys.aliasPatternNumber)), findsOneWidget);
    expect(find.byKey(const Key('key_alias_optimize')), findsOneWidget, reason: 'the old answer no longer applies');
  });
}
