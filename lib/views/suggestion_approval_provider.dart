import 'package:flutter/material.dart';
import 'package:money/data/entities/transaction_split.dart';
import 'package:money/views/category_suggestion_interface.dart';
import 'package:money/views/suggestion_approval.dart';

/// Implementation of CategorySuggestionProvider using SuggestionApproval widget
class SuggestionApprovalProvider implements CategorySuggestionProvider {
  @override
  Widget buildSuggestionWidget({
    required void Function()? onApproved,
    required void Function(BuildContext)? onChooseCategory,
    required bool isSplit,
    required String transactionString,
    required List<TransactionSplit> splits,
    required int uniqueId,
    required double totalAmount,
    required Widget child,
  }) {
    return SuggestionApproval(
      onApproved: onApproved,
      onChooseCategory: onChooseCategory,
      isSplit: isSplit,
      transactionString: transactionString,
      splits: splits,
      uniqueId: uniqueId,
      totalAmount: totalAmount,
      child: child,
    );
  }
}
