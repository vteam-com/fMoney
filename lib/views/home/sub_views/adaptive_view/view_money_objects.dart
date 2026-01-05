import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:money/controller/data_controller.dart';
import 'package:money/controller/preferences_controller.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/money_objects/transactions/transaction.dart';
import 'package:money/views/adaptive_list/column_filter_panel.dart';
import 'package:money/views/adaptive_list/footer_accumulators.dart';
import 'package:money/views/adaptive_list/multiple_selection_context.dart';
import 'package:money/views/data/data.dart';
import 'package:money/views/dialog/confirmation_dialog.dart';
import 'package:money/views/dialog/dialog.dart';
import 'package:money/views/dialog/dialog_button.dart';
import 'package:money/views/dialog/dialog_mutate_money_object.dart';
import 'package:money/views/home/sub_views/adaptive_view/adaptable_view_with_list.dart';
import 'package:money/views/home/sub_views/money_object_card.dart';
import 'package:money/views/home/sub_views/view_header.dart';
import 'package:money/views/side_panel/side_panel.dart';
import 'package:money/views/side_panel/side_panel_support.dart';
import 'package:money/views/side_panel/side_panel_views_enum.dart';
import 'package:money/widgets/box.dart';
import 'package:money/widgets/center_message.dart';
import 'package:money/widgets/default_values.dart';
import 'package:money/widgets/field.dart';
import 'package:money/widgets/field_filter.dart';
import 'package:money/widgets/field_filters.dart';
import 'package:money/widgets/field_type.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/message_box.dart';
import 'package:money/widgets/money_object.dart';
import 'package:money/widgets/money_objects.dart';
import 'package:money/widgets/text_title.dart';
import 'package:money/widgets/working.dart';

class ViewForMoneyObjects extends StatefulWidget {
  const ViewForMoneyObjects({super.key, this.includeClosedAccount = false});

  final bool includeClosedAccount;

  @override
  State<ViewForMoneyObjects> createState() => ViewForMoneyObjectsState();
}

class ViewForMoneyObjectsState extends State<ViewForMoneyObjects> {
  Fields<MoneyObject> _fieldToDisplay = Fields<MoneyObject>();

  FieldFilters _filterByFieldsValue = FieldFilters();

  String _filterByText = '';

  final FooterAccumulators _footerAccumulators = FooterAccumulators();

  bool _isMultiSelectionOn = false;

  int _lastSelectedItemId = -1;

  final ValueNotifier<List<int>> _selectedItemsByUniqueId = ValueNotifier<List<int>>(<int>[]);

  bool _sortAscending = true;

  int _sortByFieldIndex = 0;

  final DataController dataController = Get.find();

  bool firstLoadCompleted = false;

  final ListControllerMain lc = ListControllerMain();

  List<MoneyObject> list = <MoneyObject>[];

  List<String> listOfUniqueString = <String>[];

  List<ValueSelection> listOfValueSelected = <ValueSelection>[];

  void Function()? onAddTransaction;

  VoidCallback? onDeleteItems;

  VoidCallback? onEditItems;

  VoidCallback? onMultiSelect;

