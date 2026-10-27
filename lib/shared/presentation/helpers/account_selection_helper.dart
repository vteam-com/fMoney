import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/widgets/state/preferences_controller.dart';

const int _unsetId = -1;

/// Preference key for the last selected account in the accounts view.
String getViewPreferenceIdAccountLastSelected() {
  return ViewId.viewAccounts.getViewPreferenceId(
    settingKeySelectedListItemId,
  );
}

/// Returns the most recently selected account, or the first account if none selected.
Account getMostRecentlySelectedAccount() {
  final int lastSelectionId = PreferenceController.to.getInt(
    getViewPreferenceIdAccountLastSelected(),
    _unsetId,
  );
  if (lastSelectionId != _unsetId) {
    final Account? accountExist = Data().accounts.get(lastSelectionId);
    if (accountExist != null) {
      return accountExist;
    }
  }

  return Data().accounts.firstItem()!;
}

/// Remembers [account] as the most recently used account.
void setMostRecentUsedAccount(Account account) {
  PreferenceController.to.setInt(
    getViewPreferenceIdAccountLastSelected(),
    account.fieldId.value,
  );
}
