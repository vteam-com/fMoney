// ignore_for_file: unnecessary_this

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:money/data/collections/investments.dart';
import 'package:money/data/collections/loan_payments.dart';
import 'package:money/data/collections/securities.dart';
import 'package:money/data/collections/transactions.dart';
import 'package:money/data/entities/data_abstract.dart';
import 'package:money/data/entities/investment.dart';
import 'package:money/data/entities/loan_payment.dart';
import 'package:money/helpers/account_types_enum.dart';
import 'package:money/helpers/accumulator.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/models/account.dart';
import 'package:money/models/money_objects.dart';
import 'package:money/widgets/preferences_controller.dart';

class Accounts extends MoneyObjects<Account> {
  Accounts() {
    collectionName = 'Accounts';
  }
  late DataAbstract data;

  @override
  Account instanceFromJson(final MyJson json) {
    return Account.fromJson(json);
  }

  @override
  void onAllDataLoaded() {
    for (final Account account in iterableList()) {
      account.fieldCount.value = 0;
      account.balance = account.fieldOpeningBalance.value.asDouble();
      account.minBalancePerYears.clear();
      account.maxBalancePerYears.clear();

      // TODO when we deal with downloading online
      // account.onlineAccountInstance = Data().onlineAccounts.get(this.onlineAccountId);

      // TODO as seen in MyMoney.net
      // if (!string.IsNullOrEmpty(this.categoryForPrincipalName))
      // {
      //   this.CategoryForPrincipal = myMoney.Categories.GetOrCreateCategory(this.categoryForPrincipalName, CategoryType.Expense);
      //   this.categoryForPrincipalName = null;
      // }
      // if (!string.IsNullOrEmpty(this.categoryForInterestName))
      // {
      //   this.categoryForInterest = myMoney.Categories.GetOrCreateCategory(this.categoryForInterestName, CategoryType.Expense);
      //   this.categoryForInterestName = null;
      // }
    }

    // Cumulate
    final List<Transaction> transactionsSortedByDate = (this.data.transactions as Transactions).iterableList().sorted(
      (Transaction a, Transaction b) => sortByDate(a.fieldDateTime.value, b.fieldDateTime.value),
    );

    for (final Transaction t in transactionsSortedByDate) {
      final Account? account = get(t.fieldAccountId.value);
      if (account != null) {
        if (account.fieldType.value == AccountType.moneyMarket || account.fieldType.value == AccountType.investment) {
          t.getOrCreateInvestment();
        }

        account.fieldCount.value++;
        account.balance += t.fieldAmount.value.asDouble();

        final int yearOfTheTransaction = t.fieldDateTime.value!.year;

        // Min Balance of the year
        final double currentMinBalanceValue =
            account.minBalancePerYears[yearOfTheTransaction] ?? IntValues.maxSigned(32).toDouble();
        account.minBalancePerYears[yearOfTheTransaction] = min(
          currentMinBalanceValue,
          account.balance,
        );

        // Max Balance of the year
        final double currentMaxBalanceValue =
            account.maxBalancePerYears[yearOfTheTransaction] ?? IntValues.minSigned(32).toDouble();
        account.maxBalancePerYears[yearOfTheTransaction] = max(
          currentMaxBalanceValue,
          account.balance,
        );

        // keep track of the most recent record transaction for the account
        if (t.fieldDateTime.value != null) {
          if (account.fieldUpdatedOn.value == null ||
              account.fieldUpdatedOn.value!.compareTo(t.fieldDateTime.value!) < 0) {
            account.fieldUpdatedOn.value = t.fieldDateTime.value;
          }
        }
      }
    }

    // Increase the balance of any investment account with the current Stock value
    final List<Account> investmentAccounts = this
        .iterableList()
        .where(
          (Account account) =>
              account.fieldType.value == AccountType.moneyMarket ||
              account.fieldType.value == AccountType.investment ||
              account.fieldType.value == AccountType.retirement,
        )
        .toList();

    final AccumulatorList<String, Investment> groupBySymbol = AccumulatorList<String, Investment>();

    for (final Account account in investmentAccounts) {
      groupAccountStockSymbols(account, groupBySymbol, this.data);
    }

    // apply the investment running balance amount
    groupBySymbol.values.forEach((
      String keyAccountAndSymbol,
      Set<Investment> valuesInvestments,
    ) {
      final double totalAdjustedShareForThisStockInThisAccount = Investments.applyHoldingSharesAdjustedForSplits(
        valuesInvestments.toList(),
      );
      final List<String> tokens = keyAccountAndSymbol.split('|');
      final String accountId = tokens[0];
      final String symbol = tokens[1];
      final Account? account = this.get(int.parse(accountId));
      if (account != null) {
        final Security? security = (this.data.securities as Securities).getBySymbol(symbol);
        if (security != null) {
          account.fieldStockHoldingEstimation.value.setAmount(
            totalAdjustedShareForThisStockInThisAccount * security.fieldLastPrice.value.asDouble(),
          );
          if (account.fieldStockHoldingEstimation.value.asDouble() != 0) {
            account.balance += account.fieldStockHoldingEstimation.value.asDouble();
          }
        }
      }
    });

    // Loans
    final List<Account> accountLoans = this
        .iterableList()
        .where(
          (Account account) => account.fieldType.value == AccountType.loan,
        )
        .toList();
    for (final Account account in accountLoans) {
      final LoanPayment? latestPayment = getAccountLoanPayments(account, this.data).lastOrNull;
      if (latestPayment != null) {
        account.fieldUpdatedOn.value = latestPayment.fieldDate.value;
        account.balance = latestPayment.fieldBalance.value.asDouble() * -1;
      }
    }

    // Credit Card "Paid On" date
    // attempt to match Statement balance to a payment
    for (final Account account in iterableList().where(
      (Account a) => a.fieldType.value == AccountType.credit,
    )) {
      _updateCreditCardPaidOn(account);
    }
  }

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }

  List<Account> activeAccounts(
    final List<AccountType> types, {
    final bool? isActive = true,
  }) {
    return iterableList().where((final Account item) {
      if (!item.matchType(types)) {
        return false;
      }
      if (isActive == null) {
        return true;
      }
      return item.isOpen == isActive;
    }).toList();
  }

  bool activeBankAccounts(final Account account) {
    return account.isActiveBankAccount();
  }

  Account addNewAccount(final String accountName) {
    // find next available name
    String nextAvailableName = accountName;
    int next = 1;
    while (getByName(nextAvailableName) != null) {
      // already taken
      nextAvailableName = '$accountName $next';
      // the the next one
      next++;
    }

    // add a new Account
    final Account account = Account();
    account.fieldName.value = nextAvailableName;
    account.isOpen = true;

    this.appendNewMoneyObject(account, fireNotification: false);
    return account;
  }

  bool compareDoubles(double a, double b, int precision) {
    final num threshold = pow(10, -precision);
    return (a - b).abs() < threshold;
  }

  /// Find a transaction that has a date in the future but not more than 2 months and has inverse amount
  Transaction? findBackwardInTimeForTransactionBalanceThatMatchThisAmount(
    final List<Transaction> transactionForAccountSortedByDateAscending,
    final int indexStartingFrom,
    final DateTime validDateInThePast,
    final double amountToMatch,
  ) {
    for (int i = indexStartingFrom; i >= 0; i--) {
      final Transaction t = transactionForAccountSortedByDateAscending[i];

      if (t.fieldDateTime.value!.isBefore(validDateInThePast)) {
        return null; // out of range break early
      }

      if (compareDoubles(t.balance, amountToMatch, 2)) {
        return t;
      }
    }

    return null;
  }

  Account? findByIdAndType(
    final String accountId,
    final AccountType? accountType,
  ) {
    return iterableList().firstWhereOrNull((final Account account) {
      return account.fieldAccountId.value == accountId &&
          (accountType == null || account.fieldType.value == accountType);
    });
  }

  Account? getByName(final String name) {
    return iterableList().firstWhereOrNull((final Account item) {
      return stringCompareIgnoreCasing(item.fieldName.value, name) == 0;
    });
  }

  List<Account> getListSorted() {
    final List<Account> list = iterableList()
        .where(
          (Account account) =>
              account.isMatchingUserChoiceIncludingClosedAccount && account.fieldType.value != AccountType.categoryFund,
        )
        .toList();
    list.sort(
      (Account a, Account b) => sortByString(a.fieldName.value, b.fieldName.value, true),
    );
    return list;
  }

  List<String> getSortedAccountNames() {
    return getListSorted().map((Account a) => a.fieldName.value).toList();
  }

  Account getMostRecentlySelectedAccount() {
    final int lastSelectionId = PreferenceController.to.getInt(
      getViewPreferenceIdAccountLastSelected(),
      -1,
    );
    if (lastSelectionId != -1) {
      final Account? accountExist = get(lastSelectionId);
      if (accountExist != null) {
        return accountExist;
      }
    }

    return firstItem()!;
  }

  String getNameFromId(final int id) {
    final Account? account = get(id);
    if (account == null) {
      return id.toString();
    }
    return account.fieldName.value;
  }

  List<Account> getOpenAccounts() {
    return iterableList().where((final Account account) => account.isOpen).toList();
  }

  List<Account> getOpenRealAccounts() {
    return iterableList()
        .where(
          (final Account account) => !account.isFakeAccount() && account.isOpen,
        )
        .toList();
  }

  double getSumOfAccountBalances() {
    double sum = 0.00;

    for (final Account account in iterableList()) {
      if (account.isMatchingUserChoiceIncludingClosedAccount) {
        sum += (account.fieldBalanceNormalized.getValueForDisplay(account) as AmountModel).asDouble();
      }
    }
    return sum;
  }

  Iterable<Transaction> getTransactions(final Account account) {
    return (this.data.transactions as Transactions).iterableList().where(
      (Transaction t) => t.fieldAccountId.value == account.uniqueId,
    );
  }

  String getViewPreferenceIdAccountLastSelected() {
    return ViewId.viewAccounts.getViewPreferenceId(
      settingKeySelectedListItemId,
    );
  }

  static void groupAccountStockSymbols(
    Account account,
    AccumulatorList<String, Investment> groupBySymbol,
    DataAbstract data,
  ) {
    final Iterable<Investment> investments = (data.investments as Investments).iterableList().where(
      (Investment i) => i.transactionInstance!.fieldAccountId.value == account.uniqueId,
    );

    for (final Investment investment in investments) {
      final Security? security = (data.securities as Securities).get(
        investment.fieldSecurity.value,
      );
      if (security != null) {
        final String stockSymbol = security.fieldSymbol.value;
        groupBySymbol.cumulate('${account.uniqueId}|$stockSymbol', investment);
      }
    }
  }

  bool removeAccount(Account a, [bool forceRemoveAfterSave = false]) {
    if (a.isInserted || forceRemoveAfterSave) {
      if (this.containsKey(a.uniqueId)) {
        deleteItem(a);
      }
    }

    // Fix up any transfers that are pointing to this account.
    Iterable<Transaction> view = (this.data.transactions as Transactions).findTransfersToAccount(a);
    if (view.isNotEmpty) {
      for (Transaction u in view) {
        this.data.clearTransferToAccount(u.uniqueId, a);
      }
    }

    view = getTransactions(a);

    for (Transaction t in view) {
      this.data.removeTransaction(t.uniqueId);
    }
    return true;
  }

  void setMostRecentUsedAccount(Account account) {
    PreferenceController.to.setInt(
      getViewPreferenceIdAccountLastSelected(),
      account.fieldId.value,
    );
  }

  void _updateCreditCardPaidOn(final Account account) {
    final List<Transaction> transactionForAccountSortedByDateAscending = (this.data.transactions as Transactions)
        .iterableList()
        .where(
          (Transaction t) => t.fieldAccountId.value == account.uniqueId,
        )
        .toList();
    // sort date as string to match the ListView sorting logic
    transactionForAccountSortedByDateAscending.sort(
      (Transaction a, Transaction b) => Transaction.sortByDateTime(a, b, true),
    );

    double runningBalanceForThisAccount = 0;

    for (final Transaction t in transactionForAccountSortedByDateAscending) {
      runningBalanceForThisAccount += t.fieldAmount.value.asDouble();
      t.balance = runningBalanceForThisAccount;
      t.fieldPaidOn.value = '';
    }

    final int length = transactionForAccountSortedByDateAscending.length - 1;

    for (int i = length; i >= 0; i--) {
      final Transaction t = transactionForAccountSortedByDateAscending[i];
      if (t.fieldAmount.value.asDouble() > 0) {
        // a payment or reimbursement was made

        final DateTime maxDateToLookAt = t.fieldDateTime.value!.subtract(
          const Duration(days: 60),
        );
        final Transaction? transactionWithMatchingBalance = findBackwardInTimeForTransactionBalanceThatMatchThisAmount(
          transactionForAccountSortedByDateAscending,
          i - 1,
          maxDateToLookAt,
          -t.fieldAmount.value.asDouble(),
        );

        if (transactionWithMatchingBalance == null) {
          // t.paidOn.value = doubleToCurrency(statementBalance, '');
        } else {
          transactionWithMatchingBalance.fieldPaidOn.value = '${t.dateTimeAsString} ⤵';
          t.fieldPaidOn.value =
              '${transactionWithMatchingBalance.dateTimeAsString} ⤴${t.fieldPaidOn.value.isNotEmpty ? '⤵' : ''}';
        }
      }
    }
  }
}
