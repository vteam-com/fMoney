import 'package:money/data/models/account_alias.dart';
import 'package:money/data/money_objects.dart';
import 'package:money/helpers/json_helper.dart';

class AccountAliases extends MoneyObjects<AccountAlias> {
  AccountAliases() {
    collectionName = 'Account Aliases';
  }

  @override
  AccountAlias instanceFromJson(final MyJson json) {
    return AccountAlias.fromJson(json);
  }
}
