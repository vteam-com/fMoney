import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/pair_xyz_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transactions_collection.dart';
import 'package:money/shared/presentation/helpers/menu_entry_model.dart';
import 'package:money/views/panels/charts/transaction_timeline_chart.dart';
import 'package:money/views/panels/dialogs/merge_categories_dialog.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/list/add_new_item_button_mixin.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/views/panels/list/side_panel_lists_helper.dart';
import 'package:money/views/panels/list/transactions_list_view.dart';
import 'package:money/widgets/charts/chart_widget.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';

const double _zeroDouble = 0.0;
const int _chartMaxItems = 10;

/// Pivot toggles in order: widget key, label translation key and the category types listed (all when empty).
const List<(Key, String, List<CategoryType>)> _pivots = <(Key, String, List<CategoryType>)>[
  (Key('key_toggle_show_none'), AppTranslationKeys.noneLabel, <CategoryType>[CategoryType.none]),
  (
    Key('key_toggle_show_expenses'),
    AppTranslationKeys.expenseLabel,
    <CategoryType>[CategoryType.expense, CategoryType.recurringExpense],
  ),
  (Key('key_toggle_show_income'), AppTranslationKeys.incomeLabel, <CategoryType>[CategoryType.income]),
  (Key('key_toggle_show_saving'), AppTranslationKeys.savingLabel, <CategoryType>[CategoryType.saving]),
  (Key('key_toggle_show_investments'), AppTranslationKeys.investment, <CategoryType>[CategoryType.investment]),
  (Key('key_toggle_show_all'), AppTranslationKeys.allLabel, <CategoryType>[]),
];

/// Represents view categories.
class ViewCategories extends ViewForMoneyObjects {
  const ViewCategories({super.key});

  @override
  State<ViewForMoneyObjects> createState() => _ViewCategoriesState();
}

class _ViewCategoriesState extends ViewForMoneyObjectsState with AddNewItemButtonMixin {
  _ViewCategoriesState() {
    viewId = ViewId.viewCategories;
  }

  final List<bool> _selectedPivot = <bool>[
    false,
    false,
    false,
    false,
    false,
    true,
  ];

  @override
  String get addNewItemTooltip => AppL10n.tr(AppTranslationKeys.addNewCategory);

  /// Creates a category under the selected one, if any.
  @override
  DataObject createNewItem() {
    final Category? currentSelectedCategory = getFirstSelectedItem() as Category?;
    return Data().categories.addNewCategory(parentId: currentSelectedCategory?.uniqueId ?? -1);
  }

  @override
  Widget buildHeader([Widget? child]) {
    return super.buildHeader(_buildToggles());
  }

  /// add more top level action buttons
  @override
  List<Widget> getActionsButtons(bool forSidePanelTransactions) {
    final List<Widget> list = super.getActionsButtons(forSidePanelTransactions);
    if (!forSidePanelTransactions) {
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
        list.add(buildJumpToButton(context, <MenuEntry>[MenuEntry.toTransactionsOfCategory(category: category)]));
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
          (Category instance) =>
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
      onTransactions: getSidePanelViewTransactions,
    );
  }

  /// Builds the horizontal toggle row used to filter categories by type, each with the sum of its categories.
  Widget _buildToggles() {
    return buildStandardPivotToggleRow(
      selectedPivot: _selectedPivot,
      pivots: <(Key?, String, String)>[
        for (final (Key key, String labelKey, List<CategoryType> types) in _pivots)
          (key, AppL10n.tr(labelKey), getAmountAsStringUsingCurrency(_getTotalBalanceOfCategories(types))),
      ],
    );
  }

  /// Returns the category types listed by the selected pivot toggle; all when empty.
  List<CategoryType> _getSelectedCategoryType() => _pivots[_selectedPivot.indexOf(true)].$3;

  /// Sums the categories of [types] (all when empty) matching the view filters.
  double _getTotalBalanceOfCategories(List<CategoryType> types) {
    double total = _zeroDouble;
    for (final Category category in Data().categories.iterableList()) {
      if ((types.isEmpty || types.contains(category.fieldType.value)) && isMatchingFilters(category)) {
        total += category.fieldSum.value.asDouble();
      }
    }
    return total;
  }

  /// Returns transactions whose categories fall within the selected category subtree.
  List<Transaction> _getTransactionsFromSelectedIds(
    List<int> selectedIds,
  ) {
    final Category? category = getMoneyObjectFromFirstSelectedId<Category>(
      selectedIds,
      list,
    );
    if (category != null) {
      final List<int> listOfDescendentCategories = Data().categories.getTreeIds(category.uniqueId);
      return getTransactions(
        flattenSplits: true,
        filter: (Transaction transaction) => listOfDescendentCategories.contains(transaction.fieldCategoryId.value),
      );
    }
    return <Transaction>[];
  }

  /// Details panels Chart panel for Categories
  Widget _getSubViewContentForChart({
    required List<int> selectedIds,
    required bool showAsNativeCurrency,
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
      map.forEach((String key, num value) {
        listChart.add(PairXYY(key, value));
      });

      listChart.sort((PairXYY a, PairXYY b) {
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

  @override
  List<DataObject> getSidePanelTransactions() {
    final int? firstSelectedId = getUniqueIdOfFirstSelectedItem();
    return _getTransactionsFromSelectedIds(
      firstSelectedId == null ? <int>[] : <int>[firstSelectedId],
    );
  }
}
