import 'dart:io';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money/core/controller/data_controller.dart';
import 'package:money/core/controller/preferences_controller.dart';
import 'package:money/core/widgets/side_panel/side_panel_header.dart';
import 'package:money/core/widgets/snack_bar.dart';
import 'package:money/data/storage/data/data.dart';
import 'package:money/data/storage/data/data_source.dart';
import 'package:money/data/storage/import/import_qfx.dart';
import 'package:money/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

export 'package:money/core/widgets/widgets.dart';

void main() {
  group('App Test', () {
    testWidgets('Full app test', (WidgetTester tester) async {
      // Use an empty SharedPreferences to get the same results each time
      SharedPreferences.setMockInitialValues(<String, Object>{});

      // // Enable GetX test mode to allow contextless navigation in tests
      Get.testMode = true;

      // Enable snackbar testing mode to skip showing snackbars in integration tests
      SnackBarService.enableTestingMode();

      app.main();
      await tester.pumpAndSettle();

      //*************************************************************************
      //
      // Small screen
      //
      await switchToSmall(tester);
      await stepWelcomeSettingAndTheme(tester);

      //*************************************************************************
      //
      // Medium screen - import
      //
      await switchToMedium(tester);
      await stepImportWizardOptions(tester);

      //------------------------------------------------------------------------
      // Close the current file
      await tapOnKeyString(tester, 'key_menu_button');
      await tester.pumpAndSettle();
      await tapOnText(tester, 'Close file');
      await tester.pumpAndSettle();

      //*************************************************************************
      //
      // Large screen - Demo data
      //
      await switchToLarge(tester);
      await stepDemoDataViews(tester);

      //*************************************************************************
      //
      // Back to small screen using Demo data
      //
      await switchToSmall(tester);
      await stepDemoDataViewInSmallScreen(tester);
    });
  });
}

Future<void> stepWelcomeSettingAndTheme(WidgetTester tester) async {
  //------------------------------------------------------------------------
  // Welcome screen - Policy
  await testWelcomeScreen(tester);

  //------------------------------------------------------------------------
  // Themes
  await testTheme(tester);

  //------------------------------------------------------------------------
  // Platforms
  await tapOnKey(tester, Constants.keySettingsButton);
  await tapOnKey(tester, Constants.keyPlatformsButton);
  await tapBackButton(tester);

  //------------------------------------------------------------------------
  // The Settings dialog
  await testThemeColors(tester);
}

Future<void> stepDemoDataViewInSmallScreen(WidgetTester tester) async {
  await tapOnKeyString(tester, 'key_menu_cashflow');
  await tapOnKeyString(tester, 'key_menu_events');
  await tapOnKeyString(tester, 'key_menu_accounts');
  await tapOnKeyString(tester, 'key_menu_categories');
  await tapOnKeyString(tester, 'key_menu_payees');
  await tapOnKeyString(tester, 'key_menu_aliases');
  await tapOnKeyString(tester, 'key_menu_transactions');
  await tapOnKeyString(tester, 'key_menu_transfers');
  await tapOnKeyString(tester, 'key_menu_investments');
  await tapOnKeyString(tester, 'key_menu_stocks');
  await tapOnKeyString(tester, 'key_menu_rentals');
}

