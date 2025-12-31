import 'package:money/helpers/json_helper.dart';
import 'package:money/models/money_objects.dart';
import 'package:money/models/money_objects/online_accounts/online_account.dart';

class OnlineAccounts extends MoneyObjects<OnlineAccount> {
  OnlineAccounts() {
    collectionName = 'Online Accounts';
  }

  @override
  void loadFromJson(final List<MyJson> rows) {
    clear();
    for (final MyJson row in rows) {
      appendMoneyObject(OnlineAccount.fromJson(row));
    }
  }

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }
}
