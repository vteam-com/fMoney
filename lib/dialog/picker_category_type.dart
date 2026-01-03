import 'package:flutter/material.dart';
import 'package:money/dialog/picker_edit_box.dart';
import 'package:money/money_objects/categories/category_types.dart';

// Exports
export 'package:flutter/material.dart';

Widget pickerCategoryType({
  required final CategoryType itemSelected,
  required final void Function(CategoryType) onSelected,
}) {
  return PickerEditBox(
    title: 'Category',
    items: CategoryTypeExtension.getNames(),
    initialValue: itemSelected.asString(),
    onChanged: (String newSelection) {
      onSelected(CategoryTypeExtension.fromName(newSelection));
    },
  );
}
