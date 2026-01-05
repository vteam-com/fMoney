import 'package:flutter/material.dart';
import 'package:money/helpers/account_types.dart';
import 'package:money/helpers/account_types_enum.dart';
import 'package:money/views/dialog/picker_edit_box.dart';

Widget pickerAccountType({
  required final AccountType itemSelected,
  required final void Function(AccountType) onSelected,
}) {
  final String selectedName = getTypeAsText(itemSelected);

  return PickerEditBox(
    title: 'Accounts',
    items: getAccountTypeAsText(),
    initialValue: selectedName,
    onChanged: (String newSelection) {
      onSelected(getAccountTypeFromText(newSelection)!);
    },
  );
}
