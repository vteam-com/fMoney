import 'package:money/data/models/data_object_model.dart';

/// Rental unit lookups.
abstract class RentUnitOperations {
  /// Returns rent units.
  List<DataObject> getRentUnits();
}
