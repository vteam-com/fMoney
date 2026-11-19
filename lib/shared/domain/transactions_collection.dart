// ignore_for_file: prefer_conditional_assignment
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money/data/helpers/accumulator_helper.dart';
import 'package:money/data/models/pair_xyz_model.dart';
import 'package:money/data/models/ranges_model.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/pairs_model.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';

export 'package:money/shared/domain/transaction_entity.dart';

const int _unsetId = -1;
const int _zeroInt = 0;
const double _zeroDouble = 0.0;
const int _yearTokenIndex = 0;
const int _monthTokenIndex = 1;
const int _dayTokenIndex = 2;

/// Represents transactions.
class Transactions extends MoneyObjects<Transaction> {
  Transactions() {
    collectionName = SharedDomainStrings.domainString143;
  }
  late DataAbstract data;

  DateRange dateRangeActiveAccount = DateRange();
  DateRange dateRangeIncludingClosedAccount = DateRange();

  @override
  Transaction instanceFromJson(MyJson json) {
    return Transaction.fromJSon(json, _zeroDouble, data: data);
  }

  /// Now that everything is loaded, adjust relation between MoneyObjects
  @override
  void onAllDataLoaded() {
    // Pre computer possible category matching for Transaction that have no associated categories
    // We use this to give a Hint to the user about the best category to pick for a transaction
    final MapAccumulatorSet<int, String, int> accountsToPayeeNameToCategories = MapAccumulatorSet<int, String, int>();

    final List<Transaction> transactionsWithCategories = getListFlattenSplits();
    for (final Transaction t in transactionsWithCategories) {
      if (t.fieldCategoryId.value != _unsetId) {
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
      if (transactionSource.fieldCategoryId.value == _unsetId) {
        // watchFind.start();
        final Set<int> setOfPossibleCategoryId = accountsToPayeeNameToCategories.find(
          transactionSource.fieldAccountId.value,
          transactionSource.getPayeeOrTransferCaption(),
        );
        transactionSource.possibleMatchingCategoryId = setOfPossibleCategoryId.isEmpty
            ? _unsetId
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

      if (transactionSource.fieldTransferSplit.value > _zeroInt) {
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
      if (transferId == _unsetId) {
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
        if (transactionSource.fieldTransferSplit.value == _unsetId) {
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

  /// Checks all transactions for dangling transfers and populates collections.
  void checkTransfers(
    Set<Transaction> dangling,
    List<Account> deletedAccounts,
  ) {
    for (Transaction t in iterableList()) {
      t.checkTransfers(dangling, deletedAccounts);
    }
  }

  /// Cumulates transactions per year/month for charting.
  static List<FlSpot> cumulateTransactionPerYearMonth(
    List<Transaction> transactions,
    DataAbstract data,
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
    for (final DateTime eventDate in data.getEventDates()) {
      cumulateYearMonthBalance.cumulate(dateToString(eventDate), _zeroDouble);
    }

    final List<FlSpot> tmpDataPoints = <FlSpot>[];
    cumulateYearMonthBalance.getEntries().forEach((
      MapEntry<String, double> entry,
    ) {
      final List<String> tokens = entry.key.split('-');
      final DateTime dateForYearMonth = DateTime(
        int.parse(tokens[_yearTokenIndex]),
        int.parse(tokens[_monthTokenIndex]),
        int.parse(tokens[_dayTokenIndex]),
      );
      tmpDataPoints.add(
        FlSpot(dateForYearMonth.millisecondsSinceEpoch.toDouble(), entry.value),
      );
    });

    tmpDataPoints.sort((FlSpot a, FlSpot b) => a.x.compareTo(b.x));

    double netWorth = _zeroDouble;
    final List<FlSpot> tmpDataPointsWithNetWorth = <FlSpot>[];
    for (final FlSpot dp in tmpDataPoints) {
      netWorth += dp.y;
      tmpDataPointsWithNetWorth.add(FlSpot(dp.x, netWorth));
    }

    return tmpDataPointsWithNetWorth;
  }

  /// match amount and date YYYY,MM,DD, optionally restrict to a specific account by passing -1
  ///
  /// [includeDeleted] keeps deleted rows as candidates (the historical default).
  /// Transactions in [excluded] are never returned, so callers can match each
  /// existing transaction at most once. When [fitid] is a bank-issued id, a
  /// transaction with the same FITID wins regardless of date/amount, and an
  /// amount/date match carrying a different bank-issued FITID is not a match.
  /// Ids generated by the CSV/XLSX importers are not bank-issued and are ignored.
  Transaction? findExistingTransaction({
    required int accountId,
    required DateRange dateRange,
    required double amount,
    bool includeDeleted = true,
    String fitid = '',
    Set<Object> excluded = const <Object>{},
  }) {
    // 'xlsx_row_' is no longer generated but may still be stored in older files.
    const List<String> generatedFitidPrefixes = <String>[
      SharedStrings.fitidPrefixCsvRow,
      'xlsx_row_',
      '${SharedStrings.importTypeInvestmentCsv}_',
    ];

    /// Returns [value] when it is a bank-issued FITID, otherwise an empty string.
    String bankFitid(String value) =>
        generatedFitidPrefixes.any((String prefix) => value.startsWith(prefix)) ? '' : value.trim();

    final String importedFitid = bankFitid(fitid);
    final Iterable<Transaction> candidates = iterableList(includeDeleted: includeDeleted).where(
      (Transaction transaction) =>
          !excluded.contains(transaction) && (accountId == _unsetId || transaction.fieldAccountId.value == accountId),
    );

    if (importedFitid.isNotEmpty) {
      final Transaction? sameFitid = candidates.firstWhereOrNull(
        (Transaction transaction) => bankFitid(transaction.fieldFitid.value) == importedFitid,
      );
      if (sameFitid != null) {
        return sameFitid;
      }
    }

    return candidates.firstWhereOrNull((Transaction transaction) {
      if (transaction.fieldAmount.value.asDouble() != amount ||
          !dateRange.isBetweenEqual(transaction.fieldDateTime.value)) {
        return false;
      }
      final String existingFitid = bankFitid(transaction.fieldFitid.value);
      return importedFitid.isEmpty || existingFitid.isEmpty || existingFitid == importedFitid;
    });
  }

  /// Returns transfers that point to the given account.
  Iterable<Transaction> findTransfersToAccount(Account a) {
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

  /// Sorts [list] by date (then id, so same-day order is stable) and stores the
  /// running total of the amounts in each [Transaction.balance].
  static void applyRunningBalance(List<Transaction> list) {
    list.sort((Transaction a, Transaction b) => Transaction.sortByDateTime(a, b, true));
    double runningBalance = _zeroDouble;
    for (final Transaction transaction in list) {
      runningBalance += transaction.fieldAmount.value.asDouble();
      transaction.balance = runningBalance;
    }
  }

  /// Flattens split transactions into individual entries, see [_flattenSplits].
  static List<Transaction> flatTransactions(
    Iterable<Transaction> transactions,
  ) {
    return transactions.expand(_flattenSplits).toList();
  }

  /// Returns [t] itself, or one stand-in transaction per split row when [t] has splits.
  ///
  /// Each stand-in keeps the parent's date, status and account, takes the split's
  /// category, memo and amount, and uses the split's payee when it has one.
  static Iterable<Transaction> _flattenSplits(Transaction t) {
    if (!t.isSplit) {
      return <Transaction>[t];
    }
    return t.splits.map(
      (TransactionSplit s) =>
          Transaction(
              date: t.fieldDateTime.value,
              status: t.fieldStatus.value,
            )
            ..fieldAccountId.value = t.fieldAccountId.value
            ..fieldPayee.value = s.fieldPayeeId.value == _unsetId ? t.fieldPayee.value : s.fieldPayeeId.value
            ..fieldCategoryId.value = s.fieldCategoryId.value
            ..fieldMemo.value = s.fieldMemo.value
            ..fieldAmount.value = s.fieldAmount.value,
    );
  }

  /// Returns all unique transaction dates for a given year.
  List<DateTime> getAllTransactionDatesForYear(int year) {
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

  /// Returns transactions with splits flattened; optional filter.
  List<Transaction> getListFlattenSplits({
    bool Function(Transaction)? whereClause,
  }) {
    return flatTransactions(
      iterableList().where((Transaction t) => whereClause == null || whereClause(t)),
    );
  }

  /// Returns the transactions dated from [minYear] to [maxYear] (inclusive) that are not pending
  /// deletion and match [where] when given, with each split transaction listed as its split lines.
  List<Transaction> getListFlattenSplitsInYearRange({
    required int minYear,
    required int maxYear,
    bool Function(Transaction)? where,
  }) => getListFlattenSplits(
    whereClause: (Transaction t) =>
        isBetweenOrEqual(t.fieldDateTime.value!.year, minYear, maxYear) && (where == null || where(t)),
  );

  /// Filters transactions within a year range and optional income/expense.
  Iterable<Transaction> transactionInYearRange({
    required int minYear,
    required int maxYear,
    required bool? incomesOrExpenses,
  }) {
    return iterableList(includeDeleted: true).where(
      (Transaction element) =>
          isBetweenOrEqual(
            element.fieldDateTime.value!.year,
            minYear,
            maxYear,
          ) &&
          (incomesOrExpenses == null ||
              (incomesOrExpenses == true && element.fieldAmount.value.asDouble() > _zeroDouble) ||
              (incomesOrExpenses == false && element.fieldAmount.value.asDouble() < _zeroDouble)),
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
    List<Transaction> transactions,
    String Function(DateTime) keyGenerator,
  ) {
    final Map<String, double> sums = <String, double>{};

    for (final Transaction t in transactions) {
      final String key = keyGenerator(t.fieldDateTime.value!);
      sums[key] = (sums[key] ?? _zeroDouble) + t.fieldAmount.value.asDouble();
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
