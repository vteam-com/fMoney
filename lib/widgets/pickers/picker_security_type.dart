import 'package:flutter/material.dart';
import 'package:money/data/models/investment_types.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/widgets/pickers/picker_edit_box.dart';

export 'package:flutter/material.dart';
export 'package:money/data/models/investment_types.dart';

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
