// Imports
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:money/data/storages/database_storage.dart';
import 'package:money/helpers/file_systems_service.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:money/widgets/widgets_domain/data_access_model.dart';
import 'package:money/widgets/widgets_domain/data_source_model.dart';

/// Represents money data io.
class MoneyDataIO {
  /// Loads data from file path based on file extension.
  Future<bool> loadFromPath(final Data data, final DataSource dateSource) async {
    try {
      final String fileExtension = MyFileSystems.getFileExtension(
        dateSource.filePath,
      );
      switch (fileExtension.toLowerCase()) {
        // Sqlite
        case SharedStrings.fileExtensionMmdb:
          // Load from SQLite
          if (await loadFromSql(
            data,
            filePath: dateSource.filePath,
            fileBytes: dateSource.fileBytes,
          )) {
            DataAccess.addToMRU(dateSource.filePath);
          }
        case SharedStrings.fileExtensionMmcsv:
          // Zip CSV files
          await loadFromZippedCsv(data, dateSource.filePath, dateSource.fileBytes);
          DataAccess.addToMRU(dateSource.filePath);

        default:
          SnackBarService.displayWarning(
            autoDismiss: false,
            message: '${SharedStrings.messageUnsupportedFileTypePrefix}$fileExtension',
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

  /// Loads data from SQLite database file.
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
      data.accountAliases.loadFromJson(await _selectAll(db, SharedStrings.tableAccountAliases));
      data.accounts.loadFromJson(await _selectAll(db, SharedStrings.tableAccounts));
      data.aliases.loadFromJson(await _selectAll(db, SharedStrings.tableAliases));
      data.categories.loadFromJson(await _selectAll(db, SharedStrings.tableCategories));
      data.currencies.loadFromJson(await _selectAll(db, SharedStrings.tableCurrencies));
      data.investments.loadFromJson(await _selectAll(db, SharedStrings.tableInvestments));
      data.loanPayments.loadFromJson(await _selectAll(db, SharedStrings.tableLoanPayments));
      data.onlineAccounts.loadFromJson(
        await _selectAll(db, SharedStrings.tableOnlineAccounts),
      );
      data.payees.loadFromJson(await _selectAll(db, SharedStrings.tablePayees));
      data.rentBuildings.loadFromJson(
        await _selectAll(db, SharedStrings.tableRentBuildings),
      );
      data.rentUnits.loadFromJson(await _selectAll(db, SharedStrings.tableRentUnits));
      data.securities.loadFromJson(await _selectAll(db, SharedStrings.tableSecurities));
      data.stockSplits.loadFromJson(await _selectAll(db, SharedStrings.tableStockSplits));

      // Check if the Events table exists before loading it
      if (await db.tableExists(SharedStrings.tableEvents)) {
        data.events.loadFromJson(await _selectAll(db, SharedStrings.tableEvents));
      }

      data.transactions.loadFromJson(await _selectAll(db, SharedStrings.tableTransactions));
      data.transactionExtras.loadFromJson(
        await _selectAll(db, SharedStrings.tableTransactionExtras),
      );
      // Must come after Transactions are loaded
      data.splits.loadFromJson(await _selectAll(db, SharedStrings.tableSplits));

      // Close the database when done
      db.dispose();
      return true;
    }
    return false;
  }

  /// Validates database file path and returns valid path or null.
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
    } catch (_) {
      // next line will handle things
    }
    return null;
  }

  /// Saves data to SQLite database file with completion callback.
  Future<bool> saveToSql(
    final Data data, {
    required final String filePath,
    required final void Function(
      bool _, // success
      String _, //errorMessage
    )
    onSaveCompleted,
  }) async {
    try {
      final MyDatabase db = MyDatabase();
      db.load(filePath, Uint8List(0));

      // Save transaction first
      data.accountAliases.saveSql(db, SharedStrings.tableAccountAliases);
      data.accounts.saveSql(db, SharedStrings.tableAccounts);
      data.aliases.saveSql(db, SharedStrings.tableAliases);
      data.categories.saveSql(db, SharedStrings.tableCategories);
      data.currencies.saveSql(db, SharedStrings.tableCurrencies);
      data.investments.saveSql(db, SharedStrings.tableInvestments);
      data.loanPayments.saveSql(db, SharedStrings.tableLoanPayments);
      data.onlineAccounts.saveSql(db, SharedStrings.tableOnlineAccounts);
      data.payees.saveSql(db, SharedStrings.tablePayees);
      data.rentBuildings.saveSql(db, SharedStrings.tableRentBuildings);
      data.rentUnits.saveSql(db, SharedStrings.tableRentUnits);
      data.securities.saveSql(db, SharedStrings.tableSecurities);
      data.stockSplits.saveSql(db, SharedStrings.tableStockSplits);

      if (!await db.tableExists(SharedStrings.tableEvents)) {
        // Create the Events table if it doesn't exist
        db.execute(SharedSqlStrings.sqlCreateEventsTable);
      }
      data.events.saveSql(db, SharedStrings.tableEvents);

      data.transactions.saveSql(db, SharedStrings.tableTransactions);
      data.transactionExtras.saveSql(db, SharedStrings.tableTransactionExtras);
      data.splits.saveSql(db, SharedStrings.tableSplits);

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

  /// Loads data from zipped CSV archive file.
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

  /// Loads data from archive containing multiple CSV files.
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

  /// Extracts and returns content from a single zip archive file.
  String getZipSingleFileContent(ArchiveFile file) {
    try {
      final List<int> fileBytes = file.content as List<int>;
      String fileContent = utf8.decode(fileBytes, allowMalformed: true);
      // Remove UTF-8 BOM if present
      fileContent = removeUtf8Bom(fileContent);
      return fileContent;
    } catch (_) {
      // logger.e(e.toString());
      return '';
    }
  }

  /// Saves data to CSV format and returns the file path.
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

  /// Creates and returns CSV zip archive as list of integers.
  List<int> getCsvZipAchieveListOfInt(Data data) {
    // Create the ZIP archive
    final Archive archive = Archive();

    // Add files to the archive
    writeEachFiles(data, archive);
    // Encode the archive to a byte array
    final List<int> zipBytes = ZipEncoder().encode(archive);
    return zipBytes;
  }

  /// Writes each data collection as CSV file to the archive.
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

  /// Adds CSV content as file to the archive.
  void addCsvToArchive(
    final Archive archive,
    final String filename,
    final String textContent,
  ) {
    final List<int> bytes = utf8.encode(textContent);
    archive.addFile(ArchiveFile(filename, bytes.length, bytes));
  }
}

Future<List<Map<String, dynamic>>> _selectAll(MyDatabase db, String tableName) async {
  return await db.select('${SharedSqlStrings.sqlSelectAllPrefix}$tableName');
}
