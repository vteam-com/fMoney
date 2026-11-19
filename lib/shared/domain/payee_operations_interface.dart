import 'package:money/data/models/data_object_model.dart';

/// Payee lookups and maintenance.
abstract class PayeeOperations {
  /// Finds or creates a new payee by name.
  DataObject? findOrCreateNewPayee(String name, {bool fireNotification = true});

  // Payees
  /// Returns a payee by ID.
  DataObject? getPayee(int id);

  /// Returns a payee by name.
  DataObject? getPayeeByName(String name);

  /// Finds or creates a payee by name.
  DataObject getOrCreatePayee(String name, {bool fireNotification = true});

  /// Re-points the split lines and aliases of each payee in [fromPayeeIds] that no longer has
  /// transactions to [toPayeeId], then deletes that payee.
  void mergePayeesWithNoTransactionsInto(List<int> fromPayeeIds, int toPayeeId);

  /// Returns the name of a payee by ID.
  String getPayeeName(int id);

  /// Returns all payee names sorted.
  List<String> getPayeeNamesSorted();
}
