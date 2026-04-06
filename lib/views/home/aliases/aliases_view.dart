import 'package:flutter/material.dart';
import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/views/panels/list/transactions_list_view.dart';
import 'package:money/widgets/pure/center_message_widget.dart';
import 'package:money/widgets/state/selection_controller.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

/// Represents view aliases.
class ViewAliases extends ViewForMoneyObjects {
  const ViewAliases({super.key});

  @override
  State<ViewForMoneyObjects> createState() => _ViewAliasesState();
}

class _ViewAliasesState extends ViewForMoneyObjectsState {
  _ViewAliasesState() {
    viewId = ViewId.viewAliases;
  }

  @override
  String getClassNamePlural() {
    return AppL10n.tr(AppTranslationKeys.aliases);
  }

  @override
  String getClassNameSingular() {
    return AppL10n.tr(AppTranslationKeys.alias);
  }

  @override
  String getDescription() {
    return AppL10n.tr(AppTranslationKeys.payeeAliasesDescription);
  }

  @override
  Fields<Alias> getFieldsForTable() {
    return Alias.fieldsForColumnView;
  }

  @override
  List<Alias> getList({bool includeDeleted = false, bool applyFilter = true}) {
    return Data().aliases
        .iterableList(includeDeleted: includeDeleted)
        .where(
          (Alias instance) => applyFilter == false || isMatchingFilters(instance),
        )
        .toList();
  }

  @override
  /// Returns a SidePanelSupport configured for aliases view.
  SidePanelSupport getSidePanelSupport() {
    return SidePanelSupport(
      onDetails: getSidePanelViewDetails,
      onTransactions: getSidePanelViewTransactions,
    );
  }

  /// Builds the side panel view for transactions with selection and currency options.
  Widget getSidePanelViewTransactions({
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency,
  }) {
    keepUnused(showAsNativeCurrency);
    final SelectionController selectionController = SelectionController(
      getPreferenceKey(settingKeySidePanel + settingKeySelectedListItemId),
    );

    final Alias? alias = getMoneyObjectFromFirstSelectedId<Alias>(
      selectedIds,
      list,
    );
    if (alias != null && alias.fieldId.value > -1) {
      return ListViewTransactions(
        key: Key(alias.uniqueId.toString()),
        listController: AppScope.instance.listControllerSidePanel,
        columnsToInclude: <Field<dynamic>>[
          Transaction.fields.getFieldByName(columnIdDate),
          Transaction.fields.getFieldByName(columnIdAccount),
          Transaction.fields.getFieldByName(columnIdCategory),
          Transaction.fields.getFieldByName(columnIdMemo),
          Transaction.fields.getFieldByName(columnIdAmount),
        ],
        getList: () => getTransactions(
          flattenSplits: true,
          filter: (final Transaction transaction) => transaction.fieldPayee.value == alias.fieldPayeeId.value,
        ),
        selectionController: selectionController,
      );
    }
    return CenterMessage.noTransaction();
  }
}
