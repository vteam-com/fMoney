import 'package:flutter/material.dart';
import 'package:money/core/widgets/picker_edit_box.dart';
import 'package:money/data/models/money_objects/accounts/account_types.dart';
import 'package:money/data/models/money_objects/accounts/account_types_enum.dart';

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
