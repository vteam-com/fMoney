// Imports
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:money/data/models/data_access_model.dart';
import 'package:money/data/models/data_source_model.dart';
import 'package:money/data/storages/database_storage.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/file_systems_service.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';

/// Represents money data io.
class MoneyDataIO {
  /// Loads data from file path based on file extension.
  Future<bool> loadFromPath(Data data, DataSource dateSource) async {
    try {
      final String fileExtension = MyFileSystems.getFileExtension(
        dateSource.filePath,
      );
      switch (fileExtension.toLowerCase()) {
        // Sqlite
        case SharedStrings.fileExtensionMmdb:
          // Load from SQLite
          if (!await loadFromSql(
            data,
            filePath: dateSource.filePath,
            fileBytes: dateSource.fileBytes,
          )) {
            // the file is missing or unreadable: report it instead of opening empty data
            SnackBarService.displayWarning(
              autoDismiss: false,
              message: AppL10n.tr(
                AppTranslationKeys.unableToOpenFile,
                params: <String, String>{'fileName': dateSource.filePath},
              ),
            );
            return false;
          }
          DataAccess.addToMRU(dateSource.filePath);
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
    Data data, {
    required String filePath,
    required Uint8List fileBytes,
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
    String? filePath,
    Uint8List fileBytes,
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
    Data data, {
    required String filePath,
    required void Function(
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
    Data data,
    String filePathToLoad,
    Uint8List fileBytes,
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
  ///
  /// Files are loaded in [_csvTables] order (not archive order) so that splits
  /// are attached to transactions that are already loaded.
  void loadFromArchive(Data data, Archive archive) {
    final Map<String, String> contentByFileName = <String, String>{};
    for (final ArchiveFile file in archive) {
      if (file.isFile) {
        contentByFileName[MyFileSystems.getFileName(file.name).toLowerCase()] = getZipSingleFileContent(file);
      }
    }

    for (final (String fileName, MoneyObjects<dynamic> collection) in _csvTables(data)) {
      final String? fileContent = contentByFileName[fileName];
      if (fileContent != null) {
        collection.loadFromJson(convertFromRawCsvTextToListOfJSonObject(fileContent));
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
  Future<String> saveToCsv(Data data) async {
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
    for (final (String fileName, MoneyObjects<dynamic> collection) in _csvTables(data)) {
      addCsvToArchive(archive, fileName, collection.toCSV());
    }
  }

  /// Adds CSV content as file to the archive.
  void addCsvToArchive(
    Archive archive,
    String filename,
    String textContent,
  ) {
    final List<int> bytes = utf8.encode(textContent);
    archive.addFile(ArchiveFile(filename, bytes.length, bytes));
  }
}

/// Returns each CSV archive file name paired with its collection, in load order.
///
/// Mirrors [MoneyDataIO.loadFromSql]: splits must come after transactions.
List<(String, MoneyObjects<dynamic>)> _csvTables(Data data) {
  return <(String, MoneyObjects<dynamic>)>[
    ('account_aliases.csv', data.accountAliases),
    ('accounts.csv', data.accounts),
    ('aliases.csv', data.aliases),
    ('categories.csv', data.categories),
    ('currencies.csv', data.currencies),
    ('investments.csv', data.investments),
    ('loan_payments.csv', data.loanPayments),
    ('online_accounts.csv', data.onlineAccounts),
    ('payees.csv', data.payees),
    ('rent_buildings.csv', data.rentBuildings),
    ('rent_units.csv', data.rentUnits),
    ('securities.csv', data.securities),
    ('stock_splits.csv', data.stockSplits),
    ('events.csv', data.events),
    ('transactions.csv', data.transactions),
    ('transaction_extras.csv', data.transactionExtras),
    ('splits.csv', data.splits),
  ];
}

Future<List<Map<String, dynamic>>> _selectAll(MyDatabase db, String tableName) async {
  return await db.select('${SharedSqlStrings.sqlSelectAllPrefix}$tableName');
}
