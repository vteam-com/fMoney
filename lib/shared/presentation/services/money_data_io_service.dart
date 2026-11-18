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
  /// Suffix of the copy kept of a file before it is overwritten.
  static const String _backupFileSuffix = '.bak';

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
      // never leave a half-loaded file in memory, where it could be saved over the real one
      data.clearExistingData();
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

      try {
        await db.load(filePath, fileBytes);
        // Tables in dependency order (splits after transactions); a table missing from an older file loads empty
        for (final _Table table in _tables(data)) {
          if (await db.tableExists(table.tableName)) {
            table.collection.loadFromJson(await _selectAll(db, table.tableName));
          }
        }
      } finally {
        // Close the database when done
        db.dispose();
      }
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

  /// Saves the pending changes into the SQLite file at [filePath] with completion callback.
  ///
  /// The previous file is kept as `<file>.bak`, and all changes are written in one transaction:
  /// on any error nothing is written and every pending change stays pending.
  Future<bool> saveToSql(
    Data data, {
    required String filePath,
    required void Function(
      bool _, // success
      String _, //errorMessage
    )
    onSaveCompleted,
  }) async {
    return _saveInTransaction(
      data,
      filePath: filePath,
      onSaveCompleted: onSaveCompleted,
      writeTable: (MyDatabase db, String tableName, MoneyObjects<dynamic> collection) =>
          collection.saveSql(db, tableName),
    );
  }

  /// Writes every live object into a brand-new SQLite file at [filePath] (used by Save As).
  ///
  /// Pending changes stay pending: call [markAllSaved] once the file reached its destination.
  /// Returns null on success, else the error message.
  Future<String?> writeAllToNewSqlFile(Data data, {required String filePath}) async {
    final File file = File(filePath);
    if (file.existsSync()) {
      file.deleteSync();
    }
    String? errorMessage;
    await _saveInTransaction(
      data,
      filePath: filePath,
      commitState: false,
      onSaveCompleted: (bool success, String message) => errorMessage = success ? null : message,
      writeTable: (MyDatabase db, String tableName, MoneyObjects<dynamic> collection) =>
          collection.saveAllSql(db, tableName),
    );
    return errorMessage;
  }

  /// Marks every collection as matching the saved file (see [MoneyObjects.onSaveCommitted]).
  void markAllSaved(Data data) {
    for (final _Table table in _tables(data)) {
      table.collection.onSaveCommitted();
    }
  }

  /// Runs [writeTable] for every table inside one SQL transaction, then (if [commitState]) marks the data as saved.
  Future<bool> _saveInTransaction(
    Data data, {
    required String filePath,
    required void Function(bool success, String errorMessage) onSaveCompleted,
    required void Function(MyDatabase db, String tableName, MoneyObjects<dynamic> collection) writeTable,
    bool commitState = true,
  }) async {
    final bool isExistingFile = File(filePath).existsSync();
    final MyDatabase db = MyDatabase();
    try {
      await db.load(filePath, Uint8List(0));
      if (isExistingFile) {
        _keepBackupOf(filePath);
      }
      db.execute(SharedSqlStrings.sqlBeginTransaction);
      try {
        if (!await db.tableExists(SharedStrings.tableEvents)) {
          // Create the Events table if it doesn't exist
          db.execute(SharedSqlStrings.sqlCreateEventsTable);
        }
        for (final _Table table in _tables(data)) {
          writeTable(db, table.tableName, table.collection);
        }
        db.execute(SharedSqlStrings.sqlCommitTransaction);
      } catch (_) {
        db.execute(SharedSqlStrings.sqlRollbackTransaction);
        rethrow;
      }
    } catch (e) {
      onSaveCompleted(false, e.toString());
      return false;
    } finally {
      db.dispose();
    }

    if (commitState) {
      markAllSaved(data);
    }
    onSaveCompleted(true, '');
    return true;
  }

  /// Copies [filePath] to `<file>.bak` (replacing an older backup) before it gets overwritten.
  void _keepBackupOf(String filePath) {
    final File file = File(filePath);
    if (file.existsSync()) {
      file.copySync('$filePath$_backupFileSuffix');
    }
  }

  // --- CSV Extension Methods ---

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
  /// Files are loaded in [_tables] order (not archive order) so that splits
  /// are attached to transactions that are already loaded.
  void loadFromArchive(Data data, Archive archive) {
    final Map<String, String> contentByFileName = <String, String>{};
    for (final ArchiveFile file in archive) {
      if (file.isFile) {
        contentByFileName[MyFileSystems.getFileName(file.name).toLowerCase()] = getZipSingleFileContent(file);
      }
    }

    for (final _Table table in _tables(data)) {
      final String? fileContent = contentByFileName[table.csvFileName];
      if (fileContent != null) {
        table.collection.loadFromJson(convertFromRawCsvTextToListOfJSonObject(fileContent));
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
    for (final _Table table in _tables(data)) {
      addCsvToArchive(archive, table.csvFileName, table.collection.toCSV());
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

/// One persisted table: its SQL name, its file name in the CSV archive, and its collection.
typedef _Table = ({String tableName, String csvFileName, MoneyObjects<dynamic> collection});

/// Returns every persisted table in load/save order, shared by SQL and CSV.
///
/// Splits must come after transactions so they attach to loaded transactions.
List<_Table> _tables(Data data) {
  return <_Table>[
    (tableName: SharedStrings.tableAccountAliases, csvFileName: 'account_aliases.csv', collection: data.accountAliases),
    (tableName: SharedStrings.tableAccounts, csvFileName: 'accounts.csv', collection: data.accounts),
    (tableName: SharedStrings.tableAliases, csvFileName: 'aliases.csv', collection: data.aliases),
    (tableName: SharedStrings.tableCategories, csvFileName: 'categories.csv', collection: data.categories),
    (tableName: SharedStrings.tableCurrencies, csvFileName: 'currencies.csv', collection: data.currencies),
    (tableName: SharedStrings.tableInvestments, csvFileName: 'investments.csv', collection: data.investments),
    (tableName: SharedStrings.tableLoanPayments, csvFileName: 'loan_payments.csv', collection: data.loanPayments),
    (tableName: SharedStrings.tableOnlineAccounts, csvFileName: 'online_accounts.csv', collection: data.onlineAccounts),
    (tableName: SharedStrings.tablePayees, csvFileName: 'payees.csv', collection: data.payees),
    (tableName: SharedStrings.tableRentBuildings, csvFileName: 'rent_buildings.csv', collection: data.rentBuildings),
    (tableName: SharedStrings.tableRentUnits, csvFileName: 'rent_units.csv', collection: data.rentUnits),
    (tableName: SharedStrings.tableSecurities, csvFileName: 'securities.csv', collection: data.securities),
    (tableName: SharedStrings.tableStockSplits, csvFileName: 'stock_splits.csv', collection: data.stockSplits),
    (tableName: SharedStrings.tableEvents, csvFileName: 'events.csv', collection: data.events),
    (tableName: SharedStrings.tableTransactions, csvFileName: 'transactions.csv', collection: data.transactions),
    (
      tableName: SharedStrings.tableTransactionExtras,
      csvFileName: 'transaction_extras.csv',
      collection: data.transactionExtras,
    ),
    (tableName: SharedStrings.tableSplits, csvFileName: 'splits.csv', collection: data.splits),
  ];
}

Future<List<Map<String, dynamic>>> _selectAll(MyDatabase db, String tableName) async {
  return await db.select('${SharedSqlStrings.sqlSelectAllPrefix}$tableName');
}
