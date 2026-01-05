import 'package:flutter/material.dart';
import 'package:money/models/accounts/account.dart';
import 'package:money/models/payees/payee.dart';
import 'package:money/sub_views/view_payees/merge_payees.dart';
import 'package:money/views/dialog/picker_account.dart';
import 'package:money/views/dialog/picker_payee.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/my_segment.dart';

enum TransactionFlavor { payee, transfer }

class PickPayeeOrTransfer extends StatefulWidget {
  const PickPayeeOrTransfer({
    required this.choice,
    required this.payee,
    required this.account,
    required this.amount,
    required this.onSelected,
    super.key,
  });

  final Account? account;
  final double amount;
  final TransactionFlavor choice;
  final void Function(TransactionFlavor choice, Payee? payee, Account? account) onSelected;
  final Payee? payee;

  @override
  State<PickPayeeOrTransfer> createState() => _PickPayeeOrTransferState();
}

class _PickPayeeOrTransferState extends State<PickPayeeOrTransfer> {
  late TransactionFlavor _choice;

  @override
  void initState() {
    super.initState();
    _choice = widget.choice;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        gapMedium(),
        SizedBox(width: 250, child: buildChoice()),
        gapSmall(),
        Expanded(child: buildIInput()),
      ],
    );
  }

  Widget buildChoice() {
    return mySegmentSelector(
      context: context,
      segments: <ButtonSegment<int>>[
        ButtonSegment<int>(
          value: TransactionFlavor.payee.index,
          label: const Text('Payee'),
        ),
        ButtonSegment<int>(
          value: TransactionFlavor.transfer.index,
          label: const Text('Transfer'),
        ),
      ],
      selectedId: _choice.index,
      onSelectionChanged: (final int newSelection) {
        setState(() {
          _choice = TransactionFlavor.values[newSelection];
        });
      },
    );
  }

  Widget buildIInput() {
    if (_choice == TransactionFlavor.payee) {
      return Row(
        children: <Widget>[
          Expanded(
            child: pickerPayee(
              itemSelected: widget.payee,
              onSelected: (Payee? payee) {
                widget.onSelected(_choice, payee, widget.account);
              },
            ),
          ),
          if (widget.payee != null)
            IconButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                showMergePayee(
                  context,
                  widget.payee!,
                ); //transactions.toList());
              },
              icon: const Icon(Icons.merge_outlined),
            ),
        ],
      );
    } else {
      return presentInput(
        widget.amount > 0 ? 'From Account' : 'To Account',
        pickerAccount(
          selected: widget.account,
          onSelected: (Account? account) {
            widget.onSelected(_choice, widget.payee, account);
          },
        ),
      );
    }
  }

  Widget presentInput(final String caption, final Widget widget) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (caption.isNotEmpty) SizedBox(width: 100, child: Text(caption)),
        gapMedium(),
        Expanded(child: widget),
      ],
    );
  }
}
