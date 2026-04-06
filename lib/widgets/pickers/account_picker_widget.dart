import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';

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
