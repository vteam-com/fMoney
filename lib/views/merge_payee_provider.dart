import 'package:flutter/material.dart';
import 'package:money/data/models/mergeable_item.dart';
import 'package:money/views/merge_payee_interface.dart';
import 'package:money/views/providers/data_abstract.dart';
import 'package:money/views/providers/payee.dart';

/// Implementation of MergePayeeProvider using showMergePayee function
class DefaultMergePayeeProvider implements MergePayeeProvider {
  @override
  void showMergePayee<T extends MergeableItem>(
    BuildContext context,
    Payee payee,
    Iterable<T> transactions,
    DataAbstract data,
  ) {
    showMergePayee(
      context,
      payee,
      transactions,
      data,
    );
  }
}
