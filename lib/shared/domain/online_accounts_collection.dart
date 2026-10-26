import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/online_account_entity.dart';

/// Represents online accounts.
class OnlineAccounts extends MoneyObjects<OnlineAccount> {
  OnlineAccounts() {
    collectionName = SharedDomainStrings.domainString097;
  }

  @override
  OnlineAccount instanceFromJson(MyJson json) {
    return OnlineAccount.fromJson(json);
  }
}
