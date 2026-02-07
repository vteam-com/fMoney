import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money/data/collections/data.dart';
import 'package:money/data/entities/alias.dart';
import 'package:money/data/entities/transaction.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/helpers/transaction_types.dart';
import 'package:money/views/adaptive_view/view_money_objects.dart';
import 'package:money/views/list_view_transactions.dart';
import 'package:money/views/panels/side_panel/side_panel_support.dart';
import 'package:money/widgets/center_message.dart';
import 'package:money/widgets/selection_controller.dart';
import 'package:money/widgets/widgets_domain/field.dart';

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
    return 'Aliases';
  }

  @override
  String getClassNameSingular() {
    return 'Alias';
  }

  @override
  String getDescription() {
    return 'Payee aliases.';
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
  SidePanelSupport getSidePanelSupport() {
    return SidePanelSupport(
      onDetails: getSidePanelViewDetails,
      onTransactions: getSidePanelViewTransactions,
    );
  }

  Widget getSidePanelViewTransactions({
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency,
  }) {
    final SelectionController selectionController = Get.put(
      SelectionController(
        getPreferenceKey(settingKeySidePanel + settingKeySelectedListItemId),
      ),
    );

    final Alias? alias = getMoneyObjectFromFirstSelectedId<Alias>(
      selectedIds,
      list,
    );
    if (alias != null && alias.fieldId.value > -1) {
      return ListViewTransactions(
        key: Key(alias.uniqueId.toString()),
        listController: Get.find<ListControllerSidePanel>(),
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