Future<void> stepDemoDataViews(WidgetTester tester) async {
  //------------------------------------------------------------------------
  // Open a Demo Data
  await tapOnText(tester, 'Use Demo Data');

  for (final MoneyObjects<dynamic> table in Data().tables) {
    expect(table.isNotEmpty, true, reason: table.collectionName);
    final String text = table.firstItem(false).toString();
    // ignore: avoid_print
    // print('${table.collectionName}>$text');
    expect(text.isNotEmpty, true, reason: '${table.collectionName}=[$text]');
  }

  //------------------------------------------------------------------------
  // Show the Settings dialog in Larger screen size
  await testSettingsFontsAndRental(tester);

  //------------------------------------------------------------------------
  // Cash Flow
  await testCashFlow(tester);

  //------------------------------------------------------------------------
  // Events
  await testEvents(tester);

  //------------------------------------------------------------------------
  // Accounts
  await testAccounts(tester);

  //------------------------------------------------------------------------
  // Categories
  await testCategories(tester);

  //------------------------------------------------------------------------
  // Payees
  await testPayees(tester);

  //------------------------------------------------------------------------
  // Aliases
  await testAliases(tester);

  //------------------------------------------------------------------------
  // Transactions
  await testTransactions(tester);

  //------------------------------------------------------------------------
  // Transfers
  await testTransfers(tester);

  //------------------------------------------------------------------------
  // Investments
  await testInvestments(tester);

  //------------------------------------------------------------------------
  // Stocks
  await testStocks(tester);

  //------------------------------------------------------------------------
  // Rentals
  await testRentals(tester);

  //------------------------------------------------------------------------
  // Pending Changes
  await testPendingChanges(tester);
}

Future<void> stepImportWizardOptions(WidgetTester tester) async {
  // Import QFX
  await testImportQfx(tester);

  // Import from manual text input in bulk
  await testImportBulkManualTextInput(tester);

  // Record a Transfer
  await testImportWizadRecordTransfer(tester);
}

Future<void> bringUpImportWizard(final WidgetTester tester) async {
  // Import Wizard
  await tapOnKeyString(tester, 'key_menu_button');
  await tapOnText(tester, 'Add transactions...');
}

Future<void> testImportQfx(WidgetTester tester) async {
  // Import Wizard
  await bringUpImportWizard(tester);

  // Also test the Import from file
  {
    const String fileContent = '''<OFX><BANKACCTFROM>
    <BANKID>123456<ACCTID>00001 99-55555<ACCTTYPE>SAVINGS</BANKACCTFROM>
    <BANKTRANLIST><STMTTRN><TRNTYPE>DEBIT<DTPOSTED>20230810
    <TRNAMT>-50.00<NAME>Sample Transaction</STMTTRN></BANKTRANLIST></OFX>''';

    // Should not throw error when context is null
    final BuildContext context = tester.element(find.byType(Navigator));
    expect(() => importQfxFromString(context, fileContent), returnsNormally);

    // Verify import success
    await tester.pumpAndSettle();
    // Wait for the dialog box to appear
    expect(find.text('Pick account to import to'), findsOneWidget);
    await tapOnText(tester, 'New Bank Account', lastOneFound: true);
    await tester.pumpAndSettle();
    await tapOnText(tester, 'Import');
    // expect(find.text('Imported'), findsOneWidget);
    await tester.pumpAndSettle();

    // Close the dialog
    await tapOnText(tester, 'Cancel');
  }
}

Future<void> testImportBulkManualTextInput(WidgetTester tester) async {
  // Import Wizard
  await bringUpImportWizard(tester);

  await tapOnText(tester, 'Manual bulk text input');
  await tester.myPump();

  // Drop down
  await tapOnKeyString(tester, 'key_dropdown');
  await tapOnText(tester, 'New Bank Account');
  await tapOnText(tester, 'Close');

  await tapOnKeyString(tester, 'key_import_tab_free_style');
  await tester.pumpAndSettle();
  final Finder textFieldInput = find.byKey(const Key('key_input_text_field_value')).at(0); // top most element found
  await tester.pumpAndSettle(Durations.extralong4);
  await inputTextToElement(
    tester,
    textFieldInput,
    '2001-12-25;Hawaii;123.45\n2002-12-25;ABC;-123.45\n2003-01-01;Ibiza;(77.99)\nabc;+123.45\nHawaii;99.99',
  );
  await tester.pumpAndSettle(Durations.extralong4);
  await tapOnKeyString(tester, 'key_import_tab_three_columns');
  await tester.pumpAndSettle(Durations.extralong4);
  await tapOnKeyString(tester, 'key_import_tab_free_style');
  await tester.pumpAndSettle(Durations.extralong4);

  // Close ImportDialog
  await tapOnText(tester, 'Import');
}

