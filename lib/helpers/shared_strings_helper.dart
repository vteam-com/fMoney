export 'package:money/helpers/shared_strings_domain.dart';
export 'package:money/helpers/shared_strings_simulation_helper.dart';
export 'package:money/helpers/shared_strings_sql_helper.dart';

/// Centralized non-localized string tokens shared across the codebase.
abstract class SharedStrings {
  /// Prevents instantiation.
  SharedStrings._();

  /// An empty string token.
  static const String empty = '';

  /// A single space token.
  static const String space = ' ';

  /// A line-feed token.
  static const String lineFeed = '\n';

  /// A tab token.
  static const String tab = '\t';

  /// Process command token used to locate an executable.
  static const String processWhich = 'which';

  /// Process command token used on Windows shells.
  static const String processCmd = 'cmd';

  /// Process argument token used to start background processes on Windows.
  static const String processStart = 'start';

  /// Executable token for local Ollama invocations.
  static const String executableOllama = 'ollama';

  /// Ollama argument used to run a model.
  static const String ollamaArgRun = 'run';

  /// Ollama argument used to start the local API server.
  static const String ollamaArgServe = 'serve';

  /// JSON payload key for batched chat messages.
  static const String payloadKeyMessages = 'messages';

  /// Prompt prefix used for system role content.
  static const String promptPrefixSystem = 'System: ';

  /// Prompt prefix used for user role content.
  static const String promptPrefixUser = 'User: ';

  /// Prompt prefix used for assistant role content.
  static const String promptPrefixAssistant = 'Assistant: ';

  /// GitHub API media type for v3 responses.
  static const String githubApiAcceptV3Json = 'application/vnd.github.v3+json';

  /// Platform key used for Windows artifacts.
  static const String platformKeyWindows = 'windows';

  /// Platform key used for Linux artifacts.
  static const String platformKeyLinux = 'linux';

  /// Platform key used for macOS artifacts.
  static const String platformKeyMacos = 'macos';

  /// Label for regex alias type values.
  static const String aliasTypeRegExp = 'RegExp';

  /// Number format pattern with up to five decimal places.
  static const String numberFormatUpToFiveDecimals = '#,##0.#####';

  /// Number format pattern with up to two decimal places.
  static const String numberFormatTrimmedDecimals = '#,##0.##';

  /// Country code used as default locale fallback.
  static const String countryCodeUs = 'US';

  /// Lowercase locale fallback country code.
  static const String countryCodeUsLower = 'us';

  /// Lowercase ISO currency code for Euro.
  static const String currencyCodeEurLower = 'eur';

  /// Lowercase ISO currency code for US Dollar.
  static const String currencyCodeUsdLower = 'usd';

  /// Lowercase ISO currency code for Canadian Dollar.
  static const String currencyCodeCadLower = 'cad';

  /// Human-readable suffix for gigabyte values.
  static const String byteUnitGigabytes = ' GB';

  /// Human-readable suffix for megabyte values.
  static const String byteUnitMegabytes = ' MB';

  /// Human-readable suffix for kilobyte values.
  static const String byteUnitKilobytes = ' KB';

  /// Human-readable suffix for byte values.
  static const String byteUnitBytes = ' B';

  /// Year token for 4-digit date format parsing.
  static const String dateTokenYearFour = 'yyyy';

  /// Year token for 2-digit date format parsing.
  static const String dateTokenYearTwo = 'yy';

  /// Month token for 2-digit date format parsing.
  static const String dateTokenMonthTwo = 'MM';

  /// Month token for 1-digit date format parsing.
  static const String dateTokenMonthOne = 'M';

  /// Day token for 2-digit date format parsing.
  static const String dateTokenDayTwo = 'dd';

  /// Day token for 1-digit date format parsing.
  static const String dateTokenDayOne = 'd';

  /// Separator between date and time in ISO-8601 strings.
  static const String dateTimeIsoSeparator = 'T';

  /// Relative-time unit label for year.
  static const String elapsedYear = 'year';

  /// Relative-time unit label for month.
  static const String elapsedMonth = 'month';

  /// Relative-time unit label for day.
  static const String elapsedDay = 'day';

  /// Relative-time unit label for hour.
  static const String elapsedHour = 'hour';

