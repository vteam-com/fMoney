import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/account_alias_entity.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';

/// Represents account aliases.
class AccountAliases extends MoneyObjects<AccountAlias> {
  AccountAliases() {
    collectionName = SharedDomainStrings.domainString012;
  }

  @override
  AccountAlias instanceFromJson(MyJson json) {
    return AccountAlias.fromJson(json);
  }
}
