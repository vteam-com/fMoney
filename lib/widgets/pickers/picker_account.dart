import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/widgets/pickers/picker_edit_box.dart';

/// Shows a picker for selecting an account name.
Widget pickerAccount({
  required final List<String> accountNames,
  required final String? selectedName,
  required final void Function(String?) onSelected,
}) {
  return PickerEditBox(
    key: Constants.keyAccountPicker,
    title: AppL10n.tr(AppTranslationKeys.account),
    items: accountNames,
    initialValue: selectedName ?? '',
    onChanged: onSelected,
  );
}
