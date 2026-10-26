import 'package:money/data/models/account_types_enum.dart';
import 'package:money/helpers/shared_strings_helper.dart';

enum AccountFlags {
  none, // 0
  budgeted, // 1
  closed, // 2
  taxDeferred, // 3
}

/// True if [type] holds investments (investment, retirement or money market).
bool isInvestmentAccountType(AccountType? type) {
  return type == AccountType.investment || type == AccountType.retirement || type == AccountType.moneyMarket;
}

/// Display text of each account type; the single source for [getTypeAsText]
/// and [getAccountTypeFromText].
const Map<AccountType, String> _accountTypeTexts = <AccountType, String>{
  AccountType.savings: SharedStrings.accountTypeSavings,
  AccountType.checking: SharedStrings.accountTypeChecking,
  AccountType.moneyMarket: SharedStrings.accountTypeMoneyMarket,
  AccountType.cash: SharedStrings.accountTypeCash,
  AccountType.credit: SharedStrings.accountTypeCredit,
  AccountType.creditLine: SharedStrings.accountTypeCreditLine,
  AccountType.investment: SharedStrings.accountTypeInvestment,
  AccountType.retirement: SharedStrings.accountTypeRetirement,
  AccountType.asset: SharedStrings.accountTypeAsset,
  AccountType.categoryFund: SharedStrings.accountTypeFund,
  AccountType.loan: SharedStrings.accountTypeLoan,
};

/// Account types offered to the user, in display order.
const List<AccountType> selectableAccountTypes = <AccountType>[
  AccountType.checking,
  AccountType.savings,
  AccountType.retirement,
  AccountType.cash,
  AccountType.credit,
  AccountType.creditLine,
  AccountType.investment,
  AccountType.moneyMarket,
  AccountType.asset,
  AccountType.loan,
];

/// Convert a text into a AccountType
AccountType? getAccountTypeFromText(String text) {
  if (text == SharedStrings.accountTypeCreditCard) {
    // as seen in OFX <ACCTTYPE>
    return AccountType.credit;
  }
  for (final MapEntry<AccountType, String> entry in _accountTypeTexts.entries) {
    if (entry.value == text) {
      return entry.key;
    }
  }
  return null;
}

/// Convert a AccountType into a readable/localized String
String getTypeAsText(AccountType type) {
  return _accountTypeTexts[type] ?? '${SharedStrings.accountTypeOtherPrefix}$type';
}
