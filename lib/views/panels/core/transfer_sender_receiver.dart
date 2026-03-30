import 'package:flutter/material.dart';
import 'package:money/shared/domain/transaction.dart';
import 'package:money/shared/domain/transfer.dart';
import 'package:money/views/panels/core/money_transaction_card.dart';

const double _panelSpacing = 30.0;

/// Displays a view that shows the sender and receiver information for a transfer.
///
/// This widget is a part of the `view_transfers` sub-view in the home screen of the app.
/// It takes a [Transfer] object as a required parameter and renders a [SingleChildScrollView]
/// containing two [TransactionCard] widgets - one for the sender and one for the receiver.
/// The [TransactionCard] widgets display the relevant transaction information for the transfer.
class TransferSenderReceiver extends StatelessWidget {
  /// Constructs a [TransferSenderReceiver] widget with the given [Transfer] object.
  ///
  /// The [transfer] parameter is required and must not be null. It represents the transfer
  /// information that will be displayed in the widget.
  const TransferSenderReceiver({super.key, required this.transfer});

  final Transfer transfer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          runSpacing: _panelSpacing,
          spacing: _panelSpacing,
          children: <Widget>[
            IntrinsicWidth(
              child: TransactionCard(
                title: 'Sender',
                transaction: transfer.senderTransaction as Transaction?,
              ),
            ),
            IntrinsicWidth(
              child: TransactionCard(
                title: 'Receiver',
                transaction: transfer.receiverTransaction as Transaction?,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
