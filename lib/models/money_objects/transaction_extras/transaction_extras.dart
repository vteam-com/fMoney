import 'package:money/helpers/json_helper.dart';
import 'package:money/models/money_objects.dart';
import 'package:money/models/money_objects/transaction_extras/transaction_extra.dart';

// Exports
export 'package:money/models/money_objects/transaction_extras/transaction_extra.dart';

class TransactionExtras extends MoneyObjects<TransactionExtra> {
  TransactionExtras() {
    collectionName = 'TransactionExtras';
  }

  @override
  TransactionExtra instanceFromJson(final MyJson json) {
    return TransactionExtra.fromJson(json);
  }
}
