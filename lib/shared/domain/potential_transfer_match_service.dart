import 'package:money/helpers/date_helper.dart';
import 'package:money/shared/domain/transaction_entity.dart';

/// Default day window used when searching potential transfer counterparts.
const int potentialTransferDefaultMaxDays = 3;

/// Default maximum number of candidates returned by the finder.
const int potentialTransferDefaultMaxResults = 5;

/// Absolute amount tolerance for treating two amounts as opposites.
const double _amountTolerance = 0.005;

/// Milliseconds in one day, used to bucket transactions per calendar day.
const int _millisecondsPerDay = Duration.millisecondsPerDay;

/// Lightweight index entry used by same-account opposite-match precomputation.
class _SignedAmountEntry {
  /// Creates a compact entry with transaction id and signed amount.
  const _SignedAmountEntry({required this.transactionId, required this.amount});

  /// Unique id of the transaction represented by this entry.
  final int transactionId;

  /// Signed amount for precise tolerance checks.
  final double amount;
}

/// Lightweight index entry used by cross-account transfer-hint precomputation.
class _CrossAccountEntry {
  /// Creates a compact entry with account id and signed amount.
  const _CrossAccountEntry({required this.accountId, required this.amount});

  /// Account the transaction belongs to, used to exclude same-account pairs.
  final int accountId;

  /// Signed amount for precise tolerance checks.
  final double amount;
}

/// Finds likely disconnected transactions in [eligibleTransactions] that could
/// be linked as a transfer counterpart for [transaction].
///
/// Candidates are constrained to other accounts, opposite-sign matching
/// amounts, and dates within [maxDays]. Results are sorted by closest date.
List<Transaction> findPotentialTransferMatchesForTransaction({
  required Transaction transaction,
  required List<Transaction> eligibleTransactions,
  int maxDays = potentialTransferDefaultMaxDays,
  int maxResults = potentialTransferDefaultMaxResults,
}) {
  final Set<int> sameAccountOppositeMatchIds = _buildSameAccountOppositeMatchIds(
    transactionsToCheck: eligibleTransactions,
    maxDays: maxDays,
  );

  final DateTime? sourceDateValue = transaction.fieldDateTime.value;
  if (sourceDateValue == null || sameAccountOppositeMatchIds.contains(transaction.uniqueId)) {
    return <Transaction>[];
  }

  final DateTime sourceDate = sourceDateValue.startOfDay;
  final double sourceAmount = transaction.fieldAmount.value.asDouble();
  final List<Transaction> candidates = eligibleTransactions.where((Transaction candidate) {
    if (candidate.uniqueId == transaction.uniqueId) {
      return false;
    }
    if (candidate.fieldAccountId.value == transaction.fieldAccountId.value) {
      return false;
    }
    if (sameAccountOppositeMatchIds.contains(candidate.uniqueId)) {
      return false;
    }
    if (!isOppositeAmountWithinTolerance(sourceAmount, candidate.fieldAmount.value.asDouble())) {
      return false;
    }
    final DateTime? candidateDateValue = candidate.fieldDateTime.value;
    if (candidateDateValue == null) {
      return false;
    }
    final DateTime candidateDate = candidateDateValue.startOfDay;
    final int dayDifference = (candidateDate.difference(sourceDate).inHours / Duration.hoursPerDay).abs().round();
    return dayDifference <= maxDays;
  }).toList();

  candidates.sort((Transaction a, Transaction b) {
    final DateTime? aDateValue = a.fieldDateTime.value;
    final DateTime? bDateValue = b.fieldDateTime.value;
    if (aDateValue == null && bDateValue == null) {
      return 0;
    }
    if (aDateValue == null) {
      return 1;
    }
    if (bDateValue == null) {
      return -1;
    }

    final int aDelta = (aDateValue.startOfDay.difference(sourceDate).inHours / Duration.hoursPerDay).abs().round();
    final int bDelta = (bDateValue.startOfDay.difference(sourceDate).inHours / Duration.hoursPerDay).abs().round();
    if (aDelta != bDelta) {
      return aDelta.compareTo(bDelta);
    }
    return b.uniqueId.compareTo(a.uniqueId);
  });

  if (candidates.length > maxResults) {
    return candidates.sublist(0, maxResults);
  }
  return candidates;
}

