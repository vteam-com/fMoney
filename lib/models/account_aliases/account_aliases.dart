import 'package:money/helpers/json_helper.dart';
import 'package:money/models/account_aliases/account_alias.dart';
import 'package:money/widgets/money_objects.dart';

class AccountAliases extends MoneyObjects<AccountAlias> {
  AccountAliases() {
    collectionName = 'Account Aliases';
  }

  @override
  AccountAlias instanceFromJson(final MyJson json) {
    return AccountAlias.fromJson(json);
  }
}
