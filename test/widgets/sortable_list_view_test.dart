import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/shared/presentation/widgets/money_object_card_widget.dart';
import 'package:money/shared/presentation/widgets/sortable_list_view_widget.dart';
import 'package:money/shared/presentation/widgets/transaction_splits_list_view_widget.dart';
import 'package:money/widgets/state/selection_controller.dart';

import '../helpers/test_fixtures_helper.dart';

/// Returns a split of [amount] with [memo].
TransactionSplit _split(int id, double amount, String memo) => TransactionSplit(
  id: id,
  transactionId: 1,
  categoryId: -1,
  payeeId: -1,
  amount: amount,
  transferId: -1,
  memo: memo,
  flags: 0,
  budgetBalanceDate: null,
  data: Data(),
);

/// Returns true when the row showing [above] is drawn above the row showing [below].
bool _isAbove(WidgetTester tester, String above, String below) =>
    tester.getTopLeft(find.text(above)).dy < tester.getTopLeft(find.text(below)).dy;

void main() {
  late AppServices services;

  setUp(() {
    resetTestData();
    services = createTestServices();
  });

  tearDown(() => disposeTestServices(services));

  testWidgets('the splits list sorts its rows by the tapped column', (WidgetTester tester) async {
    await pumpTestApp(
      tester,
      services,
      ListViewTransactionSplits(
        splits: <TransactionSplit>[_split(1, 5, 'memo b'), _split(2, 1, 'memo a')],
        totalAmount: 6,
      ),
    );
    expect(_isAbove(tester, 'memo b', 'memo a'), isTrue);

    await tester.tap(find.text('Memo'));
    await tester.pumpAndSettle();

    expect(_isAbove(tester, 'memo a', 'memo b'), isTrue);
  });

  testWidgets('a long press selects the row, reports it and opens it', (WidgetTester tester) async {
    final ListController listController = ListController();
    addTearDown(listController.dispose);
    final SelectionController selection = SelectionController();
    final List<int> reportedSelections = <int>[];
    final List<String> opened = <String>[];
    final TransactionSplit split = _split(1, 5, 'memo b');

    await pumpTestApp(
      tester,
      services,
      SortableListView<TransactionSplit>(
        columnsToInclude: TransactionSplit.fields.definitions,
        getList: () => <TransactionSplit>[split],
        listController: listController,
        selectionController: selection,
        onUserChoiceChanged: (int _, bool _, int selectedId) => reportedSelections.add(selectedId),
        onItemLongPress: (BuildContext _, TransactionSplit item) => opened.add(item.fieldMemo.value),
      ),
    );
    await tester.longPress(find.text('memo b'));
    await tester.pumpAndSettle();

    expect(selection.firstSelectedId, split.uniqueId);
    expect(reportedSelections, <int>[split.uniqueId]);
    expect(opened, <String>['memo b']);
  });

  testWidgets('an adaptive box lists its rows, or says it has none', (WidgetTester tester) async {
    await pumpTestApp(
      tester,
      services,
      Builder(
        builder: (BuildContext context) => Column(
          children: <Widget>[
            buildAdaptiveBox(
              context: context,
              title: 'Renters',
              count: 2,
              itemBuilder: (BuildContext _, int index) => Text('row $index'),
            ),
            buildAdaptiveBox(
              context: context,
              title: 'Splits',
              count: 0,
              itemBuilder: (BuildContext _, int index) => Text('row $index'),
            ),
          ],
        ),
      ),
    );

    expect(find.text('row 0'), findsOneWidget);
    expect(find.text('row 1'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(find.text('${AppL10n.tr(AppTranslationKeys.noItems)} Splits'), findsOneWidget);
  });
}