/// Computes the ids of every transaction in [eligibleTransactions] that has at
/// least one potential cross-account transfer counterpart, mirroring the
/// candidate rules of [findPotentialTransferMatchesForTransaction]
/// (opposite-sign amount within tolerance, different account, date within
/// [maxDays], neither side already explained by a same-account opposite
/// match).
Set<int> computeAllPotentialTransferMatchIds({
  required List<Transaction> eligibleTransactions,
  required int maxDays,
}) {
  final Set<int> sameAccountOppositeMatchIds = _buildSameAccountOppositeMatchIds(
    transactionsToCheck: eligibleTransactions,
    maxDays: maxDays,
  );

  // Cross-account index: sign -> dayKey -> amount bucket -> entries.
  final Map<bool, Map<int, Map<int, List<_CrossAccountEntry>>>> index =
      <bool, Map<int, Map<int, List<_CrossAccountEntry>>>>{};

  for (final Transaction tx in eligibleTransactions) {
    if (sameAccountOppositeMatchIds.contains(tx.uniqueId)) {
      continue;
    }
    final DateTime? dateValue = tx.fieldDateTime.value;
    if (dateValue == null) {
      continue;
    }

    final double amount = tx.fieldAmount.value.asDouble();
    final bool isPositive = amount.isNegative == false;
    final int dayKey = dateValue.startOfDay.millisecondsSinceEpoch ~/ _millisecondsPerDay;
    final int bucketKey = _amountBucketKey(amount.abs());

    index
        .putIfAbsent(isPositive, () => <int, Map<int, List<_CrossAccountEntry>>>{})
        .putIfAbsent(dayKey, () => <int, List<_CrossAccountEntry>>{})
        .putIfAbsent(bucketKey, () => <_CrossAccountEntry>[])
        .add(
          _CrossAccountEntry(
            accountId: tx.fieldAccountId.value,
            amount: amount,
          ),
        );
  }

  final Set<int> matchIds = <int>{};
  for (final Transaction tx in eligibleTransactions) {
    if (sameAccountOppositeMatchIds.contains(tx.uniqueId)) {
      continue;
    }
    final DateTime? dateValue = tx.fieldDateTime.value;
    if (dateValue == null) {
      continue;
    }

    final double amount = tx.fieldAmount.value.asDouble();
    final bool isPositive = amount.isNegative == false;
    final int dayKey = dateValue.startOfDay.millisecondsSinceEpoch ~/ _millisecondsPerDay;
    final int bucketKey = _amountBucketKey(amount.abs());

    final Map<int, Map<int, List<_CrossAccountEntry>>>? oppositeSignIndex = index[!isPositive];
    if (oppositeSignIndex == null) {
      continue;
    }

    bool foundMatch = false;
    for (int day = dayKey - maxDays; day <= dayKey + maxDays && !foundMatch; day++) {
      final Map<int, List<_CrossAccountEntry>>? dayIndex = oppositeSignIndex[day];
      if (dayIndex == null) {
        continue;
      }

      for (int bucket = bucketKey - 1; bucket <= bucketKey + 1 && !foundMatch; bucket++) {
        final List<_CrossAccountEntry>? entries = dayIndex[bucket];
        if (entries == null) {
          continue;
        }

        for (final _CrossAccountEntry entry in entries) {
          if (entry.accountId == tx.fieldAccountId.value) {
            continue;
          }
          if (isOppositeAmountWithinTolerance(amount, entry.amount)) {
            matchIds.add(tx.uniqueId);
            foundMatch = true;
            break;
          }
        }
      }
    }
  }

  return matchIds;
}

/// Returns true when [a] and [b] have opposite signs and cancel each other out
/// within the configured amount tolerance.
bool isOppositeAmountWithinTolerance(double a, double b) {
  return (a + b).abs() < _amountTolerance && a.sign != b.sign;
}

