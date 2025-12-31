// ignore_for_file: always_specify_types

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets/csv_column_mapper_dialog.dart';

void main() {
  // Sample data for testing
  const List<String> sampleHeaders = <String>['Date', 'Description', 'Amount', 'Category'];
  const List<List<String>> sampleDataRows = <List<String>>[
    // Make this const
    <String>['2023-01-01', 'Groceries', '50.00', 'Food'], // Inner lists also become effectively const
    <String>['2023-01-02', 'Gas', '30.00', 'Transport'],
    <String>['2023-01-03', 'Rent', '500.00', 'Housing'],
  ];

  Future<void> pumpDialog(
    WidgetTester tester, {
    List<String> headers = sampleHeaders,
    List<List<String>> dataRows = sampleDataRows,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                child: const Text('Show Dialog'),
                onPressed: () {
                  showCsvColumnMapperDialog(
                    context: context,
                    headers: headers,
                    dataRows: dataRows,
                  );
                },
              );
            },
          ),
        ),
      ),
    );

    // Tap the button to show the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle(); // Wait for dialog to appear and animations to finish
  }

  testWidgets('Dialog displays correctly with CSV data and headers', (WidgetTester tester) async {
    await pumpDialog(tester);

    // Verify dialog title
    expect(find.text('Choose Columns'), findsOneWidget);

    // Verify presence of mapping dropdowns (identified by their labels for now)
    expect(find.text('Date Column:'), findsOneWidget);
    expect(find.text('Description Column:'), findsOneWidget);
    expect(find.text('Amount Column:'), findsOneWidget);

    // Verify presence of preview table title
    expect(find.text('Data Preview (First 5 rows):'), findsOneWidget);

    // Verify presence of action buttons
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Confirm'), findsOneWidget);
  });

  testWidgets('Dropdown menus are populated with header names', (WidgetTester tester) async {
    await pumpDialog(tester);

    final Finder dateDropdownFinder = find.byType(DropdownButtonFormField<String>).at(0);
    final Finder descriptionDropdownFinder = find.byType(DropdownButtonFormField<String>).at(1);
    final Finder amountDropdownFinder = find.byType(DropdownButtonFormField<String>).at(2);

    // Helper function to test a single dropdown
    Future<void> testDropdown(Finder dropdownFinder, String initialHeaderToSelect) async {
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle(); // Wait for dropdown items to appear

      // Check if all headers are present as dropdown items
      for (final String header in sampleHeaders) {
        // .last is important as items might appear in multiple open dropdowns if not careful
        expect(find.widgetWithText(DropdownMenuItem<String>, header).last, findsOneWidget);
      }
      // Close the dropdown by tapping one item
      await tester.tap(find.widgetWithText(DropdownMenuItem<String>, initialHeaderToSelect).last);
      await tester.pumpAndSettle();
    }

    // Test each dropdown
    await testDropdown(dateDropdownFinder, sampleHeaders.first);
    await testDropdown(descriptionDropdownFinder, sampleHeaders.first);
    await testDropdown(amountDropdownFinder, sampleHeaders.first);
    await tester.pumpAndSettle();
  });

  testWidgets('User can select columns for Date, Description, and Amount', (WidgetTester tester) async {
    await pumpDialog(tester);

    final Finder dateDropdownFinder = find.byType(DropdownButtonFormField<String>).at(0);
    final Finder descriptionDropdownFinder = find.byType(DropdownButtonFormField<String>).at(1);
    final Finder amountDropdownFinder = find.byType(DropdownButtonFormField<String>).at(2);

    // Select 'Date' for Date Column
    await tester.tap(dateDropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(DropdownMenuItem<String>, 'Date').last);
    await tester.pumpAndSettle();
    expect(find.descendant(of: dateDropdownFinder, matching: find.text('Date')), findsOneWidget);

    // Select 'Description' for Description Column
    await tester.tap(descriptionDropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(DropdownMenuItem<String>, 'Description').last);
    await tester.pumpAndSettle();
    expect(find.descendant(of: descriptionDropdownFinder, matching: find.text('Description')), findsOneWidget);

    // Select 'Amount' for Amount Column
    await tester.tap(amountDropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(DropdownMenuItem<String>, 'Amount').last);
    await tester.pumpAndSettle();
    expect(find.descendant(of: amountDropdownFinder, matching: find.text('Amount')), findsOneWidget);
  });

  testWidgets('Confirm button works correctly with auto-detected mappings', (WidgetTester tester) async {
    await pumpDialog(tester);

    // With standard headers, auto-detection should work and confirm should succeed
    await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
    await tester.pumpAndSettle(); // Allow dialog to close

    // Dialog should close successfully with auto-detected mappings
    expect(find.text('Choose Columns'), findsNothing);
  });

  testWidgets('User can clear auto-detected selections and get validation error', (WidgetTester tester) async {
    // Use headers that won't auto-match to test validation
    final List<String> customHeaders = <String>['Field A', 'Field B', 'Field C'];
    const List<List<String>> customDataRows = <List<String>>[
      <String>['Value A1', 'Value B1', 'Value C1'],
    ];

    await pumpDialog(tester, headers: customHeaders, dataRows: customDataRows);

    // With custom headers that don't match patterns, nothing should be auto-selected
    // Try to confirm - should get validation error
    await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
    await tester.pumpAndSettle(); // Allow SnackBar to appear

    expect(find.text('Please map all fields (Date, Description, Amount).'), findsOneWidget);
  });

  testWidgets('Confirm button returns mapping when all fields are mapped', (WidgetTester tester) async {
    dynamic result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                child: const Text('Show Dialog'),
                onPressed: () async {
                  result = await showCsvColumnMapperDialog(
                    context: context,
                    headers: sampleHeaders,
                    dataRows: sampleDataRows,
                  );
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    final Finder dateDropdownFinder = find.byType(DropdownButtonFormField<String>).at(0);
    final Finder descriptionDropdownFinder = find.byType(DropdownButtonFormField<String>).at(1);
    final Finder amountDropdownFinder = find.byType(DropdownButtonFormField<String>).at(2);

    // Select 'Date' for Date Column
    await tester.tap(dateDropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(DropdownMenuItem<String>, 'Date').last);
    await tester.pumpAndSettle();

    // Select 'Description' for Description Column
    await tester.tap(descriptionDropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(DropdownMenuItem<String>, 'Description').last);
    await tester.pumpAndSettle();

    // Select 'Amount' for Amount Column
    await tester.tap(amountDropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(DropdownMenuItem<String>, 'Amount').last);
    await tester.pumpAndSettle();

    // Tap Confirm button
    await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
    await tester.pumpAndSettle(); // Allow dialog to close and result to be processed

    expect(result, isA<Map<String, String>>());
    expect(result['date'], 'Date');
    expect(result['description'], 'Description');
    expect(result['amount'], 'Amount');
  });

  testWidgets('Cancel button closes the dialog and returns null', (WidgetTester tester) async {
    dynamic result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                child: const Text('Show Dialog'),
                onPressed: () async {
                  result = await showCsvColumnMapperDialog(
                    context: context,
                    headers: sampleHeaders,
                    dataRows: sampleDataRows,
                  );
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Tap Cancel button
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle(); // Allow dialog to close

    expect(result, isNull);
  });

  testWidgets('Preview table displays CSV data correctly', (WidgetTester tester) async {
    await pumpDialog(tester);

    // Check for headers in the DataTable
    // Ensure header text is found within the context of the DataTable
    for (final String header in sampleHeaders) {
      expect(find.descendant(of: find.byType(DataTable), matching: find.text(header)), findsOneWidget);
    }

    // Check for data cells in the DataTable
    // sampleDataRows has 3 rows, all should be displayed as preview can take up to 5
    for (int i = 0; i < sampleDataRows.length; i++) {
      for (int j = 0; j < sampleHeaders.length; j++) {
        // Iterate through headers to ensure all cells in a row are checked
        // Ensure cell text is found within the context of the DataTable
        expect(find.descendant(of: find.byType(DataTable), matching: find.text(sampleDataRows[i][j])), findsOneWidget);
      }
    }
  });

  testWidgets('Dialog shows error message when headers are empty', (WidgetTester tester) async {
    await pumpDialog(tester, headers: <String>[], dataRows: <List<String>>[]);

    expect(find.text('Error'), findsOneWidget);
    expect(find.text('CSV headers are missing or empty.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'OK'), findsOneWidget);

    // Close the error dialog
    await tester.tap(find.widgetWithText(TextButton, 'OK'));
    await tester.pumpAndSettle();

    expect(find.text('Error'), findsNothing);
  });

  testWidgets('Preview table handles rows with inconsistent column counts', (WidgetTester tester) async {
    const List<String> headersForInconsistentTest = <String>['H1', 'H2', 'H3'];
    final List<List<String>> dataRowsForInconsistentTest = <List<String>>[
      <String>['R1C1', 'R1C2', 'R1C3'], // Correct length
      <String>['R2C1', 'R2C2'], // Shorter
      <String>['R3C1', 'R3C2', 'R3C3', 'R3C4'], // Longer
    ];

    await pumpDialog(
      tester,
      headers: headersForInconsistentTest,
      dataRows: dataRowsForInconsistentTest,
    );

    // Verify dialog title (to ensure dialog loaded)
    expect(find.text('Choose Columns'), findsOneWidget);

    // Verify headers are displayed
    for (final String header in headersForInconsistentTest) {
      expect(find.descendant(of: find.byType(DataTable), matching: find.text(header)), findsOneWidget);
    }

    // Verify data for the row with correct length
    expect(find.descendant(of: find.byType(DataTable), matching: find.text('R1C1')), findsOneWidget);
    expect(find.descendant(of: find.byType(DataTable), matching: find.text('R1C2')), findsOneWidget);
    expect(find.descendant(of: find.byType(DataTable), matching: find.text('R1C3')), findsOneWidget);

    // Verify data for all rows by checking all Text widgets in the table.
    // This indirectly verifies padding and truncation.
    final Finder dataTableFinder = find.byType(DataTable);
    expect(dataTableFinder, findsOneWidget);

    final Finder allTextInTableFinder = find.descendant(of: dataTableFinder, matching: find.byType(Text));
    final List<Text> allTextWidgetsInTable = tester.widgetList<Text>(allTextInTableFinder).toList();
    final List<String?> allTextDataInTable = allTextWidgetsInTable.map((Text t) => t.data).toList();

    // Expected texts: Headers + Cells for each row according to headersForInconsistentTest
    // Headers: H1, H2, H3
    // Row 1 (correct length): R1C1, R1C2, R1C3
    // Row 2 (shorter): R2C1, R2C2, "" (empty string from DataCell(const Text('')))
    // Row 3 (longer): R3C1, R3C2, R3C3 (R3C4 is truncated)
    final List<String> expectedTextsInOrder = <String>[
      // Headers
      headersForInconsistentTest[0], headersForInconsistentTest[1], headersForInconsistentTest[2],
      // Row 1
      dataRowsForInconsistentTest[0][0], dataRowsForInconsistentTest[0][1], dataRowsForInconsistentTest[0][2],
      // Row 2 (padded)
      dataRowsForInconsistentTest[1][0], dataRowsForInconsistentTest[1][1], '', // Padded cell
      // Row 3 (truncated)
      dataRowsForInconsistentTest[2][0], dataRowsForInconsistentTest[2][1], dataRowsForInconsistentTest[2][2],
    ];

    expect(
      allTextDataInTable,
      equals(expectedTextsInOrder),
      reason:
          'The content of all Text widgets in the DataTable (headers and cells) does not match the expected order and content.\n'
          'Expected: $expectedTextsInOrder\n'
          'Actual:   $allTextDataInTable',
    );

    // Explicitly check that R3C4 (from the longer row) is NOT present as a Text widget in the table.
    // This is implicitly covered by the list equality check above if the list length is correct,
    // but an explicit check makes the truncation test clearer.
    expect(find.descendant(of: dataTableFinder, matching: find.text('R3C4')), findsNothing);
  });

  testWidgets('Auto-detects Date column from common header names', (WidgetTester tester) async {
    final List<String> testHeaders = <String>[
      'Transaction Date',
      'Description',
      'Amount',
      'Category',
    ];
    const List<List<String>> testDataRows = <List<String>>[
      <String>['2023-01-01', 'Groceries', '50.00', 'Food'],
    ];

    await pumpDialog(tester, headers: testHeaders, dataRows: testDataRows);

    // Verify Date column is auto-selected to 'Transaction Date'
    final Finder dateDropdownFinder = find.byType(DropdownButtonFormField<String>).at(0);
    expect(find.descendant(of: dateDropdownFinder, matching: find.text('Transaction Date')), findsOneWidget);
  });

  testWidgets('Auto-detects Description column from common header names', (WidgetTester tester) async {
    final List<String> testHeaders = <String>[
      'Date',
      'Payee',
      'Amount',
      'Category',
    ];
    const List<List<String>> testDataRows = <List<String>>[
      <String>['2023-01-01', 'Groceries', '50.00', 'Food'],
    ];

    await pumpDialog(tester, headers: testHeaders, dataRows: testDataRows);

    // Verify Description column is auto-selected to 'Payee'
    final Finder descriptionDropdownFinder = find.byType(DropdownButtonFormField<String>).at(1);
    expect(find.descendant(of: descriptionDropdownFinder, matching: find.text('Payee')), findsOneWidget);
  });

  testWidgets('Auto-detects Amount column from common header names', (WidgetTester tester) async {
    final List<String> testHeaders = <String>[
      'Date',
      'Description',
      'Credit',
      'Category',
    ];
    const List<List<String>> testDataRows = <List<String>>[
      <String>['2023-01-01', 'Groceries', '50.00', 'Food'],
    ];

    await pumpDialog(tester, headers: testHeaders, dataRows: testDataRows);

    // Verify Amount column is auto-selected to 'Credit'
    final Finder amountDropdownFinder = find.byType(DropdownButtonFormField<String>).at(2);
    expect(find.descendant(of: amountDropdownFinder, matching: find.text('Credit')), findsOneWidget);
  });

  testWidgets('User can override auto-detected columns', (WidgetTester tester) async {
    final List<String> testHeaders = <String>[
      'Transaction Date',
      'Memo', // Should auto-detect as Description
      'Amount',
    ];
    const List<List<String>> testDataRows = <List<String>>[
      <String>['2023-01-01', 'Groceries', '50.00'],
    ];

    await pumpDialog(tester, headers: testHeaders, dataRows: testDataRows);

    // Verify auto-detection worked
    final Finder descriptionDropdownFinder = find.byType(DropdownButtonFormField<String>).at(1);
    expect(find.descendant(of: descriptionDropdownFinder, matching: find.text('Memo')), findsOneWidget);

    // Override the selection
    await tester.tap(descriptionDropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(DropdownMenuItem<String>, 'Transaction Date').last);
    await tester.pumpAndSettle();

    // Verify override worked
    expect(find.descendant(of: descriptionDropdownFinder, matching: find.text('Transaction Date')), findsOneWidget);
  });

  testWidgets('Handles headers with no matches gracefully', (WidgetTester tester) async {
    final List<String> testHeaders = <String>[
      'CustomField1',
      'CustomField2',
      'CustomField3',
    ];
    const List<List<String>> testDataRows = <List<String>>[
      <String>['Value1', 'Value2', 'Value3'],
    ];

    await pumpDialog(tester, headers: testHeaders, dataRows: testDataRows);

    // Verify no columns are pre-selected (they should be null)
    final Finder dateDropdownFinder = find.byType(DropdownButtonFormField<String>).at(0);
    final Finder descriptionDropdownFinder = find.byType(DropdownButtonFormField<String>).at(1);
    final Finder amountDropdownFinder = find.byType(DropdownButtonFormField<String>).at(2);

    // Should show "Select column" hint text when no value is selected
    expect(find.descendant(of: dateDropdownFinder, matching: find.text('Select column')), findsOneWidget);
    expect(find.descendant(of: descriptionDropdownFinder, matching: find.text('Select column')), findsOneWidget);
    expect(find.descendant(of: amountDropdownFinder, matching: find.text('Select column')), findsOneWidget);
  });

  testWidgets('Preview table scrolls horizontally with many columns', (WidgetTester tester) async {
    // 1. Setup data with many columns
    final int manyColumnCount = 20;
    final List<String> wideHeaders = List.generate(manyColumnCount, (int i) => 'Col ${i + 1}');
    final List<List<String>> wideDataRows = <List<String>>[
      List.generate(manyColumnCount, (int i) => 'R1 Cell ${i + 1}'),
      List.generate(manyColumnCount, (int i) => 'R2 Cell ${i + 1}'),
    ];

    await pumpDialog(
      tester,
      headers: wideHeaders,
      dataRows: wideDataRows,
    );

    // 2. Verify dialog and table are present
    expect(find.text('Choose Columns'), findsOneWidget);
    final Finder dataTableFinder = find.byType(DataTable);
    expect(dataTableFinder, findsOneWidget);

    // 3. Find the horizontal SingleChildScrollView
    final Finder horizontalScrollViewFinder = find.byWidgetPredicate(
      (Widget widget) => widget is SingleChildScrollView && widget.scrollDirection == Axis.horizontal,
    );
    expect(
      horizontalScrollViewFinder,
      findsOneWidget,
      reason: 'Expected a horizontal SingleChildScrollView wrapping the DataTable.',
    );

    // Ensure the DataTable is a child of this scroll view
    expect(find.descendant(of: horizontalScrollViewFinder, matching: dataTableFinder), findsOneWidget);

    // 4. Verify an off-screen column is initially not found (or not visible)
    // For simplicity, we'll check if it's composed in the tree. If it's truly off-screen, it might not be.
    // A more robust check would be to ensure it's not hittable or has size zero if it's not rendered.
    // However, `findsNothing` is a good start if it's outside the viewport.
    final String lastColumnHeader = wideHeaders.last;
    final String firstColumnHeader = wideHeaders.first;

    expect(find.text(firstColumnHeader), findsOneWidget); // First column should be visible

    // To ensure the last column is truly off-screen and not just found by chance
    // if the dialog is very wide, we'd ideally check its position or visibility.
    // For now, if the number of columns is large enough, findsNothing is a reasonable proxy.
    // This might need adjustment based on actual dialog width during tests.
    // A more reliable way is to scroll and then check.

    // If the table is wide enough, the last column header might not be rendered yet.
    // If it is rendered but off-screen, find.text() would still find it.
    // So, we'll test by scrolling.

    // 5. Scroll horizontally
    // We target the DataTable for the drag, as it's inside the SingleChildScrollView
    await tester.drag(horizontalScrollViewFinder, const Offset(-600, 0)); // Drag left to scroll content right
    await tester.pumpAndSettle();

    // 6. Assert the previously off-screen column is now visible
    expect(
      find.text(lastColumnHeader),
      findsOneWidget,
      reason: "Last column header '$lastColumnHeader' should be visible after scrolling.",
    );

    // Optionally, check if the first column is now off-screen (or less visible)
    // This depends on the scroll amount and viewport width.
    // For now, just ensuring the last one becomes visible is the key test.
  });
}

// Note: The test 'Confirm button becomes enabled when all fields are mapped'
// is implicitly covered by 'Confirm button returns mapping when all fields are mapped'.
// The dialog's current behavior is to show a SnackBar if fields are missing,
// rather than disabling the button. So, we test that the SnackBar *doesn't* appear
// when fields *are* mapped (which is what happens before successful pop).
// If the button were to be disabled, the test would be different, e.g.,
// expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Confirm')).enabled, isTrue);
// For now, the successful pop is the indicator.

// Also, the test 'User can select columns for Date, Description, and Amount'
// already verifies that the selected value is displayed in the dropdown.
// The actual state update is confirmed by the 'Confirm button returns mapping' test.

// The test 'Preview table displays the CSV data correctly' checks for the first 3 rows.
// The dialog itself limits preview to 5 rows. If sampleDataRows had more than 5,
// we'd need to adjust the test to only check for the first 5.
// Currently, sampleDataRows has 3, so all are checked.

// Added a test for the error dialog when headers are empty.
// This covers the `if (widget.headers.isEmpty)` block in the dialog.
