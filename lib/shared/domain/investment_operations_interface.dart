import 'package:money/data/models/data_object_model.dart';

/// Investment lookups.
abstract class InvestmentOperations {
  /// Returns an investment by ID.
  DataObject? getInvestment(int id);

  /// Returns all investments.
  List<DataObject> getInvestments();
}
