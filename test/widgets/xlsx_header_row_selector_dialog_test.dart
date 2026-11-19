import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/widgets/dialogs/xlsx_header_row_selector_dialog.dart';

/// Returns the row index currently selected in the shown header row selector dialog.
int? selectedRowIndex(WidgetTester tester) => tester.widget<RadioGroup<int>>(find.byType(RadioGroup<int>)).groupValue;

void main() {
  group('XlsxHeaderRowSelectorDialog', () {
    testWidgets('filters out rows with less than 3 columns and shows message when none qualify', (
      WidgetTester tester,
    ) async {
      // Test data with only rows having less than 3 columns
      final List<List<String>> testRows = <List<String>>[
        <String>['A'], // 1 column
        <String>['A', 'B'], // 2 columns
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(),
        ),
      );

      // Show the dialog
      final BuildContext context = tester.element(find.byType(Scaffold));
      showXlsxHeaderRowSelectorDialog(context: context, rows: testRows);

      await tester.pumpAndSettle();

      // Should show the filtering message
      expect(find.text('No rows found with 3 or more columns.'), findsOneWidget);
      expect(find.text('Select Header Row'), findsOneWidget);
    });

    testWidgets('filters rows and shows only eligible rows with correct numbering', (WidgetTester tester) async {
      // Test data with mixed columns (some < 3, some >= 3)
      final List<List<String>> testRows = <List<String>>[
        <String>['A'], // row 1: 1 column - excluded
        <String>['Date', 'Description', 'Amount'], // row 2: 3 columns - included
        <String>['X'], // row 3: 1 column - excluded
        <String>['Value', 'Balance'], // row 4: 2 columns - excluded
        <String>['Data', 'Descrição', 'Valor', 'Saldo'], // row 5: 4 columns - included
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(),
        ),
      );

      // Show the dialog
      final BuildContext context = tester.element(find.byType(Scaffold));
      showXlsxHeaderRowSelectorDialog(context: context, rows: testRows);

      await tester.pumpAndSettle();

      // Should show the filtering message indicating some rows were excluded
      expect(find.text('Showing 2 eligible rows (excluded rows with < 3 columns)'), findsOneWidget);

      // Should show Row 2 and Row 5 (the eligible rows)
      expect(find.text('Row 2'), findsOneWidget);
      expect(find.text('Row 5'), findsOneWidget);

      // Should not show excluded rows
      expect(find.text('Row 1'), findsNothing);
      expect(find.text('Row 3'), findsNothing);
      expect(find.text('Row 4'), findsNothing);
    });

    testWidgets('auto-selects best matching header row (date + description + amount combination)', (
      WidgetTester tester,
    ) async {
      // Test rows with different header combinations
      final List<List<String>> testRows = <List<String>>[
        <String>['Name', 'Address', 'Phone'], // row 1: generic columns
        <String>['Date', 'Description', 'Amount'], // row 2: perfect match
        <String>['Data', 'Detalhes', 'Valor'], // row 3: same but Portuguese
        <String>['Date', 'Amount'], // row 4: good but incomplete
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(),
        ),
      );

      // Show the dialog
      final BuildContext context = tester.element(find.byType(Scaffold));
      showXlsxHeaderRowSelectorDialog(context: context, rows: testRows);

      await tester.pumpAndSettle();

      // The dialog should auto-select row 2 (index 1 in the filtered list, but row 2 in original)
      // We can check that "Row 2" is selected, meaning the radio button for row 2 is checked

      // Find the RadioListTile for "Row 2" and verify it's selected
      final RadioListTile<int> radioForRow2 = tester.widget<RadioListTile<int>>(
        find.ancestor(
          of: find.text('Row 2'),
          matching: find.byType(RadioListTile<int>),
        ),
      );

      // The radio button should have value 1 (original index 1 = Row 2)
      expect(radioForRow2.value, 1);
    });

    testWidgets('auto-selects reasonable headers when perfect match not available', (WidgetTester tester) async {
      // Test rows with weaker matches
      final List<List<String>> testRows = <List<String>>[
        <String>['Name'], // row 1: 1 column - excluded
        <String>['Date', 'Amount', 'Balance'], // row 2: date + amount + balance (3 columns, good combination)
        <String>['Description', 'Value', 'Type'], // row 3: desc + amount + type (3 columns, also good)
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(),
        ),
      );

      // Show the dialog
      final BuildContext context = tester.element(find.byType(Scaffold));
      showXlsxHeaderRowSelectorDialog(context: context, rows: testRows);

      await tester.pumpAndSettle();

      // Should auto-select row 2 (Date + Amount is a good financial combination)
      final RadioListTile<int> radioForRow2 = tester.widget<RadioListTile<int>>(
        find.ancestor(
          of: find.text('Row 2'),
          matching: find.byType(RadioListTile<int>),
        ),
      );
      expect(radioForRow2.value, 1);
    });

    testWidgets('falls back to first eligible row when no good matches found', (WidgetTester tester) async {
      // Test rows with no financial headers ('Price' would count as an amount, like in the column mapper)
      final List<List<String>> testRows = <List<String>>[
        <String>['Name', 'Address', 'Phone'], // row 1: no financial keywords
        <String>['Product', 'Category', 'Size'], // row 2: no financial keywords
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(),
        ),
      );

      // Show the dialog
      final BuildContext context = tester.element(find.byType(Scaffold));
      showXlsxHeaderRowSelectorDialog(context: context, rows: testRows);

      await tester.pumpAndSettle();

      // Should auto-select first eligible row (row 1)
      final RadioListTile<int> radioForRow1 = tester.widget<RadioListTile<int>>(
        find.ancestor(
          of: find.text('Row 1'),
          matching: find.byType(RadioListTile<int>),
        ),
      );
      expect(radioForRow1.value, 0);
      expect(selectedRowIndex(tester), 0);
    });

    testWidgets('does not count a balance column as an amount, like the column mapper', (WidgetTester tester) async {
      final List<List<String>> testRows = <List<String>>[
        <String>['Date', 'Description', 'Balance'], // row 1: no amount column
        <String>['Date', 'Description', 'Amount'], // row 2: mappable header row
      ];

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      showXlsxHeaderRowSelectorDialog(context: tester.element(find.byType(Scaffold)), rows: testRows);
      await tester.pumpAndSettle();

      expect(selectedRowIndex(tester), 1);
    });

    testWidgets('selects a Portuguese header row', (WidgetTester tester) async {
      final List<List<String>> testRows = <List<String>>[
        <String>['Extrato', 'Conta 123', 'Período'], // row 1: statement title
        <String>['Data', 'Detalhes', 'Valor', 'Saldo'], // row 2: header row
        <String>['2024-01-15', 'Café', '-5,00', '100,00'], // row 3: data
      ];

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      showXlsxHeaderRowSelectorDialog(context: tester.element(find.byType(Scaffold)), rows: testRows);
      await tester.pumpAndSettle();

      expect(selectedRowIndex(tester), 1);
    });

    testWidgets('prioritizes rows with 3-5 columns for financial data', (WidgetTester tester) async {
      // Test 4-column and 2-column financial headers
      final List<List<String>> testRows = <List<String>>[
        <String>['Date', 'Amount'], // row 1: 2 columns (too few)
        <String>['Date', 'Description', 'Amount', 'Balance'], // row 2: 4 columns (ideal)
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(),
        ),
      );

      // Show the dialog
      final BuildContext context = tester.element(find.byType(Scaffold));
      showXlsxHeaderRowSelectorDialog(context: context, rows: testRows);

      await tester.pumpAndSettle();

      // Should prioritize row 2 (4 columns is preferred for financial data)
      final RadioListTile<int> radioForRow2 = tester.widget<RadioListTile<int>>(
        find.ancestor(
          of: find.text('Row 2'),
          matching: find.byType(RadioListTile<int>),
        ),
      );
      expect(radioForRow2.value, 1);
    });
  });
}
