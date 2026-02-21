import 'package:money/data/models/database_interface.dart';
import 'package:money/data/storages/database_sql.dart' if (dart.library.html) 'package:money/io/database_web.dart';

/// Represents my database.
class MyDatabase extends MyDatabaseImplementation implements DatabaseInterface {
  // abstraction class
}
