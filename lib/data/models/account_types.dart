import 'package:money/data/models/account_types_enum.dart';
import 'package:money/helpers/shared_strings.dart';

enum AccountFlags {
  none, // 0
  budgeted, // 1
  closed, // 2
  taxDeferred, // 3
}

/// Convert a text into a AccountType
AccountType? getAccountTypeFromText(final String text) {
  switch (text) {
    case SharedStrings.accountTypeSavings:
      return AccountType.savings;
    case SharedStrings.accountTypeChecking:
      return AccountType.checking;
    case SharedStrings.accountTypeMoneyMarket:
      return AccountType.moneyMarket;
    case SharedStrings.accountTypeCash:
      return AccountType.cash;
    case SharedStrings.accountTypeCredit:
    case SharedStrings.accountTypeCreditCard: // as seen in OFX <ACCTTYPE>
      return AccountType.credit;
    case SharedStrings.accountTypeCreditLine:
      return AccountType.creditLine;
    case SharedStrings.accountTypeInvestment:
      return AccountType.investment;
    case SharedStrings.accountTypeRetirement:
      return AccountType.retirement;
    case SharedStrings.accountTypeAsset:
      return AccountType.asset;
    case SharedStrings.accountTypeFund:
      return AccountType.categoryFund;
    case SharedStrings.accountTypeLoan:
      return AccountType.loan;
    default:
      return null;
  }
}

/// Convert a AccountType into a readable/localized String
String getTypeAsText(final AccountType type) {
  switch (type) {
    case AccountType.savings:
      return SharedStrings.accountTypeSavings;
    case AccountType.checking:
      return SharedStrings.accountTypeChecking;
    case AccountType.moneyMarket:
      return SharedStrings.accountTypeMoneyMarket;
    case AccountType.cash:
      return SharedStrings.accountTypeCash;
    case AccountType.credit:
      return SharedStrings.accountTypeCredit;
    case AccountType.investment:
      return SharedStrings.accountTypeInvestment;
    case AccountType.retirement:
      return SharedStrings.accountTypeRetirement;
    case AccountType.asset:
      return SharedStrings.accountTypeAsset;
    case AccountType.categoryFund:
      return SharedStrings.accountTypeFund;
    case AccountType.loan:
      return SharedStrings.accountTypeLoan;
    case AccountType.creditLine:
      return SharedStrings.accountTypeCreditLine;
    default:
      break;
  }

  return '${SharedStrings.accountTypeOtherPrefix}$type';
}

/// Returns list of account type names as strings.
List<String> getAccountTypeAsText() {
  return <String>[
    getTypeAsText(AccountType.checking),
    getTypeAsText(AccountType.savings),
    getTypeAsText(AccountType.retirement),
    getTypeAsText(AccountType.cash),
    getTypeAsText(AccountType.credit),
    getTypeAsText(AccountType.creditLine),
    getTypeAsText(AccountType.investment),
    getTypeAsText(AccountType.moneyMarket),
    getTypeAsText(AccountType.asset),
    getTypeAsText(AccountType.loan),
  ];
}
