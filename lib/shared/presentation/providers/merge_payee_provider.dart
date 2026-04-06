import 'package:flutter/material.dart';
import 'package:money/data/models/mergeable_item_interface.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/presentation/providers/merge_payee_provider_interface.dart';

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
