import 'package:flutter/material.dart';
import 'package:money/data/helpers/investment_type_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';

export 'package:flutter/material.dart';
export 'package:money/data/helpers/investment_type_helper.dart';

/// Shows a picker for selecting a security type.
Widget pickerSecurityType({
  required final SecurityType itemSelected,
  required final void Function(SecurityType?) onSelected,
}) {
  final List<String> options = enumToStringList(SecurityType.values);

  return PickerEditBox(
    title: SharedStrings.fieldType,
    items: options,
    initialValue: itemSelected.name,
    onChanged: (String newSelection) {
      final SecurityType found = SecurityType.values.byName(newSelection);
      onSelected(found);
    },
  );
}
