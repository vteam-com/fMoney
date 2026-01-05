import 'dart:math';

import 'package:get/get.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/views/data/budget.dart';
import 'package:money/views/data/category.dart';
import 'package:money/views/data/data.dart';
import 'package:money/views/data/domain_buttons.dart';
import 'package:money/views/data/menu_entry.dart';
import 'package:money/views/data/transaction.dart';
import 'package:money/views/view_cashflow/recurring/panel_recurring.dart';
import 'package:money/views/view_cashflow/recurring/recurring_expenses.dart';
import 'package:money/widgets/box.dart';
import 'package:money/widgets/center_message.dart';
import 'package:money/widgets/columns/column_header_button.dart';
import 'package:money/widgets/field_filter.dart';
import 'package:money/widgets/field_filters.dart';
import 'package:money/widgets/money_widget.dart';
import 'package:money/widgets/my_segment.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/theme_controller.dart';
import 'package:money/widgets/token_text.dart';

class PanelBudget extends StatefulWidget {
  const PanelBudget({
    super.key,
    required this.title,
    required this.categoryTypes,
    required this.dateRangeSearch,
    required this.minYear,
    required this.maxYear,
  });

  final List<CategoryType> categoryTypes;
  final DateRange dateRangeSearch;
  final int maxYear;
  final int minYear;
  final String title;

  @override
  State<PanelBudget> createState() => _PanelBudgetState();

  int get numberOfYears => max(1, maxYear - minYear);
}

class _PanelBudgetState extends State<PanelBudget> {
  late BudgetRecommendation _budget;

  bool _sortAscending = false;

  int _sortColumnIndex = 1;

  List<RecurringExpenses> items = <RecurringExpenses>[];

  late BudgetViewAs panelType = isForIncome
      ? PreferenceController.to.budgetViewAsForIncomes.value
      : PreferenceController.to.budgetViewAsForExpenses.value;

  double sumForAllCategories = 0.00;

  double sumForAllCategoriesBudget = 0.00;

  @override
  void initState() {
    super.initState();

    initializeItems();
  }

