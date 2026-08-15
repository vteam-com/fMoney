import 'package:money/helpers/json_helper.dart';

/// Abstract interface for database operations (insert, update, delete).
abstract class DatabaseInterface {
  /// Inserts an item into the specified table.
  void itemInsert(String tableName, MyJson data);

  /// Updates an item in the specified table matching the [whereClause].
  void itemUpdate(
    String tableName,
    MyJson jsonMap,
    String whereClause,
  );

  /// Deletes items from the specified table matching the [whereClause].
  void itemDelete(String tableName, String whereClause);
}
