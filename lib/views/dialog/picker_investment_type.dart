import 'package:flutter/material.dart';
import 'package:money/views/dialog/picker_edit_box.dart';
import 'package:money/views/models/investments/investment_types.dart';

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
