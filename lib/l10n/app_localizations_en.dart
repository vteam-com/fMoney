// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get about => 'About';

  @override
  String get aboutMenuItem => 'About...';

  @override
  String get account => 'Account';

  @override
  String get accountNames => 'Account names';

  @override
  String get accounts => 'Accounts';

  @override
  String get accountsDescription => 'Your main assets.';

  @override
  String get activeLabel => 'Active';

  @override
  String get add => 'Add';

  @override
  String get addInvestment => 'Add investment';

  @override
  String get addInvestmentTransaction => 'Add Investment Transaction';

  @override
  String get addNewAccount => 'Add new account';

  @override
  String get addNewCategory => 'Add new category';

  @override
  String get addNewEvent => 'Add new event';

  @override
  String get addNewTransactions => 'Add new transactions';

  @override
  String get addTransactionBetweenTwoAccounts => 'Add a transaction between two accounts.';

  @override
  String get addTransactionsMenuItem => 'Add transactions...';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get aiDropPdfFileOnly => 'Please drop a PDF file.';

  @override
  String aiLearnedAboutAccountsAndTransactions(String count) {
    return 'AI has learned about @count accounts and their transactions.';
  }

  @override
  String aiMatchedAccount(String account) {
    return 'Matched account: @account';
  }

  @override
  String get aiNoMatchingAccountFound => 'No matching account found. Select an account to continue.';

  @override
  String get aiNoOpenAccountsAvailableForImport => 'No open accounts are available for import.';

  @override
  String get aiPdfNotBankStatement => 'No bank statement transactions were detected in this PDF.';

  @override
  String get aiReadingPdfStatement => 'Reading PDF statement...';

  @override
  String get aiStatementAccountFoundLabel => 'Account found';

  @override
  String get aiStatementAccountNotFoundSelectDestinationAccount =>
      'was not found in your accounts. Please select the destination account.';

  @override
  String get aiStatementBalance => 'Statement balance';

  @override
  String get aiUnableToReadPdf => 'Unable to read this PDF file.';

  @override
  String get alias => 'Alias';

  @override
  String get aliases => 'Aliases';

  @override
  String get allLabel => 'All';

  @override
  String get allTime => 'All time';

  @override
  String get allYourMajorLifeEventsDescription => 'All your major life events';

  @override
  String get amount => 'Amount';

  @override
  String get amountIsMatching => 'Amount is matching';

  @override
  String get amountIsOffBy => 'Amount is off by';

  @override
  String get amountPerUnit => 'Amount per unit';

  @override
  String get analyzeSpending => 'Analyze spending';

  @override
  String get appCopyright => '© 2024 fMoney Team. All rights reserved.';

  @override
  String get appDescription => 'Free open-source Flutter Personal Finance Management Application';

  @override
  String get append => 'Append';

  @override
  String get appLongDescription =>
      'A comprehensive money management solution for tracking expenses, managing budgets, and monitoring investments.';

  @override
  String get apply => 'Apply';

  @override
  String get appName => 'fMoney';

  @override
  String get approveCategory => 'Approve category';

  @override
  String get appTitle => 'fMoney by VTeam';

  @override
  String get assets => 'Assets';

  @override
  String get availableOn => 'Available on';

  @override
  String get averageCost => 'Average cost';

  @override
  String get averages => 'Averages';

  @override
  String get avgLabel => 'Avg: ';

  @override
  String get badDateFormat => 'Bad Date Format';

  @override
  String get bankaccounts => 'BankAccounts';

  @override
  String get banks => 'Banks';

  @override
  String get begin => 'Begin';

  @override
  String get budget => 'Budget';

  @override
  String get budgetAccuracyActualZero => 'Actual amount is zero. Cannot calculate percentages.';

  @override
  String get budgetAccuracyBothZero => 'Both budgeted and actual amounts are zero. Accuracy is undefined.';

  @override
  String budgetAccuracyPercent(String value) {
    return 'Accuracy:    @value%';
  }

  @override
  String budgetVariancePercent(String value) {
    return 'Variance:    @value%';
  }

  @override
  String get budgetVarianceUndefined => 'Budgeted amount is zero. Variance is undefined.';

  @override
  String get buildNumberLabel => 'Build Number';

  @override
  String get buySellDividend => 'Buy/Sell/Dividend.';

  @override
  String get cancel => 'Cancel';

  @override
  String get cash => 'Cash';

  @override
  String get cashFlow => 'Cash Flow';

  @override
  String get categories => 'Categories';

  @override
  String get categoriesDescription => 'Classification of your money transactions.';

  @override
  String get category => 'Category';

  @override
  String get chart => 'Chart';

  @override
  String get chartUpperSpacer => 'CHART ';

  @override
  String get chatTruncatedSuffix => '\n...';

  @override
  String get checkingOllamaStatus => 'Checking Ollama status...';

  @override
  String get chooseAnOptionToGetStarted => 'Choose an option to get started:';

  @override
  String get chooseColumns => 'Choose Columns';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get close => 'Close';

  @override
  String get closedLabel => 'Closed';

  @override
  String get closeFile => 'Close file';

  @override
  String get closePosition => 'Close Position';

  @override
  String columnFilterName(String name) {
    return 'Column Filter ($name)';
  }

  @override
  String columnIndex(String index) {
    return 'Column $index';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get content => 'Content:';

  @override
  String get contentGoesHere => 'Content goes here';

  @override
  String get continueLabel => 'Continue';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get copyListToClipboard => 'Copy list to clipboard';

  @override
  String get copyMessage => 'Copy message';

  @override
  String get copyMessageToClipboard => 'Copy message to clipboard';

  @override
  String countSelected(String count) {
    return '@count selected';
  }

  @override
  String countYears(String count) {
    return '@count years';
  }

  @override
  String get credit => 'Credit';

  @override
  String get csvFileEmpty => 'CSV file is empty.';

  @override
  String get csvHeadersAreMissingOrEmpty => 'CSV headers are missing or empty.';

  @override
  String get csvImportCancelled => 'CSV import cancelled.';

  @override
  String csvImportRowsImportedAndSkipped(Object imported, Object skipped) {
    return 'CSV import parsed $imported entries and skipped $skipped rows.';
  }

  @override
  String get dataPreviewFirst5Rows => 'Data Preview (First 5 rows):';

  @override
  String get date => 'Date';

  @override
  String get day => 'Day';

  @override
  String get debit => 'Debit';

  @override
  String get defaultListOfItems => 'Default list of items';

  @override
  String get delete => 'Delete';

  @override
  String get deleteSelectedItems => 'Delete selected item(s)';

  @override
  String deleteSelectedItemsQuestion(String count, String items) {
    return 'Are you sure you want to delete the $count selected $items?';
  }

  @override
  String deleteThisItemQuestion(String item) {
    return 'Are you sure you want to delete this $item?';
  }

  @override
  String get description => 'Description';

  @override
  String get descriptionPayee => 'Description/Payee';

  @override
  String get details => 'Details';

  @override
  String get dividend => 'Dividend';

  @override
  String get dropFilesHere => 'Drop files here';

  @override
  String get edit => 'Edit';

  @override
  String editedElapsed(String elapsed) {
    return 'Edited $elapsed';
  }

  @override
  String get editSelectedItems => 'Edit selected item(s)';

  @override
  String elapsedElapsed(String elapsed) {
    return 'Elapsed: @elapsed';
  }

  @override
  String get end => 'End';

  @override
  String entriesCount(String count) {
    return '$count entries';
  }

  @override
  String get error => 'Error';

  @override
  String errorImportingCsvError(String error) {
    return 'Error importing CSV: @error';
  }

  @override
  String errorImportingXlsxError(String error) {
    return 'Error importing XLSX: @error';
  }

  @override
  String get errorInvalidResponseFromOllama => 'Error: Invalid response from Ollama';

  @override
  String errorWithReason(String reason) {
    return 'Error: @reason';
  }

  @override
  String get event => 'Event';

  @override
  String get events => 'Events';

  @override
  String get eventTolerances => 'Event Tolerances';

  @override
  String get expenseLabel => 'Expense';

  @override
  String get expensePredictions => 'Expense predictions';

  @override
  String get expenses => 'Expenses';

  @override
  String get fileLocationMenuItem => 'File location...';

  @override
  String get fileLocationNotSupportedOnMobile => 'Opening the file location is only supported on desktop platforms.';

  @override
  String get fileMenuTooltip => 'File menu';

  @override
  String get filter => 'filter';

  @override
  String get fmoney => 'fMoney';

  @override
  String get forAccessingTwelveData => 'for accessing https://twelvedata.com';

  @override
  String get forSpacer => ' for ';

  @override
  String get freeStyle => 'Free style';

  @override
  String get fromAccount => 'From Account';

  @override
  String get fromCategory => 'From category';

  @override
  String get fromPayee => 'From payee';

  @override
  String get fullPromptSentToAi => 'Full Prompt Sent to AI';

  @override
  String get getLatestPrice => 'Get latest price';

  @override
  String get helperForDebugging => 'Helper for debugging';

  @override
  String get hideClosedAccounts => 'Hide closed accounts';

  @override
  String get idLabel => 'ID: ';

  @override
  String importedTransactionsIntoAccount(String count, String account) {
    return 'Imported - $count transactions into \"$account\"';
  }

  @override
  String importFileType(String fileType) {
    return 'Import $fileType';
  }

  @override
  String get importFromQfxQifXlsxCsvDescription => 'Import transactions from a QFX, QIF, XLSX, CSV, or PDF file.';

  @override
  String get importFromQfxQifXlsxCsvFile => 'From QFX|QIF|XLSX|CSV|PDF file';

  @override
  String importNoMatchingAccountsWithId(String fileType, String id) {
    return 'Import - No matching \"$fileType\" accounts with ID \"$id\"';
  }

  @override
  String get importTransactions => 'Import transactions';

  @override
  String get importTransactionToAccount => 'Import transaction to account';

  @override
  String get importWord => 'Import';

  @override
  String get includeAssetAccounts => 'Include Asset Accounts';

  @override
  String get incomeLabel => 'Income';

  @override
  String get incomes => 'Incomes';

  @override
  String get info => 'Info';

  @override
  String get installAppMenuItem => 'Install App...';

  @override
  String get installOllamaNow => 'Install Ollama now';

  @override
  String get interest => 'Interest';

  @override
  String get investment => 'Investment';

  @override
  String get investments => 'Investments';

  @override
  String get investmentTransaction => 'Investment Transaction';

  @override
  String get investmentType => 'Investment Type';

  @override
  String get item => 'Item';

  @override
  String get items => 'Items';

  @override
  String get keepAllTransactionsToTheirCurrentCategories => 'Keep all transactions to their current categories';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Francais';

  @override
  String get languageSpanish => 'Español';

  @override
  String get largestTransactions => 'Largest transactions';

  @override
  String get licenses => 'Licenses';

  @override
  String get licensesDescription =>
      'fMoney is built using open-source software. View the licenses for all packages used in this application.';

  @override
  String get lifeTimePnl => 'Life Time P&L';

  @override
  String get list => 'List';

  @override
  String get loanPayment => 'Loan Payment';

  @override
  String get loss => 'Loss';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get management => 'Management';

  @override
  String get manageTheExpensesAndRentalIncomeOfProperties => 'Manage the expenses and rental income of properties.';

  @override
  String get manualBulkTextInput => 'Manual bulk text input';

  @override
  String get manualBulkTextInputDescription =>
      'Refer to your online statements, then Copy & Paste text or use OCR to extract the [Dates | Memos | Amounts].';

  @override
  String get marketPrice => 'Market price';

  @override
  String get matchingTransaction => 'Found matching transactions';

  @override
  String get maxLabel => 'Max: ';

  @override
  String get memo => 'Memo';

  @override
  String get merge => 'Merge';

  @override
  String get mergeItems => 'Merge item(s)';

  @override
  String mergeTransactionsCount(String count) {
    return 'Merge @count transactions';
  }

  @override
  String mergeTransactionsIntoCategory(String from, String to) {
    return 'Use this option to merge transactions from \"@from\" into \"@to\".';
  }

  @override
  String get messageDetails => 'Message Details';

  @override
  String get minLabel => 'Min: ';

  @override
  String get missingTransfer => 'Missing Transfer';

  @override
  String get month => 'Month';

  @override
  String get monthlyActual => 'Monthly Actual';

  @override
  String get monthlyBudgeted => 'Monthly Budgeted';

  @override
  String get moveCategory => 'Move Category';

  @override
  String moveCategoryAsChild(String from, String to) {
    return 'Use this option to move \"@from\" as a child category of \"@to\".';
  }

  @override
  String multipleSelectionCount(String count) {
    return 'Multiple selection.($count)';
  }

  @override
  String get mutationAdded => 'added';

  @override
  String get mutationDeleted => 'deleted';

  @override
  String get mutationModified => 'modified';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navAccountsTooltip => 'Show Accounts';

  @override
  String get navAiAssistantTooltip => 'AI-powered financial insights';

  @override
  String get navAliases => 'Aliases';

  @override
  String get navAliasesTooltip => 'Show Aliases';

  @override
  String get navCashflow => 'Cashflow';

  @override
  String get navCashflowTooltip => 'Show your Cash Flow';

  @override
  String get navCategories => 'Categories';

  @override
  String get navCategoriesTooltip => 'Show Categories';

  @override
  String get navEvents => 'Events';

  @override
  String get navEventsTooltip => 'Your life events';

  @override
  String get navInvestments => 'Investments';

  @override
  String get navInvestmentsTooltip => 'Investment transactions';

  @override
  String get navPayees => 'Payees';

  @override
  String get navPayeesTooltip => 'Show Payees';

  @override
  String get navRentals => 'Rentals';

  @override
  String get navRentalsTooltip => 'Rentals';

  @override
  String navShowLabel(String label) {
    return 'Show @label';
  }

  @override
  String get navStocks => 'Stocks';

  @override
  String get navStocksTooltip => 'Stocks tracking';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navTransactionsTooltip => 'Show Transactions';

  @override
  String get navTransfers => 'Transfers';

  @override
  String get navTransfersTooltip => 'View transfers between accounts';

  @override
  String get networth => 'NetWorth';

  @override
  String get newBankAccount => 'New Bank Account';

  @override
  String get newFile => 'New File ...';

  @override
  String newItemLabel(String item) {
    return 'New @item';
  }

  @override
  String get newMenuItem => 'New';

  @override
  String get noAccountSelected => 'No account selected';

  @override
  String get noAccountSelectedPeriod => 'No account selected.';

  @override
  String get noBudgetIncomeCategoryFound => 'No budget income category found';

  @override
  String get noChartToDisplay => 'No chart to display';

  @override
  String get noData => 'No data';

  @override
  String get noDataPoints => 'No data points';

  @override
  String get noDataRowsToPreview => 'No data rows to preview.';

  @override
  String get noDataToDisplay => 'No data to display';

  @override
  String get noDateRangeYet => 'No date range yet';

  @override
  String noFieldsFoundForItem(String item) {
    return 'No fields found for @item';
  }

  @override
  String noHistoryInformationAboutSymbol(String symbol) {
    return 'No history information about \"$symbol\"';
  }

  @override
  String get noItems => 'No items';

  @override
  String get noItemSelected => 'No item selected.';

  @override
  String get noItemsToDelete => 'No items to delete';

  @override
  String noItemsWereTitle(String title) {
    return 'No items were @title';
  }

  @override
  String get noMatchingTransactions => 'No matching transactions';

  @override
  String get noNeedToMergeCategoryToItself => 'No need to merge to itself, select a different category.';

  @override
  String get noneLabel => 'None';

  @override
  String noneWithTitle(String title) {
    return 'None @title';
  }

  @override
  String get noPicker => 'no picker';

  @override
  String get noRelatedTransactions => 'No related transactions';

  @override
  String get noRowsFoundWith3OrMoreColumns => 'No rows found with 3 or more columns.';

  @override
  String get noSecuritySelected => 'No security selected.';

  @override
  String get noSheetXmlFoundInXlsxFile => 'No sheet XML found in XLSX file.';

  @override
  String get noStockSelected => 'No stock selected';

  @override
  String get notFound => '- not found -';

  @override
  String get nothingToImport => 'Nothing to import';

  @override
  String get noTransactions => 'No transactions';

  @override
  String get noTransactionsPeriod => 'No transactions.';

  @override
  String get noUi => 'no UI';

  @override
  String get noValidEntriesFoundInCsvToImport => 'No valid entries found in CSV to import.';

  @override
  String get noValidEntriesFoundInXlsxToImport => 'No valid entries found in XLSX to import.';

  @override
  String get ocr => 'OCR';

  @override
  String get ollamaAiAssistant => 'Ollama AI Assistant';

  @override
  String get ollamaIsRequiredToUseTheAiAssistantClickBelowToInstallIt =>
      'Ollama is required to use the AI assistant. Click below to install it.';

  @override
  String get openFile => 'Open File ...';

  @override
  String get openMenuItem => 'Open...';

  @override
  String get optional => 'optional';

  @override
  String get orChangeToCategory => 'or change to category';

  @override
  String get packageNameLabel => 'Package Name';

  @override
  String get payee => 'Payee';

  @override
  String get payeeAliasesDescription => 'Payee aliases.';

  @override
  String get payeeMatch => 'Payee Match';

  @override
  String get payees => 'Payees';

  @override
  String get pendingChanges => 'Pending Changes';

  @override
  String get pickAccountToImportTo => 'Pick account to import to';

  @override
  String pickDifferentCategoryThan(String category) {
    return 'Pick a different category than \"@category\".';
  }

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformDesktop64bitSoftware => 'Desktop 64bit Software.';

  @override
  String get platformDesktopIntelSiliconSoftware => 'Desktop Intel & Silicon Software.';

  @override
  String get platformDesktopSoftware => 'Desktop Software.';

  @override
  String get platformIos => 'iOS';

  @override
  String get platformLinux => 'Linux';

  @override
  String get platformMacos => 'macOS';

  @override
  String get platformMobileApp => 'Mobile app.';

  @override
  String get platformRunOnAnyOsWithMostBrowsers => 'Run on any OS with most browsers.';

  @override
  String get platformWebBrowser => 'Web Browser';

  @override
  String get platformWindows => 'Windows';

  @override
  String get pleaseMapAllFieldsDateDescriptionAmount => 'Please map all fields (Date, Description, Amount).';

  @override
  String get pleaseSelectDifferentAccounts => 'Please select different accounts';

  @override
  String get pnl => 'PnL';

  @override
  String get policy => 'Policy';

  @override
  String get preview => 'Preview';

  @override
  String get price => 'Price';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicyMarkdown =>
      '# Privacy Policy for fMoney App\n\n## 1. No Information Collected:\nfMoney does not collect any personal information from its users. We do not require users to provide any personal data such as name, email address, or any other identifying information.\n\n## 2. Information Usage:\nSince we do not collect any personal information, we do not use or share any information about our users.\n\n## 3. No Data Logged:\nfMoney does not log any data from its users.\n\n## 4. Contact Us:\nIf you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us at questions@vteam.com.\n\n_________________\n\n\nBy using fMoney, you signify your acceptance of this Privacy Policy. If you do not agree to this policy, please do not use our application. Your continued use of the application following the posting of changes to this policy will be deemed your acceptance of those changes.\n';

  @override
  String get profit => 'Profit';

  @override
  String get propertiesToRentDescription => 'Properties to rent.';

  @override
  String get quantity => 'Quantity';

  @override
  String questionsQuestioncountTokensTokencount(String questionCount, String tokenCount) {
    return 'Questions: $questionCount | Tokens: $tokenCount';
  }

  @override
  String get range => 'Range';

  @override
  String get readLess => 'Read Less';

  @override
  String get readMore => 'Read More';

  @override
  String get rebalanceMenuItem => 'Rebalance...';

  @override
  String get receiver => 'Receiver';

  @override
  String get recordATransferBetweenTwoAccounts => 'Convert as Transfer';

  @override
  String get recordTransfer => 'Record Transfer';

  @override
  String get recurring => 'Recurring';

  @override
  String get refreshList => 'Refresh list';

  @override
  String get rental => 'Rental';

  @override
  String get rentalPropertyNotFound => 'Rental property not found';

  @override
  String get rentals => 'Rentals';

  @override
  String get renters => 'Renters';

  @override
  String get repairs => 'Repairs';

  @override
  String get requestWasCancelled => 'Request was cancelled.';

  @override
  String rowIndex(String index) {
    return 'Row $index';
  }

  @override
  String get runOllama => 'Run Ollama';

  @override
  String get sankey => 'Sankey';

  @override
  String get saveToCsv => 'Save to CSV';

  @override
  String get saveToSql => 'Save to SQL';

  @override
  String get savingLabel => 'Saving';

  @override
  String get searchForPayee => 'Search for Payee';

  @override
  String securitySymbolInvalid(String symbol) {
    return 'Security \"$symbol\" is not valid';
  }

  @override
  String get selectARentalPropertyToSeeItsPL => 'Select a Rental property to see its P&L';

  @override
  String get selectCategory => 'Select a category';

  @override
  String get selectColumn => 'Select column';

  @override
  String get selectHeaderRow => 'Select Header Row';

  @override
  String get selectTheRowThatContainsTheColumnHeadersAutomaticallySelectedBasedOnContent =>
      'Select the row that contains the column headers (automatically selected based on content):';

  @override
  String get selectValidAccounts => 'Select valid accounts.';

  @override
  String get sender => 'Sender';

  @override
  String get setApiKey => 'Set API Key';

  @override
  String get settings => 'Settings';

  @override
  String get settingsMenuItem => 'Settings...';

  @override
  String get shares => 'Shares';

  @override
  String get shortcutAddTransactions => 'Ctrl+T';

  @override
  String get shortcutNewFile => 'Ctrl+N';

  @override
  String get shortcutOpenFile => 'Ctrl+O';

  @override
  String get shortcutRebalance => 'Ctrl+R';

  @override
  String get shortcutZoomDecrease => 'Cmd/Ctrl -';

  @override
  String get shortcutZoomIncrease => 'Cmd/Ctrl +';

  @override
  String get shortcutZoomReset => 'Cmd/Ctrl 0';

  @override
  String get showClosedAccounts => 'Show closed accounts';

  @override
  String showingFirstMaxrowsOfRowcountEligibleRows(String maxRows, String rowCount) {
    return 'Showing first $maxRows of $rowCount eligible rows';
  }

  @override
  String showingRowcountEligibleRowsExcludedRowsWith3Columns(String rowCount) {
    return 'Showing $rowCount eligible rows (excluded rows with < 3 columns)';
  }

  @override
  String get sidePanelExpandCollapseTooltip => 'Expand/collapse panel';

  @override
  String get skippingDuplicate => ' Skipping Duplicate ';

  @override
  String get smallScreenContentGoesHere => 'Small screen content goes here';

  @override
  String get split => 'Split';

  @override
  String splitRatio(String numerator, String denominator) {
    return '$numerator for $denominator';
  }

  @override
  String get splits => 'Splits';

  @override
  String get stock => 'Stock';

  @override
  String get stocks => 'Stocks';

  @override
  String get stocksTrackingDescription => 'Stocks tracking.';

  @override
  String get success => 'Success';

  @override
  String get suggestion => 'Suggestion';

  @override
  String get switchToCategories => 'Switch to Categories';

  @override
  String get switchToPayees => 'Switch to Payees';

  @override
  String get switchToStocks => 'Switch to Stocks';

  @override
  String get switchToTransactions => 'Switch to Transactions';

  @override
  String get symbol => 'Symbol';

  @override
  String get taxes => 'Taxes';

  @override
  String get teachingCancelled => 'Teaching cancelled.';

  @override
  String get teachingFailedPartially => 'Teaching failed partially - some accounts may not be learned.';

  @override
  String get themeColorBlue => 'Blue';

  @override
  String get themeColorGreen => 'Green';

  @override
  String get themeColorOrange => 'Orange';

  @override
  String get themeColorPink => 'Pink';

  @override
  String get themeColorPurple => 'Purple';

  @override
  String get themeColorTeal => 'Teal';

  @override
  String get themeColorYellow => 'Yellow';

  @override
  String get thinking => 'Thinking...';

  @override
  String get timeline => 'Timeline';

  @override
  String timestampTimestamp(String timestamp) {
    return 'Timestamp: @timestamp';
  }

  @override
  String get toAccount => 'To Account';

  @override
  String get toCategory => 'To category';

  @override
  String get toggleBrightness => 'Toggle brightness';

  @override
  String get toPayee => 'To payee';

  @override
  String get total => 'Total';

  @override
  String get totalTransactionAmount => 'Total Transaction Amount';

  @override
  String get trackYourStockPortfolioDescription => 'Track your stock portfolio.';

  @override
  String get transaction => 'Transaction';

  @override
  String get transactions => 'Transactions';

  @override
  String transactionsAddedCount(String count) {
    return '$count transactions added';
  }

  @override
  String transactionsAveraging(String count) {
    return '@count transactions averaging';
  }

  @override
  String get transactionsDescription => 'Details actions of your accounts.';

  @override
  String transactionsFoundInFileToImport(String count, String fileType, String account) {
    return '$count transactions found in $fileType file, to be imported into \"$account\"';
  }

  @override
  String get transactionSplit => 'Transaction split';

  @override
  String get transfer => 'Transfer';

  @override
  String get transfers => 'Transfers';

  @override
  String get transfersBetweenAccountsDescription => 'Transfers between accounts.';

  @override
  String get trend => 'Trend';

  @override
  String get units => 'Units';

  @override
  String get unknown => 'Unknown';

  @override
  String get useDemoData => 'Use Demo Data';

  @override
  String get value => 'Value';

  @override
  String get versionInformation => 'Version Information';

  @override
  String get versionLabel => 'Version';

  @override
  String get viewClosedAccounts => 'View closed accounts';

  @override
  String get viewLicenses => 'View Licenses';

  @override
  String get viewMessageDetails => 'View message details';

  @override
  String get viewPromptDetails => 'View prompt details';

  @override
  String get warning => 'Warning';

  @override
  String get welcomeToFmoney => 'Welcome to fMoney';

  @override
  String get welcomeToYourAiAccountant => 'Welcome to your AI Accountant';

  @override
  String get whoIsGettingYourMoney => 'Who is getting your money.';

  @override
  String get xlsxFileContainsNoDataRows => 'XLSX file contains no data rows.';

  @override
  String get xlsxFileContainsNoValidData => 'XLSX file contains no valid data.';

  @override
  String get xlsxImportCancelled => 'XLSX import cancelled.';

  @override
  String get year => 'Year';

  @override
  String get zoom => 'Zoom';
}
