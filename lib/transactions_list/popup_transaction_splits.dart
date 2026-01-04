import 'package:get/get.dart';
import 'package:money/data/data.dart';
import 'package:money/dialog/dialog.dart';
import 'package:money/dialog/dialog_button.dart';
import 'package:money/money_objects/splits/money_split.dart';
import 'package:money/money_objects/transactions/transaction.dart';
import 'package:money/transactions_list/list_view_transaction_splits.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets_data/mutation_types.dart';

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
