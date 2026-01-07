import 'package:flutter/material.dart';
import 'package:money/data/collections/data.dart';
import 'package:money/data/entities/money_split.dart';
import 'package:money/views/list_view_transaction_splits.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/icon_button.dart';
import 'package:money/widgets/mutation_types.dart';
import 'package:money/widgets/working.dart';

class SuggestionApproval extends StatefulWidget {
  const SuggestionApproval({
    super.key,
    required this.onApproved,
    required this.onChooseCategory,
    required this.isSplit,
    required this.transactionString,
    required this.splits,
    required this.uniqueId,
    required this.totalAmount,
    required this.child,
  });

  final Widget child;

  /// Data for showing splits
  final bool isSplit;

  /// Optional - Approval button will show if there's a callback function
  final void Function()? onApproved;

  /// Optional - Dropdown button
  final void Function(BuildContext)? onChooseCategory;

  final List<MoneySplit> splits;

  final double totalAmount;

  final String transactionString;

  final int uniqueId;

  @override
  SuggestionApprovalState createState() => SuggestionApprovalState();
}

class SuggestionApprovalState extends State<SuggestionApproval> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  late Animation<double> _opacityAnimation;

  bool approved = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.ease),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSplit) {
      return InkWell(
        onTap: () => _showTransactionSplits(context),
        child: widget.child,
      );
    }

    final double opacity = widget.onApproved == null ? 1 : 0.6;

    if (approved) {
      return const WorkingIndicator(size: 10);
    }
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Opacity(
        opacity: opacity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: IntrinsicWidth(child: widget.child),
              ),
            ),

            /// Optional Accept Suggestion
            if (widget.onApproved != null)
              MyIconButton(
                icon: Icons.thumb_up,
                tooltip: 'Approve category',
                hoverColor: Colors.green,
                onPressed: _fadeOutAndApproved,
              ),

            // Optional Dropdown button
            if (widget.onChooseCategory != null)
              MyIconButton(
                icon: Icons.arrow_drop_down,
                tooltip: 'Select a category',
                hoverColor: Colors.blue,
                onPressed: () {
                  if (context.mounted) {
                    widget.onChooseCategory?.call(context);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _fadeOutAndApproved() {
    _animationController.forward().then((_) {
      setState(() {
        approved = true;
      });
      if (widget.onApproved != null) {
        Future<void>.delayed(
          const Duration(milliseconds: 10),
          () => widget.onApproved!(),
        );
      }
    });
  }

  void _showTransactionSplits(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Transaction split'),
        content: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.transactionString),
              gapLarge(),
              SizedBox(
                height: 300,
                width: 800,
                child: ListViewTransactionSplits(
                  splits: widget.splits,
                  totalAmount: widget.totalAmount,
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              final MoneySplit newSplit = MoneySplit(
                id: widget.splits.length,
                transactionId: widget.uniqueId,
                categoryId: -1,
                payeeId: -1,
                amount: 0.00,
                transferId: -1,
                memo: '',
                flags: 0,
                budgetBalanceDate: null,
                data: Data(),
              );
              newSplit.mutation = MutationType.inserted;
              Data().splits.appendMoneyObject(newSplit);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
