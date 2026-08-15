// ignore_for_file: unnecessary_this

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' show Color;
import 'package:money/data/helpers/accumulator_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/investments_collection.dart';
import 'package:money/shared/domain/loan_payment_entity.dart';
import 'package:money/shared/domain/loan_payments_collection.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/securities_collection.dart';
import 'package:money/shared/domain/transactions_collection.dart';
import 'package:money/widgets/state/preferences_controller.dart';

/// Statement segment gradient start color (accrual start).
const Color _segmentGradientStart = Color.fromARGB(255, 249, 175, 4); // red

/// Statement segment gradient end color (payment row).
const Color _segmentGradientEnd = Color(0xFF43A047); // green

const int _zeroInt = 0;
const int _oneInt = 1;
const int _unsetId = -1;
const double _zeroDouble = 0.0;
const double _negativeMultiplier = -1.0;
const int _decimalBase = 10;
const int _defaultPrecision = 2;
const int _accountTokenIndex = 0;
const int _symbolTokenIndex = 1;
const int _intBitCount = 32;
const int _creditCardLookbackDays = 60;

/// Represents accounts.
class Accounts extends MoneyObjects<Account> {
  Accounts() {
    collectionName = SharedDomainStrings.domainString014;
  }
  late DataAbstract data;

  @override
  Account instanceFromJson(MyJson json) {
    return Account.fromJson(json);
  }

