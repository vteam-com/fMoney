import 'package:money/helpers/json_helper.dart';

abstract class DatabaseInterface {
  void itemInsert(final String tableName, final MyJson data);

  void itemUpdate(
    final String tableName,
    final MyJson jsonMap,
    final String whereClause,
  );

  void itemDelete(final String tableName, final String whereClause);
}
