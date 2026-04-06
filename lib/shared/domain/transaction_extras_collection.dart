import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/transaction_extra_entity.dart';

/// Represents transaction extras.
class TransactionExtras extends MoneyObjects<TransactionExtra> {
  TransactionExtras() {
    collectionName = SharedDomainStrings.domainString142;
  }

  @override
  TransactionExtra instanceFromJson(final MyJson json) {
    return TransactionExtra.fromJson(json);
  }
}
