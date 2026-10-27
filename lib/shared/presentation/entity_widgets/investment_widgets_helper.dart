import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

/// Returns the [Investment]-specific editor for [field], or null for the generic one.
///
/// The investment type and trade type have no picker yet.
Widget? buildInvestmentFieldEditWidget(
  Investment investment,
  Field<dynamic> field,
  void Function(bool /* wasModified */) _,
) {
  if (field.isSameDefinition(investment.fieldInvestmentType) || field.isSameDefinition(investment.fieldTradeType)) {
    return Text(AppL10n.tr(AppTranslationKeys.noPicker));
  }
  return null;
}

/// Builds the small-screen card for an investment; there is no compact layout yet.
Widget buildInvestmentSmallScreenWidget(Investment _) {
  return Text(AppL10n.tr(AppTranslationKeys.noUi));
}
