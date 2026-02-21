import 'package:money/helpers/json_helper.dart';
import 'package:money/views/money_objects.dart';
import 'package:money/views/providers/account_alias.dart';

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
