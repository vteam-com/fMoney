import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/home/payees/payees_view.dart';
import 'package:money/views/home/transactions/transactions_view.dart';
import 'package:money/views/panels/list/money_objects_view.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  late AppServices services;

  setUp(() {
    resetTestData();
    services = createTestServices();
  });

  tearDown(() => disposeTestServices(services));

  /// Returns the column [name] of the transactions list.
  Field<dynamic> transactionColumn(String name) => Transaction.fieldsForColumnView.getFieldByName(name);

  /// Returns the value labels of the open column filter, in display order.
  List<String> shownValues(WidgetTester tester) => tester
      .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
      .map((CheckboxListTile tile) => (tile.title! as Text).data!)
      .toList();

  /// Returns whether [value] is ticked in the open column filter.
  bool isTicked(WidgetTester tester, String value) =>
      tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, value)).value!;

  /// Opens the filter of [column] on [state], toggles each of [toggle], and applies it.
  Future<void> filterColumn(
    WidgetTester tester,
    ViewForMoneyObjectsState state,
    Field<dynamic> column,
    List<String> toggle,
  ) async {
    state.onCustomizeColumn(column);
    await tester.pumpAndSettle();
    for (final String value in toggle) {
      await tester.tap(find.widgetWithText(CheckboxListTile, value));
      await tester.pump();
    }
    await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.apply)));
    await tester.pumpAndSettle();
  }

  /// Returns the memos of the transactions [state] lists.
  List<String> listedMemos(ViewForMoneyObjectsState state) =>
      state.list.map((DataObject t) => (t as Transaction).fieldMemo.value).toList()..sort();

  group('transactions column filter', () {
    late ViewForMoneyObjectsState state;

    setUp(() {
      final Account checking = createTestAccount();
      final Account savings = createTestAccount('Savings');
      for (final (Account account, String memo) in <(Account, String)>[
        (checking, 'Alpha'),
        (checking, 'Beta'),
        (checking, 'Gamma'),
        (savings, 'Alpha'),
      ]) {
        createTestTransaction(account, 'Grocer').fieldMemo.value = memo;
      }
    });

    /// Pumps the transactions view and keeps its state in [state].
    Future<void> pumpTransactions(WidgetTester tester) async {
      await pumpTestApp(tester, services, const ViewTransactions());
      state = tester.state<ViewForMoneyObjectsState>(find.byType(ViewTransactions));
    }

    testWidgets('filtering the same column again replaces its filter instead of narrowing it', (
      WidgetTester tester,
    ) async {
      await pumpTransactions(tester);
      final Field<dynamic> memo = transactionColumn(columnIdMemo);

      await filterColumn(tester, state, memo, <String>['Beta']);
      expect(listedMemos(state), <String>['Alpha', 'Alpha', 'Gamma']);

      await filterColumn(tester, state, memo, <String>['Beta', 'Alpha']);
      expect(listedMemos(state), <String>['Beta', 'Gamma']);
    });

    testWidgets('the filter opens with the values the active filter keeps ticked', (WidgetTester tester) async {
      await pumpTransactions(tester);
      final Field<dynamic> memo = transactionColumn(columnIdMemo);
      await filterColumn(tester, state, memo, <String>['Beta']);

      state.onCustomizeColumn(memo);
      await tester.pumpAndSettle();

      expect(isTicked(tester, 'Alpha'), isTrue);
      expect(isTicked(tester, 'Beta'), isFalse);
      expect(isTicked(tester, 'Gamma'), isTrue);
      await tester.tap(find.byKey(Constants.keyButtonCancel));
      await tester.pumpAndSettle();
    });

    testWidgets('ticking every value clears only that column, keeping the other columns filtered', (
      WidgetTester tester,
    ) async {
      await pumpTransactions(tester);
      final Field<dynamic> memo = transactionColumn(columnIdMemo);
      await filterColumn(tester, state, transactionColumn(columnIdAccount), <String>['Savings']);
      await filterColumn(tester, state, memo, <String>['Beta']);
      expect(listedMemos(state), <String>['Alpha', 'Gamma']);

      await filterColumn(tester, state, memo, <String>['Beta']);

      expect(listedMemos(state), <String>['Alpha', 'Beta', 'Gamma']);
    });
  });

  testWidgets('a numeric column lists its values in numeric order, aligned right', (WidgetTester tester) async {
    for (final (String name, int count) in <(String, int)>[('Nine', 9), ('Hundred', 100), ('Ten', 10)]) {
      Data().payees.getOrCreate(name, fireNotification: false).fieldCount.value = count;
    }
    await pumpTestApp(tester, services, const ViewPayees());
    final ViewForMoneyObjectsState state = tester.state<ViewForMoneyObjectsState>(find.byType(ViewPayees));
    final Payee nine = Data().payees.getByName('Nine')!;

    state.onCustomizeColumn(Payee.fieldsForColumnView.getFieldByName(nine.fieldCount.name));
    await tester.pumpAndSettle();

    expect(shownValues(tester), <String>['9', '10', '100']);
    expect(
      tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .every((CheckboxListTile tile) => (tile.title! as Text).textAlign == TextAlign.right),
      isTrue,
    );
    await tester.tap(find.byKey(Constants.keyButtonCancel));
    await tester.pumpAndSettle();
  });
}
