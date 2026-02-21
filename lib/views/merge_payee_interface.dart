import 'package:flutter/material.dart';
import 'package:money/data/models/mergeable_item.dart';
import 'package:money/views/providers/data_abstract.dart';
import 'package:money/views/providers/payee.dart';

/// Abstract interface for providing merge payee functionality
/// This allows decoupling Transaction from specific merge implementations
abstract class MergePayeeProvider {
  /// Shows the merge payee dialog for the given transactions
  void showMergePayee<T extends MergeableItem>(
    BuildContext context,
    Payee payee,
    Iterable<T> transactions,
    DataAbstract data,
  );
}
