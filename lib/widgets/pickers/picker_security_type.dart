import 'package:flutter/material.dart';
import 'package:money/data/helpers/investment_type_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';

export 'package:flutter/material.dart';
export 'package:money/data/helpers/investment_type_helper.dart';

/// Shows a picker for selecting a security type.
Widget pickerSecurityType({
  required SecurityType itemSelected,
  required void Function(SecurityType?) onSelected,
}) {
  return pickerEnum<SecurityType>(
    title: SharedStrings.fieldType,
    values: SecurityType.values,
    selected: itemSelected,
    toText: (SecurityType type) => type.name,
    onSelected: onSelected,
  );
}
