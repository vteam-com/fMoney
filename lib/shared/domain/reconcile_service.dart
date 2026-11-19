import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/accounts_collection.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/transaction_entity.dart';

const double _zeroDouble = 0.0;

/// One reconciliation of [account] against a bank statement.
///
/// The statement starts from the [reconciledBalance] (opening balance plus every
/// reconciled transaction). The user marks the transactions that appear on the
/// statement as cleared; once the [clearedBalance] equals [statementBalance],
/// [finish] turns those cleared transactions into reconciled ones.
class ReconcileService {
  /// Starts reconciling [account] against a statement dated [statementDate] whose
  /// ending balance is [statementBalance], in the account's own currency.
  ReconcileService({
    required this.account,
    required this.data,
    required DateTime statementDate,
    required this.statementBalance,
  }) : statementDate = statementDate.startOfDay;

  /// The account being reconciled.
  final Account account;

  /// Data access used to read the account's transactions and record the changes.
  final DataAbstract data;

  /// Ending balance printed on the statement.
  final double statementBalance;

  /// Closing date printed on the statement, without a time of day.
  final DateTime statementDate;

  /// Balance of the cleared transactions on this statement plus the [reconciledBalance].
  double get clearedBalance => reconciledBalance + _sumOfAmounts(_clearedOnStatement);

  /// Amount still unexplained: [statementBalance] minus [clearedBalance].
  double get difference => statementBalance - clearedBalance;

  /// True when the cleared transactions match the statement to the cent.
  bool get isBalanced => isConsideredZero(difference);

  /// Opening balance of the account plus all its reconciled transactions.
  double get reconciledBalance => reconciledBalanceOf(account, data);

  /// Marks the cleared transactions on this statement as reconciled on [statementDate], records
  /// that date as the account's last reconciled statement, and returns how many were reconciled.
  ///
  /// Changes nothing and returns 0 while [isBalanced] is false.
  int finish() {
    if (!isBalanced) {
      return 0;
    }

    final List<Transaction> toReconcile = _clearedOnStatement.toList();
    for (final Transaction transaction in toReconcile) {
      transaction.stashValueBeforeEditing();
      transaction.fieldStatus.value = TransactionStatus.reconciled;
      transaction.fieldReconciledDate.value = statementDate;
      data.notifyMutationChanged(
        mutation: MutationType.changed,
        moneyObject: transaction,
        recalculateBalances: false,
      );
    }

    account.stashValueBeforeEditing();
    account.fieldLastBalance.value = statementDate;
    data.notifyMutationChanged(mutation: MutationType.changed, moneyObject: account);

    return toReconcile.length;
  }

  /// True when [transaction] still needs to be checked against this statement:
  /// it is neither reconciled nor void, and is dated on or before [statementDate].
  bool isPending(Transaction transaction) {
    final TransactionStatus status = transaction.fieldStatus.value;
    return status != TransactionStatus.reconciled && status != TransactionStatus.voided && _isOnStatement(transaction);
  }

  /// Returns the opening balance of [account] plus the amounts of its reconciled transactions in [data].
  static double reconciledBalanceOf(Account account, DataAbstract data) {
    return account.fieldOpeningBalance.value.asDouble() +
        _sumOfAmounts(
          Accounts.transactionsOf(account, data).where(
            (Transaction t) => t.fieldStatus.value == TransactionStatus.reconciled,
          ),
        );
  }

  /// True when [account] can be reconciled; investment and loan accounts cannot,
  /// because their balance does not come from their transactions alone.
  static bool supportsAccount(Account account) {
    return !account.isInvestmentAccount() && account.fieldType.value != AccountType.loan;
  }

  /// Cleared transactions of the account dated on or before [statementDate].
  Iterable<Transaction> get _clearedOnStatement => Accounts.transactionsOf(account, data).where(
    (Transaction t) => t.fieldStatus.value == TransactionStatus.cleared && _isOnStatement(t),
  );

  /// True when [transaction] is dated on or before [statementDate].
  bool _isOnStatement(Transaction transaction) {
    final DateTime? date = transaction.fieldDateTime.value;
    return date != null && !date.isAfter(statementDate.endOfDay);
  }

  /// Returns the sum of the amounts of [transactions].
  static double _sumOfAmounts(Iterable<Transaction> transactions) {
    return transactions.fold(
      _zeroDouble,
      (double sum, Transaction t) => sum + t.fieldAmount.value.asDouble(),
    );
  }
}
