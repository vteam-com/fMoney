// Imports
// The following lines import necessary libraries and packages for the file.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:money/data/accounts.dart';
import 'package:money/data/aliases.dart';
import 'package:money/data/categories.dart';
import 'package:money/data/data_interface.dart';
import 'package:money/data/events.dart';
import 'package:money/data/investments.dart';
import 'package:money/data/loan_payments.dart';
import 'package:money/data/payees.dart';
import 'package:money/data/rent_buildings.dart';
import 'package:money/data/securities.dart';
import 'package:money/data/splits.dart';
import 'package:money/data/stock_splits.dart';
import 'package:money/data/transactions.dart';
import 'package:money/data/transfer.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/file_systems.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/helpers/transaction_types.dart';
import 'package:money/models/account.dart';
import 'package:money/models/account_aliases.dart';
import 'package:money/models/currencies.dart';
import 'package:money/models/money_objects.dart';
import 'package:money/models/online_accounts.dart';
import 'package:money/models/rental_units.dart';
import 'package:money/models/transaction_extras/transaction_extras.dart';
import 'package:money/widgets/data_access.dart';
import 'package:money/widgets/data_source.dart';
import 'package:money/widgets/database.dart';
import 'package:money/widgets/mutation_types.dart';
import 'package:money/widgets/snack_bar.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';

class Data implements DataInterface {
  // private constructor

  /// singleton access
  factory Data() {
    return _instance;
  }

  /// private constructor
  Data._internal() {
    tables = <MoneyObjects<dynamic>>[
      accountAliases, // 1
      aliases, // 3
      categories, // 4
      currencies, // 5
      loanPayments, // 7
      onlineAccounts, // 8
      payees, // 9
      transactionExtras, // 15
      transactions, // 16
      // Keep in this order - must come after Transactions
      splits, // 13
      // Keep in this order
      stockSplits, // 14
      investments, // 6 Must be locate after [stockSplits]
      securities, // 12 Must be locate after [investments]

      accounts, // 2
      // Can be last
      rentBuildings, // 10
      rentUnits, // 11
      events,
    ];

    // Inject data interface to managers
    accounts.data = this as DataInterface;
    aliases.data = this as DataInterface;
    categories.data = this as DataInterface;
    payees.data = this as DataInterface;
    investments.data = this as DataInterface;
    loanPayments.data = this as DataInterface;
    securities.data = this as DataInterface;
    rentBuildings.data = this as DataInterface;
    splits.data = this as DataInterface;
    events.data = this as DataInterface;
    transactions.data = this as DataInterface;

    // Note: Some data managers use dependency injection (accounts, aliases, categories, payees, investments, loanPayments, securities, rentBuildings, splits, events, transactions)
    // while others use the global Data() singleton directly for cross-collection access

    DataAccess.notifyMutationChanged = notifyMutationChanged;
    DataAccess.getCategoryName = categories.getNameFromId;
    DataObject.onMutationChanged = notifyMutationChanged;
    DataObject.getCategoryName = categories.getNameFromId;
    DataObject.getCurrencyRatio = currencies.getRatioFromSymbol;
  }

  late final List<MoneyObjects<dynamic>> tables;

  /// 1 Account Aliases
  AccountAliases accountAliases = AccountAliases();

  /// 2 Accounts
  @override
  Accounts accounts = Accounts();

  /// 3 Aliases of Payees
  @override
  Aliases aliases = Aliases();

  /// 4 Categories of Transactions
  @override
  Categories categories = Categories();

  /// 5 Currencies definitions used in the money files
  Currencies currencies = Currencies();

  /// 16 Events
  @override
  Events events = Events();

  /// 6 Investment transactions
  @override
  Investments investments = Investments();

  /// 7
  @override
  LoanPayments loanPayments = LoanPayments();

  /// 8
  OnlineAccounts onlineAccounts = OnlineAccounts();

  /// 9
  @override
  Payees payees = Payees();

  /// 10
  @override
  RentBuildings rentBuildings = RentBuildings();

  /// 11
  RentUnits rentUnits = RentUnits();

  /// 12
  @override
  Securities securities = Securities();

  /// 13
  @override
  Splits splits = Splits();

  /// 14
  @override
  StockSplits stockSplits = StockSplits();

  /// 15
  TransactionExtras transactionExtras = TransactionExtras();

  /// 16 All Transactions in the Money file
  @override
  Transactions transactions = Transactions();

