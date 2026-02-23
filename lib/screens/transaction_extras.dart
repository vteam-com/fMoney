import 'package:money/helpers/json_helper.dart';
import 'package:money/views/money_objects.dart';
import 'package:money/views/providers/transaction_extra.dart';

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
