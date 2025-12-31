import 'package:flutter/material.dart';
import 'package:money/models/money_objects/investments/investment_types.dart';
import 'package:money/widgets/picker_edit_box.dart';

Widget pickerInvestmentTradeType({
  required final InvestmentTradeType itemSelected,
  required final void Function(InvestmentTradeType) onSelected,
}) {
  final String selectedName = getInvestmentTradeTypeText(itemSelected);

  return PickerEditBox(
    title: 'Investment Trade Type',
    items: getInvestmentTradeTypeNames(),
    initialValue: selectedName,
    onChanged: (String newSelection) {
      onSelected(getInvestmentTradeTypeFromText(newSelection));
    },
  );
}
