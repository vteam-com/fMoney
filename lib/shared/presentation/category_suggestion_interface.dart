import 'package:flutter/material.dart';
import 'package:money/shared/domain/transaction_split.dart';

/// Abstract interface for providing category suggestion widgets
/// This allows decoupling Transaction from specific widget implementations
abstract class CategorySuggestionProvider {
  /// Builds a widget that displays category suggestions with optional approval and selection functionality
  Widget buildSuggestionWidget({
    required void Function()? onApproved,
    required void Function(BuildContext)? onChooseCategory,
    required bool isSplit,
    required String transactionString,
    required List<TransactionSplit> splits,
    required int uniqueId,
    required double totalAmount,
    required Widget child,
  });
}