  /// Relative-time unit label for minute.
  static const String elapsedMinute = 'minute';

  /// Relative-time suffix used to indicate past values.
  static const String elapsedAgo = 'ago';

  /// Relative-time label for immediate events.
  static const String elapsedJustNow = 'Just now';

  /// Comma + space separator used in elapsed-time formatting.
  static const String commaSpace = ', ';

  /// URI scheme used for opening local filesystem locations.
  static const String fileUriScheme = 'file:';

  /// Preferred desktop application title.
  static const String appWindowTitle = 'fMoney by vTeam';

  /// Currency formatting custom pattern with symbol prefix.
  static const String currencyPatternSymbolLeft = '¤#,##0.00';

  /// Singular duration label for day.
  static const String durationDay = 'day';

  /// Plural duration label for day.
  static const String durationDays = 'days';

  /// Singular duration label for year.
  static const String durationYear = 'year';

  /// Plural duration label for year.
  static const String durationYears = 'years';

  /// Range description infix for minimum values.
  static const String rangeMinInfix = ' min, ';

  /// Range description suffix for maximum values.
  static const String rangeMaxSuffix = ' max';

  /// Running-average title label.
  static const String runningAverageLabel = 'Average';

  /// Running-average count suffix when all entries are non-zero.
  static const String runningAverageEntriesSuffix = ' entries.';

  /// Running-average infix between non-zero and total counts.
  static const String runningAverageOfInfix = ' of ';

  /// Running-average suffix when zero entries were excluded.
  static const String runningAverageNonZeroEntriesSuffix = ' non zero entries.';

  /// Text prefix for account/object representation IDs.
  static const String idPrefixReadable = 'Id: ';

  /// Text prefix for SQL-style where clause IDs.
  static const String idPrefixWhere = 'Id=';

  /// Error message used when derived classes skip implementing `uniqueId`.
  static const String errorDerivedClassMustImplementUniqueId = 'derived class must implement uniqueId';

  /// Field identifier serialize name.
  static const String fieldId = 'Id';

  /// Assertion message for generic field collections.
  static const String errorTypeTCannotBeDynamic = 'Type T cannot be dynamic';

  /// Fixed-width font family name used in tables.
  static const String fontRobotoMono = 'RobotoMono';

  /// Proportional font family name used in tables.
  static const String fontRobotoFlex = 'RobotoFlex';

  /// Footer tooltip suffix used when truncating sample content.
  static const String footerSampleTruncation = '\n...';

  /// Footer tooltip label for sum cells.
  static const String footerSumLabel = 'Sum.';

  /// Footer value prefix for averages.
  static const String footerAveragePrefix = 'Av ';

  /// Unique-state prefix label for readiness.
  static const String preferenceStateReady = 'isReady:';

  /// Unique-state segment label for rental feature.
  static const String preferenceStateRental = 'Rental:';

  /// Unique-state segment label for closed-account inclusion.
  static const String preferenceStateIncludeClosedAccounts = 'IncludeClosedAccounts:';

  /// Unique-state segment label for text scale.
  static const String preferenceStateTextScale = 'TextScale:';

  /// Default app locale code.
  static const String localeCodeEnglish = 'en';

  /// Account type label: savings.
  static const String accountTypeSavings = 'Savings';

  /// Account type label: checking.
  static const String accountTypeChecking = 'Checking';

  /// Account type label: money market.
  static const String accountTypeMoneyMarket = 'MoneyMarket';

  /// Account type label: cash.
  static const String accountTypeCash = 'Cash';

  /// Account type label: credit.
  static const String accountTypeCredit = 'Credit';

  /// Account type label: credit card.
  static const String accountTypeCreditCard = 'CreditCard';

  /// Account type label: credit line.
  static const String accountTypeCreditLine = 'CreditLine';

  /// Account type label: investment.
  static const String accountTypeInvestment = 'Investment';

  /// Account type label: retirement.
  static const String accountTypeRetirement = 'Retirement';

  /// Account type label: asset.
  static const String accountTypeAsset = 'Asset';

  /// Account type label: fund.
  static const String accountTypeFund = 'Fund';

  /// Account type label: loan.
  static const String accountTypeLoan = 'Loan';

  /// Prefix used for unknown account type fallback rendering.
  static const String accountTypeOtherPrefix = 'other ';

