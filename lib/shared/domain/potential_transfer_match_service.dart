import 'package:collection/collection.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transfer_entity.dart';

/// Default day window used when searching potential transfer counterparts.
const int potentialTransferDefaultMaxDays = 3;

/// Default maximum number of candidates returned by the finder.
const int potentialTransferDefaultMaxResults = 5;

/// Absolute amount tolerance for treating two amounts as opposites.
const double _amountTolerance = 0.005;

/// Cents per currency unit; amounts within [_amountTolerance] land in the same or an adjacent cents bucket.
const int _centsPerUnit = 100;

/// Milliseconds in one day, used to number calendar days.
const int _millisecondsPerDay = Duration.millisecondsPerDay;

/// Id meaning "none" for categories.
const int _unsetId = -1;

/// Id given to display-only transfers built for previews.
const int _previewTransferId = 0;

/// Transfer-matching index over a pool of eligible transactions.
///
/// Transactions are grouped by amount sign, calendar day and cents bucket so each lookup only visits
/// opposite-sign entries in nearby days and buckets. Transactions that have an opposite entry in their own
/// account (a refund or a correction) are set aside: they never match and are never matched.
class _TransferMatchIndex {
  /// Indexes [pool] for matches dated at most [maxDays] days apart.
  _TransferMatchIndex(List<Transaction> pool, this.maxDays) : _neutralCategoryIds = _transferAndSplitCategoryIds(pool) {
    for (final Transaction transaction in pool) {
      final DateTime? date = transaction.fieldDateTime.value;
      if (date == null) {
        continue;
      }
      _entries
          .putIfAbsent(_isPositive(transaction), () => <int, Map<int, List<Transaction>>>{})
          .putIfAbsent(_dayNumber(date), () => <int, List<Transaction>>{})
          .putIfAbsent(_amountBucket(transaction), () => <Transaction>[])
          .add(transaction);
    }
    for (final Transaction transaction in pool) {
      final Transaction? sameAccountOpposite = _nearbyOpposites(transaction).firstWhereOrNull(
        (Transaction other) =>
            other.fieldAccountId.value == transaction.fieldAccountId.value &&
            _isOppositeNonZeroAmount(transaction, other),
      );
      if (sameAccountOpposite != null) {
        _sameAccountMatchedIds
          ..add(transaction.uniqueId)
          ..add(sameAccountOpposite.uniqueId);
      }
    }
  }

  /// Largest number of days between the two legs of a match.
  final int maxDays;

  /// Indexed transactions by sign (true for positive), then calendar day number, then cents bucket.
  final Map<bool, Map<int, Map<int, List<Transaction>>>> _entries = <bool, Map<int, Map<int, List<Transaction>>>>{};

  /// Ids of the Transfer and Split categories, which count as neither income nor expense.
  final Set<int> _neutralCategoryIds;

  /// Ids of transactions explained by an opposite entry in their own account.
  final Set<int> _sameAccountMatchedIds = <int>{};

  /// Returns true when [source] has at least one potential transfer counterpart.
  bool hasCandidate(Transaction source) => _candidatesFor(source).isNotEmpty;

  /// Returns the potential transfer counterparts of [source], closest date first, then newest id first.
  List<Transaction> rankedCandidatesFor(Transaction source) {
    final DateTime? sourceDate = source.fieldDateTime.value;
    if (sourceDate == null) {
      return <Transaction>[];
    }
    return _candidatesFor(source).sorted((Transaction a, Transaction b) {
      final int byDays = _daysBetween(sourceDate, a.fieldDateTime.value!).compareTo(
        _daysBetween(sourceDate, b.fieldDateTime.value!),
      );
      return byDays != 0 ? byDays : b.uniqueId.compareTo(a.uniqueId);
    });
  }

  /// Yields the indexed transactions that pass [_isCandidatePair] with [source].
  Iterable<Transaction> _candidatesFor(Transaction source) {
    if (_sameAccountMatchedIds.contains(source.uniqueId)) {
      return const <Transaction>[];
    }
    return _nearbyOpposites(source).where(
      (Transaction candidate) =>
          !_sameAccountMatchedIds.contains(candidate.uniqueId) && _isCandidatePair(source, candidate),
    );
  }

