import 'package:money/providers/account.dart';
import 'package:money/providers/category.dart';

/// Represents import fields for transfer.
class ImportFieldsForTransfer {
  ImportFieldsForTransfer({
    required this.accountFrom,
    required this.accountTo,
    required this.date,
    required this.category,
    required this.amount,
    required this.memo,
  });

  Account accountFrom;
  Account accountTo;
  double amount;
  DateTime date;
  String memo;

  Category? category;

  /// Returns true if accounts are valid for transfer (different accounts).
  bool get validAccounts => accountFrom != accountTo;
}