  @override
  Widget build(final BuildContext context) {
    return Box(
      margin: 8,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: ThemeController.to.isDeviceWidthSmall.value ? _buildContentForSmallScreen() : _buildContentAsList(),
      ),
    );
  }

  String calculateBudgetAccuracy(double budgeted, double actual) {
    if (budgeted == 0 && actual == 0) {
      return 'Both budgeted and actual amounts are zero. Accuracy is undefined.';
    }

    if (actual == 0) {
      return 'Actual amount is zero. Cannot calculate percentages.';
    }

    final double accuracyPercentage = (budgeted / actual) * 100;
    final double variancePercentage = ((actual - budgeted) / budgeted) * 100;

    String result = 'Accuracy:    ${accuracyPercentage.toStringAsFixed(2)}%\n';

    // Check for cases where variance calculation is invalid
    if (budgeted == 0) {
      result += 'Budgeted amount is zero. Variance is undefined.';
    } else {
      result += 'Variance:    ${variancePercentage.toStringAsFixed(2)}%';
    }

    return result;
  }

  void initializeItems() {
    bool whereClause(Transaction t) {
      return t.isCandidateForBudget &&
          isBetweenOrEqual(
            t.fieldDateTime.value!.year,
            widget.minYear,
            widget.maxYear,
          );
    }

    final List<Transaction> transactions = Data().transactions.getListFlattenSplits(whereClause: whereClause);

    final BudgetAnalyzer analyzer = BudgetAnalyzer(transactions);
    _budget = analyzer.calculateMonthlyBudget();

    items = RecurringExpenses.getBudgetedTransactions(
      widget.minYear,
      widget.maxYear,
      true,
      widget.categoryTypes,
      isForIncome ? 1 : -1,
    );

    sumForAllCategories = 0.00;
    sumForAllCategoriesBudget = 0.00;

    final int adjustValue = isForIncome ? 1 : -1;

    items.forEach((RecurringExpenses item) {
      sumForAllCategories += item.sumOfAllTransactions;
      sumForAllCategoriesBudget += item.category.fieldBudget.value.asDouble() * adjustValue;
    });

    _sort();
  }

  bool get isForIncome => widget.categoryTypes.contains(CategoryType.income);

  bool get isListEmpty {
    return items.isEmpty;
  }

  Widget sectionHeader(final BuildContext context) {
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: headerText(context, widget.title, large: true),
        ),
        mySegmentSelector(
          context: context,
          segments: <ButtonSegment<int>>[
            ButtonSegment<int>(
              value: BudgetViewAs.list.index,
              label: const Text('List'),
            ),
            ButtonSegment<int>(
              value: BudgetViewAs.chart.index,
              label: const Text('Chart'),
            ),
            ButtonSegment<int>(
              value: BudgetViewAs.recurrences.index,
              label: const Text('Recurring'),
            ),
            const ButtonSegment<int>(value: 3, label: Text('Suggestion')),
          ],
          selectedId: panelType.index,
          onSelectionChanged: (final int newSelection) {
            setState(() {
              panelType = BudgetViewAs.values[newSelection];
              if (isForIncome) {
                PreferenceController.to.budgetViewAsForIncomes.value = BudgetViewAs.values[newSelection];
              } else {
                PreferenceController.to.budgetViewAsForExpenses.value = BudgetViewAs.values[newSelection];
              }
            });
          },
        ),
      ],
    );
  }

  double get sumForAllCategoriesActual => (sumForAllCategories / widget.numberOfYears) / 12;

  Widget verticalLine(Color color) {
    return SizedBox(height: 38, child: VerticalDivider(color: color));
  }

  Widget _buildContent() {
    switch (panelType) {
      case BudgetViewAs.list:
        return isListEmpty ? const CenterMessage(message: 'No budget income category found') : _buildList();

      case BudgetViewAs.chart:
        return const CenterMessage(message: 'CHART ');

      case BudgetViewAs.recurrences:
        final DateRange dateRangeTransactions = DateRange.fromStarEndYears(
          Data().transactions.dateRangeActiveAccount.min?.year ?? DateTime.now().year,
          Data().transactions.dateRangeActiveAccount.max?.year ?? DateTime.now().year,
        );

        return PanelRecurring(
          dateRangeSearch: dateRangeTransactions,
          minYear: widget.minYear,
          maxYear: widget.maxYear,
          forIncome: isForIncome,
        );

      case BudgetViewAs.suggestions:
        return _buildSuggestion(
          isForIncome
              ? _budget.categoryBudgetsIncomes.entries.toList()
              : _budget.categoryBudgetsExpenses.entries.toList(),
        );
    }
  }

  Widget _buildContentAsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        sectionHeader(context),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContentForSmallScreen() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(widget.title, style: context.textTheme.headlineLarge),
          const SizedBox(height: 20),
          Text('Monthly Budgeted', style: context.textTheme.bodyLarge),
          MoneyWidget.fromDouble(
            sumForAllCategoriesBudget,
            MoneyWidgetSize.header,
          ),
          const SizedBox(height: 10),
          Text('Monthly Actual', style: context.textTheme.bodyLarge),
          MoneyWidget.fromDouble(
            sumForAllCategoriesActual,
            MoneyWidgetSize.header,
          ),
          const SizedBox(height: 20),
          Text(
            calculateBudgetAccuracy(
              sumForAllCategoriesBudget,
              sumForAllCategoriesActual,
            ),
            textAlign: TextAlign.end,
            style: context.textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final Color dividersColor = Theme.of(context).dividerColor.withAlpha(100);
    final int adjustValue = isForIncome ? 1 : -1;

    return Column(
      children: <Widget>[
        Container(
          color: getColorTheme(context).surfaceContainer,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              //
              // Column Header
              //
              Row(
                children: <Widget>[
                  buildColumnHeaderButton(
                    context: context,
                    text: 'Category',
                    textAlign: TextAlign.start,
                    flex: 3,
                    sortIndicator: getSortIndicator(
                      _sortColumnIndex,
                      0,
                      _sortAscending,
                    ),
                    onPressed: () => _onColumnSort(0),
                  ),
                  verticalLine(dividersColor),
                  buildColumnHeaderButton(
                    context: context,
                    text: 'Budgeted/M',
                    textAlign: TextAlign.end,
                    flex: 1,
                    sortIndicator: getSortIndicator(
                      _sortColumnIndex,
                      4,
                      _sortAscending,
                    ),
                    onPressed: () => _onColumnSort(4),
                  ),
                  buildColumnHeaderButton(
                    context: context,
                    text: 'Actual/M',
                    textAlign: TextAlign.end,
                    flex: 1,
                    sortIndicator: getSortIndicator(
                      _sortColumnIndex,
                      3,
                      _sortAscending,
                    ),
                    onPressed: () => _onColumnSort(3),
                  ),
                  verticalLine(dividersColor),
                  buildColumnHeaderButton(
                    context: context,
                    text: 'Budgeted/Y',
                    textAlign: TextAlign.end,
                    flex: 1,
                    sortIndicator: getSortIndicator(
                      _sortColumnIndex,
                      4,
                      _sortAscending,
                    ),
                    onPressed: () => _onColumnSort(4),
                  ),
                  buildColumnHeaderButton(
                    context: context,
                    text: 'Actual/Y',
                    textAlign: TextAlign.end,
                    flex: 1,
                    sortIndicator: getSortIndicator(
                      _sortColumnIndex,
                      2,
                      _sortAscending,
                    ),
                    onPressed: () => _onColumnSort(2),
                  ),
                  verticalLine(dividersColor),
                  buildColumnHeaderButton(
                    context: context,
                    text: 'Range',
                    textAlign: TextAlign.end,
                    flex: 1,
                  ),
                  buildColumnHeaderButton(
                    context: context,
                    text: 'All time',
                    textAlign: TextAlign.end,
                    flex: 1,
                    sortIndicator: getSortIndicator(
                      _sortColumnIndex,
                      1,
                      _sortAscending,
                    ),
                    onPressed: () => _onColumnSort(1),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Column details
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.separated(
              separatorBuilder: (BuildContext context, int index) => Divider(height: 0, color: dividersColor),
              padding: const EdgeInsets.all(0),
              itemCount: items.length,
              itemBuilder: (final BuildContext context, final int index) {
                // build the Card UI
                final RecurringExpenses item = items[index];
                return Row(
                  children: <Widget>[
                    // Category Long Name
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: <Widget>[
                          _categoryContextMenu(item.category),
                          Expanded(child: item.category.getNameAsWidget()),
                        ],
                      ),
                    ),
                    verticalLine(dividersColor),
                    // Budgeted and actual sum per month
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: <Widget>[
                          // Budgeted per month
                          Expanded(
                            child: MoneyWidget.fromDouble(
                              item.category.fieldBudget.value.asDouble() * adjustValue,
                              MoneyWidgetSize.title,
                            ),
                          ),
                          Expanded(
                            child: MoneyWidget.fromDouble(
                              item.sumPerMonth,
                              MoneyWidgetSize.title,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // column line
                    verticalLine(dividersColor),

                    // Budgeted & actual per Year
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: <Widget>[
                          // Budget per year
                          Expanded(
                            child: MoneyWidget.fromDouble(
                              item.category.fieldBudget.value.asDouble() * 12 * adjustValue,
                              MoneyWidgetSize.title,
                            ),
                          ),

                          // Sum per year
                          Expanded(
                            child: MoneyWidget.fromDouble(
                              item.sumPerMonth * 12,
                              MoneyWidgetSize.title,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // column line
                    verticalLine(dividersColor),

                    // Date and range and total sum for all date
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Tooltip(
                              message: item.dates!.toStringDays(),
                              child: Text(
                                item.dates!.toStringYears(),
                                textAlign: TextAlign.right,
                                // style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          Expanded(
                            child: MoneyWidget.fromDouble(
                              item.sumOfAllTransactions,
                              MoneyWidgetSize.title,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            const Expanded(flex: 3, child: Text('')),
            verticalLine(dividersColor),
            Expanded(
              child: MoneyWidget.fromDouble(
                sumForAllCategoriesBudget,
                MoneyWidgetSize.title,
              ),
            ),
            Expanded(
              child: MoneyWidget.fromDouble(
                sumForAllCategoriesActual,
                MoneyWidgetSize.title,
              ),
            ),
            verticalLine(dividersColor),
            Expanded(
              child: MoneyWidget.fromDouble(
                sumForAllCategoriesBudget * 12,
                MoneyWidgetSize.title,
              ),
            ),
            Expanded(
              child: MoneyWidget.fromDouble(
                sumForAllCategories / widget.numberOfYears,
                MoneyWidgetSize.title,
              ),
            ),
            verticalLine(dividersColor),
            const Expanded(child: Text('')),
            Expanded(
              child: MoneyWidget.fromDouble(
                sumForAllCategories,
                MoneyWidgetSize.title,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestion(List<MapEntry<String, BudgetCumulator>> list) {
    final List<Widget> widgets = <Widget>[];

    list.sort(
      (
        MapEntry<String, BudgetCumulator> a,
        MapEntry<String, BudgetCumulator> b,
      ) => a.value.monthlyAmount.compareTo(b.value.monthlyAmount),
    );

    for (final MapEntry<String, BudgetCumulator> categoryBudget in list) {
      widgets.add(
        Row(
          children: <Widget>[
            _categoryContextMenu(
              Data().categories.getByName(categoryBudget.key)!,
            ),
            Expanded(flex: 2, child: TokenText(categoryBudget.key)),
            Expanded(child: Text(categoryBudget.value.frequency.name)),
            Expanded(
              child: MoneyWidget.fromDouble(
                categoryBudget.value.monthlyAmount.round().toDouble(),
              ),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        height: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widgets,
          ),
        ),
      ),
    );
  }

  Widget _categoryContextMenu(final Category category) {
    return buildMenuButton(context, <MenuEntry>[
      // View - Transactions
      MenuEntry.toTransactions(
        transactionId: -1,
        filters: FieldFilters(<FieldFilter>[
          FieldFilter(
            fieldName: Constants.viewTransactionFieldNameCategory,
            strings: <String>[category.name],
          ),
          FieldFilter(
            fieldName: Constants.viewTransactionFieldNameDate,
            byDateRange: true,
            strings: <String>[
              '${widget.minYear}-01-01',
              '${widget.maxYear}-12-31',
            ],
          ),
        ]),
      ),

      // View - Category
      MenuEntry.toCategory(category: category),
      // Edit Category
      MenuEntry.editCategory(
        category: category,
        onApplyChange: () {
          setState(() {
            // refresh the screen
          });
        },
      ),
    ], icon: Icons.more_vert);
  }

  void _onColumnSort(int columnIndex) {
    setState(() {
      if (columnIndex == _sortColumnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
      }
      _sort();
    });
  }

  void _sort() {
    items.sort((RecurringExpenses a, RecurringExpenses b) {
      switch (_sortColumnIndex) {
        case 0:
          return sortByString(a.category.name, b.category.name, _sortAscending);
        case 1:
          return sortByValue(
            a.sumOfAllTransactions,
            b.sumOfAllTransactions,
            _sortAscending,
          );
        case 2:
          return sortByValue(
            a.sumOfAllTransactions,
            b.sumOfAllTransactions,
            _sortAscending,
          );
        case 3:
          return sortByValue(
            a.sumOfAllTransactions,
            b.sumOfAllTransactions,
            _sortAscending,
          );
        case 4:
          return sortByValue(
            a.category.fieldBudget.value.asDouble(),
            b.category.fieldBudget.value.asDouble(),
            _sortAscending,
          );
        default:
          return sortByValue(
            a.sumOfAllTransactions,
            b.sumOfAllTransactions,
            _sortAscending,
          );
      }
    });
  }
}