Future<void> testThemeColors(WidgetTester tester) async {
  // Change Colors, Purple is the default, and we use "Teal" as the last color.
  {
    for (final String themeColorName in <String>[
      'Blue',
      'Green',
      'Yellow',
      'Orange',
      'Pink',
      'Teal',
    ]) {
      await tapOnKey(tester, Constants.keySettingsButton);
      await tapOnKeyString(tester, 'key_theme_$themeColorName');
    }
  }
}

Future<void> testSettingsFontsAndRental(WidgetTester tester) async {
  await tapOnKey(tester, Constants.keySettingsButton);
  // Test Font Scaling
  {
    await tapOnKey(tester, Constants.keyZoomIncrease);
    await tapOnKey(tester, Constants.keyZoomIncrease);
    await tapOnKey(tester, Constants.keyZoomNormal);
    await tapOnKey(tester, Constants.keyZoomDecrease);
  }

  await tapOnKeyString(tester, 'key_settings');

  // Turn on Rentals
  {
    // Find the SwitchListTile using the text label provided in the Semantics
    final Finder switchTileFinder = find.byWidgetPredicate(
      (Widget widget) => widget is SwitchListTile && widget.title is Text && (widget.title as Text).data == 'Rental',
    );

    // Verify initial state is OFF (false)
    final SwitchListTile switchTile = tester.widget(switchTileFinder);
    expect(switchTile.value, isFalse);

    // Toggle the switch to "On"
    await tester.tap(switchTileFinder);
    await tester.myPump(); // Wait for the state to update
    await Future<dynamic>.delayed(const Duration(seconds: 1));
  }
  await tapBackButton(tester);
}

Future<void> testTheme(WidgetTester tester) async {
  // Turn Dark-Mode on
  await tapOnKeyString(tester, 'key_toggle_mode');
}

Future<void> testWelcomeScreen(WidgetTester tester) async {
  //------------------------------------------------------------------------
  // Welcome screen - Policy
  await tapOnText(tester, 'Privacy Policy');
  await tapBackButton(tester);

  //------------------------------------------------------------------------
  // Welcome screen - Licenses
  await tapOnText(tester, 'Licenses');
  await tapBackButton(tester);

  //------------------------------------------------------------------------
  // Welcome screen - MRU
  await tapOnKey(tester, Constants.keyMruButton);
  await tapOnText(tester, 'Close');

  //------------------------------------------------------------------------
  // Tap the "New File"
  await tapOnText(tester, 'New File ...');
  await tester.myPump();
}

