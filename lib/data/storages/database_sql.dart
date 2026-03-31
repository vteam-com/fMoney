import 'dart:io';
import 'dart:typed_data';

import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:sqlite3/sqlite3.dart';

/// local client SQLite access
class MyDatabaseImplementation {
  late final Database _db;

  /// Closes the database connection.
  void dispose() {
    _db.close();
  }

  /// Executes SQL command on the database.
  void execute(final String command) {
    _db.execute(command);
  }

  /// Initializes the database with required tables.
  void initDatabase(Database database) {
    database.execute(SharedSqlStrings.sqlSchemaBootstrap);
    // Add more tables or alter the schema as needed
  }

  /// SQL Delete
  void itemDelete(final String tableName, final String whereClause) {
    final String statement = SharedSqlStrings.sqlDeleteTemplate
        .replaceAll(SharedSqlStrings.sqlPlaceholderTable, tableName)
        .replaceAll(SharedSqlStrings.sqlPlaceholderWhere, whereClause);
    _db.execute(statement);
  }

  /// SQL Insert
  void itemInsert(final String tableName, final MyJson data) {
    final String columnNames = data.keys.map((final String key) => '"$key"').join(', ');
    final String columnValues = data.values.map((final dynamic value) => encodeValueWrapStringTypes(value)).join(', ');
    final String statement = SharedSqlStrings.sqlInsertTemplate
        .replaceAll(SharedSqlStrings.sqlPlaceholderTable, tableName)
        .replaceAll(SharedSqlStrings.sqlPlaceholderColumns, columnNames)
        .replaceAll(SharedSqlStrings.sqlPlaceholderValues, columnValues);
    _db.execute(statement);
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
    final String statement = SharedSqlStrings.sqlUpdateTemplate
        .replaceAll(SharedSqlStrings.sqlPlaceholderTable, tableName)
        .replaceAll(SharedSqlStrings.sqlPlaceholderSet, fieldNamesAndValues)
        .replaceAll(SharedSqlStrings.sqlPlaceholderWhere, whereClause);
    _db.execute(statement);
  }

  /// Loads database from file path.
  Future<void> load(final String fileToOpen, final Uint8List _ /* fileBytes */) async {
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

  /// Executes SELECT query and returns results as list of MyJson.
  Future<List<MyJson>> select(final String query) async {
    return _db.select(query);
  }

  /// Checks if table exists in the database.
  Future<bool> tableExists(String tableName) async {
    final ResultSet result = _db.select(
      SharedSqlStrings.sqlSelectTableNameByName,
      <Object?>[tableName],
    );
    return result.isNotEmpty;
  }
}
