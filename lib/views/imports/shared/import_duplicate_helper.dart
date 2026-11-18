import 'package:money/data/models/ranges_model.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/widgets/columns/value_parser.dart';
import 'package:money/widgets/columns/value_quality.dart';

/// Flags each of [values] whose transaction is already in [accountId].
///
/// Deleted transactions are ignored, each existing transaction can mark only one
/// imported row, and bank FITIDs take precedence over date/amount matching.
void markExistingImportValues({
  required int accountId,
  required List<ValuesQuality> values,
}) {
  ValuesParser.evaluateExistence(
    accountId: accountId,
    values: values,
    transactionExistsCallback:
        ({
          required int accountId,
          required DateTime dateTime,
          required double amount,
          required String fitid,
          required Set<Object> alreadyMatched,
        }) => Data().transactions.findExistingTransaction(
          accountId: accountId,
          dateRange: DateRange(min: dateTime.startOfDay, max: dateTime.endOfDay),
          amount: amount,
          includeDeleted: false,
          fitid: fitid,
          excluded: alreadyMatched,
        ),
  );
}