  @override
  void onAllDataLoaded() {
    for (final Account account in iterableList()) {
      account.fieldCount.value = _zeroInt;
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
    final List<Transaction> transactionsSortedByDate = this.data
        .getTransactions()
        .cast<Transaction>()
        .sorted(
          (Transaction a, Transaction b) => sortByDate(a.fieldDateTime.value, b.fieldDateTime.value),
        )
        .toList();

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
            account.minBalancePerYears[yearOfTheTransaction] ?? IntValues.maxSigned(_intBitCount).toDouble();
        account.minBalancePerYears[yearOfTheTransaction] = min(
          currentMinBalanceValue,
          account.balance,
        );

        // Max Balance of the year
        final double currentMaxBalanceValue =
            account.maxBalancePerYears[yearOfTheTransaction] ?? IntValues.minSigned(_intBitCount).toDouble();
        account.maxBalancePerYears[yearOfTheTransaction] = max(
          currentMaxBalanceValue,
          account.balance,
        );

        // keep track of the most recent record transaction for the account
        if (t.fieldDateTime.value != null) {
          if (account.fieldUpdatedOn.value == null ||
              account.fieldUpdatedOn.value!.compareTo(t.fieldDateTime.value!) < _zeroInt) {
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
      final String accountId = tokens[_accountTokenIndex];
      final String symbol = tokens[_symbolTokenIndex];
      final Account? account = this.get(int.parse(accountId));
      if (account != null) {
        final Security? security = this.data.getSecurityBySymbol(symbol) as Security?;
        if (security != null) {
          account.fieldStockHoldingEstimation.value.setAmount(
            totalAdjustedShareForThisStockInThisAccount * security.fieldLastPrice.value.asDouble(),
          );
          if (account.fieldStockHoldingEstimation.value.asDouble() != _zeroDouble) {
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
        account.balance = latestPayment.fieldBalance.value.asDouble() * _negativeMultiplier;
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

  /// Returns active accounts filtered by [types] and optional [isActive] status.
  List<Account> activeAccounts(
    List<AccountType> types, {
    bool? isActive = true,
  }) {
    return iterableList().where((Account item) {
      if (!item.matchType(types)) {
        return false;
      }
      if (isActive == null) {
        return true;
      }
      return item.isOpen == isActive;
    }).toList();
  }

  /// Creates and adds a new account with a unique name derived from [accountName].
  Account addNewAccount(String accountName) {
    // find next available name
    String nextAvailableName = accountName;
    int next = _oneInt;
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

  /// Compares two doubles [a] and [b] within a given [precision].
  bool compareDoubles(double a, double b, int precision) {
    final num threshold = pow(_decimalBase, -precision);
    return (a - b).abs() < threshold;
  }

  /// Find a transaction that has a date in the future but not more than 2 months and has inverse amount
  Transaction? findBackwardInTimeForTransactionBalanceThatMatchThisAmount(
    List<Transaction> transactionForAccountSortedByDateAscending,
    int indexStartingFrom,
    DateTime validDateInThePast,
    double amountToMatch,
  ) {
    for (int i = indexStartingFrom; i >= _zeroInt; i--) {
      final Transaction t = transactionForAccountSortedByDateAscending[i];

      if (t.fieldDateTime.value!.isBefore(validDateInThePast)) {
        return null; // out of range break early
      }

      if (compareDoubles(t.balance, amountToMatch, _defaultPrecision)) {
        return t;
      }
    }

    return null;
  }

  /// Finds the transaction in [transactions] within the look-back window whose
  /// running [balance] is closest to [amountToMatch].
  ///
  /// Used to produce a diagnostic hint when no exact statement-balance match
  /// exists for a credit card payment, revealing missing or extra transactions.
  Transaction? _findClosestMatchInWindow(
    List<Transaction> transactions,
    int indexStartingFrom,
    DateTime validDateInThePast,
    double amountToMatch,
  ) {
    Transaction? closest;
    double smallestDelta = double.infinity;
    for (int i = indexStartingFrom; i >= _zeroInt; i--) {
      final Transaction t = transactions[i];
      if (t.fieldDateTime.value!.isBefore(validDateInThePast)) {
        break;
      }
      final double delta = (t.balance - amountToMatch).abs();
      if (delta < smallestDelta) {
        smallestDelta = delta;
        closest = t;
      }
    }
    return closest;
  }

  /// Finds an account by ID and optional account type.
  Account? findByIdAndType(
    String accountId,
    AccountType? accountType,
  ) {
    return iterableList().firstWhereOrNull((Account account) {
      return account.fieldAccountId.value == accountId &&
          (accountType == null || account.fieldType.value == accountType);
    });
  }

  /// Finds an account by name (case-insensitive).
  Account? getByName(String name) {
    return iterableList().firstWhereOrNull((Account item) {
      return stringCompareIgnoreCasing(item.fieldName.value, name) == _zeroInt;
    });
  }

  /// Returns a sorted list of accounts matching user choice (excluding category funds).
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

  /// Returns sorted account names for display.
  List<String> getSortedAccountNames() {
    return getListSorted().map((Account a) => a.fieldName.value).toList();
  }

  /// Returns the most recently selected account, or the first account if none selected.
  Account getMostRecentlySelectedAccount() {
    final int lastSelectionId = PreferenceController.to.getInt(
      getViewPreferenceIdAccountLastSelected(),
      _unsetId,
    );
    if (lastSelectionId != _unsetId) {
      final Account? accountExist = get(lastSelectionId);
      if (accountExist != null) {
        return accountExist;
      }
    }

    return firstItem()!;
  }

  /// Gets the account name for the given [id]; returns the ID as string if not found.
  String getNameFromId(int id) {
    final Account? account = get(id);
    if (account == null) {
      return id.toString();
    }
    return account.fieldName.value;
  }

  /// Returns all open accounts.
  List<Account> getOpenAccounts() {
    return iterableList().where((Account account) => account.isOpen).toList();
  }

  /// Returns open, non-fake (real) accounts only.
  List<Account> getOpenRealAccounts() {
    return iterableList()
        .where(
          (Account account) => !account.isFakeAccount() && account.isOpen,
        )
        .toList();
  }

  /// Computes the sum of balances for accounts matching user choice.
  double getSumOfAccountBalances() {
    double sum = _zeroDouble;

    for (final Account account in iterableList()) {
      if (account.isMatchingUserChoiceIncludingClosedAccount) {
        sum += (account.fieldBalanceNormalized.getValueForDisplay(account) as AmountModel).asDouble();
      }
    }
    return sum;
  }

  /// Returns all transactions associated with the given [account].
  Iterable<Transaction> getTransactions(Account account) {
    return this.data.getTransactions().cast<Transaction>().where(
      (Transaction t) => t.fieldAccountId.value == account.uniqueId,
    );
  }

  /// Preference key for the last selected account in the accounts view.
  String getViewPreferenceIdAccountLastSelected() {
    return ViewId.viewAccounts.getViewPreferenceId(
      settingKeySelectedListItemId,
    );
  }

  /// Groups investments by stock symbol for the given [account].
  static void groupAccountStockSymbols(
    Account account,
    AccumulatorList<String, Investment> groupBySymbol,
    DataAbstract data,
  ) {
    final Iterable<Investment> investments = data.getInvestments().cast<Investment>().where(
      (Investment i) => i.transactionInstance!.fieldAccountId.value == account.uniqueId,
    );

    for (final Investment investment in investments) {
      final Security? security = data.getSecurity(
        investment.fieldSecurity.value,
      ) as Security?;
      if (security != null) {
        final String stockSymbol = security.fieldSymbol.value;
        groupBySymbol.cumulate('${account.uniqueId}|$stockSymbol', investment);
      }
    }
  }

  /// Removes an account and cleans up related transfers and transactions.
  bool removeAccount(Account a, [bool forceRemoveAfterSave = false]) {
    if (a.isInserted || forceRemoveAfterSave) {
      if (this.containsKey(a.uniqueId)) {
        deleteItem(a);
      }
    }

    // Fix up any transfers that are pointing to this account.
    Iterable<Transaction> view = this.data.findTransfersToAccount(a).cast<Transaction>();
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

  /// Sets the most recently used account preference.
  void setMostRecentUsedAccount(Account account) {
    PreferenceController.to.setInt(
      getViewPreferenceIdAccountLastSelected(),
      account.fieldId.value,
    );
  }

  /// Updates the `paidOn` markers for credit card transactions based on matching statement payments.
  void _updateCreditCardPaidOn(Account account) {
    final List<Transaction> transactionForAccountSortedByDateAscending = this.data
        .getTransactions()
        .cast<Transaction>()
        .where(
          (Transaction t) => t.fieldAccountId.value == account.uniqueId,
        )
        .toList();
    // sort date as string to match the ListView sorting logic
    transactionForAccountSortedByDateAscending.sort(
      (Transaction a, Transaction b) => Transaction.sortByDateTime(a, b, true),
    );

    double runningBalanceForThisAccount = _zeroDouble;

    for (final Transaction t in transactionForAccountSortedByDateAscending) {
      runningBalanceForThisAccount += t.fieldAmount.value.asDouble();
      t.balance = runningBalanceForThisAccount;
      t.fieldPaidOn.value = '';
      t.pairHighlightColor = null;
      t.pairHighlightTopCap = false;
      t.pairHighlightBottomCap = false;
    }

    final int length = transactionForAccountSortedByDateAscending.length - _oneInt;

    // Pass 2: walk backward, match payments to statement balances and assign
    // fieldPaidOn text.  Color is stored on the payment row only — Pass 3 fills
    // the full region.
    for (int i = length; i >= _zeroInt; i--) {
      final Transaction t = transactionForAccountSortedByDateAscending[i];
      if (t.fieldAmount.value.asDouble() > _zeroDouble && t.isTransfer) {
        // a credit card payment (transfer from another account)

        final DateTime maxDateToLookAt = t.fieldDateTime.value!.subtract(
          const Duration(days: _creditCardLookbackDays),
        );
        final Transaction? transactionWithMatchingBalance = findBackwardInTimeForTransactionBalanceThatMatchThisAmount(
          transactionForAccountSortedByDateAscending,
          i - _oneInt,
          maxDateToLookAt,
          t.fieldAmount.value.asDouble() * _negativeMultiplier,
        );

        if (transactionWithMatchingBalance == null) {
          // No exact match — find the closest balance to hint at the discrepancy.
          final Transaction? closest = _findClosestMatchInWindow(
            transactionForAccountSortedByDateAscending,
            i - _oneInt,
            maxDateToLookAt,
            t.fieldAmount.value.asDouble() * _negativeMultiplier,
          );
          if (closest != null) {
            final double target = t.fieldAmount.value.asDouble() * _negativeMultiplier;
            final double delta = closest.balance - target;
            final String sign = delta >= _zeroDouble ? '+' : '-';
            final String deltaStr = sign + doubleToCurrency(delta.abs());
            // Payment row is a transfer — it IS the payment, not "paid on" anything.
            t.fieldPaidOn.value = '';
            // Statement-close row: show approximate payment date + discrepancy.
            closest.fieldPaidOn.value = '⚠ ${t.dateTimeAsString} $deltaStr';
          }
        } else {
          // Statement-close row: show the date the balance was paid.
          transactionWithMatchingBalance.fieldPaidOn.value = t.dateTimeAsString;
          // Payment row is the transfer itself — clear its Paid On.
          t.fieldPaidOn.value = '';
        }
      }
    }

    // Pass 3: forward sweep — every transaction belongs to the statement period
    // that ends at the next payment. Paint the full region with a linear
    // gradient from accrual-start red to payment-row green.
    int segmentStart = _zeroInt;
    for (int i = _zeroInt; i <= length; i++) {
      final Transaction t = transactionForAccountSortedByDateAscending[i];
      if (t.fieldAmount.value.asDouble() > _zeroDouble && t.isTransfer) {
        final int segmentLength = i - segmentStart;
        for (int j = segmentStart; j <= i; j++) {
          final double ratio = segmentLength == _zeroInt ? _oneInt.toDouble() : (j - segmentStart) / segmentLength;
          final Transaction segmentRow = transactionForAccountSortedByDateAscending[j];
          segmentRow.pairHighlightColor =
              Color.lerp(_segmentGradientStart, _segmentGradientEnd, ratio) ?? _segmentGradientEnd;
          segmentRow.pairHighlightTopCap = false;
          segmentRow.pairHighlightBottomCap = false;
        }
        transactionForAccountSortedByDateAscending[segmentStart].pairHighlightTopCap = true;
        transactionForAccountSortedByDateAscending[i].pairHighlightBottomCap = true;
        segmentStart = i + _oneInt;
      }
    }
  }
}
