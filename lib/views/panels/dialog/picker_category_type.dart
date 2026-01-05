import 'package:flutter/material.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/views/panels/dialog/picker_edit_box.dart';

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