  /// Category type lookup token for income.
  static const String categoryTypeIncomeToken = 'income';

  /// Category type lookup token for expense.
  static const String categoryTypeExpenseToken = 'expense';

  /// Category type lookup token for recurring expense.
  static const String categoryTypeRecurringExpenseToken = 'recurringexpense';

  /// Category type lookup token for alternate recurring expense spelling.
  static const String categoryTypeExpenseRecurringToken = 'expenserecurring';

  /// Category type lookup token for saving.
  static const String categoryTypeSavingToken = 'saving';

  /// Category type lookup token for reserved.
  static const String categoryTypeReservedToken = 'reserved';

  /// Category type lookup token for transfer.
  static const String categoryTypeTransferToken = 'transfer';

  /// Category type lookup token for investment.
  static const String categoryTypeInvestmentToken = 'investment';

  /// Category display label for income.
  static const String categoryTypeIncomeLabel = 'Income';

  /// Category display label for expense.
  static const String categoryTypeExpenseLabel = 'Expense';

  /// Category display label for recurring expense.
  static const String categoryTypeExpenseRecurringLabel = 'ExpenseRecurring';

  /// Category display label for saving.
  static const String categoryTypeSavingLabel = 'Saving';

  /// Category display label for reserved.
  static const String categoryTypeReservedLabel = 'Reserved';

  /// Category display label for transfer.
  static const String categoryTypeTransferLabel = 'Transfer';

  /// Category display label for investment.
  static const String categoryTypeInvestmentLabel = 'Investment';

  /// Category display label for no type.
  static const String categoryTypeNoneLabel = 'None';

  /// Transaction status letter for electronic entries.
  static const String transactionStatusLetterElectronic = 'E';

  /// Transaction status letter for cleared entries.
  static const String transactionStatusLetterCleared = 'C';

  /// Transaction status letter for reconciled entries.
  static const String transactionStatusLetterReconciled = 'R';

  /// Transaction status letter for voided entries.
  static const String transactionStatusLetterVoided = 'V';

  /// Canonical data-field name used by category mutation operations.
  static const String fieldType = 'Type';

  /// Yahoo/TwelveData stock event token for split history.
  static const String stockEventSplits = 'splits';

  /// ISO currency token used as default during free-text imports.
  static const String currencyUsd = 'USD';

  /// Generic multiplication marker used in generated import descriptions.
  static const String multiplierX = ' x ';

  /// Canonical file type label for CSV imports.
  static const String fileTypeCsv = 'CSV';

  /// Canonical file type label for QFX imports.
  static const String fileTypeQfx = 'QFX';

  /// Canonical file type label for QIF imports.
  static const String fileTypeQif = 'QIF';

  /// Canonical file type label for XLSX imports.
  static const String fileTypeXlsx = 'XLSX';

  /// Supported file extension for QIF imports.
  static const String fileExtensionQif = 'qif';

  /// Supported file extension for QFX imports.
  static const String fileExtensionQfx = 'qfx';

  /// Supported file extension for XLSX imports.
  static const String fileExtensionXlsx = 'xlsx';

  /// Supported file extension for CSV imports.
  static const String fileExtensionCsv = 'csv';

  /// Supported file extension for PDF imports.
  static const String fileExtensionPdf = 'pdf';

  /// Supported file extension for database files.
  static const String fileExtensionMmdb = '.mmdb';

  /// Supported file extension for zipped CSV project files.
  static const String fileExtensionMmcsv = '.mmcsv';

  /// Internal import-entry type identifier for CSV rows.
  static const String importTypeCsv = 'CSVImport';

  /// Internal import-entry type identifier for XLSX rows.
  static const String importTypeXlsx = 'XLSXImport';

  /// QIF header token that identifies investment account content.
  static const String qifTypeInvestment = 'Type:Invst';

  /// QIF field token for posting date.
  static const String qifFieldDate = 'D';

  /// QIF field token for amount.
  static const String qifFieldAmount = 'T';

  /// QIF field token for alternate amount representation.
  static const String qifFieldAmountAlt = 'U';

  /// QIF field token for memo.
  static const String qifFieldMemo = 'M';

  /// QIF field token for transaction action.
  static const String qifFieldAction = 'N';

