import 'package:money/data/helpers/investment_type_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/domain/transfer_entity.dart';

const int _transactionUnsetId = -1;
const int _transactionZeroInt = 0;
const double _transactionZeroDouble = 0.0;

/// Checks transfer linkage consistency and adds invalid transactions to [dangling].
void transactionCheckTransfers(
  dynamic transaction,
  Set<dynamic> dangling,
  List<dynamic> deletedAccounts,
) {
  keepUnused(deletedAccounts);
  if (transaction.fieldTransfer.value != _transactionUnsetId && transaction.instanceOfTransfer == null) {
    dangling.add(transaction);
  }

  if (transaction.instanceOfTransfer != null) {
    final dynamic other = transaction.instanceOfTransfer.relatedTransaction;
    if (other.isSplit as bool) {
      // Intentionally ignored: split transfer dangling auto-fix logic is not implemented.
    } else {
      if (other.instanceOfTransfer == null || other.instanceOfTransfer.relatedTransaction != transaction) {
        dangling.add(transaction);
      } else if (other.fieldTransfer.value != transaction.uniqueId) {
        dangling.add(transaction);
      }
    }
  }
}

/// Returns true when [transaction] contains a transfer to [account].
bool transactionContainsTransferTo(dynamic transaction, dynamic account) {
  if (transaction.isSplit as bool) {
    for (final TransactionSplit split in transaction.splits as List<TransactionSplit>) {
      if (split.fieldTransferId.value != _transactionUnsetId &&
          split.getTransferTransaction()?.fieldAccountId.value == account.uniqueId) {
        return true;
      }
    }
  }
  if (transaction.instanceOfTransfer != null &&
      transaction.instanceOfTransfer.relatedTransaction?.fieldAccountId.value == account.uniqueId) {
    return true;
  }
  return false;
}

/// Converts [nativeValue] into normalized currency using transaction account ratio.
double transactionGetNormalizedAmount(dynamic transaction, double nativeValue) {
  if (transaction.instanceOfAccount == null ||
      transaction.instanceOfAccount.getCurrencyRatio() == _transactionZeroDouble) {
    return nativeValue;
  }
  return nativeValue * (transaction.instanceOfAccount.getCurrencyRatio() as num).toDouble();
}

/// Returns existing investment for a transaction or creates a default one.
Investment transactionGetOrCreateInvestment(dynamic transaction) {
  final DataAbstract data = transaction.data as DataAbstract;
  transaction.instanceOfInvestment ??=
      data.getInvestment((transaction.uniqueId as num).toInt()) as Investment? ??
      Investment(
        id: (transaction.uniqueId as num).toInt(),
        security: _transactionUnsetId,
        unitPrice: _transactionZeroDouble,
        units: _transactionZeroDouble,
        investmentType: _transactionZeroInt,
        tradeType: _transactionZeroInt,
        data: data,
      );
  return transaction.instanceOfInvestment as Investment;
}

/// Returns payee text or transfer caption for [transaction].
String transactionGetPayeeOrTransferCaption(
  dynamic transaction, {
  required bool showAccount,
}) {
  final Investment? investment = transaction.instanceOfInvestment as Investment?;
  final double amount = transaction.fieldAmount.value.asDouble() as double;

  bool isFrom = false;
  String displayName = '';
  if (transaction.isTransfer as bool) {
    if (investment != null) {
      if (investment.fieldInvestmentType.value == InvestmentType.add.index) {
        isFrom = true;
      }
    } else if (amount > _transactionZeroDouble) {
      isFrom = true;
    }

    return transactionGetTransferCaption(
      transaction,
      transaction.instanceOfTransfer?.receiverAccount,
      isFrom,
      showAccount: showAccount,
    );
  } else {
    displayName = (transaction.data as DataAbstract).getPayeeName((transaction.fieldPayee.value as num).toInt());
  }
  return displayName.isEmpty ? SharedDomainStrings.domainString007 : displayName;
}

/// Builds transfer caption text for [transaction] and [relatedAccount].
String transactionGetTransferCaption(
  dynamic transaction,
  dynamic relatedAccount,
  bool isFrom, {
  required bool showAccount,
}) {
  String caption = showAccount ? transaction.accountName as String : SharedDomainStrings.domainString144;
  final String arrowDirection = isFrom ? ' <- ' : ' -> ';
  caption += arrowDirection;
  caption += transactionRelatedAccountName(relatedAccount);
  return caption;
}

/// Returns formatted account name for [relatedAccount].
String transactionRelatedAccountName(dynamic relatedAccount) {
  if (relatedAccount == null) {
    return SharedDomainStrings.domainString006;
  }
  String name = '';

  if (relatedAccount.isClosed() as bool) {
    name += 'Closed-Account: ';
  }
  return name + (relatedAccount.fieldName.value as String);
}

/// Stores original payee text if no original payee has been captured yet.
void transactionStashOriginalPayee(dynamic transaction) {
  if ((transaction.fieldOriginalPayee.value as String).isEmpty) {
    transaction.fieldOriginalPayee.value = transaction.getPayeeOrTransferCaption();
  }
}

/// Returns one-line description combining payee/transfer and category.
String transactionOneLinePayeeAndDescription(dynamic transaction) {
  String description = transaction.getPayeeOrTransferCaption(showAccount: true) as String;
  if ((transaction.categoryName as String).isNotEmpty) {
    description += ' | ${transaction.categoryName}';
  }
  return description;
}

/// Returns true when transaction category or split category matches any target.
bool transactionIsMatchingAnyOfTheseCategories(
  dynamic transaction,
  List<int> categoriesToMatch,
) {
  if (categoriesToMatch.contains(transaction.fieldCategoryId.value as int)) {
    return true;
  }
  if (transaction.isSplit as bool) {
    for (final TransactionSplit split in transaction.splits as List<TransactionSplit>) {
      if (categoriesToMatch.contains(split.fieldCategoryId.value)) {
        return true;
      }
    }
  }
  return false;
}

/// Lazily resolves and wires transfer linkage for a transaction.
Transfer? transactionResolveInstanceOfTransfer(dynamic transaction) {
  if (transaction.cachedTransfer == null && (transaction.isTransfer as bool)) {
    final dynamic relatedTransaction = (transaction.data as DataAbstract).getTransaction(
      transaction.fieldTransfer.value as int,
    );
    if (relatedTransaction != null) {
      transaction.cachedTransfer = Transfer(
        id: _transactionZeroInt,
        source: transaction,
        relatedTransaction: relatedTransaction,
        isOrphan: false,
      );
      relatedTransaction.cachedTransfer = Transfer(
        id: _transactionZeroInt,
        source: relatedTransaction,
        relatedTransaction: transaction,
        isOrphan: false,
      );
    }
  }
  return transaction.cachedTransfer as Transfer?;
}

/// Sorts transactions by date and uses ID as deterministic tie-breaker.
int transactionSortByDateTime(
  dynamic a,
  dynamic b,
  bool ascending,
) {
  int result = sortByDate(
    a.fieldDateTime.value as DateTime?,
    b.fieldDateTime.value as DateTime?,
    ascending,
  );
  if (result == _transactionZeroInt) {
    result = sortByValue(a.uniqueId as num, b.uniqueId as num, ascending);
  }
  return result;
}
