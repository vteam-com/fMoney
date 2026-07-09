import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:money/data/models/field_filter_model.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/dialogs/mutate_money_object_dialog.dart';
import 'package:money/shared/presentation/helpers/money_objects_filter_helper.dart';
import 'package:money/shared/presentation/helpers/money_objects_ui_helper.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/shared/presentation/widgets/adaptable_list_view_widget.dart';
import 'package:money/shared/presentation/widgets/money_object_card_widget.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/layout/side_panel_widget.dart';
import 'package:money/views/panels/list/money_objects_footer_helper.dart';
import 'package:money/views/panels/list/money_objects_view_builders_helper.dart';
import 'package:money/views/panels/list/money_objects_view_selection_helper.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';
import 'package:money/widgets/dialogs/confirmation_dialog.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';
import 'package:money/widgets/dialogs/message_box_dialog.dart';
import 'package:money/widgets/list/column_filter_panel.dart';
import 'package:money/widgets/list/multiple_selection_context_model.dart';
import 'package:money/widgets/list/view_header_widget.dart';
import 'package:money/widgets/pure/center_message_widget.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_filters_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';
import 'package:money/widgets/widgets_domain/footer_accumulators_helper.dart';

/// A stateful widget for view for money objects.
class ViewForMoneyObjects extends StatefulWidget {
  const ViewForMoneyObjects({super.key, this.includeClosedAccount = false});

  final bool includeClosedAccount;

  @override
  State<ViewForMoneyObjects> createState() => ViewForMoneyObjectsState();
}

/// State for view for money objects.
class ViewForMoneyObjectsState extends State<ViewForMoneyObjects> {
  Fields<DataObject> _fieldToDisplay = Fields<DataObject>();
  FieldFilters _filterByFieldsValue = FieldFilters();
  String _filterByText = '';
  final FooterAccumulators _footerAccumulators = FooterAccumulators();
  bool _isMultiSelectionOn = false;
  int _lastSelectedItemId = -1;
  final ValueNotifier<List<int>> _selectedItemsByUniqueId = ValueNotifier<List<int>>(<int>[]);
  bool _sortAscending = true;
  int _sortByFieldIndex = 0;
  final DataFileController dataController = DataFileController.to;
  bool firstLoadCompleted = false;
  final ListControllerMain lc = ListControllerMain();
  List<DataObject> list = <DataObject>[];
  List<String> listOfUniqueString = <String>[];
  List<ValueSelection> listOfValueSelected = <ValueSelection>[];
  void Function()? onAddTransaction;
  VoidCallback? onDeleteItems;
  VoidCallback? onEditItems;
  VoidCallback? onMultiSelect;
  PreferenceController preferenceController = AppScope.instance.preferenceController;
  late final SidePanelSupport sidePanelOptions;
  Object? subViewSelectedItem;
  bool supportsMultiSelection = false;
  late final ViewId viewId;
  @override
  void initState() {
    super.initState();
    firstLoad();
    this.sidePanelOptions = getSidePanelSupport();
  }

