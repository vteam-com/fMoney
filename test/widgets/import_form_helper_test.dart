import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/data/helpers/investment_type_helper.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/investment_import_fields_helper.dart';
import 'package:money/views/imports/investment/investment_import_panel.dart';
import 'package:money/views/imports/shared/import_form_helper.dart';

import '../helpers/test_fixtures_helper.dart';

/// Pumps [child] in a scaffold large enough for the manual import forms.
Future<void> _pumpForm(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = testWindowSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  setUp(resetTestData);

  testWidgets('showImportFormDialog shows the panel with Cancel before the action buttons', (
    WidgetTester tester,
  ) async {
    await _pumpForm(
      tester,
      Builder(
        builder: (BuildContext context) => ElevatedButton(
          onPressed: () => showImportFormDialog(
            context: context,
            panel: const Text('Form panel'),
            actionButtons: <Widget>[TextButton(onPressed: () {}, child: const Text('Record'))],
          ),
          child: const Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Form panel'), findsOneWidget);
    expect(find.text('Record'), findsOneWidget);

    await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.cancel)));
    await tester.pumpAndSettle();

    expect(find.text('Form panel'), findsNothing);
  });

  testWidgets('buildImportDateField reports the typed date', (WidgetTester tester) async {
    DateTime? picked;
    await _pumpForm(
      tester,
      buildImportDateField(
        date: DateTime(2024, 1, 15),
        onChanged: (DateTime date) {
          picked = date;
        },
      ),
    );

    expect(find.text(AppL10n.tr(AppTranslationKeys.date)), findsOneWidget);

    await tester.enterText(find.byType(TextField), '2024-02-20');

    expect(picked, DateTime(2024, 2, 20));
  });

  testWidgets('buildImportCategoryField reports the category picked by name', (WidgetTester tester) async {
    final Category groceries = Data().categories.appendNewMoneyObject(
      Category(id: -1, name: 'Groceries', type: CategoryType.expense),
      fireNotification: false,
    ) as Category;
    Category? picked;
    await _pumpForm(
      tester,
      buildImportCategoryField(
        category: null,
        onChanged: (Category category) {
          picked = category;
        },
      ),
    );

    await tester.enterText(find.byType(TextField), 'Unknown');
    expect(picked, isNull);

    await tester.enterText(find.byType(TextField), 'Groceries');
    expect(picked, same(groceries));
  });

  testWidgets('ImportInvestmentPanel stores the picked account and listens to no keyboard', (
    WidgetTester tester,
  ) async {
    final Account checking = createTestAccount('Checking');
    final Account brokerage = createTestAccount('Brokerage');
    final InvestmentImportFields fields = InvestmentImportFields(
      account: checking,
      date: DateTime(2024, 1, 15),
      investmentType: InvestmentType.buy,
      category: Data().categories.investmentOther,
      symbol: '',
      units: 1,
      amountPerUnit: 0,
      transactionAmount: 0,
      description: '',
    );
    await _pumpForm(tester, ImportInvestmentPanel(inputFields: fields));

    expect(find.byType(KeyboardListener), findsNothing);

    await tester.enterText(
      find.descendant(of: find.byKey(Constants.keyAccountPicker), matching: find.byType(TextField)),
      'Brokerage',
    );
    await tester.pump();

    expect(fields.account, same(brokerage));
  });
}