  /// singleton
  static final Data _instance = Data._internal();

  void checkTransfers() {
    final Set<Transaction> dangling = getDanglingTransfers();
    if (dangling.isNotEmpty) {
      Timer(
        const Duration(milliseconds: 100),
        () => SnackBarService.displayWarning(
          message: '${dangling.length} Dangling transfers have been found',
          title: 'Dangling Transfers',
          autoDismiss: false,
        ),
      );
    }
  }

  void clear() {
    DataAccess.trackMutations.reset();
    clearExistingData();
  }

  void clearExistingData() {
    for (final MoneyObjects<dynamic> moneyObjects in tables) {
      moneyObjects.clear();
    }
  }

  @override
  void clearTransferToAccount(final Transaction t, final Account a) {
    // TODO
    // if (t.isSplit) {
    //   for (MoneySplit s in t.splits) {
    //     if (s.Transfer != null && s.Transfer.Transaction.Account == a) {
    //       ClearTransferToAccount(s.Transfer);
    //       s.ClearTransfer();
    //       s.Category =
    //           s.Amount < 0 ? this.Categories.TransferToDeletedAccount : this.Categories.TransferFromDeletedAccount;
    //       if (string.IsNullOrEmpty(s.Memo)) {
    //         s.Memo = a.Name;
    //       }
    //     }
    //   }
    // }

    // if (t.Transfer != null && t.Transfer.Transaction.Account == a) {
    //   ClearTransferToAccount(t.Transfer);
    //   t.Transfer = null;
    //   if (!t.IsSplit) {
    //     t.Category =
    //         t.Amount < 0 ? this.Categories.TransferToDeletedAccount : this.Categories.TransferFromDeletedAccount;
    //   }
    //   if (string.IsNullOrEmpty(t.Memo)) {
    //     t.Memo = a.Name;
    //   }
    // }
  }

  /// Close data source
  void close() {
    clearExistingData();

    DataAccess.onFileClosed();
    DataAccess.trackMutations.reset();
  }

  void deleteItems(final List<DataObject> itemsToDelete) {
    for (final DataObject item in itemsToDelete) {
      notifyMutationChanged(
        mutation: MutationType.deleted,
        moneyObject: item,
        recalculateBalances: false,
      );
    }
    updateAll();
  }

  Set<Transaction> getDanglingTransfers() {
    final Set<Transaction> dangling = <Transaction>{};
    final List<Account> deletedAccounts = <Account>[];
    transactions.checkTransfers(dangling, deletedAccounts);
    for (final Account a in deletedAccounts) {
      accounts.removeAccount(a);
    }
    return dangling;
  }

  DateTime? getLastDateTimeModified(final String fullPathToFile) {
    final File file = File(fullPathToFile);
    return file.lastModifiedSync();
  }

  List<DataObject> getMutatedInstances(final MutationType typeOfMutation) {
    final List<DataObject> mutated = <DataObject>[];
    for (final MoneyObjects<dynamic> listOfInstance in tables) {
      mutated.addAll(listOfInstance.getMutatedObjects(typeOfMutation));
    }
    return mutated;
  }

  List<MutationGroup> getMutationGroups(final MutationType typeOfMutation) {
    final List<MutationGroup> allMutationGroups = <MutationGroup>[];

    for (final MoneyObjects<dynamic> moneyObjects in tables) {
      final List<DataObject> mutatedInstances = moneyObjects.getMutatedObjects(
        typeOfMutation,
      );
      if (mutatedInstances.isNotEmpty) {
        final MutationGroup mutationGroup = MutationGroup();
        mutationGroup.title = moneyObjects.collectionName;
        mutationGroup.whatWasMutated = moneyObjects.whatWasMutated(
          mutatedInstances,
        );
        allMutationGroups.add(mutationGroup);
      }
    }
    return allMutationGroups;
  }

  AmountModel getNetWorth() {
    final double sum = accounts.getSumOfAccountBalances();
    return AmountModel(amount: sum);
  }