  /// QIF field token for quantity.
  static const String qifFieldQuantity = 'Q';

  /// QIF field token for security symbol.
  static const String qifFieldSecurity = 'Y';

  /// QIF field token for payee.
  static const String qifFieldPayee = 'P';

  /// QIF field token for price.
  static const String qifFieldPrice = 'I';

  /// XML entity token for ampersand.
  static const String xmlEntityAmp = '&amp;';

  /// XML entity token for less-than.
  static const String xmlEntityLt = '&lt;';

  /// XML entity token for greater-than.
  static const String xmlEntityGt = '&gt;';

  /// XML entity token for double quote.
  static const String xmlEntityQuot = '&quot;';

  /// XML entity token for apostrophe.
  static const String xmlEntityApos = '&#39;';

  /// XML entity token for lowercase cedilla.
  static const String xmlEntityCedilla = '&#xE7;';

  /// XML entity token for lowercase a-tilde.
  static const String xmlEntityATilde = '&#xE3;';

  /// XML entity token for lowercase e-acute.
  static const String xmlEntityEAcute = '&#xE9;';

  /// XML entity token for lowercase e-circumflex.
  static const String xmlEntityECirc = '&#xEA;';

  /// XML entity token for lowercase o-tilde.
  static const String xmlEntityOTilde = '&#xF5;';

  /// XML entity token for lowercase o-acute.
  static const String xmlEntityOAcute = '&#xF3;';

  /// OFX tag used to locate the bank identifier.
  static const String ofxTagBankId = '<BANKID>';

  /// OFX tag used to locate the account identifier.
  static const String ofxTagAccountId = '<ACCTID>';

  /// OFX tag used to locate the account type.
  static const String ofxTagAccountType = '<ACCTTYPE>';

  /// OFX transaction type token for credit entries.
  static const String ofxTypeCredit = 'CREDIT';

  /// OFX transaction type token for debit entries.
  static const String ofxTypeDebit = 'DEBIT';

  /// OFX transaction type token for interest entries.
  static const String ofxTypeInterest = 'INT';

  /// OFX transaction type token for dividend entries.
  static const String ofxTypeDividend = 'DIV';

  /// OFX transaction type token for fee entries.
  static const String ofxTypeFee = 'FEE';

  /// OFX transaction type token for service charge entries.
  static const String ofxTypeServiceCharge = 'SRVCHG';

  /// OFX transaction type token for deposit entries.
  static const String ofxTypeDeposit = 'DEP';

  /// OFX transaction type token for ATM entries.
  static const String ofxTypeAtm = 'ATM';

  /// OFX transaction type token for point-of-sale entries.
  static const String ofxTypePos = 'POS';

  /// OFX transaction type token for payment entries.
  static const String ofxTypePayment = 'PAYMENT';

  /// OFX transaction type token for cash entries.
  static const String ofxTypeCash = 'CASH';

  /// OFX transaction type token for direct deposit entries.
  static const String ofxTypeDirectDeposit = 'DIRECTDEP';

  /// OFX transaction type token for direct debit entries.
  static const String ofxTypeDirectDebit = 'DIRECTDEBIT';

  /// OFX transaction type token for repeating payment entries.
  static const String ofxTypeRepeatPayment = 'REPEATPMT';

  /// OFX transaction type token for check entries.
  static const String ofxTypeCheck = 'CHECK';

  /// OFX transaction type token for miscellaneous entries.
  static const String ofxTypeOther = 'OTHER';

  /// OFX transaction type token for transfer entries.
  static const String ofxTypeTransfer = 'XFER';

  /// OFX close tag for a transaction block.
  static const String ofxCloseStatementTransaction = '</STMTTRN>';

  /// OFX open tag for a transaction block.
  static const String ofxOpenStatementTransaction = '<STMTTRN>';

  /// OFX close tag for a transaction block with trailing line feed.
  static const String ofxCloseStatementTransactionLine = '</STMTTRN>\n';

  /// OFX tag for transaction type.
  static const String ofxTagTransactionType = '<TRNTYPE>';

  /// OFX tag for posted date.
  static const String ofxTagDatePosted = '<DTPOSTED>';

  /// OFX tag for transaction amount.
  static const String ofxTagTransactionAmount = '<TRNAMT>';

