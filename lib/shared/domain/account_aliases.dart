import 'package:money/helpers/json_helper.dart';
import 'package:money/shared/domain/account_alias.dart';
import 'package:money/shared/domain/money_objects.dart';

/// Represents account aliases.
class AccountAliases extends MoneyObjects<AccountAlias> {
  AccountAliases() {
    collectionName = 'Account Aliases';
  }

  @override
  AccountAlias instanceFromJson(final MyJson json) {
    return AccountAlias.fromJson(json);
  }
}
