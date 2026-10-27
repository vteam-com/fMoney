import 'package:flutter/material.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/event_entity.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/loan_payment_entity.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/rent_building_entity.dart';
import 'package:money/shared/domain/security_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/presentation/entity_widgets/account_widgets_helper.dart';
import 'package:money/shared/presentation/entity_widgets/alias_widgets_helper.dart';
import 'package:money/shared/presentation/entity_widgets/category_widgets_helper.dart';
import 'package:money/shared/presentation/entity_widgets/event_widgets_helper.dart';
import 'package:money/shared/presentation/entity_widgets/investment_widgets_helper.dart';
import 'package:money/shared/presentation/entity_widgets/loan_payment_widgets_helper.dart';
import 'package:money/shared/presentation/entity_widgets/payee_widgets_helper.dart';
import 'package:money/shared/presentation/entity_widgets/rent_building_widgets_helper.dart';
import 'package:money/shared/presentation/entity_widgets/security_widgets_helper.dart';
import 'package:money/shared/presentation/entity_widgets/transaction_split_widgets_helper.dart';
import 'package:money/shared/presentation/entity_widgets/transaction_widgets_helper.dart';
import 'package:money/widgets/widgets_domain/data_object_widget_builders_model.dart';

/// Widget builders for every entity type, for use by generic list and detail widgets.
const DataObjectWidgetBuilders entityWidgetBuilders = DataObjectWidgetBuilders(
  buildFieldWidget: buildEntityFieldDisplayWidget,
  buildEditWidget: buildEntityFieldEditWidget,
  buildSmallScreen: buildEntitySmallScreenWidget,
);

/// Returns the entity-specific display widget for [field] of [instance], or null for the generic one.
Widget? buildEntityFieldDisplayWidget(DataObject instance, Field<dynamic> field) {
  return switch (instance) {
    final Transaction transaction => buildTransactionFieldDisplayWidget(transaction, field),
    final Account account => buildAccountFieldDisplayWidget(account, field),
    final Category category => buildCategoryFieldDisplayWidget(category, field),
    final Event event => buildEventFieldDisplayWidget(event, field),
    final RentBuilding building => buildRentBuildingFieldDisplayWidget(building, field),
    _ => null,
  };
}

/// Returns the entity-specific editor for [field] of [instance], or null for the generic one.
Widget? buildEntityFieldEditWidget(
  DataObject instance,
  Field<dynamic> field,
  void Function(bool /* wasModified */) onEdited,
) {
  return switch (instance) {
    final Transaction transaction => buildTransactionFieldEditWidget(transaction, field, onEdited),
    final TransactionSplit split => buildTransactionSplitFieldEditWidget(split, field, onEdited),
    final Account account => buildAccountFieldEditWidget(account, field, onEdited),
    final Category category => buildCategoryFieldEditWidget(category, field, onEdited),
    final Event event => buildEventFieldEditWidget(event, field, onEdited),
    final Investment investment => buildInvestmentFieldEditWidget(investment, field, onEdited),
    final Security security => buildSecurityFieldEditWidget(security, field, onEdited),
    _ => null,
  };
}

/// Builds the small-screen card for [instance].
Widget buildEntitySmallScreenWidget(DataObject instance) {
  return switch (instance) {
    final Transaction transaction => buildTransactionSmallScreenWidget(transaction),
    final Account account => buildAccountSmallScreenWidget(account),
    final Alias alias => buildAliasSmallScreenWidget(alias),
    final Category category => buildCategorySmallScreenWidget(category),
    final Event event => buildEventSmallScreenWidget(event),
    final Investment investment => buildInvestmentSmallScreenWidget(investment),
    final LoanPayment loanPayment => buildLoanPaymentSmallScreenWidget(loanPayment),
    final Payee payee => buildPayeeSmallScreenWidget(payee),
    final RentBuilding building => buildRentBuildingSmallScreenWidget(building),
    final Security security => buildSecuritySmallScreenWidget(security),
    _ => Text(AppL10n.tr(AppTranslationKeys.smallScreenContentGoesHere)),
  };
}