  /// OFX tag for name.
  static const String ofxTagName = '<NAME>';

  /// OFX tag for fit id.
  static const String ofxTagFitId = '<FITID>';

  /// OFX tag for memo.
  static const String ofxTagMemo = '<MEMO>';

  /// OFX tag for check number.
  static const String ofxTagCheckNumber = '<CHECKNUM>';

  /// Canonical investment-field name: date.
  static const String investmentFieldDate = 'Date';

  /// Canonical investment-field name: account.
  static const String investmentFieldAccount = 'Account';

  /// Canonical investment-field name: activity.
  static const String investmentFieldActivity = 'Activity';

  /// Canonical investment-field name: units.
  static const String investmentFieldUnits = 'Units';

  /// Canonical investment-field name: split.
  static const String investmentFieldSplit = 'Split';

  /// Canonical investment-field name: split-adjusted units.
  static const String investmentFieldUnitsAdjusted = 'Units A.S.';

  /// Canonical investment-field name: holding.
  static const String investmentFieldHolding = 'Holding';

  /// Canonical investment-field name: price.
  static const String investmentFieldPrice = 'Price';

  /// Canonical investment-field name: split-adjusted price.
  static const String investmentFieldPriceAdjusted = 'Price A.S.';

  /// Canonical investment-field name: holding value.
  static const String investmentFieldHoldingValue = 'HoldingValue';

  /// Canonical investment-field name: commission.
  static const String investmentFieldCommission = 'Commission';

  /// Canonical investment-field name: activity amount.
  static const String investmentFieldActivityAmount = 'ActivityAmount';

  /// Payload role token used for user messages in AI requests.
  static const String payloadRoleUser = 'user';

  /// Payload key that stores generated response text.
  static const String payloadKeyResponse = 'response';

  /// Payload key that stores model conversation context.
  static const String payloadKeyContext = 'context';

  /// Generic comma token for CSV serialization.
  static const String csvComma = ',';

  /// Shared separator token used by three-column text inputs.
  static const String semicolonSpace = '; ';

  /// Label for "3 columns" tab.
  static const String threeColumnsLabel = '3 columns';

  /// Label for date/description/amount combined text mode.
  static const String labelDateDescriptionAmount = 'Date; Description; Amount';

  /// Suffix token appended to line counters.
  static const String suffixLines = ' lines';

  /// Date format used in line-chart x-axis labels.
  static const String dateFormatYearLineMonth = 'yyyy\nMMM';

  /// Placeholder shown when amount text is empty.
  static const String placeholderNoAmount = '< no amount >';

  /// Placeholder shown when date text is empty.
  static const String placeholderNoDate = '< no date >';

  /// Placeholder shown when description text is empty.
  static const String placeholderNoDescription = '< no description >';

  /// Generic action label for completing read-only dialogs.
  static const String labelDone = 'Done';

  /// Generic close action label.
  static const String labelClose = 'Close';

  /// Generic action label for duplicating entities.
  static const String labelDuplicate = 'Duplicate';

  /// Delete confirmation title for split entities.
  static const String labelDeleteSplit = 'Delete Split';

  /// Delete confirmation question for split entities.
  static const String questionDeleteSplit = 'Are you sure you want to delete this Split?';

  /// Delete confirmation title for transaction entities.
  static const String labelDeleteTransaction = 'Delete Transaction';

  /// Delete confirmation question for transaction entities.
  static const String questionDeleteTransaction = 'Are you sure you want to delete this transaction?';

  /// Message shown when no items are available for edit.
  static const String messageNoItemsToEdit = 'No items to edit';

  /// Label for MRU picker title.
  static const String labelRecentFiles = 'Recent files';

  /// Menu label for the external finance website.
  static const String labelYahooFinance = 'Yahoo finance';

  /// Prefix for failed URL-launch messages.
  static const String messageCouldNotLaunch = 'Could not launch ';

  /// Generic tooltip label for view-switch menus.
  static const String labelSwitchView = 'Switch view';

  /// Keyboard shortcut hint for zoom reset.
  static const String shortcutZoomReset = 'Cmd/Ctrl 0';

  /// Tooltip label for toggling multi-selection mode.
  static const String tooltipToggleMultiSelection = 'Toggle multi-selection';

