import 'package:flutter/material.dart';
import 'package:money/helpers/investment_types.dart';
import 'package:money/widgets/pickers/picker_edit_box.dart';

/// Shows a picker for selecting an investment type.
Widget pickerInvestmentType({
  required final InvestmentType itemSelected,
  required final void Function(InvestmentType) onSelected,
}) {
  final String selectedName = getInvestmentTypeText(itemSelected);

  return PickerEditBox(
    title: 'Investment type',
    items: getInvestmentTypeNames(),
    initialValue: selectedName,
    onChanged: (String newSelection) {
      onSelected(getInvestmentTypeFromText(newSelection));
    },
  );
}
