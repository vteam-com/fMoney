import 'package:money/helpers/json_helper.dart';

/// Abstract interface for database operations (insert, update, delete).
abstract class DatabaseInterface {
  /// Inserts an item into the specified table.
  void itemInsert(final String tableName, final MyJson data);

  /// Updates an item in the specified table matching the [whereClause].
  void itemUpdate(
    final String tableName,
    final MyJson jsonMap,
    final String whereClause,
  );

  /// Deletes items from the specified table matching the [whereClause].
  void itemDelete(final String tableName, final String whereClause);
}
