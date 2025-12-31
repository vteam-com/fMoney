import 'package:flutter/material.dart';
import 'package:money/models/money_objects/transfers/transfer.dart';
import 'package:money/views/home/sub_views/money_object_card.dart';

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
          runSpacing: 30,
          spacing: 30,
          children: <Widget>[
            IntrinsicWidth(
              child: TransactionCard(
                title: 'Sender',
                transaction: transfer.senderTransaction,
              ),
            ),
            IntrinsicWidth(
              child: TransactionCard(
                title: 'Receiver',
                transaction: transfer.receiverTransaction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
