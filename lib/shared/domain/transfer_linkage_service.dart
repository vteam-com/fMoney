import 'package:collection/collection.dart';
import 'package:money/data/models/data_access_model.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_collections_registry_model.dart';
import 'package:money/shared/domain/potential_transfer_match_service.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transfer_entity.dart';

/// A transfer has no payee: its counterpart is the linked transaction's account.
const int _noPayeeId = -1;

/// Id meaning "none" for transactions and accounts.
const int _unsetId = -1;

/// Returns true when [a] and [b] can be linked as one transfer: two different live transactions,
/// neither already a transfer, in different accounts, with opposite amounts.
bool canLinkAsTransfer(Transaction a, Transaction b) {
  return a.uniqueId != b.uniqueId &&
      !a.isDeleted &&
      !b.isDeleted &&
      !a.isTransfer &&
      !b.isTransfer &&
      a.fieldAccountId.value != b.fieldAccountId.value &&
      isOppositeAmountWithinTolerance(a.fieldAmount.value.asDouble(), b.fieldAmount.value.asDouble());
}

/// Links transactions as transfers and answers "could this be a transfer?" queries.
///
/// Extracted from `Data` so transfer rules change in one place; `Data` delegates to it.
class TransferLinkageService {
  /// Creates the service over [collections], reporting edits through [notifyMutationChanged]
  /// and refreshing derived state through [updateAll].
  TransferLinkageService({
    required this.collections,
    required this.notifyMutationChanged,
    required this.updateAll,
  });

  /// Collections holding the transactions, accounts and categories being linked.
  final DataCollections collections;

  /// Records a mutation on a linked transaction.
  final void Function({
    required MutationType mutation,
    required DataObject moneyObject,
    bool recalculateBalances,
  })
  notifyMutationChanged;

  /// Recalculates balances and notifies listeners after a conversion.
  final void Function() updateAll;

  /// Cached ids of transactions that currently have at least one potential
  /// cross-account transfer counterpart; rebuilt lazily when data mutates.
  Set<int>? _potentialTransferMatchIdsCache;

  /// Data-version stamp used to invalidate [_potentialTransferMatchIdsCache].
  DateTime? _potentialTransferMatchIdsCacheStamp;

  /// Finds or creates the related transfer transaction for a destination account.
  Transaction? _getOrCreateRelatedTransaction({
    required Transaction transactionSource,
    required Account destinationAccount,
  }) {
    if (transactionSource.fieldAccountId.value == destinationAccount.uniqueId) {
      logger.e('Cannot transfer to same account');
      return null;
    }

    final double destinationAmount = transactionSource.fieldAmount.value.asDouble() * -1;

    Transaction? relatedTransaction = _findReusableCounterpart(
      transactionSource: transactionSource,
      accountId: destinationAccount.uniqueId,
      amount: destinationAmount,
    );

    if (relatedTransaction == null) {
      relatedTransaction = Transaction(
        accountId: destinationAccount.uniqueId,
        date: transactionSource.fieldDateTime.value,
      );

      // flip the sign on the amount
      relatedTransaction.fieldAmount.value.setAmount(destinationAmount);
      relatedTransaction.fieldCategoryId.value = transactionSource.fieldCategoryId.value;
      relatedTransaction.fieldFitid.value = transactionSource.fieldFitid.value;
      relatedTransaction.fieldNumber.value = transactionSource.fieldNumber.value;
      relatedTransaction.fieldMemo.value = transactionSource.fieldMemo.value;
      //u.Status = t.Status; no !!!
    }

    // Investment? i = relatedTransaction.investmentInstance;
    // if (i != null) {
    //   Investment j = transactionSource.getOrCreateInvestment();
    //   j.units = i.units;
    //   j.unitPrice = i.unitPrice;
    //   j.security = i.security;
    //   //   switch (i.Type) {
    //   //     case InvestmentType.Add:
    //   //       j.Type = InvestmentType.Remove;
    //   //       break;
    //   //     case InvestmentType.Remove:
    //   //       j.Type = InvestmentType.Add;
    //   //       break;
    //   //     case InvestmentType.None: // assume it's a remove
    //   //       i.Type = InvestmentType.Remove;
    //   //       j.Type = InvestmentType.Add;
    //   //       break;
    //   //     case InvestmentType.Buy:
    //   //     case InvestmentType.Sell:
    //   //       throw new MoneyException("Transfer must be of type 'Add' or 'Remove'.");
    //   //   }
    //   //   u.Investment = j;
    // }

    return relatedTransaction;
  }

