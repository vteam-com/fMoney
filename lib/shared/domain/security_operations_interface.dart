import 'package:money/data/models/data_object_model.dart';

/// Security and stock split lookups.
abstract class SecurityOperations {
  /// Returns the security symbol for a security ID.
  String getSecuritySymbolFromId(int id);

  /// Returns a security by ID.
  DataObject? getSecurity(int id);

  /// Returns a security by symbol.
  DataObject? getSecurityBySymbol(String symbol);

  /// Returns stock splits for a security.
  List<DataObject> getStockSplitsForSecurity(DataObject security);

  /// Returns the split ratio for a security before a date.
  double getSplitRatioForSecurityBeforeDate(int securityId, DateTime date);
}