/// Returns an integer bucket key for amount indexing by tolerance.
int _amountBucketKey(double absoluteAmount) => (absoluteAmount / _amountTolerance).round();

/// Builds the set of transaction ids that have opposite-sign counterparts in
/// the same account within [maxDays].
Set<int> _buildSameAccountOppositeMatchIds({
  required List<Transaction> transactionsToCheck,
  required int maxDays,
}) {
  final Set<int> matchedIds = <int>{};

  final Map<int, Map<bool, Map<int, Map<int, List<_SignedAmountEntry>>>>> index =
      <int, Map<bool, Map<int, Map<int, List<_SignedAmountEntry>>>>>{};

  for (final Transaction tx in transactionsToCheck) {
    final DateTime? dateValue = tx.fieldDateTime.value;
    if (dateValue == null) {
      continue;
    }

    final int accountId = tx.fieldAccountId.value;
    final double amount = tx.fieldAmount.value.asDouble();
    final bool isPositive = amount.isNegative == false;
    final int dayKey = dateValue.startOfDay.millisecondsSinceEpoch ~/ _millisecondsPerDay;
    final int bucketKey = _amountBucketKey(amount.abs());

    final Map<bool, Map<int, Map<int, List<_SignedAmountEntry>>>> accountIndex = index.putIfAbsent(
      accountId,
      () => <bool, Map<int, Map<int, List<_SignedAmountEntry>>>>{},
    );
    final Map<int, Map<int, List<_SignedAmountEntry>>> signIndex = accountIndex.putIfAbsent(
      isPositive,
      () => <int, Map<int, List<_SignedAmountEntry>>>{},
    );
    final Map<int, List<_SignedAmountEntry>> dayIndex = signIndex.putIfAbsent(
      dayKey,
      () => <int, List<_SignedAmountEntry>>{},
    );
    final List<_SignedAmountEntry> bucketEntries = dayIndex.putIfAbsent(bucketKey, () => <_SignedAmountEntry>[]);

    bucketEntries.add(_SignedAmountEntry(transactionId: tx.uniqueId, amount: amount));
  }

  for (final Transaction tx in transactionsToCheck) {
    final DateTime? dateValue = tx.fieldDateTime.value;
    if (dateValue == null) {
      continue;
    }

    final int accountId = tx.fieldAccountId.value;
    final double amount = tx.fieldAmount.value.asDouble();
    final bool isPositive = amount.isNegative == false;
    final int dayKey = dateValue.startOfDay.millisecondsSinceEpoch ~/ _millisecondsPerDay;
    final int bucketKey = _amountBucketKey(amount.abs());

    final Map<bool, Map<int, Map<int, List<_SignedAmountEntry>>>>? accountIndex = index[accountId];
    if (accountIndex == null) {
      continue;
    }

    final Map<int, Map<int, List<_SignedAmountEntry>>>? oppositeSignIndex = accountIndex[!isPositive];
    if (oppositeSignIndex == null) {
      continue;
    }

    bool foundMatch = false;
    for (int day = dayKey - maxDays; day <= dayKey + maxDays && !foundMatch; day++) {
      final Map<int, List<_SignedAmountEntry>>? dayIndex = oppositeSignIndex[day];
      if (dayIndex == null) {
        continue;
      }

      for (int bucket = bucketKey - 1; bucket <= bucketKey + 1 && !foundMatch; bucket++) {
        final List<_SignedAmountEntry>? entries = dayIndex[bucket];
        if (entries == null) {
          continue;
        }

        for (final _SignedAmountEntry entry in entries) {
          if (entry.transactionId == tx.uniqueId) {
            continue;
          }
          if (isOppositeAmountWithinTolerance(amount, entry.amount)) {
            matchedIds.add(tx.uniqueId);
            matchedIds.add(entry.transactionId);
            foundMatch = true;
            break;
          }
        }
      }
    }
  }

  return matchedIds;
}
