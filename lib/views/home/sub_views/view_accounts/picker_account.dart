import 'package:flutter/material.dart';
import 'package:money/constants.dart';
import 'package:money/data.dart';
import 'package:money/money_objects/accounts/account.dart';
import 'package:money/views/dialog/picker_edit_box.dart';

Widget pickerAccount({
  required final Account? selected,
  required final void Function(Account?) onSelected,
}) {
  final List<String> options = Data().accounts
      .getListSorted()
      .map((Account element) => element.fieldName.value)
      .toList();

  final String selectedName = selected == null ? '' : selected.fieldName.value;

  return PickerEditBox(
    key: Constants.keyAccountPicker,
    title: 'Account',
    items: options,
    initialValue: selectedName,
    onChanged: (String newSelection) {
      final Account? found = Data().accounts.getByName(newSelection);
      if (found != null) {
        onSelected(found);
      }
    },
  );
}