  Transaction? getOrCreateRelatedTransaction({
    required Transaction transactionSource,
    required Account destinationAccount,
  }) {
    if (transactionSource.fieldAccountId.value == destinationAccount.uniqueId) {
      logger.e('Cannot transfer to same account');
      return null;
    }

    final double destinationAmount = transactionSource.fieldAmount.value.asDouble() * -1;

    Transaction? relatedTransaction;
    try {
      relatedTransaction = this.transactions.findExistingTransaction(
        accountId: destinationAccount.uniqueId,
        dateRange: DateRange(
          min: transactionSource.fieldDateTime.value!.startOfDay,
          max: transactionSource.fieldDateTime.value!.endOfDay,
        ),
        amount: destinationAmount,
      );
    } catch (error) {
      // something went wrong, assume no match found
    }

    if (relatedTransaction == null) {
      relatedTransaction = Transaction(
        accountId: destinationAccount.uniqueId,
        date: transactionSource.fieldDateTime.value,
      );

      // flip the sign on the amount
      relatedTransaction.fieldAmount.value.setAmount(destinationAmount);
      relatedTransaction.fieldCategoryId.value = transactionSource.fieldCategoryId.value;
      relatedTransaction.fieldFitid.value = transactionSource.fieldFitid.value;
      relatedTransaction.fieldNumber.value = transactionSource.fieldNumber.value;
      relatedTransaction.fieldMemo.value = transactionSource.fieldMemo.value;
      //u.Status = t.Status; no !!!
    }

    // Investment? i = relatedTransaction.investmentInstance;
    // if (i != null) {
    //   Investment j = transactionSource.getOrCreateInvestment();
    //   j.units = i.units;
    //   j.unitPrice = i.unitPrice;
    //   j.security = i.security;
    //   //   switch (i.Type) {
    //   //     case InvestmentType.Add:
    //   //       j.Type = InvestmentType.Remove;
    //   //       break;
    //   //     case InvestmentType.Remove:
    //   //       j.Type = InvestmentType.Add;
    //   //       break;
    //   //     case InvestmentType.None: // assume it's a remove
    //   //       i.Type = InvestmentType.Remove;
    //   //       j.Type = InvestmentType.Add;
    //   //       break;
    //   //     case InvestmentType.Buy:
    //   //     case InvestmentType.Sell:
    //   //       throw new MoneyException("Transfer must be of type 'Add' or 'Remove'.");
    //   //   }
    //   //   u.Investment = j;
    // }

    return relatedTransaction;
  }

  /// Automated detection of what type of storage to load the data from
  Future<bool> loadFromPath(final DataSource dateSource) async {
    try {
      final String fileExtension = MyFileSystems.getFileExtension(
        dateSource.filePath,
      );
      switch (fileExtension.toLowerCase()) {
        // Sqlite
        case '.mmdb':
          // Load from SQLite
          if (await loadFromSql(
            filePath: dateSource.filePath,
            fileBytes: dateSource.fileBytes,
          )) {
            DataAccess.addToMRU(dateSource.filePath);
          }
        case '.mmcsv':
          // Zip CSV files
          await loadFromZippedCsv(dateSource.filePath, dateSource.fileBytes);
          DataAccess.addToMRU(dateSource.filePath);

        default:
          SnackBarService.displayWarning(
            autoDismiss: false,
            message: 'Unsupported file type $fileExtension',
          );
          return false;
      }
    } catch (e) {
      logger.e(e.toString());
      SnackBarService.displayError(autoDismiss: false, message: e.toString());
      return false;
    }

    // All individual table were loaded, now let the cross reference money object create linked to other tables
    recalculateBalances();

    // Notify that loading is completed
    return true;
  }

  void verifyApplyTransfer({
    required final Transaction transaction,
    required final Account? relatedAccount,
  }) {
    if (relatedAccount == null) {
      return; // nothing to check
    }
    if (transaction.instanceOfTransfer != null) {
      // this was already a transfer, lets see if the destination account has changed
      if (transaction.instanceOfTransfer?.receiverAccount?.uniqueId == relatedAccount.uniqueId) {
        // same account do noting
      } else {
        // use the new account destination
        final Transaction relatedTransaction = transaction.instanceOfTransfer!.relatedTransaction! as Transaction;
        transaction.instanceOfTransfer!.relatedTransaction!.instanceOfAccount = accounts.get(
          relatedAccount.uniqueId,
        );
        relatedTransaction.mutateField(
          'Account',
          relatedAccount.uniqueId,
          false,
        );
      }
    } else {
      makeTransferLinkage(
        transactionSource: transaction,
        destinationAccount: relatedAccount,
      );
    }
  }