  PreferenceController preferenceController = Get.find();

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
      Obx(() {
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
      }),
    );
  }

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
            (MoneyObject item) => item.uniqueId == firstSelectedId,
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

  /// Allowed to be override by derived classes
  Widget buildViewContent(final Widget child) {
    return Container(color: getColorTheme(context).surface, child: child);
  }

  void clearSelection() {
    _selectedItemsByUniqueId.value = <int>[];
    saveLastUserChoicesOfView();
  }

  void firstLoad() async {
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
    } catch (error) {
      if (kDebugMode) {
        print(error.toString());
      }
    }

    list = getList();

    /// restore selection of items
    setSelectedItem(_lastSelectedItemId);
    firstLoadCompleted = true;
  }

  void footerAccumulators() {
    _footerAccumulators.clear();

    for (final MoneyObject item in list) {
      for (final Field<dynamic> field in _fieldToDisplay.definitions) {
        switch (field.type) {
          case FieldType.text:
            _footerAccumulators.accumulatorListOfText.cumulate(
              field,
              field.getValueForDisplay(item).toString(),
            );

          case FieldType.date:
            final dynamic dateTime = field.getValueForDisplay(item);
            if (dateTime != null) {
              _footerAccumulators.accumulatorDateRange.cumulate(
                field,
                dateTime as DateTime,
              );
            }
          case FieldType.dateRange:
            final dynamic dateRangeValue = field.getValue(item);
            if (dateRangeValue.min != null) {
              _footerAccumulators.accumulatorDateRange.cumulate(
                field,
                dateRangeValue.min as DateTime,
              );
            }
            if (dateRangeValue.max != null) {
              _footerAccumulators.accumulatorDateRange.cumulate(
                field,
                dateRangeValue.max as DateTime,
              );
            }

          case FieldType.widget:
            if (field.getValueForReading != null) {
              _footerAccumulators.accumulatorListOfText.cumulate(
                field,
                field.getValueForReading?.call(item)!.toString() ?? '',
              );
            }

          case FieldType.amount:
            final double value = smartToDouble(field.getValueForDisplay(item));
            if (isNumber(value)) {
              _footerAccumulators.accumulatorSumAmount.cumulate(field, value);
              if (field.footer == FooterType.average) {
                _footerAccumulators.accumulatorForAverage.cumulate(
                  field,
                  value,
                );
              }
              if (field.footer == FooterType.range) {
                _footerAccumulators.accumulatorNumericRange.cumulate(
                  field,
                  value,
                );
              }
            }

          case FieldType.numeric:
          case FieldType.amountShorthand:
          case FieldType.numericShorthand:
          case FieldType.quantity:
            final dynamic value = field.getValueForDisplay(item);
            if (field.footer == FooterType.count) {
              _footerAccumulators.accumulatorListOfText.cumulate(
                field,
                getIntAsText(value as int),
              );
            } else {
              if (value is num) {
                _footerAccumulators.accumulatorSumNumber.cumulate(
                  field,
                  value.toDouble(),
                );
                if (field.footer == FooterType.average) {
                  _footerAccumulators.accumulatorForAverage.cumulate(
                    field,
                    value,
                  );
                }
                if (field.footer == FooterType.range) {
                  _footerAccumulators.accumulatorNumericRange.cumulate(
                    field,
                    value,
                  );
                }
              }
            }
          default:
            break;
        }
      }
    }
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
    return 'Items';
  }

  /// Allowed to be override by derived classes
  String getClassNameSingular() {
    return 'Item';
  }

  /// Allowed to be override by derived classes
  /// to be overridden by derived class
  /// Use the field FooterType to decide how to render the bottom button of each columns
  Widget getColumnFooterWidget(final Field<dynamic> field) {
    return _footerAccumulators.buildWidget(field);
  }

  String getCurrency() {
    // default currency for this view
    return Constants.defaultCurrency;
  }

  /// Override in your view
  List<String> getCurrencyChoices(
    final SidePanelSubViewEnum subViewId,
    final List<int> selectedItems,
  ) {
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
    return 'Default list of items';
  }

  /// Derived class will override to customize the fields to display in the Adaptive Table
  Fields<MoneyObject> getFieldsForTable() {
    return Fields<MoneyObject>();
  }

  MoneyObject? getFirstSelectedItem() {
    if (_selectedItemsByUniqueId.value.isNotEmpty) {
      final int? firstId = _selectedItemsByUniqueId.value.firstOrNull;
      if (firstId != null) {
        return list.firstWhereOrNull(
          (MoneyObject moneyObject) => moneyObject.uniqueId == firstId,
        );
      }
    }
    return null;
  }

  MoneyObject? getFirstSelectedItemFromSelectedList(
    final List<int> selectedList,
  ) {
    return getMoneyObjectFromFirstSelectedId<MoneyObject>(selectedList, list);
  }

  List<MoneyObject> getList({
    bool includeDeleted = false,
    bool applyFilter = true,
  }) {
    return <MoneyObject>[];
  }

  String getPreferenceKey(final String suffix) {
    return viewId.getViewPreferenceId(suffix);
  }

  List<MoneyObject> getSelectedItemsFromSelectedList(
    final List<int> selectedList,
  ) {
    if (selectedList.isEmpty) {
      return <MoneyObject>[];
    }

    final Set<int> selectedIds = selectedList.toSet();
    return list
        .where(
          (MoneyObject moneyObject) => selectedIds.contains(moneyObject.uniqueId),
        )
        .toList();
  }

  Widget getSidePanelHeader(
    final BuildContext context,
    final num index,
    final MoneyObject item,
  ) {
    return Center(child: Text('${getClassNameSingular()} #${index + 1}'));
  }

  T? getSidePanelLastSelectedItem<T>(final MoneyObjects<T> list) {
    final int selectedItemId = getSidePanelLastSelectedItemId();
    if (selectedItemId == -1) {
      return null;
    }
    return list.get(selectedItemId);
  }

  int getSidePanelLastSelectedItemId() {
    return PreferenceController.to.getInt(
      getPreferenceKey(settingKeySidePanel + settingKeySelectedListItemId),
      -1,
    );
  }

  Transaction? getSidePanelLastSelectedTransaction() {
    final int selectedItemId = getSidePanelLastSelectedItemId();
    if (selectedItemId == -1) {
      return null;
    }
    return Data().transactions.get(selectedItemId);
  }

  SidePanelSupport getSidePanelSupport() {
    return SidePanelSupport(); // by default the base class does not show any content in the side panel
  }

  List<MoneyObject> getSidePanelTransactions() {
    return <MoneyObject>[];
  }

  Widget getSidePanelViewDetails({
    required final List<int> selectedIds,
    required final bool isReadOnly,
  }) {
    if (selectedIds.length > 1) {
      return CenterMessage(
        message: 'Multiple selection.(${selectedIds.length})',
      );
    }

    final MoneyObject? moneyObject = findObjectById(
      selectedIds.firstOrNull,
      list,
    );

    if (moneyObject == null) {
      return const CenterMessage(message: 'No item selected.');
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

  int? getUniqueIdOfFirstSelectedItem() {
    return _selectedItemsByUniqueId.value.firstOrNull;
  }

  /// Compile the list of single data value for a column/field definition
  List<String> getUniqueInstances(
    final Field<dynamic> columnToCustomerFilterOn,
  ) {
    final Set<String> set = <String>{}; // This is a Set()
    final List<MoneyObject> list = getList(applyFilter: false);
    for (final MoneyObject moneyObject in list) {
      final String fieldValue = columnToCustomerFilterOn.getValueForDisplay(moneyObject).toString();
      set.add(fieldValue);
    }
    return set.toList();
  }

  /// Compile the list of single date value for a column/field definition
  List<String> getUniqueInstancesOfDates(
    final Field<dynamic> columnToCustomerFilterOn,
  ) {
    final Set<String> set = <String>{}; // This is a Set()
    final List<MoneyObject> list = getList(applyFilter: false);
    for (final MoneyObject moneyObject in list) {
      final String fieldValue = dateToString(
        columnToCustomerFilterOn.getValueForDisplay(moneyObject) as DateTime?,
      );
      set.add(fieldValue);
    }
    final List<String> uniqueValues = set.toList();
    uniqueValues.sort();
    return uniqueValues;
  }

  /// Compile the list of single date value for a column/field definition
  List<String> getUniqueInstancesOfNumbers(
    final Field<dynamic> columnToCustomerFilterOn,
  ) {
    final Set<String> set = <String>{}; // This is a Set()
    final List<MoneyObject> list = getList(applyFilter: false);
    for (final MoneyObject moneyObject in list) {
      final String fieldValue = formatDoubleTrimZeros(
        columnToCustomerFilterOn.getValueForDisplay(moneyObject) as double,
      );
      set.add(fieldValue);
    }
    final List<String> uniqueValues = set.toList();
    uniqueValues.sort((String a, String b) => compareStringsAsNumbers(a, b));
    return uniqueValues;
  }

  /// Compile the list of single date value for a column/field definition
  List<String> getUniqueInstancesOfWidgets(
    final Field<dynamic> columnToCustomerFilterOn,
  ) {
    final Set<String> set = <String>{}; // This is a Set()
    final List<MoneyObject> list = getList(applyFilter: false);
    for (final MoneyObject moneyObject in list) {
      final String fieldValue = columnToCustomerFilterOn.getValueForReading?.call(moneyObject) as String? ?? '';
      set.add(fieldValue);
    }
    final List<String> uniqueValues = set.toList();
    uniqueValues.sort();
    return uniqueValues;
  }

  bool isMatchingFilters(final MoneyObject instance) {
    if (areFiltersOn()) {
      // apply filtering
      return _fieldToDisplay.applyFilters(
        instance,
        _filterByText,
        _filterByFieldsValue,
      );
    }
    return true;
  }

  void onCopyListFromMainView() {
    copyToClipboardAndInformUser(
      context,
      MoneyObjects.getCsvFromList(list, forSerialization: false),
    );
  }

  void onCopyListFromSidePanel() {
    final List<MoneyObject> listToCopy = getSidePanelTransactions();
    copyToClipboardAndInformUser(
      context,
      MoneyObjects.getCsvFromList(listToCopy, forSerialization: false),
    );
  }

  void onCustomizeColumn(final Field<dynamic> fieldDefinition) {
    Widget content;
    listOfValueSelected.clear();

    switch (fieldDefinition.type) {
      case FieldType.quantity:
        {
          listOfUniqueString = getUniqueInstancesOfNumbers(fieldDefinition);

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
          listOfUniqueString = getUniqueInstancesOfDates(fieldDefinition);

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
          listOfUniqueString = getUniqueInstancesOfWidgets(fieldDefinition);

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
          listOfUniqueString = getUniqueInstances(fieldDefinition);

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
      title: 'Column Filter (${fieldDefinition.name})',
      child: content,
      actionButtons: <Widget>[
        DialogActionButton(
          text: 'Apply',
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
    );
    preferenceController.setString(
      getPreferenceKey(settingKeyFiltersColumns),
      _filterByFieldsValue.toJsonString(),
    );
  }

  void setSelectedItem(final int uniqueId) {
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

  void updateListAndSelect(final int uniqueId) {
    setState(() {
      clearSelection();
      list = getList();
      firstLoadCompleted = true;
      setSelectedItem(uniqueId);
    });
  }

  Widget _buildCenterMessageForEmptyList(final Key key) {
    return CenterMessage(key: key, message: 'No ${getClassNamePlural()}');
  }

  Widget _buildCenterMessageForEmptyListDueToFilters(final Key key) {
    final List<String> activeFilterValues = <String>[];
    if (_filterByText.isNotEmpty) {
      activeFilterValues.add('"$_filterByText"');
    }
    if (_filterByFieldsValue.isNotEmpty) {
      activeFilterValues.addAll(
        _filterByFieldsValue.list.map(
          (FieldFilter filter) => filter.toString(),
        ),
      );
    }

    return Center(
      child: Box(
        key: key,
        padding: SizeForPadding.large,
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextTitle('No ${getClassNamePlural()} found with the filters:'),
              gapLarge(),
              SelectableText(activeFilterValues.join('\n')),
              gapHuge(),
              Row(
                children: <Widget>[
                  const Spacer(),
                  IntrinsicWidth(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _resetFiltersAndGetList();
                        });
                      },
                      child: Row(
                        children: <Widget>[
                          const Text('Clear Filters'),
                          gapSmall(),
                          const Icon(Icons.filter_alt_off_outlined),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInformUserOfEmptyList(Key key) {
    return Column(
      children: <Widget>[
        buildHeader(),
        Expanded(
          child: areFiltersOn()
              ? _buildCenterMessageForEmptyListDueToFilters(key)
              : _buildCenterMessageForEmptyList(key),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Column(
      children: <Widget>[
        buildHeader(),
        const Expanded(child: WorkingIndicator()),
      ],
    );
  }

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

  void _onFilterTextChanged(final String text) {
    setState(() {
      _filterByText = text.toLowerCase();
      saveLastUserChoicesOfView();
      list = getList();
    });
  }

  void _onItemTap(final BuildContext context, final int uniqueId) {
    if (isPlatformMobile()) {
      adaptiveScreenSizeDialog(
        context: context,
        title: '${getClassNameSingular()} #${uniqueId + 1}',
        actionButtons: <Widget>[],
        child: getSidePanelViewDetails(
          selectedIds: <int>[uniqueId],
          isReadOnly: true,
        ),
      );
    }
  }

  void _onUserRequestToEdit(
    final BuildContext context,
    final List<MoneyObject> moneyObjects,
  ) {
    myShowDialogAndActionsForMoneyObjects(
      title: getSingularPluralText(
        'Edit',
        moneyObjects.length,
        getClassNameSingular(),
        getClassNamePlural(),
      ),
      moneyObjects: moneyObjects,
    );
  }

  void _onUserRequestedToDelete(
    final BuildContext context,
    final List<MoneyObject> moneyObjects,
  ) {
    if (moneyObjects.isEmpty) {
      messageBox(context, 'No items to delete');
      return;
    }

    final String nameSingular = getClassNameSingular();
    final String namePlural = getClassNamePlural();

    final String title = getSingularPluralText(
      'Delete',
      moneyObjects.length,
      nameSingular,
      namePlural,
    );

    final String question = moneyObjects.length == 1
        ? 'Are you sure you want to delete this $nameSingular?'
        : 'Are you sure you want to delete the ${moneyObjects.length} selected $namePlural?';
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
      buttonText: 'Delete',
      onConfirmation: () {
        Data().deleteItems(moneyObjects);
      },
    );
  }

  void _resetFiltersAndGetList() {
    _filterByText = '';
    _filterByFieldsValue.clear();

    saveLastUserChoicesOfView();
    list = getList();
  }
}
