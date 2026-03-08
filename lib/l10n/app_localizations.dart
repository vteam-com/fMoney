import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('es'), Locale('fr')];

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutMenuItem.
  ///
  /// In en, this message translates to:
  /// **'About...'**
  String get aboutMenuItem;

  /// No description provided for @accountNames.
  ///
  /// In en, this message translates to:
  /// **'Account names'**
  String get accountNames;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addInvestmentTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Investment Transaction'**
  String get addInvestmentTransaction;

  /// No description provided for @addNewTransactions.
  ///
  /// In en, this message translates to:
  /// **'Add new transactions'**
  String get addNewTransactions;

  /// No description provided for @addTransactionsMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Add transactions...'**
  String get addTransactionsMenuItem;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @amountIsMatching.
  ///
  /// In en, this message translates to:
  /// **'Amount is matching'**
  String get amountIsMatching;

  /// No description provided for @amountIsOffBy.
  ///
  /// In en, this message translates to:
  /// **'Amount is off by'**
  String get amountIsOffBy;

  /// No description provided for @analyzeSpending.
  ///
  /// In en, this message translates to:
  /// **'Analyze spending'**
  String get analyzeSpending;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Free open-source Flutter Personal Finance Management Application'**
  String get appDescription;

  /// No description provided for @appLongDescription.
  ///
  /// In en, this message translates to:
  /// **'A comprehensive money management solution for tracking expenses, managing budgets, and monitoring investments.'**
  String get appLongDescription;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'fMoney'**
  String get appName;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'fMoney by VTeam'**
  String get appTitle;

  /// No description provided for @append.
  ///
  /// In en, this message translates to:
  /// **'Append'**
  String get append;

  /// No description provided for @availableOn.
  ///
  /// In en, this message translates to:
  /// **'Available on'**
  String get availableOn;

  /// No description provided for @avgLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg: '**
  String get avgLabel;

  /// No description provided for @badDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Bad Date Format'**
  String get badDateFormat;

  /// No description provided for @bankaccounts.
  ///
  /// In en, this message translates to:
  /// **'BankAccounts'**
  String get bankaccounts;

  /// No description provided for @begin.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get begin;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @cashFlow.
  ///
  /// In en, this message translates to:
  /// **'Cash Flow'**
  String get cashFlow;

  /// No description provided for @chart.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get chart;

  /// No description provided for @chartUpperSpacer.
  ///
  /// In en, this message translates to:
  /// **'CHART '**
  String get chartUpperSpacer;

  /// No description provided for @checkingOllamaStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking Ollama status...'**
  String get checkingOllamaStatus;

  /// No description provided for @chooseAnOptionToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Choose an option to get started:'**
  String get chooseAnOptionToGetStarted;

  /// No description provided for @chooseColumns.
  ///
  /// In en, this message translates to:
  /// **'Choose Columns'**
  String get chooseColumns;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @closeFile.
  ///
  /// In en, this message translates to:
  /// **'Close file'**
  String get closeFile;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content:'**
  String get content;

  /// No description provided for @contentGoesHere.
  ///
  /// In en, this message translates to:
  /// **'Content goes here'**
  String get contentGoesHere;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @copyListToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy list to clipboard'**
  String get copyListToClipboard;

  /// No description provided for @countSelected.
  ///
  /// In en, this message translates to:
  /// **'@count selected'**
  String countSelected(String count);

  /// No description provided for @countYears.
  ///
  /// In en, this message translates to:
  /// **'@count years'**
  String countYears(String count);

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @csvFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'CSV file is empty.'**
  String get csvFileEmpty;

  /// No description provided for @csvHeadersAreMissingOrEmpty.
  ///
  /// In en, this message translates to:
  /// **'CSV headers are missing or empty.'**
  String get csvHeadersAreMissingOrEmpty;

  /// No description provided for @csvImportCancelled.
  ///
  /// In en, this message translates to:
  /// **'CSV import cancelled.'**
  String get csvImportCancelled;

  /// No description provided for @dataPreviewFirst5Rows.
  ///
  /// In en, this message translates to:
  /// **'Data Preview (First 5 rows):'**
  String get dataPreviewFirst5Rows;

  /// No description provided for @debit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get debit;

  /// No description provided for @deleteSelectedItems.
  ///
  /// In en, this message translates to:
  /// **'Delete selected item(s)'**
  String get deleteSelectedItems;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @dropFilesHere.
  ///
  /// In en, this message translates to:
  /// **'Drop files here'**
  String get dropFilesHere;

  /// No description provided for @editSelectedItems.
  ///
  /// In en, this message translates to:
  /// **'Edit selected item(s)'**
  String get editSelectedItems;

  /// No description provided for @elapsedElapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed: @elapsed'**
  String elapsedElapsed(String elapsed);

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorImportingCsvError.
  ///
  /// In en, this message translates to:
  /// **'Error importing CSV: @error'**
  String errorImportingCsvError(String error);

  /// No description provided for @errorImportingXlsxError.
  ///
  /// In en, this message translates to:
  /// **'Error importing XLSX: @error'**
  String errorImportingXlsxError(String error);

  /// No description provided for @expensePredictions.
  ///
  /// In en, this message translates to:
  /// **'Expense predictions'**
  String get expensePredictions;

  /// No description provided for @fileLocationMenuItem.
  ///
  /// In en, this message translates to:
  /// **'File location...'**
  String get fileLocationMenuItem;

  /// No description provided for @fileLocationNotSupportedOnMobile.
  ///
  /// In en, this message translates to:
  /// **'Opening the file location is only supported on desktop platforms.'**
  String get fileLocationNotSupportedOnMobile;

  /// No description provided for @fileMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'File menu'**
  String get fileMenuTooltip;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'filter'**
  String get filter;

  /// No description provided for @fmoney.
  ///
  /// In en, this message translates to:
  /// **'fMoney'**
  String get fmoney;

  /// No description provided for @forSpacer.
  ///
  /// In en, this message translates to:
  /// **' for '**
  String get forSpacer;

  /// No description provided for @freeStyle.
  ///
  /// In en, this message translates to:
  /// **'Free style'**
  String get freeStyle;

  /// No description provided for @fromCategory.
  ///
  /// In en, this message translates to:
  /// **'From category'**
  String get fromCategory;

  /// No description provided for @fromPayee.
  ///
  /// In en, this message translates to:
  /// **'From payee'**
  String get fromPayee;

  /// No description provided for @fullPromptSentToAi.
  ///
  /// In en, this message translates to:
  /// **'Full Prompt Sent to AI'**
  String get fullPromptSentToAi;

  /// No description provided for @helperForDebugging.
  ///
  /// In en, this message translates to:
  /// **'Helper for debugging'**
  String get helperForDebugging;

  /// No description provided for @hideClosedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Hide closed accounts'**
  String get hideClosedAccounts;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID: '**
  String get idLabel;

  /// No description provided for @importTransactionToAccount.
  ///
  /// In en, this message translates to:
  /// **'Import transaction to account'**
  String get importTransactionToAccount;

  /// No description provided for @includeAssetAccounts.
  ///
  /// In en, this message translates to:
  /// **'Include Asset Accounts'**
  String get includeAssetAccounts;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @installAppMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Install App...'**
  String get installAppMenuItem;

  /// No description provided for @installOllamaNow.
  ///
  /// In en, this message translates to:
  /// **'Install Ollama now'**
  String get installOllamaNow;

  /// No description provided for @investments.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get investments;

  /// No description provided for @keepAllTransactionsToTheirCurrentCategories.
  ///
  /// In en, this message translates to:
  /// **'Keep all transactions to their current categories'**
  String get keepAllTransactionsToTheirCurrentCategories;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @largestTransactions.
  ///
  /// In en, this message translates to:
  /// **'Largest transactions'**
  String get largestTransactions;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @licensesDescription.
  ///
  /// In en, this message translates to:
  /// **'fMoney is built using open-source software. View the licenses for all packages used in this application.'**
  String get licensesDescription;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @manageTheExpensesAndRentalIncomeOfProperties.
  ///
  /// In en, this message translates to:
  /// **'Manage the expenses and rental income of properties.'**
  String get manageTheExpensesAndRentalIncomeOfProperties;

  /// No description provided for @maxLabel.
  ///
  /// In en, this message translates to:
  /// **'Max: '**
  String get maxLabel;

  /// No description provided for @memo.
  ///
  /// In en, this message translates to:
  /// **'Memo'**
  String get memo;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @mergeItems.
  ///
  /// In en, this message translates to:
  /// **'Merge item(s)'**
  String get mergeItems;

  /// No description provided for @messageDetails.
  ///
  /// In en, this message translates to:
  /// **'Message Details'**
  String get messageDetails;

  /// No description provided for @minLabel.
  ///
  /// In en, this message translates to:
  /// **'Min: '**
  String get minLabel;

  /// No description provided for @missingTransfer.
  ///
  /// In en, this message translates to:
  /// **'Missing Transfer'**
  String get missingTransfer;

  /// No description provided for @monthlyActual.
  ///
  /// In en, this message translates to:
  /// **'Monthly Actual'**
  String get monthlyActual;

  /// No description provided for @monthlyBudgeted.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budgeted'**
  String get monthlyBudgeted;

  /// No description provided for @navAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// No description provided for @navAccountsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show Accounts'**
  String get navAccountsTooltip;

  /// No description provided for @navAiAssistantTooltip.
  ///
  /// In en, this message translates to:
  /// **'AI-powered financial insights'**
  String get navAiAssistantTooltip;

  /// No description provided for @navAliases.
  ///
  /// In en, this message translates to:
  /// **'Aliases'**
  String get navAliases;

  /// No description provided for @navAliasesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show Aliases'**
  String get navAliasesTooltip;

  /// No description provided for @navCashflow.
  ///
  /// In en, this message translates to:
  /// **'Cashflow'**
  String get navCashflow;

  /// No description provided for @navCashflowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show your Cash Flow'**
  String get navCashflowTooltip;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// No description provided for @navCategoriesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show Categories'**
  String get navCategoriesTooltip;

  /// No description provided for @navEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// No description provided for @navEventsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Your life events'**
  String get navEventsTooltip;

  /// No description provided for @navInvestments.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get navInvestments;

  /// No description provided for @navInvestmentsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Investment transactions'**
  String get navInvestmentsTooltip;

  /// No description provided for @navPayees.
  ///
  /// In en, this message translates to:
  /// **'Payees'**
  String get navPayees;

  /// No description provided for @navPayeesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show Payees'**
  String get navPayeesTooltip;

  /// No description provided for @navRentals.
  ///
  /// In en, this message translates to:
  /// **'Rentals'**
  String get navRentals;

  /// No description provided for @navRentalsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rentals'**
  String get navRentalsTooltip;

  /// No description provided for @navShowLabel.
  ///
  /// In en, this message translates to:
  /// **'Show @label'**
  String navShowLabel(String label);

  /// No description provided for @navStocks.
  ///
  /// In en, this message translates to:
  /// **'Stocks'**
  String get navStocks;

  /// No description provided for @navStocksTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stocks tracking'**
  String get navStocksTooltip;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navTransactionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show Transactions'**
  String get navTransactionsTooltip;

  /// No description provided for @navTransfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get navTransfers;

  /// No description provided for @navTransfersTooltip.
  ///
  /// In en, this message translates to:
  /// **'View transfers between accounts'**
  String get navTransfersTooltip;

  /// No description provided for @networth.
  ///
  /// In en, this message translates to:
  /// **'NetWorth'**
  String get networth;

  /// No description provided for @newFile.
  ///
  /// In en, this message translates to:
  /// **'New File ...'**
  String get newFile;

  /// No description provided for @newMenuItem.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newMenuItem;

  /// No description provided for @noAccountSelected.
  ///
  /// In en, this message translates to:
  /// **'No account selected'**
  String get noAccountSelected;

  /// No description provided for @noAccountSelectedPeriod.
  ///
  /// In en, this message translates to:
  /// **'No account selected.'**
  String get noAccountSelectedPeriod;

  /// No description provided for @noBudgetIncomeCategoryFound.
  ///
  /// In en, this message translates to:
  /// **'No budget income category found'**
  String get noBudgetIncomeCategoryFound;

  /// No description provided for @noChartToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No chart to display'**
  String get noChartToDisplay;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @noDataPoints.
  ///
  /// In en, this message translates to:
  /// **'No data points'**
  String get noDataPoints;

  /// No description provided for @noDataRowsToPreview.
  ///
  /// In en, this message translates to:
  /// **'No data rows to preview.'**
  String get noDataRowsToPreview;

  /// No description provided for @noDataToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No data to display'**
  String get noDataToDisplay;

  /// No description provided for @noDateRangeYet.
  ///
  /// In en, this message translates to:
  /// **'No date range yet'**
  String get noDateRangeYet;

  /// No description provided for @noFieldsFoundForItem.
  ///
  /// In en, this message translates to:
  /// **'No fields found for @item'**
  String noFieldsFoundForItem(String item);

  /// No description provided for @noItemSelected.
  ///
  /// In en, this message translates to:
  /// **'No item selected.'**
  String get noItemSelected;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItems;

  /// No description provided for @noItemsWereTitle.
  ///
  /// In en, this message translates to:
  /// **'No items were @title'**
  String noItemsWereTitle(String title);

  /// No description provided for @noPicker.
  ///
  /// In en, this message translates to:
  /// **'no picker'**
  String get noPicker;

  /// No description provided for @noRelatedTransactions.
  ///
  /// In en, this message translates to:
  /// **'No related transactions'**
  String get noRelatedTransactions;

  /// No description provided for @noRowsFoundWith3OrMoreColumns.
  ///
  /// In en, this message translates to:
  /// **'No rows found with 3 or more columns.'**
  String get noRowsFoundWith3OrMoreColumns;

  /// No description provided for @noSecuritySelected.
  ///
  /// In en, this message translates to:
  /// **'No security selected.'**
  String get noSecuritySelected;

  /// No description provided for @noSheetXmlFoundInXlsxFile.
  ///
  /// In en, this message translates to:
  /// **'No sheet XML found in XLSX file.'**
  String get noSheetXmlFoundInXlsxFile;

  /// No description provided for @noStockSelected.
  ///
  /// In en, this message translates to:
  /// **'No stock selected'**
  String get noStockSelected;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get noTransactions;

  /// No description provided for @noTransactionsPeriod.
  ///
  /// In en, this message translates to:
  /// **'No transactions.'**
  String get noTransactionsPeriod;

  /// No description provided for @noUi.
  ///
  /// In en, this message translates to:
  /// **'no UI'**
  String get noUi;

  /// No description provided for @noValidEntriesFoundInCsvToImport.
  ///
  /// In en, this message translates to:
  /// **'No valid entries found in CSV to import.'**
  String get noValidEntriesFoundInCsvToImport;

  /// No description provided for @noValidEntriesFoundInXlsxToImport.
  ///
  /// In en, this message translates to:
  /// **'No valid entries found in XLSX to import.'**
  String get noValidEntriesFoundInXlsxToImport;

  /// No description provided for @ocr.
  ///
  /// In en, this message translates to:
  /// **'OCR'**
  String get ocr;

  /// No description provided for @ollamaAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'Ollama AI Assistant'**
  String get ollamaAiAssistant;

  /// No description provided for @ollamaIsRequiredToUseTheAiAssistantClickBelowToInstallIt.
  ///
  /// In en, this message translates to:
  /// **'Ollama is required to use the AI assistant. Click below to install it.'**
  String get ollamaIsRequiredToUseTheAiAssistantClickBelowToInstallIt;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open File ...'**
  String get openFile;

  /// No description provided for @openMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Open...'**
  String get openMenuItem;

  /// No description provided for @orChangeToCategory.
  ///
  /// In en, this message translates to:
  /// **'or change to category'**
  String get orChangeToCategory;

  /// No description provided for @payee.
  ///
  /// In en, this message translates to:
  /// **'Payee'**
  String get payee;

  /// No description provided for @payeeMatch.
  ///
  /// In en, this message translates to:
  /// **'Payee Match'**
  String get payeeMatch;

  /// No description provided for @pleaseMapAllFieldsDateDescriptionAmount.
  ///
  /// In en, this message translates to:
  /// **'Please map all fields (Date, Description, Amount).'**
  String get pleaseMapAllFieldsDateDescriptionAmount;

  /// No description provided for @pleaseSelectDifferentAccounts.
  ///
  /// In en, this message translates to:
  /// **'Please select different accounts'**
  String get pleaseSelectDifferentAccounts;

  /// No description provided for @pnl.
  ///
  /// In en, this message translates to:
  /// **'PnL'**
  String get pnl;

  /// No description provided for @policy.
  ///
  /// In en, this message translates to:
  /// **'Policy'**
  String get policy;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @questionsQuestioncountTokensTokencount.
  ///
  /// In en, this message translates to:
  /// **'Questions: {questionCount} | Tokens: {tokenCount}'**
  String questionsQuestioncountTokensTokencount(String questionCount, String tokenCount);

  /// No description provided for @rebalanceMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Rebalance...'**
  String get rebalanceMenuItem;

  /// No description provided for @recordATransferBetweenTwoAccounts.
  ///
  /// In en, this message translates to:
  /// **'Record a Transfer between two accounts'**
  String get recordATransferBetweenTwoAccounts;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// No description provided for @refreshList.
  ///
  /// In en, this message translates to:
  /// **'Refresh list'**
  String get refreshList;

  /// No description provided for @rental.
  ///
  /// In en, this message translates to:
  /// **'Rental'**
  String get rental;

  /// No description provided for @rentalPropertyNotFound.
  ///
  /// In en, this message translates to:
  /// **'Rental property not found'**
  String get rentalPropertyNotFound;

  /// No description provided for @rowIndex.
  ///
  /// In en, this message translates to:
  /// **'Row {index}'**
  String rowIndex(String index);

  /// No description provided for @runOllama.
  ///
  /// In en, this message translates to:
  /// **'Run Ollama'**
  String get runOllama;

  /// No description provided for @sankey.
  ///
  /// In en, this message translates to:
  /// **'Sankey'**
  String get sankey;

  /// No description provided for @saveToCsv.
  ///
  /// In en, this message translates to:
  /// **'Save to CSV'**
  String get saveToCsv;

  /// No description provided for @saveToSql.
  ///
  /// In en, this message translates to:
  /// **'Save to SQL'**
  String get saveToSql;

  /// No description provided for @selectARentalPropertyToSeeItsPL.
  ///
  /// In en, this message translates to:
  /// **'Select a Rental property to see its P&L'**
  String get selectARentalPropertyToSeeItsPL;

  /// No description provided for @selectColumn.
  ///
  /// In en, this message translates to:
  /// **'Select column'**
  String get selectColumn;

  /// No description provided for @selectHeaderRow.
  ///
  /// In en, this message translates to:
  /// **'Select Header Row'**
  String get selectHeaderRow;

  /// No description provided for @selectTheRowThatContainsTheColumnHeadersAutomaticallySelectedBasedOnContent.
  ///
  /// In en, this message translates to:
  /// **'Select the row that contains the column headers (automatically selected based on content):'**
  String get selectTheRowThatContainsTheColumnHeadersAutomaticallySelectedBasedOnContent;

  /// No description provided for @setApiKey.
  ///
  /// In en, this message translates to:
  /// **'Set API Key'**
  String get setApiKey;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Settings...'**
  String get settingsMenuItem;

  /// No description provided for @showClosedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Show closed accounts'**
  String get showClosedAccounts;

  /// No description provided for @showingFirstMaxrowsOfRowcountEligibleRows.
  ///
  /// In en, this message translates to:
  /// **'Showing first {maxRows} of {rowCount} eligible rows'**
  String showingFirstMaxrowsOfRowcountEligibleRows(String maxRows, String rowCount);

  /// No description provided for @showingRowcountEligibleRowsExcludedRowsWith3Columns.
  ///
  /// In en, this message translates to:
  /// **'Showing {rowCount} eligible rows (excluded rows with < 3 columns)'**
  String showingRowcountEligibleRowsExcludedRowsWith3Columns(String rowCount);

  /// No description provided for @skippingDuplicate.
  ///
  /// In en, this message translates to:
  /// **' Skipping Duplicate '**
  String get skippingDuplicate;

  /// No description provided for @smallScreenContentGoesHere.
  ///
  /// In en, this message translates to:
  /// **'Small screen content goes here'**
  String get smallScreenContentGoesHere;

  /// No description provided for @split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @suggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get suggestion;

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking...'**
  String get thinking;

  /// No description provided for @timestampTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp: @timestamp'**
  String timestampTimestamp(String timestamp);

  /// No description provided for @toCategory.
  ///
  /// In en, this message translates to:
  /// **'To category'**
  String get toCategory;

  /// No description provided for @toPayee.
  ///
  /// In en, this message translates to:
  /// **'To payee'**
  String get toPayee;

  /// No description provided for @toggleBrightness.
  ///
  /// In en, this message translates to:
  /// **'Toggle brightness'**
  String get toggleBrightness;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @transactionSplit.
  ///
  /// In en, this message translates to:
  /// **'Transaction split'**
  String get transactionSplit;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @trend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get trend;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @useDemoData.
  ///
  /// In en, this message translates to:
  /// **'Use Demo Data'**
  String get useDemoData;

  /// No description provided for @versionInformation.
  ///
  /// In en, this message translates to:
  /// **'Version Information'**
  String get versionInformation;

  /// No description provided for @viewClosedAccounts.
  ///
  /// In en, this message translates to:
  /// **'View closed accounts'**
  String get viewClosedAccounts;

  /// No description provided for @viewLicenses.
  ///
  /// In en, this message translates to:
  /// **'View Licenses'**
  String get viewLicenses;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @welcomeToFmoney.
  ///
  /// In en, this message translates to:
  /// **'Welcome to fMoney'**
  String get welcomeToFmoney;

  /// No description provided for @xlsxFileContainsNoDataRows.
  ///
  /// In en, this message translates to:
  /// **'XLSX file contains no data rows.'**
  String get xlsxFileContainsNoDataRows;

  /// No description provided for @xlsxFileContainsNoValidData.
  ///
  /// In en, this message translates to:
  /// **'XLSX file contains no valid data.'**
  String get xlsxFileContainsNoValidData;

  /// No description provided for @xlsxImportCancelled.
  ///
  /// In en, this message translates to:
  /// **'XLSX import cancelled.'**
  String get xlsxImportCancelled;

  /// No description provided for @zoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get zoom;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
