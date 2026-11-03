import 'package:flutter/material.dart';
import 'package:money/data/models/account_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';

/// Shows a picker for selecting an account type.
Widget pickerAccountType({
  required AccountType itemSelected,
  required void Function(AccountType) onSelected,
}) {
  return pickerEnum<AccountType>(
    title: AppL10n.tr(AppTranslationKeys.accounts),
    values: selectableAccountTypes,
    selected: itemSelected,
    toText: getTypeAsText,
    onSelected: onSelected,
  );
}