  Transaction makeTransferLinkage({
    required Transaction transactionSource,
    required Account destinationAccount,
  }) {
    final Transaction? relatedTransaction = getOrCreateRelatedTransaction(
      transactionSource: transactionSource,
      destinationAccount: destinationAccount,
    );

    if (relatedTransaction != null) {
      final Transfer transfer;

      if (transactionSource.fieldAmount.value.asDouble() < 0) {
        // transfer TO
        transfer = Transfer(
          id: 0,
          source: transactionSource,
          relatedTransaction: relatedTransaction,
          isOrphan: false,
        );
      } else {
        // transfer FROM
        transfer = Transfer(
          id: 0,
          source: relatedTransaction,
          relatedTransaction: transactionSource,
          isOrphan: false,
        );
      }

      // Keep track changes done
      relatedTransaction.stashValueBeforeEditing();

      relatedTransaction.fieldPayee.value = this.categories.transfer.uniqueId;
      relatedTransaction.fieldTransfer.value = transactionSource.fieldId.value;
      relatedTransaction.instanceOfTransfer = transfer;

      if (relatedTransaction.uniqueId == -1) {
        // This is a new related transaction Append and get a new UniqueID
        transactions.appendNewMoneyObject(
          relatedTransaction,
          fireNotification: false,
        );
      } else {
        this.notifyMutationChanged(
          mutation: MutationType.changed,
          moneyObject: relatedTransaction,
          recalculateBalances: false,
        );
      }

      // this needs to happen last since the ID for a new Relation Transaction will be establish in the above
      transactionSource.fieldPayee.value = this.categories.transfer.uniqueId;
      transactionSource.fieldTransfer.value = relatedTransaction.uniqueId;
      transactionSource.instanceOfTransfer = transfer;
    }

    return relatedTransaction!;
  }

  /// let the app know that something has changed
  @override
  void notifyMutationChanged({
    required MutationType mutation,
    required DataObject moneyObject,
    bool recalculateBalances = true,
  }) {
    switch (mutation) {
      case MutationType.inserted:
        moneyObject.mutation = MutationType.inserted;
        DataAccess.trackMutations.increaseNumber(increaseAdded: 1);
      case MutationType.changed:
        // ensure that we only count editing once and discard if this was edited on a new inserted items
        if (moneyObject.mutation == MutationType.none) {
          moneyObject.mutation = MutationType.changed;
          DataAccess.trackMutations.increaseNumber(increaseChanged: 1);
        } else {
          DataAccess.trackMutations.setLastEditToNow();
        }
      case MutationType.deleted:
        if (moneyObject.mutation == MutationType.inserted) {
          // in case the delete item was a recently added item, we need to deduct it from the sum
          DataAccess.trackMutations.increaseNumber(increaseAdded: -1);
        }
        moneyObject.mutation = MutationType.deleted;
        DataAccess.trackMutations.increaseNumber(increaseDeleted: 1);
      default:
        break;
    }

    if (recalculateBalances) {
      updateAll();
    }
  }

  /// When Changes are done we can force a reevaluation of the balances
  void recalculateBalances() {
    for (final MoneyObjects<dynamic> moneyObjects in tables) {
      moneyObjects.onAllDataLoaded();
    }

    // one last thing, Transfer are complex and we try to confirm or clean up any problem found
    checkTransfers();
  }

  @override
  bool removeTransaction(Transaction t) {
    if (t.fieldStatus.value == TransactionStatus.reconciled && t.fieldAmount.value.asDouble() != 0) {
      throw Exception('Cannot removed reconciled transaction');
    }
    // TODO
    // this.removeTransfer(t);

    // this.transactions.RemoveTransaction(t);
    // if (t.Unaccepted) {
    //   if (t.Account != null) {
    //     t.Account.Unaccepted--;
    //   }
    //   if (t.Payee != null) {
    //     t.Payee.UnacceptedTransactions--;
    //   }
    // }

    // if (t.Category == null && t.Transfer == null && !t.IsSplit) {
    //   if (t.Payee != null) {
    //     t.Payee.UnCategorizedTransactions--;
    //   }
    // }

    // this.Rebalance(t);
    return true;
  }

  /// ReBalance all objects values
  /// and Rebuild the UI
  @override
  void updateAll() {
    recalculateBalances();
    DataAccess.onDataChanged();
  }

  Future<String?> validateDataBasePathIsValidAndExist(
    final String? filePath,
    final Uint8List fileBytes,
  ) async {
    try {
      if (filePath != null) {
        if (fileBytes.isNotEmpty) {
          return filePath;
        }
        if (File(filePath).existsSync()) {
          return filePath;
        }
      }
    } catch (e) {
      // next line will handle things
    }
    return null;
  }