Future<void> testCashFlow(WidgetTester tester) async {
  await tapOnText(tester, 'Cashflow');

  await tapOnText(tester, 'NetWorth');

  await tapOnText(tester, 'Trend');

  final Finder barChartFinder = find.byType(BarChart);
  expect(barChartFinder, findsOneWidget);

  // Define scan parameters
  final int attemptsY = 10; // Number of attempts (scan points)
  final int attemptsX = 40; // Number of attempts (scan points)
  // ignore: deprecated_member_use
  final Size appSize = tester.binding.window.physicalSize;
  final double scanSpacingWidth = appSize.width / attemptsX; // Horizontal scan step
  final double scanSpacingHeight = appSize.height / attemptsY; // Horizontal scan step

  // print(
  //   '******************** Screen size $appSize scanSpacingWidth $scanSpacingWidth   scanSpacingHeight $scanSpacingHeight',
  // );

  // Attempt to tap across the chart diagonal top left to bottom right
  bool tooltipFound = false;
  final double startingHeight = appSize.height / 3; // 1/3 from he top
  for (int y = 0; y < (attemptsY / 3); y++) {
    for (int x = 0; x < attemptsX; x++) {
      // Calculate the tap position
      final Offset tapPosition = Offset(
        400 + (x * scanSpacingWidth),
        startingHeight + (y * scanSpacingHeight),
      );

      // Perform the tap
      await tester.tapAt(tapPosition, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();

      final Finder barChartFinder = find.byType(BarChart);
      if (barChartFinder.evaluate().isEmpty) {
        tooltipFound = true;
        break;
      }

      if (tooltipFound) {
        break;
      }
    }
    if (tooltipFound) {
      break;
    }
  }
  expect(
    tooltipFound,
    isTrue,
    reason: 'No tooltip was found after ${attemptsY * attemptsX} attempts.',
  );

  // At this point we are displaying the Transaction view with some filters for the BarChart that was tapped

  // remove all filters on the Transaction view
  PreferenceController.to.remove(
    ViewId.viewTransactions.getViewPreferenceId(settingKeyFilterText),
  );
  PreferenceController.to.remove(
    ViewId.viewTransactions.getViewPreferenceId(settingKeyFiltersColumns),
  );

  await tapOnText(tester, 'Cashflow');

  {
    await tapOnText(tester, 'Budget');

    await tapOnText(tester, 'List');

    await tapOnText(tester, 'Chart');

    await tapOnText(tester, 'Recurring');

    await tapOnText(tester, 'Suggestion');
  } // back to Cashflow
  await tapOnText(tester, 'Cashflow');
}

Future<void> testAliases(WidgetTester tester) async {
  await tapOnText(tester, 'Aliases');
  await tapOnTextFromParentType(tester, ListView, 'ABC');

  // Edit field "Pattern"
  await tapOnKey(tester, Constants.keyEditSelectedItems);
  await inputTextToTextFieldWithThisLabel(tester, 'Pattern', 'ABC_XYZ');
  await tapOnText(tester, 'Apply');

  await sidePanelTabs(tester, expectChart: false);
}

Future<void> testAccounts(WidgetTester tester) async {
  await tapOnKeyString(tester, 'key_menu_accounts');

  // Iterate over all found ToggleButtons and click on each child button
  await tapAllToggleButtons(tester, <String>[
    'key_toggle_show_bank',
    'key_toggle_show_investment',
    'key_toggle_show_credit',
    'key_toggle_show_assets',
    'key_toggle_show_all',
  ]);

  await sidePanelTabs(tester);

  // Select one of the row
  await tapOnTextFromParentType(tester, ListView, 'Savings');
  await sidePanelTabs(tester);

  // await tester.myPump();
  // toggle sorting
  await tapOnText(tester, 'Memo');

  // Investment - Add new
  await tapOnTextFromParentType(tester, ListView, 'Investment');
  await sidePanelTabs(tester);
  await testImportInInvestmentAccount(tester);

  // Loan Account
  await tapOnTextFromParentType(tester, ListView, 'Loan');
  await sidePanelTabs(tester);

  // CopyToCLipboard from the Side Panel Header
  await tapOnKey(tester, Constants.keyCopyListToClipboardHeaderSidePanel);

  // Accounts - Add new
  await tapOnKey(tester, Constants.keyAddNewItem);

  // Accounts - Edit
  await testAccountEdit(tester);

  // Back to Checking Account
  await tapOnTextFromParentType(tester, ListView, 'Checking');

  // CopyToCLipboard from the Main Header
  await tapOnKey(tester, Constants.keyCopyListToClipboardHeaderMain);

  // Select first element of the Side-Panel-Transaction-List
  await selectFirstItemOfSidePanelTransactionList(tester);

  // Bring upt the Mutate Transaction Dialog
  await longPressFirstItemOfSidePanelTransactionLIst(tester);

  // Delete
  {
    await tapOnText(tester, 'Delete');
    // Cancel the Delete
    await tapOnText(tester, 'Cancel');
  }

  // Duplicate
  {
    await tapOnText(tester, 'Duplicate');
    // pressing Done also will close the dialog
    await tapOnText(tester, 'Done');
  }
}

Future<void> testImportWizadRecordTransfer(WidgetTester tester) async {
  // Import Wizard
  await bringUpImportWizard(tester);
  await tapOnText(tester, 'Record a transfer');

  // Close ImportDialog
  await tapOnText(tester, 'Record Transfer');

  await tapOnText(tester, 'Cancel');
  await tester.myPump();
}

Future<void> testImportInInvestmentAccount(WidgetTester tester) async {
  // Import Wizard
  await tapOnKey(tester, Constants.keyButtonAddTransactions);
  await tapOnText(tester, 'Investment Transaction');

  // Wait for dialog to appear
  // await tester.myPump();

  // Close ImportDialog
  await tapOnText(tester, 'Add Investment');
  await tester.myPump();
}

Future<void> testAccountEdit(WidgetTester tester) async {
  await tapOnKey(tester, Constants.keyEditSelectedItems);

  // Drop down on Account Type
  await tapOnKeyString(tester, 'key_dropdown');
  await tapOnText(tester, 'Savings');

  await tapOnKey(tester, Constants.keyEditSelectedItems);
  await tapOnKeyString(tester, 'key_dropdown');
  await tapOnText(tester, 'Checking');

  // Apply Change and close the dialog
  await tapOnText(tester, 'Cancel');
}

Future<void> testCategories(WidgetTester tester) async {
  await tapOnText(tester, 'Categories');

  // Iterate over all found ToggleButtons and click on each child button
  await tapAllToggleButtons(tester, <String>[
    'key_toggle_show_none',
    'key_toggle_show_expenses',
    'key_toggle_show_saving',
    'key_toggle_show_investments',
    'key_toggle_show_all',
  ]);
  // test side panel with no list item selected
  await sidePanelTabs(tester);

  // Select an item
  await tapOnFirstRowOfListView(tester);

  // Edit
  {
    await tapOnKey(tester, Constants.keyEditSelectedItems);

    // Drop down
    await tapOnKeyString(tester, 'key_dropdown');
    await tapOnText(tester, 'Close');
    // Close Edit box
    await tapOnText(tester, 'Cancel');
  }

  // Merge - Investments:Debit into Investments:Bond
  await selectListViewItemByText(tester, 'Debit');
  await tapOnKey(tester, Constants.keyMergeButton);

  // Drop down pretend to pick a category
  await tapOnKeyString(tester, 'key_dropdown');

  await inputTextToElementByKey(tester, MyKeys.keyHeaderFilterTextInput, 'bon');
  await selectListViewItemByText(tester, 'Bonds');

  // Merge and close the dialog
  await tapOnText(tester, 'Merge');

  // continue
  await sidePanelTabs(tester);

  // Add New Item
  {
    await tapOnKey(tester, Constants.keyAddNewItem);
    await tapOnText(tester, 'Cancel');
  }
  // trigger sort by Level
  await tester.longPress(find.text('Level').first);
  await tapOnText(tester, 'Close');
}

Future<void> testEvents(WidgetTester tester) async {
  await tapOnText(tester, 'Events');
  await sidePanelTabs(tester);
  await tapOnFirstRowOfListView(tester);

  // Edit
  {
    await tapOnKey(tester, Constants.keyAddNewItem);

    // Edit the name
    {
      // Find the TextFormField by its labelText in the InputDecoration.
      final Finder textFieldFinder = find.widgetWithText(TextFormField, 'Name');

      // Check if the TextFormField with the labelText was found.
      expect(textFieldFinder, findsOneWidget);

      // Enter text into the TextFormField
      await tester.enterText(textFieldFinder, 'Wedding');

      // Verify the entered text if needed
      expect(find.text('Wedding'), findsOneWidget);
    }

    // Edit the date
    {
      // Find the TextFormField (or TextField) by its labelText.
      final Finder textFormFieldFinder = find.widgetWithText(
        InputDecorator,
        'Begins',
      );

      // Check if the TextFormField with the labelText was found.
      expect(textFormFieldFinder, findsOneWidget);

      // Find the EditableText widget within the TextFormField, which is the actual input box.
      final Finder editableTextFinder = find.descendant(
        of: textFormFieldFinder,
        matching: find.byType(EditableText),
      );

      // Enter text into the TextFormField
      await tester.enterText(editableTextFinder, '2025-01-01');
    }

    // Edit the Category
    {
      await tapOnKeyString(tester, 'key_dropdown');
      await inputTextToElement(
        tester,
        findByKeyString('key_pick_category'),
        'Food',
      );
      await tester.pumpAndSettle(
        const Duration(milliseconds: 500),
      ); // fix soem odd timing issues

      // Find the widget that displays the text 'Grocery'.
      final Finder groceryFinder = find.text('Grocery').at(0); // top most element found
      await tester.pumpAndSettle(
        const Duration(milliseconds: 500),
      ); // fix soem odd timing issues

      // Tap on the widget.
      await tester.tap(groceryFinder);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 900),
      ); // fix soem odd timing issues
    }

    await tapOnText(tester, 'Apply');
  }

  // Add New Item
  {
    await tapOnKey(tester, Constants.keyAddNewItem);
    await tapOnText(tester, 'Cancel');
  }
}

