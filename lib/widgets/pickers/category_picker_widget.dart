import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';

/// Shows a picker for selecting a category name.
Widget pickerCategory({
  Key? key,
  required List<String> categoryNames,
  required String? selectedName,
  required void Function(String?) onSelected,
}) {
  return PickerEditBox(
    key: key,
    title: AppL10n.tr(AppTranslationKeys.category),
    items: categoryNames,
    initialValue: selectedName ?? '',
    onChanged: onSelected,
  );
}

/// Shows [categoryNames] as one-tap suggestion chips; [onSelected] receives the tapped name.
Widget categorySuggestions({
  required List<String> categoryNames,
  required void Function(String) onSelected,
}) {
  return Wrap(
    spacing: SizeForPadding.normal,
    children: <Widget>[
      for (final String name in categoryNames)
        ActionChip(
          label: Text(name),
          tooltip: AppL10n.tr(AppTranslationKeys.suggestion),
          onPressed: () => onSelected(name),
        ),
    ],
  );
}
