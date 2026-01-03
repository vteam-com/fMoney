import 'package:flutter/material.dart';
import 'package:money/data/data.dart';
import 'package:money/money_objects/categories/category.dart';
import 'package:money/views/dialog/picker_edit_box.dart';

export 'package:money/money_objects/categories/category.dart';

Widget pickerCategory({
  Key? key,
  required final Category? itemSelected,
  required final void Function(Category?) onSelected,
}) {
  final String selectedName = itemSelected == null ? '' : itemSelected.fieldName.value;

  return PickerEditBox(
    key: key,
    title: 'Category',
    items: Data().categories.getCategoriesAsStrings(),
    initialValue: selectedName,
    onChanged: (String newSelection) {
      final Category? found = Data().categories.getByName(newSelection);
      if (found != null) {
        onSelected(found);
      }
    },
  );
}