  /// Returns an existing row of account [accountId] that can become the other side of a new
  /// transfer from [transactionSource]: same day, exactly [amount], and not deleted, not already
  /// a transfer and not a split parent, so linking never hijacks a row that has its own meaning.
  Transaction? _findReusableCounterpart({
    required Transaction transactionSource,
    required int accountId,
    required double amount,
  }) {
    final DateTime? date = transactionSource.fieldDateTime.value;
    if (date == null) {
      return null;
    }
    return collections.transactions.iterableList().firstWhereOrNull((Transaction candidate) {
      return !candidate.isDeleted &&
          !candidate.isTransfer &&
          !candidate.isSplit &&
          candidate.fieldAccountId.value == accountId &&
          candidate.fieldAmount.value.asDouble() == amount &&
          isSameDateWithoutTime(candidate.fieldDateTime.value, date);
    });
  }

  /// Returns the other side of [transaction]'s transfer, or null when it has none.
  ///
  /// Uses the related side of the cached [Transfer], falling back to the stored Transfer id.
  Transaction? _counterpartOf(Transaction transaction) {
    final dynamic related = transaction.instanceOfTransfer?.relatedTransaction;
    if (related is Transaction) {
      return related;
    }
    if (transaction.fieldTransfer.value == _unsetId) {
      return null;
    }
    return collections.transactions.get(transaction.fieldTransfer.value);
  }

  /// Breaks the transfer link of [transaction].
  ///
  /// Every counterpart still pointing back at [transaction] (found through the cached transfer,
  /// the Transfer id, or the Transfer id stashed before editing) is unlinked, stashed and marked
  /// changed. [transaction]'s own link fields are cleared but it is not marked: callers record it.
  void unlinkTransfer(Transaction transaction) {
    final Set<Transaction> counterparts = <Transaction>{};
    final Transaction? current = _counterpartOf(transaction);
    if (current != null) {
      counterparts.add(current);
    }
    final dynamic stashedTransferId = transaction.valueBeforeEdit?[SharedDomainStrings.domainString144];
    if (stashedTransferId is int && stashedTransferId != _unsetId) {
      final Transaction? former = collections.transactions.get(stashedTransferId);
      if (former != null) {
        counterparts.add(former);
      }
    }

    final int transferMarkerPayeeId =
        collections.categories.getIdByName(SharedDomainStrings.domainString144) ?? _unsetId;
    for (final Transaction counterpart in counterparts) {
      if (identical(counterpart, transaction) || counterpart.fieldTransfer.value != transaction.uniqueId) {
        continue;
      }
      counterpart.stashValueBeforeEditing();
      counterpart.fieldTransfer.value = _unsetId;
      counterpart.instanceOfTransfer = null;
      // Older files stored the Transfer category id in the Payee column as a marker; it is not a real payee.
      if (transferMarkerPayeeId != _unsetId && counterpart.fieldPayee.value == transferMarkerPayeeId) {
        counterpart.fieldPayee.value = _unsetId;
      }
      notifyMutationChanged(
        mutation: MutationType.changed,
        moneyObject: counterpart,
        recalculateBalances: false,
      );
    }

    transaction.fieldTransfer.value = _unsetId;
    transaction.instanceOfTransfer = null;
  }

  /// Finds likely disconnected transactions that could be linked as a transfer
  /// counterpart for [transaction].
  ///
  /// Candidates are constrained to other accounts, opposite-sign matching
  /// amounts, and dates within [maxDays]. Results are sorted by closest date.
  List<Transaction> findPotentialTransferMatches({
    required Transaction transaction,
    int maxDays = potentialTransferDefaultMaxDays,
    int maxResults = potentialTransferDefaultMaxResults,
  }) {
    return findPotentialTransferMatchesForTransaction(
      transaction: transaction,
      eligibleTransactions: _eligibleTransferMatchTransactions(),
      maxDays: maxDays,
      maxResults: maxResults,
    );
  }

  /// Returns true when [transaction] has at least one likely disconnected
  /// counterpart that could be linked as a transfer.
  ///
  /// Unlike [findPotentialTransferMatches] this is O(1) per call: the full id
  /// set is computed once and cached until the data version changes, making it
  /// safe to call from list row builders during scrolling.
  bool hasPotentialTransferMatch(Transaction sourceTransaction) {
    if (!isTransferMatchEligible(sourceTransaction, includeClosedAccounts: true)) {
      return false;
    }

    final DateTime dataVersion = DataAccess.trackMutations.lastDateTimeChanged;
    if (_potentialTransferMatchIdsCache == null || _potentialTransferMatchIdsCacheStamp != dataVersion) {
      _potentialTransferMatchIdsCache = computeAllPotentialTransferMatchIds(
        eligibleTransactions: _eligibleTransferMatchTransactions(),
        maxDays: potentialTransferDefaultMaxDays,
      );
      _potentialTransferMatchIdsCacheStamp = dataVersion;
    }
    return _potentialTransferMatchIdsCache!.contains(sourceTransaction.uniqueId);
  }

