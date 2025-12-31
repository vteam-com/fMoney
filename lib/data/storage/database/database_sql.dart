import 'dart:io';
import 'dart:typed_data';

import 'package:money/helpers/json_helper.dart';
import 'package:sqlite3/sqlite3.dart';

/// local client SQLite access
class MyDatabaseImplementation {
  late final Database _db;

  void dispose() {
    _db.close();
  }

  void execute(final String command) {
    _db.execute(command);
  }

  void initDatabase(Database database) {
    database.execute('''
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

''');
    // Add more tables or alter the schema as needed
  }

  /// SQL Delete
  void itemDelete(final String tableName, final String whereClause) {
    _db.execute('DELETE FROM $tableName WHERE $whereClause;');
  }

  /// SQL Insert
  void itemInsert(final String tableName, final MyJson data) {
    final String columnNames = data.keys.map((final String key) => '"$key"').join(', ');
    final String columnValues = data.values.map((final dynamic value) => encodeValueWrapStringTypes(value)).join(', ');
    _db.execute('INSERT INTO $tableName ($columnNames) VALUES ($columnValues)');
  }

  /// SQL Update
  void itemUpdate(
    final String tableName,
    final MyJson jsonMap,
    final String whereClause,
  ) {
    final List<String> setStatements = jsonMap.keys
        .map(
          (String key) => '"$key" = ${encodeValueWrapStringTypes(jsonMap[key])}',
        )
        .toList();

    final String fieldNamesAndValues = setStatements.join(', ');
    _db.execute(
      'UPDATE $tableName SET $fieldNamesAndValues WHERE $whereClause;',
    );
  }

  Future<void> load(final String fileToOpen, final Uint8List fileBytes) async {
    if (File(fileToOpen).existsSync()) {
      _db = sqlite3.open(fileToOpen);
    } else {
      _db = sqlite3.open(fileToOpen);
      initDatabase(_db);
      // // commit to disk
      // _db.dispose();
      //
      // // open again
      // _db = sqlite3.open(fileToOpen);
    }
  }

  Future<List<MyJson>> select(final String query) async {
    return _db.select(query);
  }

  Future<bool> tableExists(String tableName) async {
    final ResultSet result = _db.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      <Object?>[tableName],
    );
    return result.isNotEmpty;
  }
}
