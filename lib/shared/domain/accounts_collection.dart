// ignore_for_file: unnecessary_this

import 'dart:math';
import 'dart:ui' show Color;

import 'package:collection/collection.dart';
import 'package:money/data/helpers/accumulator_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/data/models/stock_summary_model.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/investments_collection.dart';
import 'package:money/shared/domain/loan_payment_entity.dart';
import 'package:money/shared/domain/loan_payments_collection.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/securities_collection.dart';
import 'package:money/shared/domain/transaction_operations_interface.dart';
import 'package:money/shared/domain/transactions_collection.dart';

/// Statement segment gradient start color (accrual start).
const Color _segmentGradientStart = Color.fromARGB(255, 249, 175, 4); // red

/// Statement segment gradient end color (payment row).
const Color _segmentGradientEnd = Color(0xFF43A047); // green

const int _zeroInt = 0;
const int _oneInt = 1;
const double _zeroDouble = 0.0;
const double _negativeMultiplier = -1.0;
const int _decimalBase = 10;
const int _defaultPrecision = 2;
const int _intBitCount = 32;
const int _creditCardLookbackDays = 60;

/// Represents accounts.
class Accounts extends MoneyObjects<Account> with NamedMoneyObjects<Account> {
  Accounts() {
    collectionName = SharedDomainStrings.domainString014;
  }
  late DataAbstract data;

  /// Returns whether account lists include closed accounts; bound to the user preference by the presentation layer.
  bool Function() isIncludingClosedAccounts = () => false;

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
        if (account.isInvestmentAccount()) {
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
    for (final Account account in iterableList().where((Account account) => account.isInvestmentAccount())) {
      final double holdingsValue = holdingsOf(account).fold(
        _zeroDouble,
        (double sum, StockSummary holding) => sum + holding.holdingValue,
      );
      account.fieldStockHoldingEstimation.value.setAmount(holdingsValue);
      account.balance += holdingsValue;
    }

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

  /// Returns sorted account names for display.
  List<String> getSortedAccountNames() {
    return getListSorted().map((Account a) => a.fieldName.value).toList();
  }

  /// Returns the holdings of [account], one per security symbol with shares: the shares adjusted
  /// for splits, the current share price (0 when no security has the symbol) and the average cost.
  List<StockSummary> holdingsOf(Account account) {
    final AccumulatorList<String, Investment> investmentsBySymbol = AccumulatorList<String, Investment>();
    for (final Investment investment in this.data.getInvestments().cast<Investment>()) {
      final Security? security = this.data.getSecurity(investment.fieldSecurity.value) as Security?;
      if (security != null && investment.transactionInstance?.fieldAccountId.value == account.uniqueId) {
        investmentsBySymbol.cumulate(security.fieldSymbol.value, investment);
      }
    }

    final List<StockSummary> holdings = <StockSummary>[];
    investmentsBySymbol.values.forEach((String symbol, Set<Investment> investments) {
      final double shares = Investments.applyHoldingSharesAdjustedForSplits(investments.toList());
      if (!isConsideredZero(shares)) {
        final double cost = investments.fold(
          _zeroDouble,
          (double sum, Investment investment) => sum + investment.costForShares,
        );
        final Security? security = this.data.getSecurityBySymbol(symbol) as Security?;
        holdings.add(
          StockSummary(
            symbol: symbol,
            shares: shares,
            sharePrice: security?.fieldPrice.value.asDouble() ?? _zeroDouble,
            averageCost: cost / shares,
          ),
        );
      }
    });
    return holdings;
  }

  /// Lists only the accounts matching the user's choice about closed accounts, and no category funds.
  @override
  bool isListed(Account item) =>
      _isMatchingUserChoiceIncludingClosedAccount(item) && item.fieldType.value != AccountType.categoryFund;

  @override
  String nameOf(Account item) => item.fieldName.value;

  /// Shows an account id that no account has as the id itself.
  @override
  String nameOfMissingId(int id) => id.toString();

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
      if (_isMatchingUserChoiceIncludingClosedAccount(account)) {
        sum += (account.fieldBalanceNormalized.getValueForDisplay(account) as AmountModel).asDouble();
      }
    }
    return sum;
  }

  /// Returns all transactions associated with the given [account].
  Iterable<Transaction> getTransactions(Account account) => transactionsOf(account, this.data);

  /// Returns the live transactions of [account] in [data].
  static Iterable<Transaction> transactionsOf(Account account, TransactionOperations data) {
    return data.getTransactions().cast<Transaction>().where(
      (Transaction t) => t.fieldAccountId.value == account.uniqueId,
    );
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

  /// Updates the `paidOn` markers for credit card transactions based on matching statement payments.
  void _updateCreditCardPaidOn(Account account) {
    final List<Transaction> transactionForAccountSortedByDateAscending = getTransactions(account).toList();
    Transactions.applyRunningBalance(transactionForAccountSortedByDateAscending);

    for (final Transaction t in transactionForAccountSortedByDateAscending) {
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
            final String deltaStr =
                sign + getAmountAsStringUsingCurrency(delta.abs(), iso4217code: account.getAccountCurrencyAsText());
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

  /// True if [account] is open, or closed accounts are included by the user's choice.
  bool _isMatchingUserChoiceIncludingClosedAccount(Account account) {
    return isIncludingClosedAccounts() || account.isOpen;
  }
}
