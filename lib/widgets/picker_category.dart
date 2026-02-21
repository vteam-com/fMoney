import 'package:flutter/material.dart';
import 'package:money/widgets/picker_edit_box.dart';

/// Shows a picker for selecting a category name.
Widget pickerCategory({
  Key? key,
  required final List<String> categoryNames,
  required final String? selectedName,
  required final void Function(String?) onSelected,
}) {
  return PickerEditBox(
    key: key,
    title: 'Category',
    items: categoryNames,
    initialValue: selectedName ?? '',
    onChanged: onSelected,
  );
}
