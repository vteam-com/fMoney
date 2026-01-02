import 'package:flutter/material.dart';
import 'package:money/models/money_objects/categories/category_types.dart';
import 'package:money/views/dialog/picker_edit_box.dart';

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
