import 'package:flutter/material.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/widgets/pickers/category_picker_widget.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

/// Returns the [TransactionSplit]-specific editor for [field], or null for the generic one.
Widget? buildTransactionSplitFieldEditWidget(
  TransactionSplit split,
  Field<dynamic> field,
  void Function(bool /* wasModified */) onEdited,
) {
  if (field.isSameDefinition(split.fieldCategoryId)) {
    return Row(
      children: <Widget>[
        Expanded(
          child: pickerCategory(
            key: const Key('key_pick_category'),
            categoryNames: split.data.getCategoriesAsStrings(),
            selectedName: split.data.getCategoryNameFromId(split.fieldCategoryId.value),
            onSelected: (String? name) {
              final int? id = name != null ? split.data.getCategoryIdFromName(name) : null;
              if (id != null) {
                split.fieldCategoryId.value = id;
                // notify container
                onEdited(true);
              }
            },
          ),
        ),
      ],
    );
  }
  return null;
}
