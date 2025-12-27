import 'package:get/get.dart';
import 'package:money/core/widgets/dialog/dialog.dart';
import 'package:money/core/widgets/dialog/dialog_button.dart';
import 'package:money/core/widgets/gaps.dart';
import 'package:money/data/models/money_objects/transactions/transaction.dart';
import 'package:money/data/storage/data/data.dart';
import 'package:money/views/home/sub_views/adaptive_view/adaptive_list/transactions/list_view_transaction_splits.dart';

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
            height: 300,
            width: 800,
            child: ListViewTransactionSplits(transaction: transaction),
          ),
        ],
      ),
    ),
    actionButtons: <Widget>[
      DialogActionButton(
        text: 'Add',
        onPressed: () {
          final MoneySplit newSplit = MoneySplit(
            id: transaction.splits.length,
            transactionId: transaction.uniqueId,
            categoryId: -1,
            payeeId: -1,
            amount: 0.00,
            transferId: -1,
            memo: '',
            flags: 0,
            budgetBalanceDate: null,
          );
          newSplit.mutation = MutationType.inserted;
          Data().splits.appendMoneyObject(newSplit);
        },
      ),
    ],
  );
}
