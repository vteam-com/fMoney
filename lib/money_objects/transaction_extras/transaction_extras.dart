import 'package:money/helpers/json_helper.dart';
import 'package:money/money_objects/transaction_extras/transaction_extra.dart';
import 'package:money/widgets_data/money_object/money_objects.dart';

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