  /// Tooltip label for scrolling to the top of a list.
  static const String tooltipScrollToTop = 'Scroll to the Top of the list';

  /// Tooltip label for scrolling to the latest selection.
  static const String tooltipScrollToSelection = 'Scroll to last selection';

  /// Tooltip label for scrolling to the bottom of a list.
  static const String tooltipScrollToBottom = 'Scroll to the Bottom of the list';

  /// Tooltip prefix for filtering indicator.
  static const String labelFiltering = 'Filtering';

  /// Tooltip label for ascending sort order.
  static const String labelSortingAscending = 'Sorting Ascending';

  /// Tooltip label for descending sort order.
  static const String labelSortingDescending = 'Sorting Descending';

  /// Default dialog title for single-text-input dialogs.
  static const String inputTitle = 'Input';

  /// Prefix used by single-input dialog hints.
  static const String enterPrefix = 'Enter ';

  /// Hint text shown in the AI chat prompt input.
  static const String aiAssistantHint = 'Ask the AI assistant...';

  /// OCR extraction failure message.
  static const String messageFailedToExtractTextFromImage = 'Failed to extract text from image.';

  /// Clipboard-empty message for OCR action.
  static const String messageNoImageFoundInClipboard = 'No image found in clipboard.';

  /// Assertion message when AppScope is missing in the widget tree.
  static const String messageAppScopeMissing = 'AppScope not found in widget tree.';

  /// Assertion message when AppScope instance is not ready.
  static const String messageAppScopeUnavailable = 'AppScope instance is not available yet.';

  /// Prefix for unsupported file-type warning messages.
  static const String messageUnsupportedFileTypePrefix = 'Unsupported file type ';

  /// Log level token used for debug entries.
  static const String logLevelDebug = 'DEBUG';

  /// Log level token used for error entries.
  static const String logLevelError = 'ERROR';

  /// Log level token used for warning entries.
  static const String logLevelWarn = 'WARN';

  /// Label token used before serialized log context.
  static const String logContextPrefix = ' | context=';

  /// Table name for account aliases.
  static const String tableAccountAliases = 'AccountAliases';

  /// Table name for accounts.
  static const String tableAccounts = 'Accounts';

  /// Table name for aliases.
  static const String tableAliases = 'Aliases';

  /// Table name for categories.
  static const String tableCategories = 'Categories';

  /// Table name for currencies.
  static const String tableCurrencies = 'Currencies';

  /// Table name for investments.
  static const String tableInvestments = 'Investments';

  /// Table name for loan payments.
  static const String tableLoanPayments = 'LoanPayments';

  /// Table name for online accounts.
  static const String tableOnlineAccounts = 'OnlineAccounts';

  /// Table name for payees.
  static const String tablePayees = 'Payees';

  /// Table name for rental buildings.
  static const String tableRentBuildings = 'RentBuildings';

  /// Table name for rental units.
  static const String tableRentUnits = 'RentUnits';

  /// Table name for securities.
  static const String tableSecurities = 'Securities';

  /// Table name for stock splits.
  static const String tableStockSplits = 'StockSplits';

  /// Table name for events.
  static const String tableEvents = 'Events';

  /// Table name for transactions.
  static const String tableTransactions = 'Transactions';

  /// Table name for transaction extras.
  static const String tableTransactionExtras = 'TransactionExtras';

  /// Table name for transaction splits.
  static const String tableSplits = 'Splits';

  /// Color-swatch label token.
  static const String colorWhite = 'white';

  /// Color-swatch label token.
  static const String colorBlack = 'black';

  /// Color-swatch label token.
  static const String colorOnSurface = 'onSurface';

  /// Color-swatch label token.
  static const String colorSurface = 'surface';

  /// Color-swatch label token.
  static const String colorOnPrimary = 'onPrimary';

  /// Color-swatch label token.
  static const String colorPrimary = 'primary';

  /// Color-swatch label token.
  static const String colorOnSecondary = 'onSecondary';

  /// Color-swatch label token.
  static const String colorSecondary = 'secondary';

  /// Color-swatch label token.
  static const String colorOnTertiary = 'onTertiary';

  /// Color-swatch label token.
  static const String colorTertiary = 'tertiary';
}
