import 'package:flutter/material.dart';
import 'package:money/data/accounts.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/models/account.dart';
import 'package:money/widgets/picker_edit_box.dart';

Widget pickerAccount({
  required final Accounts accounts,
  required final Account? selected,
  required final void Function(Account?) onSelected,
}) {
  final List<String> options = accounts.getListSorted().map((Account element) => element.fieldName.value).toList();

  final String selectedName = selected == null ? '' : selected.fieldName.value;

  return PickerEditBox(
    key: Constants.keyAccountPicker,
    title: 'Account',
    items: options,
    initialValue: selectedName,
    onChanged: (String newSelection) {
      final Account? found = accounts.getByName(newSelection);
      if (found != null) {
        onSelected(found);
      }
    },
  );
}