  /// Returns true when [a] is in an expense category and [b] in an income category (or the reverse): a refund or a
  /// reimbursement rather than a transfer. The Transfer and Split categories count as neither.
  bool _isIncomeExpensePair(Transaction a, Transaction b) {
    if (_neutralCategoryIds.contains(a.fieldCategoryId.value) ||
        _neutralCategoryIds.contains(b.fieldCategoryId.value)) {
      return false;
    }
    return (a.isExpense && b.isIncome) || (a.isIncome && b.isExpense);
  }

  /// The one rule deciding whether [a] and [b] could be the two legs of a transfer: different accounts, non-zero
  /// opposite amounts within tolerance, dates at most [maxDays] days apart, not an income/expense pair, and not a
  /// credit-card charge paired with a deposit.
  bool _isCandidatePair(Transaction a, Transaction b) {
    final DateTime? dateA = a.fieldDateTime.value;
    final DateTime? dateB = b.fieldDateTime.value;
    return a.uniqueId != b.uniqueId &&
        a.fieldAccountId.value != b.fieldAccountId.value &&
        _isOppositeNonZeroAmount(a, b) &&
        dateA != null &&
        dateB != null &&
        _daysBetween(dateA, dateB) <= maxDays &&
        !_isIncomeExpensePair(a, b) &&
        !_isCreditChargeWithDeposit(a, b);
  }

  /// Yields the indexed transactions of the opposite sign to [transaction], dated within [maxDays] days of it
  /// and in its cents bucket or an adjacent one.
  Iterable<Transaction> _nearbyOpposites(Transaction transaction) sync* {
    final DateTime? date = transaction.fieldDateTime.value;
    final Map<int, Map<int, List<Transaction>>>? byDay = _entries[!_isPositive(transaction)];
    if (date == null || byDay == null) {
      return;
    }
    final int day = _dayNumber(date);
    final int bucket = _amountBucket(transaction);
    for (int nearDay = day - maxDays; nearDay <= day + maxDays; nearDay++) {
      final Map<int, List<Transaction>>? byBucket = byDay[nearDay];
      if (byBucket == null) {
        continue;
      }
      for (int nearBucket = bucket - 1; nearBucket <= bucket + 1; nearBucket++) {
        yield* byBucket[nearBucket] ?? const <Transaction>[];
      }
    }
  }
}

/// Returns a display-only [Transfer] for the legs [a] and [b]: the negative leg is the sender (its source) and
/// the other leg the receiver (its related transaction).
Transfer buildTransferPreview(Transaction a, Transaction b) {
  final (Transaction sender, Transaction receiver) = _senderAndReceiver(a, b);
  return Transfer(id: _previewTransferId, source: sender, relatedTransaction: receiver, isOrphan: false);
}

/// Computes the ids of every transaction in [eligibleTransactions] that has at least one potential transfer
/// counterpart among them, dated at most [maxDays] days apart.
Set<int> computeAllPotentialTransferMatchIds({
  required List<Transaction> eligibleTransactions,
  required int maxDays,
}) {
  final _TransferMatchIndex index = _TransferMatchIndex(eligibleTransactions, maxDays);
  return eligibleTransactions.where(index.hasCandidate).map((Transaction t) => t.uniqueId).toSet();
}

/// Pairs up the transactions of [eligibleTransactions] that look like the two legs of a transfer.
///
/// Each transaction joins at most one pair: in list order, each still unpaired transaction takes its best
/// unpaired counterpart (closest date, then newest id). Pairs are returned as previews from [buildTransferPreview].
List<Transfer> findPotentialTransferPairs({
  required List<Transaction> eligibleTransactions,
  int maxDays = potentialTransferDefaultMaxDays,
}) {
  final _TransferMatchIndex index = _TransferMatchIndex(eligibleTransactions, maxDays);
  final Set<int> pairedIds = <int>{};
  final List<Transfer> pairs = <Transfer>[];
  for (final Transaction source in eligibleTransactions) {
    if (pairedIds.contains(source.uniqueId)) {
      continue;
    }
    final Transaction? match = index
        .rankedCandidatesFor(source)
        .firstWhereOrNull((Transaction candidate) => !pairedIds.contains(candidate.uniqueId));
    if (match != null) {
      pairedIds
        ..add(source.uniqueId)
        ..add(match.uniqueId);
      pairs.add(buildTransferPreview(source, match));
    }
  }
  return pairs;
}

