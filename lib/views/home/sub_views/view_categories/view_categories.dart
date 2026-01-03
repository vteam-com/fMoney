import 'package:money/controller/list_controller.dart';
import 'package:money/controller/selection_controller.dart';
import 'package:money/data/data.dart';
import 'package:money/money_objects/categories/category.dart';
import 'package:money/money_objects/transactions/transaction.dart';
import 'package:money/money_objects/transactions/transactions.dart';
import 'package:money/views/adaptive_list/transactions/list_view_transactions.dart';
import 'package:money/views/adaptive_list/transactions/transaction_timeline_chart.dart';
import 'package:money/views/dialog/dialog.dart';
import 'package:money/views/dialog/dialog_button.dart';
import 'package:money/views/dialog/dialog_mutate_money_object.dart';
import 'package:money/views/home/sub_views/adaptive_view/menu_entry.dart';
import 'package:money/views/home/sub_views/view_categories/merge_categories.dart';
import 'package:money/views/side_panel/side_panel_support.dart';
import 'package:money/widgets/three_part_label.dart';
import 'package:money/widgets_data/charts/chart.dart';
import 'package:money/widgets_data/money_object/currencies/currency.dart';
import 'package:money/widgets_data/money_object/field_filters.dart';
import 'package:money/widgets_data/money_object/money_object.dart';

class ViewCategories extends ViewForMoneyObjects {
  const ViewCategories({super.key});

  @override
  State<ViewForMoneyObjects> createState() => ViewCategoriesState();
}

class ViewCategoriesState extends ViewForMoneyObjectsState {
  ViewCategoriesState() {
    viewId = ViewId.viewCategories;
  }

  final List<Widget> _pivots = <Widget>[];
  final List<bool> _selectedPivot = <bool>[
    false,
    false,
    false,
    false,
    false,
    true,
  ];

  @override
  Widget buildHeader([final Widget? child]) {
    return super.buildHeader(_buildToggles());
  }

  /// add more top level action buttons
  @override
  List<Widget> getActionsButtons(final bool forSidePanelTransactions) {
    final List<Widget> list = super.getActionsButtons(forSidePanelTransactions);
    if (!forSidePanelTransactions) {
      // Add a new Category, place this at the top of the list
      list.insert(
        0,
        buildAddItemButton(() {
          // add a new Category
          final Category? currentSelectedCategory = getFirstSelectedItem() as Category?;
          final Category newItem = Data().categories.addNewCategory(
            parentId: currentSelectedCategory?.uniqueId ?? -1,
          );
          updateListAndSelect(newItem.uniqueId);

          // Queue up the edit dialog
          myShowDialogAndActionsForMoneyObject(
            title: 'New ${getClassNameSingular()}',
            moneyObject: newItem,
            onApplyChange: () {
              setState(() {
                /// update
              });
            },
          );
        }, 'Add new category'),
      );

      /// Merge
      final MoneyObject? moneyObject = getFirstSelectedItem();
      if (moneyObject != null) {
        list.add(
          buildMergeButton(() {
            // let the user pick another Category and move the transactions of the current selected Category to the destination
            adaptiveScreenSizeDialog(
              context: context,
              title: 'Move Category',
              captionForClose: 'Cancel', // this will hide the close button
              child: MergeCategoriesTransactionsDialog(
                categoryToMove: getFirstSelectedItem() as Category,
              ),
            );
          }),
        );
      }

      // this can go last
      final Category? category = getFirstSelectedItem() as Category?;
      if (category != null) {
        list.add(
          buildJumpToButton(context, <MenuEntry>[
            MenuEntry.toTransactions(
              transactionId: -1,
              filters: FieldFilters(<FieldFilter>[
                FieldFilter(
                  fieldName: Constants.viewTransactionFieldNameCategory,
                  strings: <String>[category.uniqueId.toString()],
                ),
              ]),
            ),
          ]),
        );
      }
    }
    return list;
  }

  @override
  String getClassNamePlural() {
    return 'Categories';
  }

  @override
  String getClassNameSingular() {
    return 'Category';
  }

  @override
  String getDescription() {
    return 'Classification of your money transactions.';
  }

  @override
  Fields<Category> getFieldsForTable() {
    return Category.fieldsForColumnView;
  }

  @override
  List<Category> getList({
    bool includeDeleted = false,
    bool applyFilter = true,
  }) {
    final List<CategoryType> filterType = _getSelectedCategoryType();
    final List<Category> list = Data().categories
        .iterableList(includeDeleted: includeDeleted)
        .where(
          (final Category instance) =>
              (filterType.isEmpty || filterType.contains(instance.fieldType.value)) &&
              (applyFilter == false || isMatchingFilters(instance)),
        )
        .toList();
    return list;
  }

  @override
  SidePanelSupport getSidePanelSupport() {
    return SidePanelSupport(
      onDetails: getSidePanelViewDetails,
      onChart: _getSubViewContentForChart,
      onTransactions: _getSubViewContentForTransactions,
    );
  }

