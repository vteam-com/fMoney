// Imports
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:money/data/collections/data.dart';
import 'package:money/helpers/file_systems.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/io/database.dart';
import 'package:money/widgets/data_access.dart';
import 'package:money/widgets/data_source.dart';
import 'package:money/widgets/snack_bar.dart';

class MoneyDataIO {
  Future<bool> loadFromPath(final Data data, final DataSource dateSource) async {
    try {
      final String fileExtension = MyFileSystems.getFileExtension(
        dateSource.filePath,
      );
      switch (fileExtension.toLowerCase()) {
        // Sqlite
        case '.mmdb':
          // Load from SQLite
          if (await loadFromSql(
            data,
            filePath: dateSource.filePath,
            fileBytes: dateSource.fileBytes,
          )) {
            DataAccess.addToMRU(dateSource.filePath);
          }
        case '.mmcsv':
          // Zip CSV files
          await loadFromZippedCsv(data, dateSource.filePath, dateSource.fileBytes);
          DataAccess.addToMRU(dateSource.filePath);

        default:
          SnackBarService.displayWarning(
            autoDismiss: false,
            message: 'Unsupported file type $fileExtension',
          );
          return false;
      }
    } catch (e) {
      // logger.e(e.toString()); // Logger might need to be imported or removed if not accessible
      SnackBarService.displayError(autoDismiss: false, message: e.toString());
      return false;
    }

    // All individual table were loaded, now let the cross reference money object create linked to other tables
    data.recalculateBalances();

    // Notify that loading is completed
    return true;
  }

