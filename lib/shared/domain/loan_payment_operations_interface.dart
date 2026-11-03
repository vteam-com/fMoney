import 'package:money/data/models/data_object_model.dart';

/// Loan payment lookups.
abstract class LoanPaymentOperations {
  /// Returns a loan payment by ID.
  DataObject? getLoanPayment(int id);

  /// Returns all loan payments.
  List<DataObject> getLoanPayments();
}
