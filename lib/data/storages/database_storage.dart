import 'package:money/data/models/database_interface.dart';
import 'package:money/data/storages/database_sql_storage.dart' if (dart.library.html) 'package:money/data/storages/database_web_storage.dart';

/// Represents my database.
class MyDatabase extends MyDatabaseImplementation implements DatabaseInterface {
  // abstraction class
}
