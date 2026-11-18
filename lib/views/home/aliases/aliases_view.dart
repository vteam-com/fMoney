import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/aliases_collection.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/helpers/transactions_updated_snack_bar_helper.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/list/add_new_item_button_mixin.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/views/panels/list/transactions_list_view.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';
import 'package:money/widgets/pure/center_message_widget.dart';
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

  /// True while each payee shows as a single row, its other patterns collapsed.
  bool _showOneRowPerPayee = false;

  /// Adds the collapse/expand toggle, and "apply to existing transactions" when an alias is selected.
  @override
  List<Widget> getActionsButtons(bool forSidePanelTransactions) {
    final List<Widget> buttons = super.getActionsButtons(forSidePanelTransactions);
    if (forSidePanelTransactions) {
      return buttons;
    }
    buttons.add(
      IconButton(
        key: const Key('key_toggle_alias_rows'),
        icon: Icon(_showOneRowPerPayee ? Icons.unfold_more : Icons.unfold_less),
        tooltip: AppL10n.tr(
          _showOneRowPerPayee ? AppTranslationKeys.showEveryPattern : AppTranslationKeys.showOneRowPerPayee,
        ),
        onPressed: () => setState(() {
          _showOneRowPerPayee = !_showOneRowPerPayee;
          list = getList();
        }),
      ),
    );
    final Alias? alias = getFirstSelectedItem() as Alias?;
    if (alias != null) {
      buttons.add(buildApplyAliasButton(() => _applyAlias(alias)));
    }
    return buttons;
  }

  /// Re-assigns the transactions [alias] matches to its payee and tells the user how many changed.
  void _applyAlias(Alias alias) {
    final int count = Data().applyAlias(alias);
    if (count > 0) {
      Data().updateAll();
    }
    displayTransactionsUpdated(count);
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

  /// Returns the aliases to list, one per payee while the patterns are collapsed.
  @override
  List<Alias> getList({bool includeDeleted = false, bool applyFilter = true}) {
    Data().aliases.updatePatternCounts();
    final List<Alias> aliases = Data().aliases
        .iterableList(includeDeleted: includeDeleted)
        .where(
          (Alias instance) => applyFilter == false || isMatchingFilters(instance),
        )
        .toList();
    return _showOneRowPerPayee ? Aliases.firstPerPayee(aliases) : aliases;
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
