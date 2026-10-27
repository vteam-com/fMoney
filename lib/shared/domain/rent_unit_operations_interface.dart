import 'package:money/widgets/widgets_domain/data_object_model.dart';

/// Rental unit lookups.
abstract class RentUnitOperations {
  /// Returns rent units.
  List<DataObject> getRentUnits();
}
