import 'package:money/data/models/transaction_extra.dart';
import 'package:money/data/money_objects.dart';
import 'package:money/helpers/json_helper.dart';

class TransactionExtras extends MoneyObjects<TransactionExtra> {
  TransactionExtras() {
    collectionName = 'TransactionExtras';
  }

  @override
  TransactionExtra instanceFromJson(final MyJson json) {
    return TransactionExtra.fromJson(json);
  }
}
