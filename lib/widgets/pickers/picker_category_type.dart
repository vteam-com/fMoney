import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/widgets/pickers/picker_edit_box.dart';

// Exports
export 'package:flutter/material.dart';

/// Shows a picker for selecting a category type.
Widget pickerCategoryType({
  required final CategoryType itemSelected,
  required final void Function(CategoryType) onSelected,
}) {
  return PickerEditBox(
    title: AppL10n.tr(AppTranslationKeys.category),
    items: CategoryTypeExtension.getNames(),
    initialValue: itemSelected.asString(),
    onChanged: (String newSelection) {
      onSelected(CategoryTypeExtension.fromName(newSelection));
    },
  );
}
