import 'package:flutter/material.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/money_objects/investments/investment_types.dart';
import 'package:money/views/dialog/picker_edit_box.dart';

export 'package:flutter/material.dart';
export 'package:money/money_objects/investments/investment_types.dart';

Widget pickerSecurityType({
  required final SecurityType itemSelected,
  required final void Function(SecurityType?) onSelected,
}) {
  final List<String> options = enumToStringList(SecurityType.values);

  return PickerEditBox(
    title: 'Type',
    items: options,
    initialValue: itemSelected.name,
    onChanged: (String newSelection) {
      final SecurityType found = SecurityType.values.byName(newSelection);
      onSelected(found);
    },
  );
}
