import 'package:money/data/models/data_object_model.dart';

/// Account lookups.
abstract class AccountOperations {
  /// Returns an account by ID.
  DataObject? getAccount(int id);

  /// Returns the name of an account by ID.
  String getAccountName(int id);

  /// Returns the currency symbol for an account by ID.
  String getAccountCurrency(int id);

  /// Returns true if the account is an asset type.
  bool isAccountAsset(int id);

  /// Returns an account by its name.
  DataObject? getAccountByName(String name);

  /// Returns all account names sorted.
  List<String> getAccountNamesSorted();
}
