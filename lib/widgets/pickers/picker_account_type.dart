import 'package:flutter/material.dart';
import 'package:money/helpers/account_types.dart';
import 'package:money/helpers/account_types_enum.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/widgets/pickers/picker_edit_box.dart';

/// Shows a picker for selecting an account type.
Widget pickerAccountType({
  required final AccountType itemSelected,
  required final void Function(AccountType) onSelected,
}) {
  final String selectedName = getTypeAsText(itemSelected);

  return PickerEditBox(
    title: AppL10n.tr(AppTranslationKeys.accounts),
    items: getAccountTypeAsText(),
    initialValue: selectedName,
    onChanged: (String newSelection) {
      onSelected(getAccountTypeFromText(newSelection)!);
    },
  );
}