  /// Returns the transactions eligible as transfer-match sources or candidates, closed accounts included.
  List<Transaction> _eligibleTransferMatchTransactions() {
    return collections.transactions
        .iterableList(includeDeleted: false)
        .where((Transaction t) => isTransferMatchEligible(t, includeClosedAccounts: true))
        .toList();
  }

  /// Converts two existing disconnected transactions into one linked transfer
  /// pair without creating a new mirror transaction.
  bool convertDisconnectedTransactionsToTransfer({
    required Transaction sourceTransaction,
    required Transaction targetTransaction,
  }) {
    if (!canLinkAsTransfer(sourceTransaction, targetTransaction)) {
      return false;
    }

    sourceTransaction.stashValueBeforeEditing();
    targetTransaction.stashValueBeforeEditing();

    sourceTransaction.fieldPayee.value = _noPayeeId;
    sourceTransaction.fieldTransfer.value = targetTransaction.uniqueId;

    targetTransaction.fieldPayee.value = _noPayeeId;
    targetTransaction.fieldTransfer.value = sourceTransaction.uniqueId;

    linkTransfer(sourceTransaction, targetTransaction);

    notifyMutationChanged(
      mutation: MutationType.changed,
      moneyObject: sourceTransaction,
      recalculateBalances: false,
    );
    notifyMutationChanged(
      mutation: MutationType.changed,
      moneyObject: targetTransaction,
      recalculateBalances: true,
    );
    updateAll();
    return true;
  }

  /// Ensures transfer linkage exists or updates it for the given transaction.
  ///
  /// Without [relatedAccount], a [transaction] that is no longer a transfer has its former
  /// counterpart unlinked. For an existing transfer, the counterpart is moved to [relatedAccount]
  /// when it changed, and the Transfer id (cleared by the picker to force re-evaluation) is restored.
  void verifyApplyTransfer({
    required Transaction transaction,
    required Account? relatedAccount,
  }) {
    if (relatedAccount == null) {
      if (!transaction.isTransfer) {
        unlinkTransfer(transaction);
      }
      return;
    }

    final Transaction? counterpart = _counterpartOf(transaction);
    if (relatedAccount.uniqueId == transaction.fieldAccountId.value) {
      logger.e('Cannot transfer to same account');
      if (counterpart != null) {
        transaction.fieldTransfer.value = counterpart.uniqueId;
      }
      return;
    }

    if (counterpart == null) {
      makeTransferLinkage(
        transactionSource: transaction,
        destinationAccount: relatedAccount,
      );
      return;
    }

    if (counterpart.fieldAccountId.value != relatedAccount.uniqueId) {
      counterpart.stashValueBeforeEditing();
      counterpart.fieldAccountId.value = relatedAccount.uniqueId;
      counterpart.instanceOfAccount = relatedAccount;
      notifyMutationChanged(
        mutation: MutationType.changed,
        moneyObject: counterpart,
        recalculateBalances: false,
      );
    }
    transaction.fieldTransfer.value = counterpart.uniqueId;
  }

  /// Creates a transfer linkage between source and destination transactions.
  Transaction makeTransferLinkage({
    required Transaction transactionSource,
    required Account destinationAccount,
  }) {
    final Transaction? relatedTransaction = _getOrCreateRelatedTransaction(
      transactionSource: transactionSource,
      destinationAccount: destinationAccount,
    );

    if (relatedTransaction != null) {
      // Keep track changes done
      relatedTransaction.stashValueBeforeEditing();

      relatedTransaction.fieldPayee.value = _noPayeeId;
      relatedTransaction.fieldTransfer.value = transactionSource.fieldId.value;
      linkTransfer(transactionSource, relatedTransaction);

      if (relatedTransaction.uniqueId == -1) {
        // This is a new related transaction Append and get a new UniqueID
        collections.transactions.appendNewMoneyObject(
          relatedTransaction,
          fireNotification: false,
        );
      } else {
        notifyMutationChanged(
          mutation: MutationType.changed,
          moneyObject: relatedTransaction,
          recalculateBalances: false,
        );
      }

      // this needs to happen last since the ID for a new Relation Transaction will be establish in the above
      transactionSource.fieldPayee.value = _noPayeeId;
      transactionSource.fieldTransfer.value = relatedTransaction.uniqueId;
    }

    return relatedTransaction!;
  }
}
