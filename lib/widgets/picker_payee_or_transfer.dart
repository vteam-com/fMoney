import 'package:flutter/material.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/my_segment.dart';
import 'package:money/widgets/picker_account.dart';
import 'package:money/widgets/picker_edit_box.dart';

const double _choiceWidth = 250;
const double _captionWidth = 100;

enum TransactionFlavor { payee, transfer }

class PickPayeeOrTransfer extends StatefulWidget {
  const PickPayeeOrTransfer({
    required this.choice,
    required this.selectedPayeeName,
    required this.selectedAccountName,
    required this.amount,
    required this.payeeNames,
    required this.accountNames,
    required this.onSelected,
    this.onMergePayee,
    super.key,
  });

  final List<String> accountNames;

  final double amount;

  final TransactionFlavor choice;

  final void Function(String payeeName, BuildContext context)? onMergePayee;

  final void Function(TransactionFlavor choice, String? payeeName, String? accountName) onSelected;

  final List<String> payeeNames;

  final String? selectedAccountName;

  final String? selectedPayeeName;

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
        SizedBox(width: _choiceWidth, child: buildChoice()),
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
            child: PickerEditBox(
              title: 'Payee',
              items: widget.payeeNames,
              initialValue: widget.selectedPayeeName ?? '',
              onChanged: (String? name) {
                widget.onSelected(_choice, name, widget.selectedAccountName);
              },
            ),
          ),
          if (widget.selectedPayeeName != null && widget.onMergePayee != null)
            IconButton(
              onPressed: () => widget.onMergePayee!(widget.selectedPayeeName!, context),
              icon: const Icon(Icons.merge_outlined),
            ),
        ],
      );
    } else {
      return presentInput(
        widget.amount > 0 ? 'From Account' : 'To Account',
        pickerAccount(
          accountNames: widget.accountNames,
          selectedName: widget.selectedAccountName,
          onSelected: (String? name) {
            widget.onSelected(_choice, widget.selectedPayeeName, name);
          },
        ),
      );
    }
  }

  Widget presentInput(final String caption, final Widget widget) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (caption.isNotEmpty) SizedBox(width: _captionWidth, child: Text(caption)),
        gapMedium(),
        Expanded(child: widget),
      ],
    );
  }
}