Future<void> testPayees(WidgetTester tester) async {
  Data().payees.getPayeeIdFromName('NASA');

  await tapOnText(tester, 'Payees');
  // Test Side Panel with not row selected
  await sidePanelTabs(tester);

  // Test with one row selected
  await tapOnFirstRowOfListView(tester);
  await tapOnKey(tester, Constants.keyMergeButton);
  await tapOnText(tester, 'Comcast');
  await tapOnText(tester, 'Cancel');
  await sidePanelTabs(tester);

  // Perform a Payee merge
  await tapOnKey(tester, Constants.keyMergeButton);

  await tapOnKeyString(tester, 'key_dropdown');

  await inputTextToElementByKey(
    tester,
    MyKeys.keyHeaderFilterTextInput,
    'mobile',
  );

  await tapOnText(tester, 'TMobile');

  // Merge and close the dialog
  await tapOnText(tester, 'Merge');
}

Future<void> testStocks(WidgetTester tester) async {
  await tapOnText(tester, 'Stocks');
  await tapOnTextFromParentType(tester, ListView, 'AAPL');

  // Edit
  {
    await tapOnKey(tester, Constants.keyEditSelectedItems);

    // Drop down
    await tapOnKeyString(tester, 'key_dropdown');

    // Make a change
    await tapOnText(tester, 'private');

    // Apply will close the dialog
    await tapOnText(tester, 'Apply');
  }

  await sidePanelTabs(tester);

  await tapOnTextFromParentType(tester, SidePanelHeader, 'Chart');
  await tapOnText(tester, 'Set API Key');

  await inputTextToElementByKey(
    tester,
    const Key('key_single_input_dialog'),
    Constants.fakeStockApiKey,
  );

  await tapOnText(tester, 'Continue');

  await tapOnTextFromParentType(tester, ListView, 'Ford');
  await tapOnTextFromParentType(tester, ListView, 'AAPL');
}