/// Finds likely disconnected transactions in [eligibleTransactions] that could
/// be linked as a transfer counterpart for [transaction].
///
/// Candidates follow the same rule as [computeAllPotentialTransferMatchIds], with dates within [maxDays].
/// Results are sorted by closest date, then newest id, and capped at [maxResults].
List<Transaction> findPotentialTransferMatchesForTransaction({
  required Transaction transaction,
  required List<Transaction> eligibleTransactions,
  int maxDays = potentialTransferDefaultMaxDays,
  int maxResults = potentialTransferDefaultMaxResults,
}) {
  return _TransferMatchIndex(eligibleTransactions, maxDays).rankedCandidatesFor(transaction).take(maxResults).toList();
}

/// Returns true when [a] and [b] have opposite signs and cancel each other out
/// within the configured amount tolerance.
bool isOppositeAmountWithinTolerance(double a, double b) {
  return (a + b).abs() < _amountTolerance && a.sign != b.sign;
}

/// Returns true when [transaction] can take part in transfer matching: not deleted, not already a transfer,
/// not split, and in an open account unless [includeClosedAccounts].
bool isTransferMatchEligible(Transaction transaction, {required bool includeClosedAccounts}) {
  return !transaction.isDeleted &&
      !transaction.isTransfer &&
      !transaction.isSplit &&
      (includeClosedAccounts || !(transaction.instanceOfAccount?.isClosed() ?? false));
}

/// Returns the cents bucket of [transaction]'s absolute amount.
int _amountBucket(Transaction transaction) => (_amountOf(transaction).abs() * _centsPerUnit).round();

/// Returns the signed amount of [transaction].
double _amountOf(Transaction transaction) => transaction.fieldAmount.value.asDouble();

/// Returns the number of calendar days between [a] and [b], ignoring the time of day.
int _daysBetween(DateTime a, DateTime b) => (_dayNumber(a) - _dayNumber(b)).abs();

/// Returns the calendar day of [date] as a day count, unaffected by time of day or daylight saving.
int _dayNumber(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/ _millisecondsPerDay;

/// Returns true when [account] is a credit card or a credit line.
bool _isCreditAccount(Account account) =>
    account.fieldType.value == AccountType.credit || account.fieldType.value == AccountType.creditLine;

/// Returns true when [a] and [b] pair a charge on a credit account with a deposit into another kind of account:
/// a purchase, not a transfer out. A card payment goes the other way: bank (-) to credit (+).
bool _isCreditChargeWithDeposit(Transaction a, Transaction b) {
  final (Transaction sender, Transaction receiver) = _senderAndReceiver(a, b);
  final Account? senderAccount = sender.instanceOfAccount;
  final Account? receiverAccount = receiver.instanceOfAccount;
  return senderAccount != null &&
      receiverAccount != null &&
      _isCreditAccount(senderAccount) &&
      !_isCreditAccount(receiverAccount);
}

/// Returns true when [a] and [b] are non-zero and cancel each other out within the amount tolerance.
bool _isOppositeNonZeroAmount(Transaction a, Transaction b) {
  final double amountA = _amountOf(a);
  final double amountB = _amountOf(b);
  return amountA != 0 && amountB != 0 && isOppositeAmountWithinTolerance(amountA, amountB);
}

/// Returns the legs [a] and [b] of a transfer as (sender, receiver): the negative leg sends.
(Transaction, Transaction) _senderAndReceiver(Transaction a, Transaction b) => _amountOf(a) < 0 ? (a, b) : (b, a);

/// Returns true when [transaction]'s amount is zero or more.
bool _isPositive(Transaction transaction) => !_amountOf(transaction).isNegative;

/// Returns the ids of the Transfer and Split categories in the data behind [pool], without creating them.
Set<int> _transferAndSplitCategoryIds(List<Transaction> pool) {
  if (pool.isEmpty) {
    return <int>{};
  }
  return <String>[
    SharedDomainStrings.domainString144,
    SharedDomainStrings.domainString126,
  ].map((String name) => pool.first.data.getCategoryIdFromName(name) ?? _unsetId).toSet();
}