  @override
  Widget build(final BuildContext context) {
    footerAccumulators();

    return buildViewContent(
      ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          preferenceController,
          dataController,
        ]),
        builder: (final BuildContext _, final Widget? _) {
          final Key key = Key(
            '${preferenceController.includeClosedAccounts}|${list.length}|${areFiltersOn()}|${dataController.lastUpdateAsString}|${sidePanelOptions.selectedCurrency}}',
          );

          if (firstLoadCompleted == false) {
            return _buildLoadingScreen();
          }

          if (list.isEmpty) {
            return _buildInformUserOfEmptyList(key);
          }

          return AdaptiveViewWithList(
            key: key,
            top: buildHeader(),
            list: list,
            fieldDefinitions: _fieldToDisplay.definitions,
            filters: _filterByFieldsValue,
            selectedItemsByUniqueId: _selectedItemsByUniqueId,
            sortByFieldIndex: _sortByFieldIndex,
            sortAscending: _sortAscending,
            listController: lc,
            isMultiSelectionOn: _isMultiSelectionOn,
            onColumnHeaderTap: _changeListSortOrder,
            onColumnHeaderLongPress: onCustomizeColumn,
            getColumnFooterWidget: getColumnFooterWidget,
            onSelectionChanged: (int _) {
              lc.bookmark = lc.scrollController.offset;
              _selectedItemsByUniqueId.value = _selectedItemsByUniqueId.value.toList();
              saveLastUserChoicesOfView();
            },
            onItemTap: _onItemTap,
            flexBottom: preferenceController.isSidePanelExpanded ? 1 : 0,
            bottom: SidePanel(
              key: Key(
                '${settingKeySidePanel}currency|${sidePanelOptions.selectedCurrency}',
              ),
              isExpanded: preferenceController.isSidePanelExpanded,
              onExpanded: (final bool isExpanded) {
                setState(() {
                  preferenceController.isSidePanelExpanded = isExpanded;
                });
              },
              selectedItems: _selectedItemsByUniqueId,

              // SubView
              sidePanelSupport: sidePanelOptions,

              // Currency
              getCurrencyChoices: getCurrencyChoices,
              currencySelected: sidePanelOptions.selectedCurrency,
              currencySelectionChanged: (final int selected) {
                setState(() {
                  sidePanelOptions.selectedCurrency = selected;
                });
              },

              /// Actions
              getActionButtons: getActionsButtons,
            ),
          );
        },
      ),
    );
  }

  /// Returns true if any filters (text or column) are currently active.
  bool areFiltersOn() {
    if (_filterByText.isEmpty && _filterByFieldsValue.isEmpty) {
      return false;
    }
    return true;
  }

  /// Allowed to be override by derived classes
  Widget buildHeader([final Widget? child]) {
    ViewHeaderMultipleSelection? multipleSelectionOptions;
    if (supportsMultiSelection) {
      multipleSelectionOptions = ViewHeaderMultipleSelection(
        selectedItems: _selectedItemsByUniqueId,
        isMultiSelectionOn: _isMultiSelectionOn,
        onToggleMode: () {
          setState(() {
            _isMultiSelectionOn = !_isMultiSelectionOn;
            if (!_isMultiSelectionOn) {
              setSelectedItem(-1);
            }
          });
        },
      );
    }

    return ViewHeader(
      key: Key(_selectedItemsByUniqueId.value.length.toString()),
      title: getClassNamePlural(),
      itemCount: list.length,
      selectedItems: _selectedItemsByUniqueId,
      description: getDescription(),
      multipleSelection: multipleSelectionOptions,
      getActionButtons: getActionsButtons,
      onEditMoneyObject: onEditItems,
      onDeleteMoneyObject: onDeleteItems,
      textFilter: _filterByText,
      onTextFilterChanged: _onFilterTextChanged,
      onClearAllFilters: areFiltersOn()
          ? () {
              // remove any filters from the view
              setState(() {
                _resetFiltersAndGetList();
              });
            }
          : null,
      onScrollToTop: () {
        lc.scrollToTop();
      },
      onScrollToSelection: () {
        if (_selectedItemsByUniqueId.value.isNotEmpty) {
          final int firstSelectedId = _selectedItemsByUniqueId.value.first;
          final int index = list.indexWhere(
            (DataObject item) => item.uniqueId == firstSelectedId,
          );
          if (index != -1) {
            lc.scrollToIndex(index, list.length);
          }
        }
      },
      onScrollToBottom: () {
        lc.scrollToBottom();
      },
      child: child,
    );
  }

  /// Builds a standard pivot toggle row wired to refresh this view list on selection change.
  Widget buildStandardPivotToggleRow({
    Key? key,
    required List<bool> selectedPivot,
    required List<Widget> pivotChildren,
    required EdgeInsetsGeometry padding,
    required BorderRadius borderRadius,
    required double minHeight,
    required double minWidth,
  }) {
    return buildStandardPivotToggleRowUi(
      key: key,
      selectedPivot: selectedPivot,
      pivotChildren: pivotChildren,
      padding: padding,
      borderRadius: borderRadius,
      minHeight: minHeight,
      minWidth: minWidth,
      onPressed: (int index) => updatePivotSelectionAndRefresh(selectedPivot, index),
    );
  }

  /// Builds the common details-panel layout with a money-object card and additional panels.
  Widget buildStandardSidePanelDetailsWrap<T extends DataObject>({
    required T? selectedItem,
    required List<Widget> extraPanels,
    required double spacing,
  }) {
    return buildStandardSidePanelDetailsWrapUi<T>(
      selectedItem: selectedItem,
      extraPanels: extraPanels,
      spacing: spacing,
      title: getClassNameSingular(),
    );
  }

  /// Allowed to be override by derived classes
  Widget buildViewContent(final Widget child) {
    return Container(color: getColorTheme(context).surface, child: child);
  }

  /// Clears all selected items and updates view state.
  void clearSelection() {
    _selectedItemsByUniqueId.value = <int>[];
    saveLastUserChoicesOfView();
  }

  /// Performs initial load and restores user preferences.
  Future<void> firstLoad() async {
    _fieldToDisplay = getFieldsForTable();

    // restore last user choices for this view
    _sortByFieldIndex = preferenceController.getInt(
      getPreferenceKey(settingKeySortBy),
      0,
    );
    _sortAscending = preferenceController.getBool(
      getPreferenceKey(settingKeySortAscending),
      true,
    );
    _lastSelectedItemId = preferenceController.getInt(
      getPreferenceKey(settingKeySelectedListItemId),
      -1,
    );

    // Filters
    // load text filter
    _filterByText = preferenceController.getString(
      getPreferenceKey(settingKeyFilterText),
      '',
    );

    // load the column filters
    try {
      final String filtersAsJSonString = preferenceController.getString(
        getPreferenceKey(settingKeyFiltersColumns),
      );
      _filterByFieldsValue = FieldFilters.fromJsonString(filtersAsJSonString);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to restore column filters: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    list = getList();

    /// restore selection of items
    setSelectedItem(_lastSelectedItemId);
    firstLoadCompleted = true;
  }

  /// Calculates footer accumulators for the current list data.
  void footerAccumulators() {
    recomputeFooterAccumulators(
      footerAccumulators: _footerAccumulators,
      items: list,
      definitions: _fieldToDisplay.definitions,
    );
  }

  /// Allowed to be override by derived classes
  List<Widget> getActionsButtons(final bool forSidePanelTransactions) {
    final List<Widget> widgets = <Widget>[];

    /// Info panel header
    if (forSidePanelTransactions) {
      if (PreferenceController.to.selectedSidePanelTabId == SidePanelSubViewEnum.transactions) {
        /// Add Transactions
        if (onAddTransaction != null) {
          widgets.add(buildAddTransactionsButton(onAddTransaction!));
        }

        /// Copy Info List
        widgets.add(
          buildCopyButton(
            onCopyListFromSidePanel,
            Constants.keyCopyListToClipboardHeaderSidePanel,
          ),
        );
      }
    }
    /// Main header
    else {
      /// only when there is one or more selection
      if (_selectedItemsByUniqueId.value.isNotEmpty) {
        ///  Edit
        widgets.add(
          buildEditButton(() {
            myShowDialogAndActionsForMoneyObjects(
              title: _selectedItemsByUniqueId.value.length == 1 ? getClassNameSingular() : getClassNamePlural(),
              moneyObjects: getSelectedItemsFromSelectedList(
                _selectedItemsByUniqueId.value,
              ),
            );
          }),
        );

        /// Delete
        widgets.add(
          buildDeleteButton(() {
            _onUserRequestedToDelete(
              context,
              getSelectedItemsFromSelectedList(_selectedItemsByUniqueId.value),
            );
          }),
        );

        /// Copy List
        widgets.add(buildCopyButton(onCopyListFromMainView));
      }
    }

    return widgets;
  }

  /// Allowed to be override by derived classes
  String getClassNamePlural() {
    return AppL10n.tr(AppTranslationKeys.items);
  }

  /// Allowed to be override by derived classes
  String getClassNameSingular() {
    return AppL10n.tr(AppTranslationKeys.item);
  }

  /// Allowed to be override by derived classes
  /// to be overridden by derived class
  /// Use the field FooterType to decide how to render the bottom button of each columns
  Widget getColumnFooterWidget(final Field<dynamic> field) {
    return _footerAccumulators.buildWidget(field);
  }

  /// Override in your view
  List<String> getCurrencyChoices(
    final SidePanelSubViewEnum subViewId,
    final List<int> selectedItems,
  ) {
    keepUnused(selectedItems);
    switch (subViewId) {
      case SidePanelSubViewEnum.details:
      case SidePanelSubViewEnum.chart:
      case SidePanelSubViewEnum.transactions:
      default:
        return <String>[];
    }
  }

  /// Allowed to be override by derived classes
  String getDescription() {
    return AppL10n.tr(AppTranslationKeys.defaultListOfItems);
  }

  /// Derived class will override to customize the fields to display in the Adaptive Table
  Fields<DataObject> getFieldsForTable() {
    return Fields<DataObject>();
  }

  /// Returns the first selected item from the selected items list.
  DataObject? getFirstSelectedItem() {
    return getFirstSelectedMoneyObject<DataObject>(
      _selectedItemsByUniqueId.value,
      list,
    );
  }

  /// Returns the first selected item from a specific selected list.
  DataObject? getFirstSelectedItemFromSelectedList(
    final List<int> selectedList,
  ) {
    return getMoneyObjectFromFirstSelectedId<DataObject>(selectedList, list);
  }

  /// Returns the list of data objects with optional filtering.
  List<DataObject> getList({
    bool includeDeleted = false,
    bool applyFilter = true,
  }) {
    keepUnused(includeDeleted, applyFilter);
    return <DataObject>[];
  }

  /// Returns preference key for the current view with given suffix.
  String getPreferenceKey(final String suffix) {
    return viewId.getViewPreferenceId(suffix);
  }

  /// Returns list of selected data objects from selected list IDs.
  List<DataObject> getSelectedItemsFromSelectedList(
    final List<int> selectedList,
  ) {
    return getSelectedMoneyObjectsFromIds(selectedList, list);
  }

  /// Returns the last selected item from the side panel list.
  T? getSidePanelLastSelectedItem<T>(final MoneyObjects<T> list) {
    final int selectedItemId = getSidePanelLastSelectedItemId();
    if (selectedItemId == -1) {
      return null;
    }
    return list.get(selectedItemId);
  }

  /// Returns the last selected item ID from the side panel.
  int getSidePanelLastSelectedItemId() {
    return PreferenceController.to.getInt(
      getPreferenceKey(settingKeySidePanel + settingKeySelectedListItemId),
      -1,
    );
  }

  /// Returns the last selected transaction from the side panel.
  Transaction? getSidePanelLastSelectedTransaction() {
    final int selectedItemId = getSidePanelLastSelectedItemId();
    if (selectedItemId == -1) {
      return null;
    }
    return Data().transactions.get(selectedItemId);
  }

  /// Returns side panel support configuration for the view.
  SidePanelSupport getSidePanelSupport() {
    return SidePanelSupport(); // by default the base class does not show any content in the side panel
  }

  /// Returns list of transactions for the side panel.
  List<DataObject> getSidePanelTransactions() {
    return <DataObject>[];
  }

  /// Builds side panel view details for the selected items.
  Widget getSidePanelViewDetails({required final List<int> selectedIds}) {
    if (selectedIds.length > 1) {
      return CenterMessage(
        message: AppL10n.tr(
          AppTranslationKeys.multipleSelectionCount,
          params: <String, String>{'count': selectedIds.length.toString()},
        ),
      );
    }

    final DataObject? moneyObject = findObjectById(
      selectedIds.firstOrNull,
      list,
    );

    if (moneyObject == null) {
      return CenterMessage(message: AppL10n.tr(AppTranslationKeys.noItemSelected));
    }

    return SingleChildScrollView(
      key: Key('detail_panel_${moneyObject.uniqueId}'),
      child: MoneyObjectCard(
        title: getClassNameSingular(),
        moneyObject: moneyObject,
        onEdit: _onUserRequestToEdit,
        onDelete: _onUserRequestedToDelete,
      ),
    );
  }

  /// Returns the unique ID of the first selected item.
  int? getUniqueIdOfFirstSelectedItem() {
    return getFirstSelectedMoneyObjectId(_selectedItemsByUniqueId.value);
  }

  /// Returns true if the data instance matches current filters.
  bool isMatchingFilters(final DataInterface instance) {
    return isMoneyObjectMatchingFilters(
      areFiltersOn: areFiltersOn(),
      fieldToDisplay: _fieldToDisplay,
      instance: instance,
      filterByText: _filterByText,
      filterByFieldsValue: _filterByFieldsValue,
    );
  }

  /// Copies the main view list to clipboard as CSV.
  void onCopyListFromMainView() {
    copyToClipboardAndInformUser(
      context,
      MoneyObjects.getCsvFromList(list, forSerialization: false),
    );
  }

  /// Copies the side panel list to clipboard as CSV.
  void onCopyListFromSidePanel() {
    final List<DataObject> listToCopy = getSidePanelTransactions();
    copyToClipboardAndInformUser(
      context,
      MoneyObjects.getCsvFromList(listToCopy, forSerialization: false),
    );
  }

  /// Opens column customization dialog for the specified field.
  void onCustomizeColumn(final Field<dynamic> fieldDefinition) {
    Widget content;
    listOfValueSelected.clear();

    switch (fieldDefinition.type) {
      case FieldType.quantity:
        {
          listOfUniqueString = collectUniqueNumericValues(
            getList(applyFilter: false),
            fieldDefinition,
          );

          for (final String item in listOfUniqueString) {
            listOfValueSelected.add(
              ValueSelection(name: item, isSelected: true),
            );
          }

          content = ColumnFilterPanel(
            listOfUniqueInstances: listOfValueSelected,
            textAlign: TextAlign.right,
          );
        }

      case FieldType.date:
        {
          listOfUniqueString = collectUniqueDateValues(
            getList(applyFilter: false),
            fieldDefinition,
          );

          for (final String item in listOfUniqueString) {
            listOfValueSelected.add(
              ValueSelection(name: item, isSelected: true),
            );
          }

          content = ColumnFilterPanel(
            listOfUniqueInstances: listOfValueSelected,
            textAlign: TextAlign.left,
          );
        }

      case FieldType.widget:
        {
          listOfUniqueString = collectUniqueWidgetValues(
            getList(applyFilter: false),
            fieldDefinition,
          );

          for (final String item in listOfUniqueString) {
            listOfValueSelected.add(
              ValueSelection(name: item, isSelected: true),
            );
          }

          content = ColumnFilterPanel(
            listOfUniqueInstances: listOfValueSelected,
            textAlign: TextAlign.left,
          );
        }

      case FieldType.text:
      default:
        {
          listOfUniqueString = collectUniqueStringValues(
            getList(applyFilter: false),
            fieldDefinition,
          );

          if (fieldDefinition.type == FieldType.amount) {
            listOfUniqueString.sort(
              (String a, String b) => compareStringsAsAmount(a, b),
            );
          } else {
            listOfUniqueString.sort();
          }

          for (final String item in listOfUniqueString) {
            listOfValueSelected.add(
              ValueSelection(name: item, isSelected: true),
            );
          }

          content = ColumnFilterPanel(
            listOfUniqueInstances: listOfValueSelected,
            textAlign: fieldDefinition.type == FieldType.amount ? TextAlign.right : TextAlign.left,
          );
        }
    }

    adaptiveScreenSizeDialog(
      context: context,
      title: AppL10n.tr(
        AppTranslationKeys.columnFilterName,
        params: <String, String>{'name': fieldDefinition.name},
      ),
      child: content,
      actionButtons: <Widget>[
        DialogActionButton(
          text: AppL10n.tr(AppTranslationKeys.apply),
          onPressed: () {
            Navigator.of(context).pop(false);
            setState(() {
              final List<String> selectedValues = <String>[];

              for (final ValueSelection checkbox in listOfValueSelected) {
                if (checkbox.isSelected) {
                  selectedValues.add(checkbox.name);
                }
              }

              if (selectedValues.length == listOfValueSelected.length) {
                // all unique values are selected so clear the column filter;
                _filterByFieldsValue.clear();
              } else {
                // apply filter
                _filterByFieldsValue.add(
                  FieldFilter(
                    fieldName: fieldDefinition.name,
                    strings: selectedValues,
                  ),
                );
              }

              saveLastUserChoicesOfView();

              list = getList();
            });
          },
        ),
      ],
    );
  }

  /// Saves the current user choices and preferences for the view.
  void saveLastUserChoicesOfView() {
    // Persist users choice
    preferenceController.setInt(
      getPreferenceKey(settingKeySortBy),
      _sortByFieldIndex,
    );
    preferenceController.setBool(
      getPreferenceKey(settingKeySortAscending),
      _sortAscending,
    );
    preferenceController.setInt(
      getPreferenceKey(settingKeySelectedListItemId),
      getUniqueIdOfFirstSelectedItem() ?? -1,
    );
    preferenceController.setString(
      getPreferenceKey(settingKeyFilterText),
      _filterByText,
      true,
    );

    final String serializedColumnFilters = _filterByFieldsValue.isEmpty ? '' : _filterByFieldsValue.toJsonString();
    preferenceController.setString(
      getPreferenceKey(settingKeyFiltersColumns),
      serializedColumnFilters,
      true,
    );
  }

  /// Sets the selected item by unique ID and updates UI state.
  void setSelectedItem(final int uniqueId) {
    _lastSelectedItemId = uniqueId;

    // This will cause a UI update and the bottom details will get rendered if its expanded
    setState(() {
      //
      if (uniqueId == -1) {
        // clear
        _selectedItemsByUniqueId.value.clear();
      } else {
        if (!_selectedItemsByUniqueId.value.contains(uniqueId)) {
          // _selectedItemsByUniqueId.value = <int>[uniqueId];
          _selectedItemsByUniqueId.value.add(uniqueId);
        }
      }

      // persist the last selected item index
      preferenceController.setInt(
        getPreferenceKey(settingKeySelectedListItemId),
        _lastSelectedItemId,
      );
    });
  }

  /// Updates the list data and selects the specified item.
  void updateListAndSelect(final int uniqueId) {
    setState(() {
      clearSelection();
      list = getList();
      firstLoadCompleted = true;
      setSelectedItem(uniqueId);
    });
  }

  /// Selects a pivot by index, refreshes the list, and clears current row selection.
  void updatePivotSelectionAndRefresh(
    List<bool> selectedPivot,
    int selectedIndex,
  ) {
    setState(() {
      for (int i = 0; i < selectedPivot.length; i++) {
        selectedPivot[i] = i == selectedIndex;
      }
      list = getList();
      clearSelection();
    });
  }

  /// Builds the empty-state UI for this view.
  Widget _buildInformUserOfEmptyList(final Key key) {
    return buildMoneyObjectsEmptyState(
      key: key,
      classNamePlural: getClassNamePlural(),
      areFiltersOn: areFiltersOn(),
      filterByText: _filterByText,
      filterByFieldsValue: _filterByFieldsValue,
      onClearFilters: _clearFiltersFromEmptyState,
      header: buildHeader(),
    );
  }

  /// Builds the loading state UI for this view.
  Widget _buildLoadingScreen() {
    return buildMoneyObjectsLoadingScreen(header: buildHeader());
  }

  /// Changes sort order based on the tapped column and persists the choice.
  void _changeListSortOrder(final int columnNumber) {
    setState(() {
      if (columnNumber == _sortByFieldIndex) {
        // toggle order
        _sortAscending = !_sortAscending;
      } else {
        _sortByFieldIndex = columnNumber;
      }

      // Persist users choice
      saveLastUserChoicesOfView();
    });
  }

  /// Clears filters from empty-state UI action and refreshes the list.
  void _clearFiltersFromEmptyState() {
    setState(() {
      _resetFiltersAndGetList();
    });
  }

  /// Updates the free-text filter and refreshes the list.
  void _onFilterTextChanged(final String text) {
    setState(() {
      _filterByText = text.toLowerCase();
      saveLastUserChoicesOfView();
      list = getList();
    });
  }

  /// Handles taps on list items on mobile by showing a details dialog.
  void _onItemTap(final BuildContext context, final int uniqueId) {
    if (isPlatformMobile()) {
      adaptiveScreenSizeDialog(
        context: context,
        title: '${getClassNameSingular()} #${uniqueId + 1}',
        actionButtons: <Widget>[],
        child: getSidePanelViewDetails(selectedIds: <int>[uniqueId]),
      );
    }
  }

  /// Handles the user's request to edit the selected objects.
  void _onUserRequestToEdit(
    final BuildContext _,
    final List<DataObject> moneyObjects,
  ) {
    myShowDialogAndActionsForMoneyObjects(
      title: getSingularPluralText(
        AppL10n.tr(AppTranslationKeys.edit),
        moneyObjects.length,
        getClassNameSingular(),
        getClassNamePlural(),
      ),
      moneyObjects: moneyObjects,
    );
  }

  /// Handles the user's request to delete the selected objects.
  void _onUserRequestedToDelete(
    final BuildContext context,
    final List<DataObject> moneyObjects,
  ) {
    if (moneyObjects.isEmpty) {
      messageBox(context, AppL10n.tr(AppTranslationKeys.noItemsToDelete));
      return;
    }

    final String nameSingular = getClassNameSingular();
    final String namePlural = getClassNamePlural();

    final String title = getSingularPluralText(
      AppL10n.tr(AppTranslationKeys.delete),
      moneyObjects.length,
      nameSingular,
      namePlural,
    );

    final String question = moneyObjects.length == 1
        ? AppL10n.tr(AppTranslationKeys.deleteThisItemQuestion, params: <String, String>{'item': nameSingular})
        : AppL10n.tr(
            AppTranslationKeys.deleteSelectedItemsQuestion,
            params: <String, String>{'count': getIntAsText(moneyObjects.length), 'items': namePlural},
          );
    final RenderObjectWidget content = moneyObjects.length == 1
        ? Column(
            children: moneyObjects.first.buildListOfNamesValuesWidgets(
              onEdit: null,
              compact: true,
            ),
          )
        : Center(
            child: Text(
              '${getIntAsText(moneyObjects.length)} $namePlural',
              style: getTextTheme(context).displaySmall,
            ),
          );

    showConfirmationDialog(
      context: context,
      title: title,
      question: question,
      content: content,
      buttonText: AppL10n.tr(AppTranslationKeys.delete),
      onConfirmation: () {
        Data().deleteItems(moneyObjects);
      },
    );
  }

  /// Clears active filters, persists choices, and refreshes the list.
  void _resetFiltersAndGetList() {
    _filterByText = '';
    _filterByFieldsValue.clear();

    saveLastUserChoicesOfView();
    list = getList();
  }
}

/// Return the first element of type T in a list given a list of possible index;
T? getMoneyObjectFromFirstSelectedId<T>(
  final List<int> selectedIds,
  final List<dynamic> listOfItems,
) {
  return getMoneyObjectFromFirstSelectedIdInList<T>(selectedIds, listOfItems);
}