  Future<bool> loadFromSql(
    final Data data, {
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
      data.accountAliases.loadFromJson(
        await db.select('SELECT * FROM AccountAliases'),
      );
      data.accounts.loadFromJson(await db.select('SELECT * FROM Accounts'));
      data.aliases.loadFromJson(await db.select('SELECT * FROM Aliases'));
      data.categories.loadFromJson(await db.select('SELECT * FROM Categories'));
      data.currencies.loadFromJson(await db.select('SELECT * FROM Currencies'));
      data.investments.loadFromJson(await db.select('SELECT * FROM Investments'));
      data.loanPayments.loadFromJson(await db.select('SELECT * FROM LoanPayments'));
      data.onlineAccounts.loadFromJson(
        await db.select('SELECT * FROM OnlineAccounts'),
      );
      data.payees.loadFromJson(await db.select('SELECT * FROM Payees'));
      data.rentBuildings.loadFromJson(
        await db.select('SELECT * FROM RentBuildings'),
      );
      data.rentUnits.loadFromJson(await db.select('SELECT * FROM RentUnits'));
      data.securities.loadFromJson(await db.select('SELECT * FROM Securities'));
      data.stockSplits.loadFromJson(await db.select('SELECT * FROM StockSplits'));

      // Check if the Events table exists before loading it
      if (await db.tableExists('Events')) {
        data.events.loadFromJson(await db.select('SELECT * FROM Events'));
      }

      data.transactions.loadFromJson(await db.select('SELECT * FROM Transactions'));
      data.transactionExtras.loadFromJson(
        await db.select('SELECT * FROM TransactionExtras'),
      );
      // Must come after Transactions are loaded
      data.splits.loadFromJson(await db.select('SELECT * FROM Splits'));

      // Close the database when done
      db.dispose();
      return true;
    }
    return false;
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

  Future<bool> saveToSql(
    final Data data, {
    required final String filePath,
    required final void Function(bool success, String errorMessage) onSaveCompleted,
  }) async {
    try {
      final MyDatabase db = MyDatabase();
      db.load(filePath, Uint8List(0));

      // Save transaction first
      data.accountAliases.saveSql(db, 'AccountAliases');
      data.accounts.saveSql(db, 'Accounts');
      data.aliases.saveSql(db, 'Aliases');
      data.categories.saveSql(db, 'Categories');
      data.currencies.saveSql(db, 'Currencies');
      data.investments.saveSql(db, 'Investments');
      data.loanPayments.saveSql(db, 'LoanPayments');
      data.onlineAccounts.saveSql(db, 'OnlineAccounts');
      data.payees.saveSql(db, 'Payees');
      data.rentBuildings.saveSql(db, 'RentBuildings');
      data.rentUnits.saveSql(db, 'RentUnits');
      data.securities.saveSql(db, 'Securities');
      data.stockSplits.saveSql(db, 'StockSplits');

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
      data.events.saveSql(db, 'Events');

      data.transactions.saveSql(db, 'Transactions');
      data.transactionExtras.saveSql(db, 'TransactionExtras');
      data.splits.saveSql(db, 'Splits');

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

  Future<void> loadFromZippedCsv(
    final Data data,
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
    loadFromArchive(data, archive);
  }

  void loadFromArchive(final Data data, final Archive archive) {
    // Extract the files and read the content
    for (ArchiveFile file in archive) {
      if (file.isFile) {
        final String fileContent = getZipSingleFileContent(file);

        final String fileNameInLowercase = MyFileSystems.getFileName(file.name).toLowerCase();

        switch (fileNameInLowercase) {
          case 'account_aliases.csv':
            data.accountAliases.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'accounts.csv':
            data.accounts.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'aliases.csv':
            data.aliases.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'categories.csv':
            data.categories.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'investments.csv':
            data.investments.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'loan_payments.csv':
            data.loanPayments.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'online_accounts.csv':
            data.onlineAccounts.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'payees.csv':
            data.payees.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'rent_buildings.csv':
            data.rentBuildings.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'rent_units.csv':
            data.rentUnits.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'securities.csv':
            data.securities.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'splits.csv':
            data.splits.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'stock_splits.csv':
            data.stockSplits.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'transaction_extras.csv':
            data.transactionExtras.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'transactions.csv':
            data.transactions.loadFromJson(
              convertFromRawCsvTextToListOfJSonObject(fileContent),
            );
          case 'events.csv':
            data.events.loadFromJson(
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
      // logger.e(e.toString());
      return '';
    }
  }

  Future<String> saveToCsv(final Data data) async {
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
    final List<int> zipBytes = getCsvZipAchieveListOfInt(data);
    // Write the ZIP file
    await zipFile.writeAsBytes(zipBytes);
    return zipFileName;
  }

  List<int> getCsvZipAchieveListOfInt(Data data) {
    // Create the ZIP archive
    final Archive archive = Archive();

    // Add files to the archive
    writeEachFiles(data, archive);
    // Encode the archive to a byte array
    final List<int> zipBytes = ZipEncoder().encode(archive);
    return zipBytes;
  }

  void writeEachFiles(Data data, Archive archive) {
    addCsvToArchive(archive, 'account_aliases.csv', data.accountAliases.toCSV());
    addCsvToArchive(archive, 'accounts.csv', data.accounts.toCSV());
    addCsvToArchive(archive, 'aliases.csv', data.aliases.toCSV());
    addCsvToArchive(archive, 'categories.csv', data.categories.toCSV());
    addCsvToArchive(archive, 'currencies.csv', data.currencies.toCSV());
    addCsvToArchive(archive, 'investments.csv', data.investments.toCSV());
    addCsvToArchive(archive, 'loan_payments.csv', data.loanPayments.toCSV());
    addCsvToArchive(archive, 'online_accounts.csv', data.onlineAccounts.toCSV());
    addCsvToArchive(archive, 'payees.csv', data.payees.toCSV());
    addCsvToArchive(archive, 'securities.csv', data.securities.toCSV());
    addCsvToArchive(archive, 'splits.csv', data.splits.toCSV());
    addCsvToArchive(archive, 'stock_splits.csv', data.stockSplits.toCSV());
    addCsvToArchive(archive, 'rent_units.csv', data.rentUnits.toCSV());
    addCsvToArchive(archive, 'rent_buildings.csv', data.rentBuildings.toCSV());
    addCsvToArchive(archive, 'events.csv', data.events.toCSV());
    addCsvToArchive(
      archive,
      'transaction_extras.csv',
      data.transactionExtras.toCSV(),
    );
    addCsvToArchive(archive, 'transactions.csv', data.transactions.toCSV());
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
