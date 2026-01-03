import 'package:money/helpers/json_helper.dart';
import 'package:money/money_objects/account_aliases/account_alias.dart';
import 'package:money/widgets_data/money_objects.dart';

class AccountAliases extends MoneyObjects<AccountAlias> {
  AccountAliases() {
    collectionName = 'Account Aliases';
  }

  @override
  AccountAlias instanceFromJson(final MyJson json) {
    return AccountAlias.fromJson(json);
  }
}
