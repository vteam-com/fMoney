import 'package:get/get.dart';
import 'package:money/data/collections/data.dart';
import 'package:money/data/entities/transaction.dart';
import 'package:money/data/entities/transaction_split.dart';
import 'package:money/views/list_view_transaction_splits.dart';
import 'package:money/widgets/dialog.dart';
import 'package:money/widgets/dialog_button.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/mutation_types.dart';

const double _splitListHeight = 300;
const double _splitListWidth = 800;
const int _unsetId = -1;
const double _zeroAmount = 0.0;
const int _defaultFlags = 0;

void showTransactionSplits(final Transaction transaction) {
  adaptiveScreenSizeDialog(
    context: Get.context!,
    title: 'Transaction split',
    child: IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(transaction.toString()),
          gapLarge(),
          SizedBox(
            height: _splitListHeight,
            width: _splitListWidth,
            child: ListViewTransactionSplits(
              splits: transaction.splits,
              totalAmount: transaction.fieldAmount.value.asDouble(),
            ),
          ),
        ],
      ),
    ),
    actionButtons: <Widget>[
      DialogActionButton(
        text: 'Add',
        onPressed: () {
          final TransactionSplit newSplit = TransactionSplit(
            id: transaction.splits.length,
            transactionId: transaction.uniqueId,
            categoryId: _unsetId,
            payeeId: _unsetId,
            amount: _zeroAmount,
            transferId: _unsetId,
            memo: '',
            flags: _defaultFlags,
            budgetBalanceDate: null,
            data: Data(),
          );
          newSplit.mutation = MutationType.inserted;
          Data().splits.appendMoneyObject(newSplit);
        },
      ),
    ],
  );
}
