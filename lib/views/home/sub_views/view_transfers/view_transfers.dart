import 'package:money/data.dart';
import 'package:money/fields/money_object.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/money_objects/accounts/account.dart';
import 'package:money/money_objects/transactions/transaction.dart';
import 'package:money/money_objects/transactions/transactions.dart';
import 'package:money/money_objects/transfers/transfer.dart';
import 'package:money/views/home/sub_views/adaptive_view/view_money_objects.dart';
import 'package:money/views/home/sub_views/view_transfers/transfer_sender_receiver.dart';
import 'package:money/views/side_panel/side_panel_support.dart';
import 'package:money/widgets/center_message.dart';

/// Widget for displaying transfers between accounts.
class ViewTransfers extends ViewForMoneyObjects {
  /// Creates a new instance of [ViewTransfers].
  const ViewTransfers({super.key});

  @override
  State<ViewForMoneyObjects> createState() => ViewTransfersState();
}

/// State class for [ViewTransfers].
class ViewTransfersState extends ViewForMoneyObjectsState {
  /// Creates a new instance of [ViewTransfersState].
  ViewTransfersState() {
    viewId = ViewId.viewTransfers;
  }

  @override
  String getClassNamePlural() {
    return 'Transfers';
  }

  @override
  String getClassNameSingular() {
    return 'Transfer';
  }

  @override
  String getDescription() {
    return 'Transfers between accounts.';
  }

  @override
  Fields<Transfer> getFieldsForTable() {
    return Transfer.fieldsForColumnView;
  }

  @override
  List<Transfer> getList({
    bool includeDeleted = false,
    bool applyFilter = true,
  }) {
    List<Transfer> listOfTransfers = <Transfer>[];

    // Retrieve all transactions related to transfers.
    final List<Transaction> listOfTransactionsUseForTransfer = Data().transactions
        .getListFlattenSplits()
        .where(
          (final Transaction transaction) => transaction.fieldTransfer.value != -1,
        )
        .toList();

    // Process sender transactions.
    for (final Transaction transactionOfSender in listOfTransactionsUseForTransfer) {
      // Identify sender transactions by negative amount.
      if (transactionOfSender.fieldAmount.value.asDouble() <= 0) {
        final Transaction? transactionOfReceiver = Data().transactions.get(
          transactionOfSender.fieldTransfer.value,
        );
        _addTransferToList(
          list: listOfTransfers,
          transactionSender: transactionOfSender,
          transactionReceiver: transactionOfReceiver,
          isOrphan: false,
        );
      }
    }

    // Process receiver transactions not already included.
    for (final Transaction transactionOfReceiver in listOfTransactionsUseForTransfer) {
      // Identify receiver transactions by positive amount.
      if (transactionOfReceiver.fieldAmount.value.asDouble() > 0) {
        final Transaction? transactionOfSender = Data().transactions.get(
          transactionOfReceiver.fieldTransfer.value,
        );
        if (transactionOfSender == null) {
          // Handle orphaned receiver transactions (sender not found).
          if (transactionOfReceiver.fieldTransferSplit.value != -1) {
            logger.i('This is a split'); // Log split transactions.
          }
          logger.e(
            'related account not found ${transactionOfReceiver.uniqueId} ${transactionOfReceiver.fieldAmount.value}',
          ); // Log missing sender.
          _addTransferToList(
            list: listOfTransfers,
            transactionSender: transactionOfSender!, // Non-nullable, but logged as error above.
            transactionReceiver: transactionOfReceiver,
            isOrphan: true,
          );
        }
      }
    }

    // Apply filters if enabled.
    if (applyFilter) {
      listOfTransfers = listOfTransfers.where((final Transfer instance) => isMatchingFilters(instance)).toList();
    }

    return listOfTransfers;
  }

  @override
  SidePanelSupport getSidePanelSupport() {
    return SidePanelSupport(onDetails: _getSidePanelViewDetails);
  }

  /// Adds a transfer to the list if the accounts are available and not excluded by filters.
  void _addTransferToList({
    required final List<Transfer> list,
    required Transaction transactionSender,
    required Transaction? transactionReceiver,
    required bool isOrphan,
  }) {
    final Account? accountSender = transactionSender.instanceOfAccount;
    final Account? accountReceiver = transactionReceiver?.instanceOfAccount;

    if (accountSender != null && accountReceiver != null) {
      // Exclude closed accounts if the preference is set.
      if (accountSender.isClosed() && accountReceiver.isClosed() && !PreferenceController.to.includeClosedAccounts) {
        return;
      }

      final Transfer transfer = Transfer(
        id: 0,
        source: transactionSender,
        relatedTransaction: transactionReceiver,
        isOrphan: isOrphan,
      );
      list.add(transfer);
    }
  }

  /// Returns the side panel view details for a selected transfer.
  Widget _getSidePanelViewDetails({
    required final List<int> selectedIds,
    required final bool isReadOnly,
  }) {
    if (selectedIds.isNotEmpty) {
      final int id = selectedIds.first;
      final Transfer? transfer = list.firstWhereOrNull((MoneyObject element) => element.uniqueId == id) as Transfer?;
      if (transfer != null) {
        return TransferSenderReceiver(transfer: transfer);
      }
    }
    return const CenterMessage(message: 'No item selected.');
  }
}
