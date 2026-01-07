import 'package:flutter/material.dart';
import 'package:money/data/entities/data_abstract.dart';
import 'package:money/merge_payee_interface.dart';
import 'package:money/mergeable_item.dart';
import 'package:money/models/payee.dart';

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