Future<void> testTransactions(WidgetTester tester) async {
  await tapOnText(tester, 'Transactions');

  // Toggle Multi-Selection on and off
  await tapOnKey(tester, Constants.keyMultiSelectionToggle);

  // Select All
  await tapOnKey(tester, Constants.keyCheckboxToggleSelectAll);

  // Edit
  await tapOnKey(tester, Constants.keyEditSelectedItems);
  await tapOnText(tester, 'Transfer');
  await tapOnText(tester, 'Cancel');

  // Unselect All
  await tapOnKey(tester, Constants.keyCheckboxToggleSelectAll);

  // out of multi-selection mode
  await tapOnKey(tester, Constants.keyMultiSelectionToggle);

  // Select one of the rows
  await tapOnTextFromParentType(tester, ListView, 'Bank Of America');

  // Single Transaction Edit
  {
    await tapOnKey(tester, Constants.keyEditSelectedItems);

    // Edit  the Date
    await inputTextToElement(
      tester,
      find.byKey(Constants.keyDatePicker),
      '2021-01-01',
    );

    // Edit the Category of a single transaction
    await inputTextToElement(
      tester,
      findByKeyString('key_pick_category'),
      'Food',
    );

    // Edit  the Amount
    await inputTextToTextFieldWithThisLabel(tester, 'Amount', '66.99');

    await tapOnText(tester, 'Apply');
  }
  await sidePanelTabs(tester);

  // Delete selected item
  await tapOnKey(tester, Constants.keyDeleteSelectedItems);
  await tapOnText(tester, 'Delete');

  // trigger sort by Date
  await tapOnText(tester, 'Date');
  await tapOnText(tester, 'Date'); // Descending

  // trigger sort by  Account
  await tapOnText(tester, 'Account');
  await tapOnText(tester, 'Account'); // Descending

  // trigger sort by  Account
  await tapOnText(tester, 'Payee/Transfer');
  await tapOnText(tester, 'Payee/Transfer'); // Descending

  // trigger sort by  Category
  await tapOnText(tester, 'Category');
  await tapOnText(tester, 'Category'); // Descending

  // trigger sort by  Status
  await tapOnText(tester, 'Status');
  await tapOnText(tester, 'Status'); // Descending

  // trigger sort by  Currency
  await tapOnText(tester, 'Currency');
  await tapOnText(tester, 'Currency'); // Descending

  // trigger sort by  Amount
  await tapOnText(tester, 'Amount');
  await tapOnText(tester, 'Amount'); // Descending

  // trigger sort by  Amount(USD)
  await tapOnText(tester, 'Amount(USD)');
  await tapOnText(tester, 'Amount(USD)'); // Descending

  // trigger sort by  Balance(USD)
  await tapOnText(tester, 'Balance(USD)');
  await tapOnText(tester, 'Balance(USD)'); // Descending

  // input a filter text that will return no match
  await inputText(tester, 'some text that will not return any match');

  // Not expecting to fnd any match, look for and tap the "reset the filters" button
  await tapOnText(tester, 'Clear Filters');

  await inputText(tester, '12');

  // Flitter by Category "Split"
  {
    await tester.longPress(find.text('Category').first);
    await tapOnKeyString(tester, 'key_select_unselect_all');
    await inputTextToElement(
      tester,
      findByKeyString('key_picker_input_filter'),
      'Split',
    );
    await tapOnKeyString(tester, 'key_select_unselect_all');
    await tapOnText(tester, 'Apply');
  }

  // Do some CRUD with Splits
  {
    final Finder splitCategory = find.text('Split');
    expect(splitCategory, findsAtLeast(1));
    await tester.tap(splitCategory.first);
    await tester.myPump();

    await tapOnText(tester, 'Add');
    await tester.myPump();

    await tapOnText(tester, 'Refresh list');
    await tester.myPump();

    await tester.longPress(
      find.text('Principal').last,
      warnIfMissed: true,
      kind: PointerDeviceKind.mouse,
    );
    await tester.myPump();

    // Go in Edit mode by tapping button "Edit"
    await tapOnKey(tester, Constants.keyButtonEdit);
    await tester.myPump();

    // Edit the Category
    {
      await tapOnKeyString(tester, 'key_dropdown');
      await tester.myPump();
      await tapOnText(tester, 'Investment');
      await tester.myPump();
    }

    // make a change to the Amount
    await inputTextToTextFieldWithThisLabel(tester, 'Amount', '333');

    // Tape button "Done"
    await tapOnKey(tester, Constants.keyButtonApplyOrDone);
    await tester.myPump();

    // dismiss the dialog box for "Splits"
    await tapOnText(tester, 'Close');
  }
}

