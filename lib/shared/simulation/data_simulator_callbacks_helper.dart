import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';

/// Callback for adding a transaction with account/date/payee/category details.
typedef AddTransactionCallback = Transaction Function({
  required Account account,
  required DateTime date,
  int payeeId,
  int categoryId,
  double amount,
  String memo,
});

/// Callback for creating linked transfer transactions.
typedef CreateTransferTransactionCallback = Transaction Function({
  required Account accountSource,
  required Account accountDestination,
  required DateTime date,
  required double amount,
  required String memo,
  int categoryId,
});

/// Callback for creating scheduled dates at fixed frequency.
///
/// Arguments:
/// - `yearInThePast`: Number of years back from today to start generation.
/// - `stopDate`: Optional upper date boundary; if omitted, generation uses current date.
/// - `howManyPerYear`: Number of generated dates per year.
/// - `dayOfTheMonth`: Day-of-month to use for generated entries.
typedef GenerateListOfDatesCallback = List<DateTime> Function({
  required int yearInThePast,
  DateTime? stopDate,
  required int howManyPerYear,
  required int dayOfTheMonth,
});

/// Callback for deriving a date by shifting the current year.
///
/// Arguments:
/// - `yearsToShift`: Number of years to subtract from the current year.
/// - `month`: Month for the resulting date (`DateTime.january` to `DateTime.december`).
/// - `day`: Day of month for the resulting date.
typedef ShiftedDateCallback = DateTime Function(int yearsToShift, int month, int day);
