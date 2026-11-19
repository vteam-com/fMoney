import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_filters_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/entity_widgets/entity_widgets_helper.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/home/transactions/transactions_view.dart';
import 'package:money/widgets/list/adaptive_columns_or_rows_list_widget.dart';
import 'package:money/widgets/list/list_jump_bar_widget.dart';

import '../helpers/test_fixtures_helper.dart';

/// Column index of the payee name, a text column, in [Payee.fieldsForColumnView].
const int _nameColumn = 0;

/// Column index of the payee transaction count, a numeric column, in [Payee.fieldsForColumnView].
const int _countColumn = 2;

/// Rows created per initial letter, enough for the later letters to start off screen.
const int _rowsPerLetter = 40;

/// Returns payees named `A00`..`A39`, `C00`..`C39`, `M00`..`M39`, already sorted by name.
List<DataObject> _payeesSortedByName() {
  final List<DataObject> payees = <DataObject>[];
  for (final String letter in <String>['A', 'C', 'M']) {
    for (int i = 0; i < _rowsPerLetter; i++) {
      payees.add(
        Payee()
          ..uniqueId = payees.length + 1
          ..fieldName.value = '$letter${i.toString().padLeft(2, '0')}',
      );
    }
  }
  return payees;
}

/// Pumps a Payee list sorted on [sortByFieldIndex] and returns its scroll controller.
Future<ListController> _pumpPayeeList(WidgetTester tester, int sortByFieldIndex) async {
  final ListController listController = ListController();
  final FieldDefinitions fields = Payee.fieldsForColumnView.definitions;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdaptiveListColumnsOrRows(
          list: _payeesSortedByName(),
          fieldDefinitions: fields,
          filters: FieldFilters(),
          selectedItemsByUniqueId: ValueNotifier<List<int>>(<int>[]),
          displayAsColumns: true,
          listController: listController,
          widgetBuilders: entityWidgetBuilders,
          sortByFieldIndex: sortByFieldIndex,
        ),
      ),
    ),
  );
  return listController;
}

void main() {
  group('firstIndexByJumpLetter', () {
    test('maps each letter to its first row, ignoring case and leading spaces', () {
      expect(
        firstIndexByJumpLetter(<String>['alpha', 'Apple', 'bravo', '  charlie', 'Delta']),
        <String, int>{'A': 0, 'B': 2, 'C': 3, 'D': 4},
      );
    });

    test('leaves out empty texts and texts not starting with A to Z', () {
      expect(
        firstIndexByJumpLetter(<String>['', '7-Eleven', '#tag', 'Épicerie', 'zebra']),
        <String, int>{'Z': 4},
      );
    });
  });

  group('AdaptiveListColumnsOrRows jump bar', () {
    setUp(() {
      DataFileController.instance = DataFileController();
      Data().clearExistingData();
    });

    tearDown(() {
      Data().clearExistingData();
      DataFileController.instance = null;
    });

    testWidgets('grays out letters without rows and jumps to the first row of a tapped letter', (
      WidgetTester tester,
    ) async {
      final ListController listController = await _pumpPayeeList(tester, _nameColumn);
      final Finder bar = find.byType(ListJumpBar);
      expect(bar, findsOneWidget);

      // Letters with rows are tappable, letters without rows are not.
      expect(find.descendant(of: bar, matching: find.widgetWithText(InkWell, 'C')), findsOneWidget);
      expect(find.descendant(of: bar, matching: find.widgetWithText(InkWell, 'B')), findsNothing);
      expect(find.descendant(of: bar, matching: find.text('B')), findsOneWidget);

      expect(find.text('M00'), findsNothing);
      await tester.tap(find.descendant(of: bar, matching: find.text('M')));
      await tester.pump();

      expect(find.text('M00'), findsOneWidget);
      expect(find.text('A00'), findsNothing);
      expect(listController.scrollController.offset, greaterThan(0));

      listController.dispose();
    });

    testWidgets('hides the jump bar when sorted on a non-text column', (WidgetTester tester) async {
      final ListController listController = await _pumpPayeeList(tester, _countColumn);
      expect(find.byType(ListJumpBar), findsNothing);
      listController.dispose();
    });
  });

  group('Transactions view jump bar', () {
    late AppServices services;

    setUp(() {
      resetTestData();
      services = createTestServices();
    });

    tearDown(() => disposeTestServices(services));

    /// Returns the letters the jump bar currently offers.
    Set<String> offeredLetters(WidgetTester tester) =>
        tester.widget<ListJumpBar>(find.byType(ListJumpBar)).firstIndexByLetter.keys.toSet();

    testWidgets('offers the payee and category letters, leaving out transfers', (WidgetTester tester) async {
      final Account checking = createTestAccount();
      final Category food = Data().categories.addNewCategory(name: 'Food');
      final Category household = Data().categories.addNewCategory(name: 'Household');
      createTestTransaction(checking, 'Amazon', category: food);
      createTestTransaction(checking, 'Costco', category: household);
      createTestTransaction(checking, 'Zeller', isTransfer: true).fieldPayee.value = -1;

      await pumpTestApp(tester, services, const ViewTransactions());
      final Transaction template = Transaction(date: DateTime(2024));

      await tester.tap(find.text(template.fieldPayee.name));
      await tester.pumpAndSettle();
      expect(offeredLetters(tester), <String>{'A', 'C'}, reason: 'a transfer has no payee name, whatever its caption');

      await tester.tap(find.text(template.fieldCategoryId.name));
      await tester.pumpAndSettle();
      expect(offeredLetters(tester), <String>{'F', 'H'});
    });
  });
}
