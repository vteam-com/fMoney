// ignore_for_file: prefer_conditional_assignment
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money/data/data_interface.dart';
import 'package:money/data/event.dart';
import 'package:money/data/money_split.dart';
import 'package:money/data/transaction.dart';
import 'package:money/helpers/accumulator.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/pairs.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/models/account.dart';
import 'package:money/models/money_objects.dart';
import 'package:money/widgets/charts/chart.dart';

export 'package:money/data/transaction.dart';

class Transactions extends MoneyObjects<Transaction> {
  Transactions() {
    collectionName = 'Transactions';
  }
  late DataInterface data;

  DateRange dateRangeActiveAccount = DateRange();
  DateRange dateRangeIncludingClosedAccount = DateRange();
  double runningBalance = 0.00;

  @override
  void loadFromJson(final List<MyJson> rows) {
    clear();

    runningBalance = 0.00;

    for (final MyJson row in rows) {
      final Transaction t = Transaction.fromJSon(row, runningBalance);
      runningBalance += t.balance;
      appendMoneyObject(t);
    }
  }

  /// Now that everything is loaded, adjust relation between MoneyObjects
  @override
  void onAllDataLoaded() {
    // Pre computer possible category matching for Transaction that have no associated categories
    // We use this to give a Hint to the user about the best category to pick for a transaction
    final MapAccumulatorSet<int, String, int> accountsToPayeeNameToCategories = MapAccumulatorSet<int, String, int>();

    final List<Transaction> transactionsWithCategories = getListFlattenSplits();
    for (final Transaction t in transactionsWithCategories) {
      if (t.fieldCategoryId.value != -1) {
        accountsToPayeeNameToCategories.cumulate(
          t.fieldAccountId.value,
          t.getPayeeOrTransferCaption(),
          t.fieldCategoryId.value,
        );
      }
    }

    // watchInit.stop();
    // debugInfo('getListFlattenSplits: ${watchInit.elapsedMilliseconds} ms');

    // Stopwatch watchFind = Stopwatch();
    dateRangeActiveAccount.clear();
    dateRangeIncludingClosedAccount.clear();

    for (final Transaction transactionSource in iterableList()) {
      // Pre computer possible category matching for Transaction that have no associated categories
      if (transactionSource.fieldCategoryId.value == -1) {
        // watchFind.start();
        final Set<int> setOfPossibleCategoryId = accountsToPayeeNameToCategories.find(
          transactionSource.fieldAccountId.value,
          transactionSource.getPayeeOrTransferCaption(),
        );
        transactionSource.possibleMatchingCategoryId = setOfPossibleCategoryId.isEmpty
            ? -1
            : setOfPossibleCategoryId.first;
        // watchFind.stop();
      }

      // Computer date range of all transactions
      dateRangeIncludingClosedAccount.inflate(
        transactionSource.fieldDateTime.value,
      );
      if (transactionSource.instanceOfAccount?.isOpen == true) {
        dateRangeActiveAccount.inflate(transactionSource.fieldDateTime.value);
      }

      // Resolve the Transfers
      final int transferId = transactionSource.fieldTransfer.value;
      transactionSource.instanceOfTransfer = null;

      if (transactionSource.fieldTransferSplit.value > 0) {
        // deal with transfer of split
        // Split transfer
        // if (transactionSource.transferSplit.value != -1) {
        //   final Split? s = Data().splits.get(transactionSource.transferSplit.value);
        //   if (s == null) {
        //     debugInfo('Transaction contains a split marked as a transfer, but other side of transfer was not found');
        //     continue;
        //   }
        //
        //   if (transactionSource.transferInstance == null) {
        //     transactionSource.transferInstance =
        //         Transfer(id: transferId, source: transactionSource, related: transactionRelated, relatedSplit: s);
        //     continue;
        //   }
        // debugInfo('Already have a transfer for this split');
        // }
        continue;
      }

      // Simple Transfer
      if (transferId == -1) {
        if (transactionSource.instanceOfTransfer == null) {
          // this is correct
        } else {
          // this needs to be cleared
          // TODO - should the other side transaction be cleared too?
          transactionSource.instanceOfTransfer = null;
        }
      } else {
        // hook up the transfer relation
        final Transaction? transactionRelated = get(transferId);

        // check for error
        if (transactionRelated == null) {
          logger.e(
            'Transaction.transferID of ${transactionSource.uniqueId} missing related transaction id $transferId',
          );
          continue;
        }

        // hydrate the Transfer
        if (transactionSource.fieldTransferSplit.value == -1) {
          // Normal direct transfer
          linkTransfer(transactionSource, transactionRelated);
          continue;
        }
      }
    }

    // make sure that we have valid min max dates
    dateRangeIncludingClosedAccount.ensureNoNullDates();
    dateRangeActiveAccount.ensureNoNullDates();
  }

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }

  void checkTransfers(
    Set<Transaction> dangling,
    List<Account> deletedAccounts,
  ) {
    for (Transaction t in iterableList()) {
      t.checkTransfers(dangling, deletedAccounts);
    }
  }

  static List<FlSpot> cumulateTransactionPerYearMonth(
    final List<Transaction> transactions,
    DataInterface data,
  ) {
    final AccumulatorSum<String, double> cumulateYearMonthBalance = AccumulatorSum<String, double>();

    // Add transactions to the accumulator
    for (final Transaction t in transactions) {
      final String dateKey = dateToString(t.fieldDateTime.value);
      cumulateYearMonthBalance.cumulate(
        dateKey,
        t.fieldAmount.value.asDouble(),
      );
    }

    // Add events to the accumulator with zero amount
    for (final Event event in data.events.iterableList() as Iterable<Event>) {
      final String dateKey = dateToString(event.fieldDateBegin.value);
      cumulateYearMonthBalance.cumulate(dateKey, 0.0);
    }

    final List<FlSpot> tmpDataPoints = <FlSpot>[];
    cumulateYearMonthBalance.getEntries().forEach((
      MapEntry<String, double> entry,
    ) {
      final List<String> tokens = entry.key.split('-');
      final DateTime dateForYearMonth = DateTime(
        int.parse(tokens[0]),
        int.parse(tokens[1]),
        int.parse(tokens[2]),
      );
      tmpDataPoints.add(
        FlSpot(dateForYearMonth.millisecondsSinceEpoch.toDouble(), entry.value),
      );
    });

    tmpDataPoints.sort((FlSpot a, FlSpot b) => a.x.compareTo(b.x));

    double netWorth = 0;
    final List<FlSpot> tmpDataPointsWithNetWorth = <FlSpot>[];
    for (final FlSpot dp in tmpDataPoints) {
      netWorth += dp.y;
      tmpDataPointsWithNetWorth.add(FlSpot(dp.x, netWorth));
    }

    return tmpDataPointsWithNetWorth;
  }

  /// match amount and date YYYY,MM,DD, optionally restrict to a specific account by passing -1
  Transaction? findExistingTransaction({
    required final int accountId,
    required final DateRange dateRange,
    required final double amount,
  }) {
    return iterableList(includeDeleted: true).firstWhereOrNull((
      Transaction transaction,
    ) {
      if ((accountId == -1 || transaction.fieldAccountId.value == accountId) &&
          transaction.fieldAmount.value.asDouble() == amount &&
          dateRange.isBetweenEqual(transaction.fieldDateTime.value)) {
        return true;
      }

      return false;
    });
  }

  int findPossibleMatchingCategoryId(
    final Transaction t,
    List<Transaction> transactionWithCategories,
  ) {
    final Transaction? transactionMatchingAccountPayeeAndHasCategory = transactionWithCategories.firstWhereOrNull(
      (Transaction item) =>
          item.fieldAccountId.value == t.fieldAccountId.value &&
          item.getPayeeOrTransferCaption() == t.getPayeeOrTransferCaption(),
    );
    if (transactionMatchingAccountPayeeAndHasCategory != null) {
      return transactionMatchingAccountPayeeAndHasCategory.fieldCategoryId.value;
    }
    return -1;
  }

  Iterable<Transaction> findTransfersToAccount(final Account a) {
    final List<Transaction> view = <Transaction>[];
    for (Transaction t in iterableList()) {
      if (t.isDeleted) {
        continue;
      }

      if (t.containsTransferTo(a)) {
        view.add(t);
      }
    }
    // view.sort(SortByDate);
    return view;
  }

  static List<Transaction> flatTransactions(
    final Iterable<Transaction> transactions,
  ) {
    final List<Transaction> flatList = <Transaction>[];
    for (final Transaction t in transactions) {
      if (t.isSplit) {
        for (final MoneySplit s in t.splits) {
          final Transaction fakeTransaction = Transaction(
            date: t.fieldDateTime.value,
            status: t.fieldStatus.value,
          );
          fakeTransaction.fieldAccountId.value = t.fieldAccountId.value;
          fakeTransaction.fieldPayee.value = t.fieldPayee.value;
          fakeTransaction.fieldCategoryId.value = s.fieldCategoryId.value;
          fakeTransaction.fieldMemo.value = s.fieldMemo.value;
          fakeTransaction.fieldAmount.value = s.fieldAmount.value;
          flatList.add(fakeTransaction);
        }
      } else {
        flatList.add(t);
      }
    }
    return flatList;
  }

  List<DateTime> getAllTransactionDatesForYear(final int year) {
    final Iterable<Transaction> transactions = transactionInYearRange(
      minYear: year,
      maxYear: year,
      incomesOrExpenses: null,
    );
    final List<DateTime> dates = <DateTime>[];
    for (final Transaction t in transactions) {
      if (t.fieldDateTime.value?.year == year && !dates.contains(t.fieldDateTime.value)) {
        dates.add(t.fieldDateTime.value!);
      }
    }
    return dates;
  }

  List<Transaction> getListFlattenSplits({
    final bool Function(Transaction)? whereClause,
  }) {
    final List<Transaction> flattenList = <Transaction>[];
    for (final Transaction t in iterableList()) {
      if (whereClause == null || whereClause(t)) {
        if (t.fieldCategoryId.value == data.categories.splitCategoryId()) {
          for (final MoneySplit s in t.splits) {
            final Transaction fakeT =
                Transaction(
                    date: t.fieldDateTime.value,
                    status: t.fieldStatus.value,
                  )
                  ..fieldAccountId.value = t.fieldAccountId.value
                  ..fieldPayee.value = s.fieldPayeeId.value == -1 ? t.fieldPayee.value : s.fieldPayeeId.value
                  ..fieldCategoryId.value = s.fieldCategoryId.value
                  ..fieldMemo.value = s.fieldMemo.value
                  ..fieldAmount.value = s.fieldAmount.value;

            flattenList.add(fakeT);
          }
        } else {
          flattenList.add(t);
        }
      }
    }
    return flattenList;
  }

  Iterable<Transaction> transactionInYearRange({
    required final int minYear,
    required final int maxYear,
    required final bool? incomesOrExpenses,
  }) {
    return iterableList(includeDeleted: true).where(
      (Transaction element) =>
          isBetweenOrEqual(
            element.fieldDateTime.value!.year,
            minYear,
            maxYear,
          ) &&
          (incomesOrExpenses == null ||
              (incomesOrExpenses == true && element.fieldAmount.value.asDouble() > 0) ||
              (incomesOrExpenses == false && element.fieldAmount.value.asDouble() < 0)),
    );
  }

  /// Aggregates transactions by a custom key generated from their date and sums their amounts.
  ///
  /// This method takes a list of [transactions] and a [keyGenerator] function.
  /// The [keyGenerator] function takes a [DateTime] object (the transaction date) and
  /// returns a [String] that will be used as the key to group transactions.
  ///
  /// The function returns a list of [PairXYY] objects. Each [PairXYY] represents a group
  /// of transactions with the same key. The `x` value of the [PairXYY] is the generated
  /// key (a string), and the `y` value is the sum of the amounts of all transactions
  /// in that group.
  ///
  /// The returned list is sorted alphabetically by the `x` value (the generated key).
  ///
  /// Example:
  /// ```dart
  /// // Group transactions by month and year (e.g., "2024-01", "2024-02")
  /// List<PairXY> monthlySums = Transactions.transactionSumBy(
  ///   transactions,
  ///   (dateTime) => "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}",
  /// );
  /// ```
  static List<PairXYY> transactionSumBy(
    final List<Transaction> transactions,
    final String Function(DateTime) keyGenerator,
  ) {
    final Map<String, double> sums = <String, double>{};

    for (final Transaction t in transactions) {
      final String key = keyGenerator(t.fieldDateTime.value!);
      sums[key] = (sums[key] ?? 0) + t.fieldAmount.value.asDouble();
    }

    final List<PairXYY> result = sums.entries.map((MapEntry<String, double> e) => PairXYY(e.key, e.value)).toList();
    result.sort((PairXYY a, PairXYY b) => a.xText.compareTo(b.xText));
    return result;
  }

  /// Aggregates transactions by day and sums their amounts.
  ///
  /// This method takes a list of [transactions] and returns a list of
  /// [Pair<int, double>] objects. Each [Pair] represents a day's worth of
  /// transactions.
  ///
  /// The `first` value of the [Pair] is the number of days since the epoch
  /// (millisecondsSinceEpoch ~/ Duration.millisecondsPerDay), representing the day.
  /// The `second` value of the [Pair] is the sum of the amounts of all transactions
  /// on that day.
  ///
  /// The returned list is sorted chronologically by the `first` value (the day).
  static List<Pair<int, double>> transactionSumByTime(
    List<Transaction> transactions,
  ) {
    final List<Pair<int, double>> timeAndAmounts = <Pair<int, double>>[];
    for (final Transaction t in transactions) {
      final int oneDaySlot = t.fieldDateTime.value!.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
      timeAndAmounts.add(
        Pair<int, double>(oneDaySlot, t.fieldAmount.value.asDouble()),
      );
    }
    // sort by date time
    timeAndAmounts.sort(
      (Pair<int, double> a, Pair<int, double> b) => a.first.compareTo(b.first),
    );
    return timeAndAmounts;
  }
}
