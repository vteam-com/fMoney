/// SQL-specific non-localized string tokens used by storage helpers.
abstract class SharedSqlStrings {
  /// Prevents instantiation.
  SharedSqlStrings._();

  /// Full SQL schema used to bootstrap a new local database.
  static const String sqlSchemaBootstrap = '''
CREATE TABLE [LoanPayments] (
  [Id] int PRIMARY KEY,
  [AccountId] int NOT NULL,
  [Date] datetime NOT NULL,
  [Principal] money,
  [Interest] money,
  [Memo] nvarchar(255)
);

CREATE TABLE [Accounts] (
  [Id] int PRIMARY KEY,
  [AccountId] nchar(20),
  [OfxAccountId] nvarchar(50),
  [Name] nvarchar(80) NOT NULL,
  [Description] nvarchar(255),
  [Type] int NOT NULL,
  [OpeningBalance] money,
  [Currency] nchar(3),
  [OnlineAccount] int,
  [WebSite] nvarchar(512),
  [ReconcileWarning] int,
  [LastSync] datetime,
  [SyncGuid] uniqueidentifier,
  [Flags] int,
  [LastBalance] datetime,
  [CategoryIdForPrincipal] int,
  [CategoryIdForInterest] int
);

CREATE TABLE [OnlineAccounts] (
  [Id] int PRIMARY KEY,
  [Name] nvarchar(80) NOT NULL,
  [Institution] nvarchar(80),
  [OFX] nvarchar(255),
  [OfxVersion] nchar(10),
  [FID] nvarchar(50),
  [UserId] nchar(20),
  [Password] nvarchar(50),
  [UserCred1] nvarchar(200),
  [UserCred2] nvarchar(200),
  [AuthToken] nvarchar(200),
  [BankId] nvarchar(50),
  [BranchId] nvarchar(50),
  [BrokerId] nvarchar(50),
  [LogoUrl] nvarchar(1000),
  [AppId] nchar(10),
  [AppVersion] nchar(10),
  [ClientUid] nchar(36),
  [AccessKey] nchar(36),
  [UserKey] nvarchar(64),
  [UserKeyExpireDate] datetime
);

CREATE TABLE [Payees] (
  [Id] int PRIMARY KEY,
  [Name] nvarchar(255) NOT NULL
);

CREATE TABLE [Aliases] (
  [Id] int PRIMARY KEY,
  [Pattern] nvarchar(255) NOT NULL,
  [Flags] int NOT NULL,
  [Payee] int NOT NULL
);

CREATE TABLE [RentBuildings] (
  [Id] int PRIMARY KEY,
  [Name] nvarchar(255) NOT NULL,
  [Address] nvarchar(255),
  [PurchasedDate] datetime,
  [PurchasedPrice] money,
  [LandValue] money,
  [EstimatedValue] money,
  [OwnershipName1] nvarchar(255),
  [OwnershipName2] nvarchar(255),
  [OwnershipPercentage1] money,
  [OwnershipPercentage2] money,
  [Note] nvarchar(255),
  [CategoryForTaxes] int,
  [CategoryForIncome] int,
  [CategoryForInterest] int,
  [CategoryForRepairs] int,
  [CategoryForMaintenance] int,
  [CategoryForManagement] int
);

CREATE TABLE [RentUnits] (
  [Id] int PRIMARY KEY,
  [Building] int NOT NULL,
  [Name] nvarchar(255) NOT NULL,
  [Renter] nvarchar(255),
  [Note] nvarchar(255)
);

CREATE TABLE [Categories] (
  [Id] int PRIMARY KEY,
  [ParentId] int,
  [Name] nvarchar(80) NOT NULL,
  [Description] nvarchar(255),
  [Type] int NOT NULL,
  [Color] nchar(10),
  [Budget] money,
  [Balance] money,
  [Frequency] int,
  [TaxRefNum] int
);

CREATE TABLE [Transactions] (
  [Id] bigint PRIMARY KEY,
  [Account] int NOT NULL,
  [Date] datetime NOT NULL,
  [Status] int,
  [Payee] int,
  [OriginalPayee] nvarchar(255),
  [Category] int,
  [Memo] nvarchar(255),
  [Number] nchar(10),
  [ReconciledDate] datetime,
  [BudgetBalanceDate] datetime,
  [Transfer] bigint,
  [FITID] nchar(40),
  [Flags] int NOT NULL,
  [Amount] money NOT NULL,
  [SalesTax] money,
  [TransferSplit] int,
  [MergeDate] datetime
);

CREATE TABLE [Splits] (
  [Transaction] bigint NOT NULL,
  [Id] int NOT NULL,
  [Category] int,
  [Payee] int,
  [Amount] money NOT NULL,
  [Transfer] bigint,
  [Memo] nvarchar(255),
  [Flags] int,
  [BudgetBalanceDate] datetime
);

CREATE TABLE [Investments] (
  [Id] bigint PRIMARY KEY,
  [Security] int NOT NULL,
  [UnitPrice] money NOT NULL,
  [Units] money,
  [Commission] money,
  [MarkUpDown] money,
  [Taxes] money,
  [Fees] money,
  [Load] money,
  [InvestmentType] int NOT NULL,
  [TradeType] int,
  [TaxExempt] bit,
  [Withholding] money
);

CREATE TABLE [StockSplits] (
  [Id] bigint PRIMARY KEY,
  [Date] datetime NOT NULL,
  [Security] int NOT NULL,
  [Numerator] money NOT NULL,
  [Denominator] money NOT NULL
);

CREATE TABLE IF NOT EXISTS [Securities] (
  [Id] int PRIMARY KEY,
  [Name] nvarchar(80) NOT NULL,
  [Symbol] nchar(20) NOT NULL,
  [Price] money,
  [LastPrice] money,
  [CUSPID] nchar(20),
  [SECURITYTYPE] int,
  [TAXABLE] tinyint,
  [PriceDate] datetime
);

CREATE TABLE [AccountAliases] (
  [Id] int PRIMARY KEY,
  [Pattern] nvarchar(255) NOT NULL,
  [Flags] int NOT NULL,
  [AccountId] nchar(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS [TransactionExtras] (
  [Id] int PRIMARY KEY,
  [Transaction] bigint NOT NULL,
  [TaxYear] int NOT NULL,
  [TaxDate] datetime
);

CREATE TABLE IF NOT EXISTS [Events] (
  [Id] int PRIMARY KEY,
  [Name] nvarchar(255) NOT NULL,
  [Category] int,
  [Begin] datetime NOT NULL,
  [End] datetime NOT NULL,
  [People] nvarchar(255) NOT NULL,
  [Memo] nvarchar(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS [Currencies] (
  [Id] int PRIMARY KEY,
  [Symbol] nchar(20) NOT NULL,
  [Name] nvarchar(80) NOT NULL,
  [Ratio] money,
  [LastRatio] money,
  [CultureCode] nvarchar(80)
);
''';

