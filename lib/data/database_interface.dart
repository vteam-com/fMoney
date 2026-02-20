import 'package:money/helpers/json_helper.dart';

/// Abstract interface for database operations (insert, update, delete).
abstract class DatabaseInterface {
  void itemInsert(final String tableName, final MyJson data);

  void itemUpdate(
    final String tableName,
    final MyJson jsonMap,
    final String whereClause,
  );

  void itemDelete(final String tableName, final String whereClause);
}
