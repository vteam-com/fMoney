import 'package:flutter/material.dart';
import 'package:money/data/helpers/investment_type_helper.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';

/// Shows a picker for selecting an investment type.
Widget pickerInvestmentType({
  required final InvestmentType itemSelected,
  required final void Function(InvestmentType) onSelected,
}) {
  final String selectedName = getInvestmentTypeText(itemSelected);

  return PickerEditBox(
    title: AppL10n.tr(AppTranslationKeys.investmentType),
    items: getInvestmentTypeNames(),
    initialValue: selectedName,
    onChanged: (String newSelection) {
      onSelected(getInvestmentTypeFromText(newSelection));
    },
  );
}