  /// SQL prefix for DELETE operations.
  static const String sqlDeleteFromPrefix = 'DELETE FROM ';

  /// SQL prefix for INSERT operations.
  static const String sqlInsertIntoPrefix = 'INSERT INTO ';

  /// SQL prefix for UPDATE operations.
  static const String sqlUpdatePrefix = 'UPDATE ';

  /// SQL clause prefix for WHERE conditions.
  static const String sqlWherePrefix = ' WHERE ';

  /// SQL clause prefix for SET assignments.
  static const String sqlSetPrefix = ' SET ';

  /// SQL clause prefix for VALUES payloads.
  static const String sqlValuesPrefix = ' VALUES ';

  /// SQL statement terminator.
  static const String sqlStatementTerminator = ';';

  /// Placeholder token for SQL table replacement.
  static const String sqlPlaceholderTable = '{table}';

  /// Placeholder token for SQL where-clause replacement.
  static const String sqlPlaceholderWhere = '{where}';

  /// Placeholder token for SQL columns replacement.
  static const String sqlPlaceholderColumns = '{columns}';

  /// Placeholder token for SQL values replacement.
  static const String sqlPlaceholderValues = '{values}';

  /// Placeholder token for SQL set-clause replacement.
  static const String sqlPlaceholderSet = '{set}';

  /// SQL template for delete statements.
  static const String sqlDeleteTemplate = 'DELETE FROM {table} WHERE {where};';

  /// SQL template for insert statements.
  static const String sqlInsertTemplate = 'INSERT INTO {table} ({columns}) VALUES ({values})';

  /// SQL template for update statements.
  static const String sqlUpdateTemplate = 'UPDATE {table} SET {set} WHERE {where};';

  /// SQL query used to list table metadata entries.
  static const String sqlSelectTableNames = "SELECT name FROM sqlite_master WHERE type='table'";

  /// SQL query used to detect a table by its name.
  static const String sqlSelectTableNameByName = "SELECT name FROM sqlite_master WHERE type='table' AND name=?";

  /// Generic column name key for table metadata results.
  static const String columnName = 'name';

  /// SQL query prefix for selecting all rows from a table.
  static const String sqlSelectAllPrefix = 'SELECT * FROM ';

  /// SQL statement for creating the Events table.
  static const String sqlCreateEventsTable = '''
          CREATE TABLE [Events] (
            [Id] int PRIMARY KEY,
            [Name] nvarchar(255) NOT NULL,
            [Category] int,
            [Begin] datetime NOT NULL,
            [End] datetime NOT NULL,
            [People] nvarchar(255) NOT NULL,
            [Memo] nvarchar(255) NOT NULL
          );''';
}