  // --- SQL Extension Methods ---

  Future<bool> loadFromSql({
    required final String filePath,
    required final Uint8List fileBytes,
  }) async {
    // Load from SQLite
    final String? pathToDatabaseFile = await validateDataBasePathIsValidAndExist(filePath, fileBytes);

    if (pathToDatabaseFile != null || fileBytes.isNotEmpty) {
      // Open or create the database
      final MyDatabase db = MyDatabase();

      await db.load(filePath, fileBytes);
      // Load
      accountAliases.loadFromJson(
        await db.select('SELECT * FROM AccountAliases'),
      );
      accounts.loadFromJson(await db.select('SELECT * FROM Accounts'));
      aliases.loadFromJson(await db.select('SELECT * FROM Aliases'));
      categories.loadFromJson(await db.select('SELECT * FROM Categories'));
      currencies.loadFromJson(await db.select('SELECT * FROM Currencies'));
      investments.loadFromJson(await db.select('SELECT * FROM Investments'));
      loanPayments.loadFromJson(await db.select('SELECT * FROM LoanPayments'));
      onlineAccounts.loadFromJson(
        await db.select('SELECT * FROM OnlineAccounts'),
      );
      payees.loadFromJson(await db.select('SELECT * FROM Payees'));
      rentBuildings.loadFromJson(
        await db.select('SELECT * FROM RentBuildings'),
      );
      rentUnits.loadFromJson(await db.select('SELECT * FROM RentUnits'));
      securities.loadFromJson(await db.select('SELECT * FROM Securities'));
      stockSplits.loadFromJson(await db.select('SELECT * FROM StockSplits'));

      // Check if the Events table exists before loading it
      if (await db.tableExists('Events')) {
        events.loadFromJson(await db.select('SELECT * FROM Events'));
      }

      transactions.loadFromJson(await db.select('SELECT * FROM Transactions'));
      transactionExtras.loadFromJson(
        await db.select('SELECT * FROM TransactionExtras'),
      );
      // Must come after Transactions are loaded
      splits.loadFromJson(await db.select('SELECT * FROM Splits'));

      // Close the database when done
      db.dispose();
      return true;
    }
    return false;
  }

  Future<bool> saveToSql({
    required final String filePath,
    required final void Function(bool success, String errorMessage) onSaveCompleted,
  }) async {
    try {
      final MyDatabase db = MyDatabase();
      db.load(filePath, Uint8List(0));

      // Save transaction first
      accountAliases.saveSql(db, 'AccountAliases');
      accounts.saveSql(db, 'Accounts');
      aliases.saveSql(db, 'Aliases');
      categories.saveSql(db, 'Categories');
      currencies.saveSql(db, 'Currencies');
      investments.saveSql(db, 'Investments');
      loanPayments.saveSql(db, 'LoanPayments');
      onlineAccounts.saveSql(db, 'OnlineAccounts');
      payees.saveSql(db, 'Payees');
      rentBuildings.saveSql(db, 'RentBuildings');
      rentUnits.saveSql(db, 'RentUnits');
      securities.saveSql(db, 'Securities');
      stockSplits.saveSql(db, 'StockSplits');

      if (!await db.tableExists('Events')) {
        // Create the Events table if it doesn't exist
        db.execute('''
          CREATE TABLE [Events] (
            [Id] int PRIMARY KEY,
            [Name] nvarchar(255) NOT NULL,
            [Category] int,
            [Begin] datetime NOT NULL,
            [End] datetime NOT NULL,
            [People] nvarchar(255) NOT NULL,
            [Memo] nvarchar(255) NOT NULL
          );''');
      }
      events.saveSql(db, 'Events');

      transactions.saveSql(db, 'Transactions');
      transactionExtras.saveSql(db, 'TransactionExtras');
      splits.saveSql(db, 'Splits');

      db.dispose();
    } catch (e) {
      onSaveCompleted(false, e.toString());
      return false;
    }

    onSaveCompleted(true, '');
    return true;
  }

  // --- CSV Extension Methods ---

  static const String mainFileName = 'mymoney.mmcsv';
  static const String subFolderName = 'mymoney_csv_files';