  @override
  void initState() {
    super.initState();

    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_none'),
        text1: 'None',
        small: true,
        isVertical: true,
        text2: Currency.getAmountAsStringUsingCurrency(
          _getTotalBalanceOfAccounts(<CategoryType>[CategoryType.none]),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_expenses'),
        text1: 'Expense',
        small: true,
        isVertical: true,
        text2: Currency.getAmountAsStringUsingCurrency(
          _getTotalBalanceOfAccounts(<CategoryType>[
            CategoryType.expense,
            CategoryType.recurringExpense,
          ]),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_income'),
        text1: 'Income',
        small: true,
        isVertical: true,
        text2: Currency.getAmountAsStringUsingCurrency(
          _getTotalBalanceOfAccounts(<CategoryType>[CategoryType.income]),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_saving'),
        text1: 'Saving',
        small: true,
        isVertical: true,
        text2: Currency.getAmountAsStringUsingCurrency(
          _getTotalBalanceOfAccounts(<CategoryType>[CategoryType.saving]),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_investments'),
        text1: 'Investment',
        small: true,
        isVertical: true,
        text2: Currency.getAmountAsStringUsingCurrency(
          _getTotalBalanceOfAccounts(<CategoryType>[CategoryType.investment]),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_all'),
        text1: 'All',
        small: true,
        isVertical: true,
        text2: Currency.getAmountAsStringUsingCurrency(
          _getTotalBalanceOfAccounts(<CategoryType>[]),
        ),
      ),
    );
  }

  Widget _buildToggles() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
      child: ToggleButtons(
        direction: Axis.horizontal,
        onPressed: (final int index) {
          setState(() {
            for (int i = 0; i < _selectedPivot.length; i++) {
              _selectedPivot[i] = i == index;
            }
            list = getList();
            clearSelection();
          });
        },
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        constraints: const BoxConstraints(minHeight: 40.0, minWidth: 100.0),
        isSelected: _selectedPivot,
        children: _pivots,
      ),
    );
  }

  List<CategoryType> _getSelectedCategoryType() {
    if (_selectedPivot[0]) {
      return <CategoryType>[CategoryType.none];
    }
    if (_selectedPivot[1]) {
      return <CategoryType>[
        CategoryType.expense,
        CategoryType.recurringExpense,
      ];
    }
    if (_selectedPivot[2]) {
      return <CategoryType>[CategoryType.income];
    }
    if (_selectedPivot[3]) {
      return <CategoryType>[CategoryType.saving];
    }
    if (_selectedPivot[4]) {
      return <CategoryType>[CategoryType.investment];
    }

    return <CategoryType>[]; // all
  }

  double _getTotalBalanceOfAccounts(final List<CategoryType> types) {
    double total = 0.0;
    getList().forEach((final Category category) {
      if (types.isEmpty || category.fieldType.value == types.first) {
        total += category.fieldSum.value.asDouble();
      }
    });
    return total;
  }

  List<Transaction> _getTransactionsFromSelectedIds(
    final List<int> selectedIds,
  ) {
    final Category? category = getMoneyObjectFromFirstSelectedId<Category>(
      selectedIds,
      list,
    );
    if (category != null) {
      final List<int> listOfDescendentCategories = <int>[];
      Data().categories.getTreeIdsRecursive(
        category.uniqueId,
        listOfDescendentCategories,
      );
      return getTransactions(
        flattenSplits: true,
        filter: (final Transaction transaction) =>
            listOfDescendentCategories.contains(transaction.fieldCategoryId.value),
      );
    }
    return <Transaction>[];
  }

  /// Details panels Chart panel for Categories
  Widget _getSubViewContentForChart({
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency,
  }) {
    if (selectedIds.isEmpty) {
      final Map<String, num> map = <String, num>{};

      for (final Category item in getList()) {
        if (item.fieldName.value != 'Split' && item.fieldName.value != 'Xfer to Deleted Account') {
          final Category topCategory = Data().categories.getTopAncestor(item);
          if (map[topCategory.fieldName.value] == null) {
            map[topCategory.fieldName.value] = 0;
          }
          map[topCategory.fieldName.value] = map[topCategory.fieldName.value]! + item.fieldSum.value.asDouble();
        }
      }
      final List<PairXYY> listChart = <PairXYY>[];
      map.forEach((final String key, final num value) {
        listChart.add(PairXYY(key, value));
      });

      listChart.sort((final PairXYY a, final PairXYY b) {
        return (b.yValue1.abs() - a.yValue1.abs()).toInt();
      });

      return Chart(
        key: Key(selectedIds.toString()),
        list: listChart.take(10).toList(),
      );
    } else {
      return TransactionTimelineChart(
        transactions: _getTransactionsFromSelectedIds(selectedIds),
      );
    }
  }

  // Details Panel for Transactions Categories
  Widget _getSubViewContentForTransactions({
    required final List<int> selectedIds,
    required bool showAsNativeCurrency,
  }) {
    final SelectionController selectionController = Get.put(
      SelectionController(),
    );

    return ListViewTransactions(
      listController: Get.find<ListControllerSidePanel>(),
      columnsToInclude: <Field<dynamic>>[
        Transaction.fields.getFieldByName(columnIdDate),
        Transaction.fields.getFieldByName(columnIdAccount),
        Transaction.fields.getFieldByName(columnIdPayee),
        Transaction.fields.getFieldByName(columnIdCategory),
        Transaction.fields.getFieldByName(columnIdMemo),
        Transaction.fields.getFieldByName(columnIdAmount),
      ],
      getList: () => _getTransactionsFromSelectedIds(selectedIds),
      selectionController: selectionController,
    );
  }
}
