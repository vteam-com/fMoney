// ignore_for_file: avoid_web_libraries_in_flutter
// ignore: fcheck_dead_code
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:money/helpers/app_logger_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';

/// implement the Sqlite3 WASM Web Support see https://pub.dev/packages/sqlite3#wasm-web-support
/// Web database implementation (no-op for web environment).
class MyDatabaseImplementation {
  /// No-op dispose method for web environment.
  void dispose() {}

  /// No-op execute method for web environment.
  void execute(String query) {}

  /// SQL Delete
  void itemDelete(String tableName, String whereClause) {}

  /// SQL Insert
  void itemInsert(String tableName, MyJson data) {}

  /// SQL Update
  void itemUpdate(
    String tableName,
    MyJson jsonMap,
    String whereClause,
  ) {}

  /// Loads database from file bytes in web environment using JavaScript.
  Future<void> load(String fileToOpen, Uint8List fileBytes) async {
    try {
      // Pass byte array to JavaScript function to load the database.
      await _callJsPromise(
        'loadDatabaseFromBinary',
        <JSAny?>[fileBytes.toList().jsify()],
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        module: 'database_web_storage',
        operation: 'load',
        error: e,
        stackTrace: stackTrace,
        context: <String, Object?>{
          'fileToOpen': fileToOpen,
          'bytesCount': fileBytes.length,
        },
      );
      rethrow;
    } finally {
      // Clean up the temporary table
      // _db.execute('DROP TABLE IF EXISTS temp_table');
    }
  }

  /// Executes SQL query and returns results as list of maps in web environment.
  Future<List<Map<String, dynamic>>> select(String query) async {
    try {
      final JSAny? jsObjectResult = await _callJsPromise(
        'executeSql',
        <JSAny?>[query.toJS],
      );
      final Object? dartResult = jsObjectResult?.dartify();

      if (dartResult is! List<dynamic> || dartResult.isEmpty) {
        return <Map<String, dynamic>>[];
      }

      // Access the first result set, ensuring it's a map-like object.
      final dynamic firstResult = dartResult.first;
      if (firstResult is! Map<dynamic, dynamic>) {
        AppLogger.warning(
          module: 'database_web_storage',
          operation: 'select',
          message: 'Unexpected result set structure.',
          context: <String, Object?>{'query': query},
        );
        return <Map<String, dynamic>>[];
      }
      // Convert the first result map to List<Map<String, dynamic>>.
      return _convertJsResultToList(
        firstResult.map(
          (dynamic key, dynamic value) => MapEntry<String, dynamic>(key.toString(), value),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        module: 'database_web_storage',
        operation: 'select',
        error: e,
        stackTrace: stackTrace,
        context: <String, Object?>{'query': query},
      );
      return <Map<String, dynamic>>[];
    }
  }

  /// Check if a table exists in the database
  Future<bool> tableExists(String tableName) async {
    try {
      final List<Map<String, dynamic>> list = await select(
        SharedSqlStrings.sqlSelectTableNames,
      );
      return _listMapContains(list, SharedSqlStrings.columnName, tableName);
    } catch (e, stackTrace) {
      AppLogger.error(
        module: 'database_web_storage',
        operation: 'tableExists',
        error: e,
        stackTrace: stackTrace,
        context: <String, Object?>{'tableName': tableName},
      );
      return false;
    }
  }

  /// Calls a JavaScript function on `globalThis` and awaits its Promise result.
  Future<JSAny?> _callJsPromise(
    String method,
    List<JSAny?> arguments,
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
    Map<String, dynamic> jsResult,
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