  Future<void> loadFromZippedCsv(
    String filePathToLoad,
    final Uint8List fileBytes,
  ) async {
    // Decode the ZIP file
    late Archive archive;
    if (fileBytes.isNotEmpty) {
      archive = ZipDecoder().decodeBytes(fileBytes);
    } else {
      final File file = File(filePathToLoad);
      final List<int> bytes = await file.readAsBytes();
      archive = ZipDecoder().decodeBytes(bytes);
    }
    loadFromArchive(archive);
  }

  void loadFromArchive(final Archive archive) {
    // Extract the files and read the content
    for (ArchiveFile file in archive) {
      if (file.isFile) {
        final String fileContent = getZipSingleFileContent(file);

        final String fileNameInLowercase = MyFileSystems.getFileName(file.name).toLowerCase();

        switch (fileNameInLowercase) {
          case 'account_aliases.csv':
            accountAliases.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'accounts.csv':
            accounts.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'aliases.csv':
            aliases.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'categories.csv':
            categories.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'investments.csv':
            investments.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'loan_payments.csv':
            loanPayments.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'online_accounts.csv':
            onlineAccounts.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'payees.csv':
            payees.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'rent_buildings.csv':
            rentBuildings.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'rent_units.csv':
            rentUnits.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'securities.csv':
            securities.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'splits.csv':
            splits.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'stock_splits.csv':
            stockSplits.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'transactions.csv':
            transactions.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'transaction_extras.csv':
            transactionExtras.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'events.csv':
            events.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
        }
      }
    }
  }

  String getZipSingleFileContent(ArchiveFile file) {
    try {
      final List<int> fileBytes = file.content as List<int>;
      String fileContent = utf8.decode(fileBytes, allowMalformed: true);
      // Remove UTF-8 BOM if present
      fileContent = removeUtf8Bom(fileContent);
      return fileContent;
    } catch (e) {
      logger.e(e.toString());
      return '';
    }
  }

  Future<String> saveToCsv() async {
    final String destinationFolder = await DataAccess.generateNextFolderToSaveTo();
    if (destinationFolder.isEmpty) {
      throw Exception('No container folder give for saving');
    }

    // Define the path to the ZIP file
    final String zipFileName = MyFileSystems.append(
      destinationFolder,
      mainFileName,
    );
    final File zipFile = File(zipFileName);

    // Create the ZIP archive
    final List<int> zipBytes = getCsvZipAchieveListOfInt();
    // Write the ZIP file
    await zipFile.writeAsBytes(zipBytes);
    return zipFileName;
  }

  List<int> getCsvZipAchieveListOfInt() {
    // Create the ZIP archive
    final Archive archive = Archive();

    // Add files to the archive
    writeEachFiles(archive);
    // Encode the archive to a byte array
    final List<int> zipBytes = ZipEncoder().encode(archive);
    return zipBytes;
  }

  void writeEachFiles(Archive archive) {
    addCsvToArchive(archive, 'account_aliases.csv', accountAliases.toCSV());
    addCsvToArchive(archive, 'accounts.csv', accounts.toCSV());
    addCsvToArchive(archive, 'aliases.csv', aliases.toCSV());
    addCsvToArchive(archive, 'categories.csv', categories.toCSV());
    addCsvToArchive(archive, 'currencies.csv', currencies.toCSV());
    addCsvToArchive(archive, 'investments.csv', investments.toCSV());
    addCsvToArchive(archive, 'loan_payments.csv', loanPayments.toCSV());
    addCsvToArchive(archive, 'online_accounts.csv', onlineAccounts.toCSV());
    addCsvToArchive(archive, 'payees.csv', payees.toCSV());
    addCsvToArchive(archive, 'securities.csv', securities.toCSV());
    addCsvToArchive(archive, 'splits.csv', splits.toCSV());
    addCsvToArchive(archive, 'stock_splits.csv', stockSplits.toCSV());
    addCsvToArchive(archive, 'rent_units.csv', rentUnits.toCSV());
    addCsvToArchive(archive, 'rent_buildings.csv', rentBuildings.toCSV());
    addCsvToArchive(archive, 'events.csv', events.toCSV());
    addCsvToArchive(
      archive,
      'transaction_extras.csv',
      transactionExtras.toCSV(),
    );
    addCsvToArchive(archive, 'transactions.csv', transactions.toCSV());
  }

  void addCsvToArchive(
    final Archive archive,
    final String filename,
    final String textContent,
  ) {
    final List<int> bytes = utf8.encode(textContent);
    archive.addFile(ArchiveFile(filename, bytes.length, bytes));
  }
}
