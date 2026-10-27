import 'package:money/widgets/widgets_domain/data_object_model.dart';

/// Transaction lookups, categorization and transfer linking.
abstract class TransactionOperations {
  /// Returns a transaction by ID.
  DataObject? getTransaction(int id);

  /// Returns all transactions.
  Iterable<DataObject> getTransactions({bool includeDeleted = false});

  /// Appends a transaction.
  void appendTransaction(DataObject transaction);

  /// Appends a new transaction with optional notification.
  void appendNewTransaction(DataObject transaction, {bool fireNotification = true});

  /// Returns transactions with splits flattened.
  List<DataObject> getTransactionsFlattenSplits({bool Function(DataObject)? whereClause});

  /// Finds transfers pointing to the given account.
  Iterable<DataObject> findTransfersToAccount(DataObject account);

  /// Changes the category for a transaction.
  void changeCategory(DataObject transaction, int categoryId);

  /// Changes the category for a transaction by category name.
  void changeCategoryFromCategoryName(DataObject transaction, String categoryName);

  /// Finds likely disconnected transfer counterparts for a transaction.
  List<DataObject> findPotentialTransferMatches({
    required DataObject transaction,
    int maxDays,
    int maxResults,
  });

  /// Returns true when a transaction has at least one likely disconnected
  /// transfer counterpart; cached per data version so it is cheap per row.
  bool hasPotentialTransferMatch(DataObject transaction);

  /// Converts two existing disconnected transactions into a linked transfer pair.
  bool convertDisconnectedTransactionsToTransfer({
    required DataObject transaction,
    required DataObject relatedTransaction,
  });
}
