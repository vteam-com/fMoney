// ignore_for_file: avoid_web_libraries_in_flutter, avoid_print
// ignore: fcheck_dead_code
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings.dart';

/// implement the Sqlite3 WASM Web Support see https://pub.dev/packages/sqlite3#wasm-web-support
/// Web database implementation (no-op for web environment).
class MyDatabaseImplementation {
  /// No-op dispose method for web environment.
  void dispose() {}

  /// No-op execute method for web environment.
  void execute(final String query) {}

  /// SQL Delete
  void itemDelete(final String tableName, final String whereClause) {}

  /// SQL Insert
  void itemInsert(final String tableName, final MyJson data) {}

  /// SQL Update
  void itemUpdate(
    final String tableName,
    final MyJson jsonMap,
    final String whereClause,
  ) {}

  /// Loads database from file bytes in web environment using JavaScript.
  Future<void> load(final String fileToOpen, final Uint8List fileBytes) async {
    try {
      // Pass byte array to JavaScript function to load the database.
      await _callJsPromise(
        'loadDatabaseFromBinary',
        <JSAny?>[fileBytes.toList().jsify()],
      );
    } catch (e) {
      // Rollback the transaction if an error occurs
      // _db.execute('ROLLBACK');
      // print('Error loading database: $e');
      rethrow;
    } finally {
      // Clean up the temporary table
      // _db.execute('DROP TABLE IF EXISTS temp_table');
    }
  }

  /// Executes SQL query and returns results as list of maps in web environment.
  Future<List<Map<String, dynamic>>> select(final String query) async {
    try {
      final JSAny? jsObjectResult = await _callJsPromise(
        'executeSql',
        <JSAny?>[query.toJS],
      );
      final Object? dartResult = jsObjectResult?.dartify();

      if (dartResult is! List<dynamic> || dartResult.isEmpty) {
        // no results found from the query
        // print('No results found');
        return <Map<String, dynamic>>[];
      }

      // Access the first result set, ensuring it's a map-like object.
      final dynamic firstResult = dartResult.first;
      if (firstResult is! Map<dynamic, dynamic>) {
        print('Error: The result set structure is unexpected.');
        return <Map<String, dynamic>>[];
      }
      // Convert the first result map to List<Map<String, dynamic>>.
      return _convertJsResultToList(
        firstResult.map(
          (final dynamic key, final dynamic value) => MapEntry<String, dynamic>(key.toString(), value),
        ),
      );
    } catch (e) {
      print('Error executing query: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// Check if a table exists in the database
  Future<bool> tableExists(final String tableName) async {
    try {
      final List<Map<String, dynamic>> list = await select(
        SharedSqlStrings.sqlSelectTableNames,
      );
      return _listMapContains(list, SharedSqlStrings.columnName, tableName);
    } catch (e) {
      print('Error checking if table exists: $e');
      return false;
    }
  }

  /// Calls a JavaScript function on `globalThis` and awaits its Promise result.
  Future<JSAny?> _callJsPromise(
    final String method,
    final List<JSAny?> arguments,
  ) async {
    final JSAny? result = globalContext.callMethodVarArgs<JSAny?>(
      method.toJS,
      arguments,
    );
    if (result == null) {
      return null;
    }
    if (result.isA<JSPromise<JSAny?>>()) {
      return (result as JSPromise<JSAny?>).toDart;
    }
    return result;
  }

  /// Converts SQL.js result map to a typed list of row maps.
  List<Map<String, dynamic>> _convertJsResultToList(
    final Map<String, dynamic> jsResult,
  ) {
    final List<String> columns = List<String>.from(
      jsResult['columns'] as List<dynamic>,
    );
    final List<dynamic> values = jsResult['values'] as List<dynamic>;
    if (values.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    // Map each row's values to its column name
    return values.map((dynamic row) {
      final List<dynamic> rowValues = row as List<dynamic>;
      return Map<String, dynamic>.fromIterables(columns, rowValues);
    }).toList();
  }

  bool _listMapContains(
    List<Map<String, dynamic>> list,
    String field,
    String value,
  ) {
    return list.any((Map<String, dynamic> map) => map[field] == value);
  }
}
