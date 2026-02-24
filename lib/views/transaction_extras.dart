import 'package:money/helpers/json_helper.dart';
import 'package:money/providers/transaction_extra.dart';
import 'package:money/views/money_objects.dart';

/// Represents transaction extras.
class TransactionExtras extends MoneyObjects<TransactionExtra> {
  TransactionExtras() {
    collectionName = 'TransactionExtras';
  }

  @override
  TransactionExtra instanceFromJson(final MyJson json) {
    return TransactionExtra.fromJson(json);
  }
}
