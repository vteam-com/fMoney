import 'package:flutter/material.dart';
import 'package:money/data/data_interface.dart';
import 'package:money/mergeable_item.dart';
import 'package:money/models/payee.dart';

/// Abstract interface for providing merge payee functionality
/// This allows decoupling Transaction from specific merge implementations
abstract class MergePayeeProvider {
  /// Shows the merge payee dialog for the given transactions
  void showMergePayee<T extends MergeableItem>(
    BuildContext context,
    Payee payee,
    Iterable<T> transactions,
    DataInterface data,
  );
}
