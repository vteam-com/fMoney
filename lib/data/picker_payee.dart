import 'package:flutter/material.dart';
import 'package:money/data/payees.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/models/payee.dart';
import 'package:money/widgets/picker_edit_box.dart';

Widget pickerPayee({
  required final Payees payees,
  required final Payee? itemSelected,
  required final void Function(Payee?) onSelected,
}) {
  final List<String> options = payees.getListSorted().map((Payee element) => element.fieldName.value).toList();
  options.sort((String a, String b) => sortByString(a, b, true));

  final String selectedName = itemSelected == null ? '' : itemSelected.fieldName.value;

  return PickerEditBox(
    title: 'Payee',
    items: options,
    initialValue: selectedName,
    onChanged: (String newSelection) {
      final Payee? found = payees.getByName(newSelection);
      if (found != null) {
        onSelected(found);
      }
    },
    onAddNew: (String newPayeeText) {
      final Payee found = payees.getOrCreate(newPayeeText);
      onSelected(found);
    },
  );
}
