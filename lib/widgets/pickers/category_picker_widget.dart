import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';

/// Shows a picker for selecting a category name.
Widget pickerCategory({
  Key? key,
  required final List<String> categoryNames,
  required final String? selectedName,
  required final void Function(String?) onSelected,
}) {
  return PickerEditBox(
    key: key,
    title: AppL10n.tr(AppTranslationKeys.category),
    items: categoryNames,
    initialValue: selectedName ?? '',
    onChanged: onSelected,
  );
}