Future<void> testTransfers(WidgetTester tester) async {
  await tapOnText(tester, 'Transfers');
  await tapOnFirstRowOfListView(tester);
  await sidePanelTabs(tester, expectChart: false, expectTransactions: false);
}

Future<void> testRentals(WidgetTester tester) async {
  await tapOnText(tester, 'Rentals');
  await tapOnTextFromParentType(tester, ListView, 'AirBnB');
  await sidePanelTabs(tester, expectPnl: true);
  // Go back to Chart where there's a PNL panel
  // we want to test the copy PnL data to clipboard
  await tapOnTextFromParentType(tester, SidePanelHeader, 'PnL');
  await tapOnKeyString(tester, 'key_card_copy_to_clipboard');
}

Future<void> testInvestments(WidgetTester tester) async {
  await tapOnText(tester, 'Investments');
  await tapOnTextFromParentType(tester, ListView, 'Fidelity');
  await sidePanelTabs(tester);
}

Future<void> sidePanelTabs(
  WidgetTester tester, {
  bool expectDetails = true,
  bool expectChart = true,
  bool expectTransactions = true,
  bool expectPnl = false,
}) async {
  // Expand the side panel if not already expanded
  if (PreferenceController.to.isSidePanelExpanded == false) {
    await tapOnKey(tester, Constants.keySidePanelExpando);

    final Finder splitterHandle = findByKeyString('SidePanelSplitter');
    expect(splitterHandle, findsWidgets); // Ensure at least one splitter exists

    // final Offset initialPosition = tester.getCenter(splitterHandle.first);
    // Drag the handle to the 340 from the bottom
    await tester.drag(splitterHandle, const Offset(0, -340));
    await tester.pumpAndSettle();
  }

  if (expectDetails) {
    await tapOnTextFromParentType(tester, SidePanelHeader, 'Details');
  }

  if (expectChart) {
    await tapOnTextFromParentType(tester, SidePanelHeader, 'Chart');
  }
  if (expectTransactions) {
    {
      await tapOnTextFromParentType(tester, SidePanelHeader, 'Transactions');
    }
  }
  if (expectPnl) {
    await tapOnTextFromParentType(tester, SidePanelHeader, 'PnL');
  }
}

