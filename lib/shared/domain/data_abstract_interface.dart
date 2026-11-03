import 'package:money/shared/domain/account_operations_interface.dart';
import 'package:money/shared/domain/category_operations_interface.dart';
import 'package:money/shared/domain/data_change_operations_interface.dart';
import 'package:money/shared/domain/event_operations_interface.dart';
import 'package:money/shared/domain/investment_operations_interface.dart';
import 'package:money/shared/domain/loan_payment_operations_interface.dart';
import 'package:money/shared/domain/payee_operations_interface.dart';
import 'package:money/shared/domain/rent_unit_operations_interface.dart';
import 'package:money/shared/domain/security_operations_interface.dart';
import 'package:money/shared/domain/transaction_operations_interface.dart';

/// Full data access used by the app, composed of role interfaces so consumers can depend on only the role they use.
abstract class DataAbstract
    implements
        DataChangeOperations,
        AccountOperations,
        PayeeOperations,
        CategoryOperations,
        SecurityOperations,
        LoanPaymentOperations,
        InvestmentOperations,
        TransactionOperations,
        EventOperations,
        RentUnitOperations {
  static late DataAbstract instance;
}
