import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/list/add_new_item_button_mixin.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/views/panels/list/transactions_list_view.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';
import 'package:money/widgets/pure/center_message_widget.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:money/widgets/state/selection_controller.dart';

/// Represents view aliases.
class ViewAliases extends ViewForMoneyObjects {
  const ViewAliases({super.key});

  @override
  State<ViewForMoneyObjects> createState() => _ViewAliasesState();
}

class _ViewAliasesState extends ViewForMoneyObjectsState with AddNewItemButtonMixin {
  _ViewAliasesState() {
    viewId = ViewId.viewAliases;
  }

  @override
  String get addNewItemTooltip => AppL10n.tr(AppTranslationKeys.addNewAlias);

  @override
  DataObject createNewItem() => Data().aliases.addNewAlias();

  /// Adds the "apply to existing transactions" button when an alias is selected.
  @override
  List<Widget> getActionsButtons(bool forSidePanelTransactions) {
    final List<Widget> list = super.getActionsButtons(forSidePanelTransactions);
    final Alias? alias = getFirstSelectedItem() as Alias?;
    if (!forSidePanelTransactions && alias != null) {
      list.add(buildApplyAliasButton(() => _applyAlias(alias)));
    }
    return list;
  }

  /// Re-assigns the transactions [alias] matches to its payee and tells the user how many changed.
  void _applyAlias(Alias alias) {
    final int count = Data().applyAlias(alias);
    if (count > 0) {
      Data().updateAll();
    }
    SnackBarService.displayInfo(
      message: AppL10n.tr(
        AppTranslationKeys.transactionsUpdatedCount,
        params: <String, String>{'count': count.toString()},
      ),
    );
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

  @override
  List<DataObject> getSidePanelTransactions() {
    final Alias? alias = getFirstSelectedItem() as Alias?;
    if (alias != null && alias.fieldId.value > -1) {
      return getTransactions(
        flattenSplits: true,
        filter: (Transaction transaction) => transaction.fieldPayee.value == alias.fieldPayeeId.value,
      );
    }
    return <DataObject>[];
  }

  /// Builds the side panel view for transactions with selection and currency options.
  Widget getSidePanelViewTransactions({
    required List<int> selectedIds,
    required bool showAsNativeCurrency,
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
      return buildSidePanelTransactionsList(
        key: Key(alias.uniqueId.toString()),
        columnNames: sidePanelTransactionsColumnNamesWithoutPayee,
        selectionController: selectionController,
      );
    }
    return CenterMessage.noTransaction();
  }
}
