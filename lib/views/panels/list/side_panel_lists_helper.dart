import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/dialogs/mutate_transaction_dialog.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/shared/presentation/widgets/sortable_list_view_widget.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/widgets/pure/center_message_widget.dart';
import 'package:money/widgets/state/selection_controller.dart';

/// Side panel lists shared by the money object views: each view remembers the row the user last
/// selected in them, and each of its lists the sort the user last chose.
extension SidePanelListsExtension on ViewForMoneyObjectsState {
  /// Builds a side panel list of the rows [getList] returns, sorted and selected as the user last left it;
  /// [listId] keeps the sort of a view's lists with different columns apart.
  Widget buildSidePanelList<T extends DataObject>({
    Key? key,
    required List<Field<dynamic>> columns,
    required List<T> Function() getList,
    String listId = '',
    bool sortAscendingByDefault = true,
    bool showRightAdornment = false,
    VoidCallback? onUserChoiceChanged,
    void Function(BuildContext context, T item)? onItemLongPress,
  }) {
    final String sortByKey = getPreferenceKey('$settingKeySidePanel$listId$settingKeySortBy');
    final String sortAscendingKey = getPreferenceKey('$settingKeySidePanel$listId$settingKeySortAscending');
    return SortableListView<T>(
      key: key,
      listController: AppScope.instance.listControllerSidePanel,
      columnsToInclude: columns,
      getList: getList,
      selectionController: SelectionController(_sidePanelSelectionKey),
      sortFieldIndex: preferenceController.getInt(sortByKey),
      sortAscending: preferenceController.getBool(sortAscendingKey, sortAscendingByDefault),
      showRightAdornment: showRightAdornment,
      onItemLongPress: onItemLongPress,
      onUserChoiceChanged: (int sortBy, bool sortAscending, int _) {
        preferenceController.setInt(sortByKey, sortBy);
        preferenceController.setBool(sortAscendingKey, sortAscending);
        onUserChoiceChanged?.call();
      },
    );
  }

  /// Builds the side panel "Transactions" list backed by [ViewForMoneyObjectsState.getSidePanelTransactions],
  /// so the displayed rows and the side panel Copy action always match; long-pressing a row opens it.
  Widget buildSidePanelTransactionsList({
    Key? key,
    List<String>? columnNames,
    bool showRightAdornment = false,
  }) {
    return buildSidePanelList<Transaction>(
      key: key,
      columns: <Field<dynamic>>[
        for (final String columnName in columnNames ?? sidePanelTransactionsColumns)
          Transaction.fields.getFieldByName(columnName),
      ],
      getList: () => List<Transaction>.from(getSidePanelTransactions()),
      showRightAdornment: showRightAdornment,
      onItemLongPress: (BuildContext context, Transaction transaction) =>
          showTransactionAndActions(context: context, transaction: transaction),
    );
  }

  /// Returns the item last selected in this view's side panel lists, or null.
  T? getSidePanelLastSelectedItem<T>(MoneyObjects<T> list) {
    final int selectedItemId = getSidePanelLastSelectedItemId();
    if (selectedItemId == -1) {
      return null;
    }
    return list.get(selectedItemId);
  }

  /// Returns the id of the item last selected in this view's side panel lists, or -1.
  int getSidePanelLastSelectedItemId() {
    return preferenceController.getInt(_sidePanelSelectionKey, -1);
  }

  /// Returns the transaction last selected in this view's side panel lists, or null.
  Transaction? getSidePanelLastSelectedTransaction() {
    return getSidePanelLastSelectedItem<Transaction>(Data().transactions);
  }

  /// The side panel "Transactions" tab: the transactions of the item selected in the main list,
  /// or a message when none is.
  Widget getSidePanelViewTransactions({
    required List<int> selectedIds,
    required bool showAsNativeCurrency,
  }) {
    keepUnused(showAsNativeCurrency);
    final DataObject? selectedItem = getFirstSelectedItemFromSelectedList(selectedIds);
    if (selectedItem == null) {
      return CenterMessage.noTransaction();
    }
    return buildSidePanelTransactionsList(key: Key(selectedItem.uniqueId.toString()));
  }

  /// Preference key of the row last selected in this view's side panel lists.
  String get _sidePanelSelectionKey => getPreferenceKey(settingKeySidePanel + settingKeySelectedListItemId);
}
