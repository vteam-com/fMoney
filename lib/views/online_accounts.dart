import 'package:money/helpers/json_helper.dart';
import 'package:money/views/money_objects.dart';
import 'package:money/views/providers/online_account.dart';

/// Represents online accounts.
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
