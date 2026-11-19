import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';

/// Change notification and cross-table maintenance operations.
abstract class DataChangeOperations {
  /// Notifies listeners of a mutation to a money object.
  void notifyMutationChanged({
    required MutationType mutation,
    required DataObject moneyObject,
    bool recalculateBalances = true,
  });

  /// Updates all data/collections after changes.
  void updateAll();
}
