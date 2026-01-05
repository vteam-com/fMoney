import 'package:money/helpers/json_helper.dart';
import 'package:money/models/transaction_extras/transaction_extra.dart';
import 'package:money/widgets/money_objects.dart';

class TransactionExtras extends MoneyObjects<TransactionExtra> {
  TransactionExtras() {
    collectionName = 'TransactionExtras';
  }

  @override
  TransactionExtra instanceFromJson(final MyJson json) {
    return TransactionExtra.fromJson(json);
  }
}
