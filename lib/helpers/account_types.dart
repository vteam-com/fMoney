import 'package:money/helpers/account_types_enum.dart';

enum AccountFlags {
  none, // 0
  budgeted, // 1
  closed, // 2
  taxDeferred, // 3
}

/// Convert a text into a AccountType
AccountType? getAccountTypeFromText(final String text) {
  switch (text) {
    case 'Savings':
      return AccountType.savings;
    case 'Checking':
      return AccountType.checking;
    case 'MoneyMarket':
      return AccountType.moneyMarket;
    case 'Cash':
      return AccountType.cash;
    case 'Credit':
    case 'CreditCard': // as seen in OFX <ACCTTYPE>
      return AccountType.credit;
    case 'CreditLine':
      return AccountType.creditLine;
    case 'Investment':
      return AccountType.investment;
    case 'Retirement':
      return AccountType.retirement;
    case 'Asset':
      return AccountType.asset;
    case 'Fund':
      return AccountType.categoryFund;
    case 'Loan':
      return AccountType.loan;
    default:
      return null;
  }
}

/// Convert a AccountType into a readable/localized String
String getTypeAsText(final AccountType type) {
  switch (type) {
    case AccountType.savings:
      return 'Savings';
    case AccountType.checking:
      return 'Checking';
    case AccountType.moneyMarket:
      return 'MoneyMarket';
    case AccountType.cash:
      return 'Cash';
    case AccountType.credit:
      return 'Credit';
    case AccountType.investment:
      return 'Investment';
    case AccountType.retirement:
      return 'Retirement';
    case AccountType.asset:
      return 'Asset';
    case AccountType.categoryFund:
      return 'Fund';
    case AccountType.loan:
      return 'Loan';
    case AccountType.creditLine:
      return 'CreditLine';
    default:
      break;
  }

  return 'other $type';
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
