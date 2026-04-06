import 'package:flutter/material.dart';
import 'package:money/data/models/mergeable_item.dart';
import 'package:money/shared/domain/data_abstract.dart';
import 'package:money/shared/domain/payee_domain.dart';
import 'package:money/shared/presentation/merge_payee_interface.dart';

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
