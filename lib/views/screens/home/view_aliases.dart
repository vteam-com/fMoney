import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/transaction_types.dart';
import 'package:money/shared/domain/alias.dart';
import 'package:money/shared/domain/data.dart';
import 'package:money/shared/domain/transaction.dart';
import 'package:money/shared/presentation/app_scope.dart';
import 'package:money/views/panels/core/list_view_transactions.dart';
import 'package:money/views/panels/core/side_panel_support.dart';
import 'package:money/views/panels/core/view_money_objects.dart';
import 'package:money/widgets/pure/center_message.dart';
import 'package:money/widgets/state/selection_controller.dart';
import 'package:money/widgets/widgets_domain/field.dart';

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
