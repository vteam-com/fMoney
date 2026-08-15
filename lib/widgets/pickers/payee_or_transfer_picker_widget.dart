import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/widgets/components/my_segment_widget.dart';
import 'package:money/widgets/pickers/account_picker_widget.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';

const double _choiceWidth = 250;
const double _captionWidth = 100;

enum TransactionFlavor { payee, transfer }

/// A stateful widget for pick payee or transfer.
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

  /// Builds the Payee/Transfer segmented choice widget.
  Widget buildChoice() {
    return mySegmentSelector(
      context: context,
      segments: <ButtonSegment<int>>[
        ButtonSegment<int>(
          value: TransactionFlavor.payee.index,
          label: Text(AppL10n.tr(AppTranslationKeys.payee)),
        ),
        ButtonSegment<int>(
          value: TransactionFlavor.transfer.index,
          label: Text(AppL10n.tr(AppTranslationKeys.transfer)),
        ),
      ],
      selectedId: _choice.index,
      onSelectionChanged: (int newSelection) {
        setState(() {
          _choice = TransactionFlavor.values[newSelection];
        });
      },
    );
  }

  /// Builds the appropriate input widget based on Payee/Transfer choice.
  Widget buildIInput() {
    if (_choice == TransactionFlavor.payee) {
      return Row(
        children: <Widget>[
          Expanded(
            child: PickerEditBox(
              title: AppL10n.tr(AppTranslationKeys.payee),
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
        widget.amount > 0 ? AppL10n.tr(AppTranslationKeys.fromAccount) : AppL10n.tr(AppTranslationKeys.toAccount),
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

  /// Presents an input row with optional caption and widget.
  Widget presentInput(String caption, Widget widget) {
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