Future<void> testPendingChanges(WidgetTester tester) async {
  await tapOnKey(tester, Constants.keyPendingChanges);

  await tapOnTextFromParentType(tester, Wrap, 'Aliases');
  await tapOnTextFromParentType(tester, Wrap, 'Categories');
  await tapOnTextFromParentType(tester, Wrap, 'Currencies');
  await tapOnTextFromParentType(tester, Wrap, 'LoanPayments');
  await tapOnTextFromParentType(tester, Wrap, 'Online Accounts');
  await tapOnTextFromParentType(tester, Wrap, 'Payees');
  await tapOnTextFromParentType(tester, Wrap, 'Transactions');
  await tapOnTextFromParentType(tester, Wrap, 'Splits');
  await tapOnTextFromParentType(tester, Wrap, 'Stock Splits');
  await tapOnTextFromParentType(tester, Wrap, 'Accounts');

  await tapOnText(tester, '1 modified');

  await tapOnText(tester, '3 deleted');

  // close the panel
  await tapOnText(tester, 'Save to CSV');

  // Clean/Save/Load to SQL
  final String testFilename = './test_output_sqlite.MyMoney.mmdb';
  if (await File(testFilename).exists()) {
    await File(testFilename).delete();
  }

  // Save SQL
  await Data().saveToSql(
    filePath: testFilename,
    onSaveCompleted: (bool success, String errorMessage) {
      // save completed
      expect(success, true, reason: errorMessage);
    },
  );

  // Load from SQL
  {
    final DataSource dataSource = DataSource(filePath: testFilename);
    final bool successLoading = await DataController.to.loadFileFromPath(
      dataSource,
    );
    expect(successLoading, true);
  }
  // Save to SQL
  {
    final bool result = await DataController.to.onSaveToSql();
    expect(result, true);
  }
}
