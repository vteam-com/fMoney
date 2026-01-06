import 'package:money/helpers/json_helper.dart';
import 'package:money/models/account_alias.dart';
import 'package:money/models/money_objects.dart';

class AccountAliases extends MoneyObjects<AccountAlias> {
  AccountAliases() {
    collectionName = 'Account Aliases';
  }

  @override
  AccountAlias instanceFromJson(final MyJson json) {
    return AccountAlias.fromJson(json);
  }
}
