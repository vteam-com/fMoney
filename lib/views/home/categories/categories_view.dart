import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/data/models/field_filter_model.dart';
import 'package:money/data/models/pair_xyz_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transactions_collection.dart';
import 'package:money/shared/presentation/dialogs/mutate_money_object_dialog.dart';
import 'package:money/shared/presentation/helpers/menu_entry_model.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/panels/charts/transaction_timeline_chart.dart';
import 'package:money/views/panels/dialogs/merge_categories_dialog.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/views/panels/list/transactions_list_view.dart';
import 'package:money/widgets/charts/chart_widget.dart';
import 'package:money/widgets/components/three_part_label_widget.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';
import 'package:money/widgets/state/selection_controller.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_filters_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

const int _zeroIndex = 0;
const int _pivotIndexNone = 0;
const int _pivotIndexExpense = 1;
const int _pivotIndexIncome = 2;
const int _pivotIndexSaving = 3;
const int _pivotIndexInvestment = 4;
const int _unsetId = -1;
const double _zeroDouble = 0.0;
const double _toggleMinHeight = 40.0;
const double _toggleMinWidth = 100.0;
const double _headerPadding = 5.0;
const double _toggleRadius = 8.0;
const int _chartMaxItems = 10;

/// Represents view categories.
class ViewCategories extends ViewForMoneyObjects {
  const ViewCategories({super.key});

  @override
  State<ViewForMoneyObjects> createState() => _ViewCategoriesState();
}

class _ViewCategoriesState extends ViewForMoneyObjectsState {
  _ViewCategoriesState() {
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
        _zeroIndex,
        buildAddItemButton(() {
          // add a new Category
          final Category? currentSelectedCategory = getFirstSelectedItem() as Category?;
          final Category newItem = Data().categories.addNewCategory(
            parentId: currentSelectedCategory?.uniqueId ?? _unsetId,
          );
          updateListAndSelect(newItem.uniqueId);

          // Queue up the edit dialog
          myShowDialogAndActionsForMoneyObject(
            title: AppL10n.tr(
              AppTranslationKeys.newItemLabel,
              params: <String, String>{'item': getClassNameSingular()},
            ),
            moneyObject: newItem,
            onApplyChange: () {
              setState(() {
                /// update
              });
            },
          );
        }, AppL10n.tr(AppTranslationKeys.addNewCategory)),
      );

      /// Merge
      final DataObject? moneyObject = getFirstSelectedItem();
      if (moneyObject != null) {
        list.add(
          buildMergeButton(() {
            // let the user pick another Category and move the transactions of the current selected Category to the destination
            adaptiveScreenSizeDialog(
              context: context,
              title: AppL10n.tr(AppTranslationKeys.moveCategory),
              captionForClose: AppL10n.tr(AppTranslationKeys.cancel), // this will hide the close button
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
              transactionId: _unsetId,
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
    return AppL10n.tr(AppTranslationKeys.categories);
  }

  @override
  String getClassNameSingular() {
    return AppL10n.tr(AppTranslationKeys.category);
  }

  @override
  String getDescription() {
    return AppL10n.tr(AppTranslationKeys.categoriesDescription);
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
        text1: AppL10n.tr(AppTranslationKeys.noneLabel),
        small: true,
        isVertical: true,
        text2: getAmountAsStringUsingCurrency(
          _getTotalBalanceOfAccounts(<CategoryType>[CategoryType.none]),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_expenses'),
        text1: AppL10n.tr(AppTranslationKeys.expenseLabel),
        small: true,
        isVertical: true,
        text2: getAmountAsStringUsingCurrency(
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
        text1: AppL10n.tr(AppTranslationKeys.incomeLabel),
        small: true,
        isVertical: true,
        text2: getAmountAsStringUsingCurrency(
          _getTotalBalanceOfAccounts(<CategoryType>[CategoryType.income]),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_saving'),
        text1: AppL10n.tr(AppTranslationKeys.savingLabel),
        small: true,
        isVertical: true,
        text2: getAmountAsStringUsingCurrency(
          _getTotalBalanceOfAccounts(<CategoryType>[CategoryType.saving]),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_investments'),
        text1: AppL10n.tr(AppTranslationKeys.investment),
        small: true,
        isVertical: true,
        text2: getAmountAsStringUsingCurrency(
          _getTotalBalanceOfAccounts(<CategoryType>[CategoryType.investment]),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_all'),
        text1: AppL10n.tr(AppTranslationKeys.allLabel),
        small: true,
        isVertical: true,
        text2: getAmountAsStringUsingCurrency(
          _getTotalBalanceOfAccounts(<CategoryType>[]),
        ),
      ),
    );
  }

  /// Builds the horizontal toggle row used to filter categories by type.
  Widget _buildToggles() {
    return buildStandardPivotToggleRow(
      selectedPivot: _selectedPivot,
      pivotChildren: _pivots,
      padding: const EdgeInsets.only(bottom: _headerPadding),
      borderRadius: const BorderRadius.all(Radius.circular(_toggleRadius)),
      minHeight: _toggleMinHeight,
      minWidth: _toggleMinWidth,
    );
  }

  /// Returns the selected category type filter based on the current pivot toggle.
  List<CategoryType> _getSelectedCategoryType() {
    if (_selectedPivot[_pivotIndexNone]) {
      return <CategoryType>[CategoryType.none];
    }
    if (_selectedPivot[_pivotIndexExpense]) {
      return <CategoryType>[
        CategoryType.expense,
        CategoryType.recurringExpense,
      ];
    }
    if (_selectedPivot[_pivotIndexIncome]) {
      return <CategoryType>[CategoryType.income];
    }
    if (_selectedPivot[_pivotIndexSaving]) {
      return <CategoryType>[CategoryType.saving];
    }
    if (_selectedPivot[_pivotIndexInvestment]) {
      return <CategoryType>[CategoryType.investment];
    }

    return <CategoryType>[]; // all
  }

  /// Sums balances across the currently listed categories, optionally filtered by type.
  double _getTotalBalanceOfAccounts(final List<CategoryType> types) {
    double total = _zeroDouble;
    getList().forEach((final Category category) {
      if (types.isEmpty || category.fieldType.value == types.first) {
        total += category.fieldSum.value.asDouble();
      }
    });
    return total;
  }

  /// Returns transactions whose categories fall within the selected category subtree.
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
    keepUnused(showAsNativeCurrency);
    if (selectedIds.isEmpty) {
      final Map<String, num> map = <String, num>{};

      for (final Category item in getList()) {
        if (item.fieldName.value != 'Split' && item.fieldName.value != 'Xfer to Deleted Account') {
          final Category topCategory = Data().categories.getTopAncestor(item);
          if (map[topCategory.fieldName.value] == null) {
            map[topCategory.fieldName.value] = _zeroDouble;
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
        list: listChart.take(_chartMaxItems).toList(),
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
    keepUnused(showAsNativeCurrency);
    final SelectionController selectionController = SelectionController();

    return ListViewTransactions(
      listController: AppScope.instance.listControllerSidePanel,
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
