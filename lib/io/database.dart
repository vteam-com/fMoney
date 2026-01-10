import 'package:money/data/abstract/database_interface.dart';
import 'package:money/io/database_sql.dart' if (dart.library.html) 'package:money/io/database_web.dart';

class MyDatabase extends MyDatabaseImplementation implements DatabaseInterface {
  // abstraction class
}
