import 'package:money/fields/money_objects.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/money_objects/transaction_extras/transaction_extra.dart';

// Exports
export 'package:money/money_objects/transaction_extras/transaction_extra.dart';

class TransactionExtras extends MoneyObjects<TransactionExtra> {
  TransactionExtras() {
    collectionName = 'TransactionExtras';
  }

  @override
  TransactionExtra instanceFromJson(final MyJson json) {
    return TransactionExtra.fromJson(json);
  }
}
