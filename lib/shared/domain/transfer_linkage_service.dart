import 'package:money/data/models/data_access_model.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/data/models/ranges_model.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_collections_registry_model.dart';
import 'package:money/shared/domain/potential_transfer_match_service.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transfer_entity.dart';

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

    Transaction? relatedTransaction;
    try {
      relatedTransaction = collections.transactions.findExistingTransaction(
        accountId: destinationAccount.uniqueId,
        dateRange: DateRange(
          min: transactionSource.fieldDateTime.value!.startOfDay,
          max: transactionSource.fieldDateTime.value!.endOfDay,
        ),
        amount: destinationAmount,
      );
    } catch (_) {
      // something went wrong, assume no match found
    }

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
    if (sourceTransaction.isDeleted || sourceTransaction.isTransfer) {
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

  /// Returns the transactions eligible as transfer-match sources or candidates.
  List<Transaction> _eligibleTransferMatchTransactions() {
    return collections.transactions
        .iterableList(includeDeleted: false)
        .where((Transaction t) => !t.isDeleted && !t.isTransfer)
        .toList();
  }

  /// Converts two existing disconnected transactions into one linked transfer
  /// pair without creating a new mirror transaction.
  bool convertDisconnectedTransactionsToTransfer({
    required Transaction sourceTransaction,
    required Transaction targetTransaction,
  }) {
    if (sourceTransaction.uniqueId == targetTransaction.uniqueId) {
      return false;
    }
    if (sourceTransaction.isDeleted || targetTransaction.isDeleted) {
      return false;
    }
    if (sourceTransaction.isTransfer || targetTransaction.isTransfer) {
      return false;
    }
    if (sourceTransaction.fieldAccountId.value == targetTransaction.fieldAccountId.value) {
      return false;
    }
    if (!isOppositeAmountWithinTolerance(
      sourceTransaction.fieldAmount.value.asDouble(),
      targetTransaction.fieldAmount.value.asDouble(),
    )) {
      return false;
    }

    sourceTransaction.stashValueBeforeEditing();
    targetTransaction.stashValueBeforeEditing();

    final Transfer transfer = sourceTransaction.fieldAmount.value.asDouble() < 0
        ? Transfer(id: 0, source: sourceTransaction, relatedTransaction: targetTransaction, isOrphan: false)
        : Transfer(id: 0, source: targetTransaction, relatedTransaction: sourceTransaction, isOrphan: false);

    sourceTransaction.fieldPayee.value = collections.categories.transfer.uniqueId;
    sourceTransaction.fieldTransfer.value = targetTransaction.uniqueId;
    sourceTransaction.instanceOfTransfer = transfer;

    targetTransaction.fieldPayee.value = collections.categories.transfer.uniqueId;
    targetTransaction.fieldTransfer.value = sourceTransaction.uniqueId;
    targetTransaction.instanceOfTransfer = transfer;

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
  void verifyApplyTransfer({
    required Transaction transaction,
    required Account? relatedAccount,
  }) {
    if (relatedAccount == null) {
      return; // nothing to check
    }
    if (transaction.instanceOfTransfer != null) {
      // this was already a transfer, lets see if the destination account has changed
      if (transaction.instanceOfTransfer?.receiverAccount?.uniqueId == relatedAccount.uniqueId) {
        // same account do noting
      } else {
        // use the new account destination
        final Transaction relatedTransaction = transaction.instanceOfTransfer!.relatedTransaction! as Transaction;
        transaction.instanceOfTransfer!.relatedTransaction!.instanceOfAccount = collections.accounts.get(
          relatedAccount.uniqueId,
        );
        relatedTransaction.mutateField(
          SharedDomainStrings.domainString011,
          relatedAccount.uniqueId,
          false,
        );
      }
    } else {
      makeTransferLinkage(
        transactionSource: transaction,
        destinationAccount: relatedAccount,
      );
    }
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
      final Transfer transfer;

      if (transactionSource.fieldAmount.value.asDouble() < 0) {
        // transfer TO
        transfer = Transfer(
          id: 0,
          source: transactionSource,
          relatedTransaction: relatedTransaction,
          isOrphan: false,
        );
      } else {
        // transfer FROM
        transfer = Transfer(
          id: 0,
          source: relatedTransaction,
          relatedTransaction: transactionSource,
          isOrphan: false,
        );
      }

      // Keep track changes done
      relatedTransaction.stashValueBeforeEditing();

      relatedTransaction.fieldPayee.value = collections.categories.transfer.uniqueId;
      relatedTransaction.fieldTransfer.value = transactionSource.fieldId.value;
      relatedTransaction.instanceOfTransfer = transfer;

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
      transactionSource.fieldPayee.value = collections.categories.transfer.uniqueId;
      transactionSource.fieldTransfer.value = relatedTransaction.uniqueId;
      transactionSource.instanceOfTransfer = transfer;
    }

    return relatedTransaction!;
  }
}
