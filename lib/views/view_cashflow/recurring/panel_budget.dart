import 'dart:math';

import 'package:get/get.dart';
import 'package:money/data/budget.dart';
import 'package:money/data/collections/data.dart';
import 'package:money/data/entities/category.dart';
import 'package:money/data/entities/transaction.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/views/menu_entry.dart';
import 'package:money/views/view_cashflow/recurring/panel_recurring.dart';
import 'package:money/views/view_cashflow/recurring/recurring_expenses.dart';
import 'package:money/widgets/columns/column_header_button.dart';
import 'package:money/widgets/my_segment.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/pure/box.dart';
import 'package:money/widgets/pure/center_message.dart';
import 'package:money/widgets/theme_controller.dart';
import 'package:money/widgets/token_text.dart';
import 'package:money/widgets/widgets_domain/field_filter.dart';
import 'package:money/widgets/widgets_domain/field_filters.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const int _minYears = 1;
const int _defaultSortColumnIndex = 1;
const double _positiveMultiplier = 1.0;
const double _negativeMultiplier = -1.0;
const int _suggestionSegmentValue = 3;
const int _unsetId = -1;
const int _monthsPerYear = 12;
const double _percentageMultiplier = 100.0;
const int _percentageDecimalPlaces = 2;
const double _zeroDouble = 0.0;
const double _panelMargin = 8.0;
const double _headerPadding = 8.0;
const double _smallScreenMaxWidth = 400.0;
const double _suggestionsMaxWidth = 800.0;
const double _suggestionsHeight = 400.0;
const double _spacingLarge = 20.0;
const double _spacingMedium = 10.0;
const double _verticalDividerHeight = 38.0;
const double _zeroHeight = 0.0;
const int _dividerAlpha = 100;
const int _columnFlexCategory = 3;
const int _columnFlexDouble = 2;
const int _columnFlexSingle = 1;
const int _sortColumnCategory = 0;
const int _sortColumnAllTime = 1;
const int _sortColumnActualYear = 2;
const int _sortColumnActualMonth = 3;
const int _sortColumnBudget = 4;

/// A stateful widget for panel budget.
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

  /// Returns the number of years covered by the budget panel.
  int get numberOfYears => max(_minYears, maxYear - minYear);
}

class _PanelBudgetState extends State<PanelBudget> {
  late BudgetRecommendation _budget;

  bool _sortAscending = false;

  int _sortColumnIndex = _defaultSortColumnIndex;

  List<RecurringExpenses> items = <RecurringExpenses>[];

  late BudgetViewAs panelType = isForIncome
      ? PreferenceController.to.budgetViewAsForIncomes.value
      : PreferenceController.to.budgetViewAsForExpenses.value;

  double sumForAllCategories = _zeroDouble;

  double sumForAllCategoriesBudget = _zeroDouble;

  @override
  void initState() {
    super.initState();

    initializeItems();
  }

  @override
  Widget build(final BuildContext context) {
    return Box(
      margin: _panelMargin,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: ThemeController.to.isDeviceWidthSmall.value ? _buildContentForSmallScreen() : _buildContentAsList(),
      ),
    );
  }

  /// Calculates a descriptive accuracy string comparing budgeted vs actual amounts.
  String calculateBudgetAccuracy(double budgeted, double actual) {
    if (budgeted == _zeroDouble && actual == _zeroDouble) {
      return 'Both budgeted and actual amounts are zero. Accuracy is undefined.';
    }

    if (actual == _zeroDouble) {
      return 'Actual amount is zero. Cannot calculate percentages.';
    }

    final double accuracyPercentage = (budgeted / actual) * _percentageMultiplier;
    final double variancePercentage = ((actual - budgeted) / budgeted) * _percentageMultiplier;

    String result = 'Accuracy:    ${accuracyPercentage.toStringAsFixed(_percentageDecimalPlaces)}%\n';

    // Check for cases where variance calculation is invalid
    if (budgeted == _zeroDouble) {
      result += 'Budgeted amount is zero. Variance is undefined.';
    } else {
      result += 'Variance:    ${variancePercentage.toStringAsFixed(_percentageDecimalPlaces)}%';
    }

    return result;
  }

  /// Initializes the budget items from data based on current filters.
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
      isForIncome ? _positiveMultiplier : _negativeMultiplier,
    );

    sumForAllCategories = _zeroDouble;
    sumForAllCategoriesBudget = _zeroDouble;

    final double adjustValue = isForIncome ? _positiveMultiplier : _negativeMultiplier;

    items.forEach((RecurringExpenses item) {
      sumForAllCategories += item.sumOfAllTransactions;
      sumForAllCategoriesBudget += item.category.fieldBudget.value.asDouble() * adjustValue;
    });

    _sort();
  }

  /// Returns true if the panel is configured for income categories.
  bool get isForIncome => widget.categoryTypes.contains(CategoryType.income);

  /// Returns true if there are no budget items to display.
  bool get isListEmpty => items.isEmpty;

  /// Builds a section header widget with title and controls.
  Widget sectionHeader(final BuildContext context) {
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(_headerPadding),
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
            const ButtonSegment<int>(value: _suggestionSegmentValue, label: Text('Suggestion')),
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

  /// Returns the sum of actual amounts across all categories per year.
  double get sumForAllCategoriesActual => (sumForAllCategories / widget.numberOfYears) / _monthsPerYear;

  /// Builds a vertical line divider widget with specified color.
  Widget verticalLine(Color color) {
    return SizedBox(
      height: _verticalDividerHeight,
      child: VerticalDivider(color: color),
    );
  }

  /// Builds the main panel content based on the current [panelType] selection.
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

  /// Builds the panel layout with a section header above the active content.
  Widget _buildContentAsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        sectionHeader(context),
        Expanded(child: _buildContent()),
      ],
    );
  }

  /// Builds a condensed summary view optimized for small screen widths.
  Widget _buildContentForSmallScreen() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _smallScreenMaxWidth),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(widget.title, style: context.textTheme.headlineLarge),
          const SizedBox(height: _spacingLarge),
          Text('Monthly Budgeted', style: context.textTheme.bodyLarge),
          WidgetFromData.fromDouble(
            sumForAllCategoriesBudget,
            DataWidgetSize.header,
          ),
          const SizedBox(height: _spacingMedium),
          Text('Monthly Actual', style: context.textTheme.bodyLarge),
          WidgetFromData.fromDouble(
            sumForAllCategoriesActual,
            DataWidgetSize.header,
          ),
          const SizedBox(height: _spacingLarge),
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

  /// Builds the budget list view with sortable columns and a summary footer.
  Widget _buildList() {
    final Color dividersColor = Theme.of(context).dividerColor.withAlpha(_dividerAlpha);
    final double adjustValue = isForIncome ? _positiveMultiplier : _negativeMultiplier;

    return Column(
      children: <Widget>[
        Container(
          color: getColorTheme(context).surfaceContainer,
          padding: const EdgeInsets.all(_headerPadding),
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
                    flex: _columnFlexCategory,
                    sortIndicator: getSortIndicator(
                      _sortColumnIndex,
                      _sortColumnCategory,
                      _sortAscending,
                    ),
                    onPressed: () => _onColumnSort(_sortColumnCategory),
                  ),
                  verticalLine(dividersColor),
                  buildColumnHeaderButton(
                    context: context,
                    text: 'Budgeted/M',
                    textAlign: TextAlign.end,
                    flex: _columnFlexSingle,
                    sortIndicator: getSortIndicator(
                      _sortColumnIndex,
                      _sortColumnBudget,
                      _sortAscending,
                    ),
                    onPressed: () => _onColumnSort(_sortColumnBudget),
                  ),
                  buildColumnHeaderButton(
                    context: context,
                    text: 'Actual/M',
                    textAlign: TextAlign.end,
                    flex: _columnFlexSingle,
                    sortIndicator: getSortIndicator(
                      _sortColumnIndex,
                      _sortColumnActualMonth,
                      _sortAscending,
                    ),
                    onPressed: () => _onColumnSort(_sortColumnActualMonth),
                  ),
                  verticalLine(dividersColor),
                  buildColumnHeaderButton(
                    context: context,
                    text: 'Budgeted/Y',
                    textAlign: TextAlign.end,
                    flex: _columnFlexSingle,
                    sortIndicator: getSortIndicator(
                      _sortColumnIndex,
                      _sortColumnBudget,
                      _sortAscending,
                    ),
                    onPressed: () => _onColumnSort(_sortColumnBudget),
                  ),
                  buildColumnHeaderButton(
                    context: context,
                    text: 'Actual/Y',
                    textAlign: TextAlign.end,
                    flex: _columnFlexSingle,
                    sortIndicator: getSortIndicator(
                      _sortColumnIndex,
                      _sortColumnActualYear,
                      _sortAscending,
                    ),
                    onPressed: () => _onColumnSort(_sortColumnActualYear),
                  ),
                  verticalLine(dividersColor),
                  buildColumnHeaderButton(
                    context: context,
                    text: 'Range',
                    textAlign: TextAlign.end,
                    flex: _columnFlexSingle,
                  ),
                  buildColumnHeaderButton(
                    context: context,
                    text: 'All time',
                    textAlign: TextAlign.end,
                    flex: _columnFlexSingle,
                    sortIndicator: getSortIndicator(
                      _sortColumnIndex,
                      _sortColumnAllTime,
                      _sortAscending,
                    ),
                    onPressed: () => _onColumnSort(_sortColumnAllTime),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Column details
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(_headerPadding),
            child: ListView.separated(
              separatorBuilder: (BuildContext _, int _) => Divider(height: _zeroHeight, color: dividersColor),
              padding: const EdgeInsets.all(_zeroHeight),
              itemCount: items.length,
              itemBuilder: (final BuildContext _, final int index) {
                // build the Card UI
                final RecurringExpenses item = items[index];
                return Row(
                  children: <Widget>[
                    // Category Long Name
                    Expanded(
                      flex: _columnFlexCategory,
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
                      flex: _columnFlexDouble,
                      child: Row(
                        children: <Widget>[
                          // Budgeted per month
                          Expanded(
                            child: WidgetFromData.fromDouble(
                              item.category.fieldBudget.value.asDouble() * adjustValue,
                              DataWidgetSize.title,
                            ),
                          ),
                          Expanded(
                            child: WidgetFromData.fromDouble(
                              item.sumPerMonth,
                              DataWidgetSize.title,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // column line
                    verticalLine(dividersColor),

                    // Budgeted & actual per Year
                    Expanded(
                      flex: _columnFlexDouble,
                      child: Row(
                        children: <Widget>[
                          // Budget per year
                          Expanded(
                            child: WidgetFromData.fromDouble(
                              item.category.fieldBudget.value.asDouble() * _monthsPerYear * adjustValue,
                              DataWidgetSize.title,
                            ),
                          ),

                          // Sum per year
                          Expanded(
                            child: WidgetFromData.fromDouble(
                              item.sumPerMonth * _monthsPerYear,
                              DataWidgetSize.title,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // column line
                    verticalLine(dividersColor),

                    // Date and range and total sum for all date
                    Expanded(
                      flex: _columnFlexDouble,
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
                            child: WidgetFromData.fromDouble(
                              item.sumOfAllTransactions,
                              DataWidgetSize.title,
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
            const Expanded(flex: _columnFlexCategory, child: Text('')),
            verticalLine(dividersColor),
            Expanded(
              child: WidgetFromData.fromDouble(
                sumForAllCategoriesBudget,
                DataWidgetSize.title,
              ),
            ),
            Expanded(
              child: WidgetFromData.fromDouble(
                sumForAllCategoriesActual,
                DataWidgetSize.title,
              ),
            ),
            verticalLine(dividersColor),
            Expanded(
              child: WidgetFromData.fromDouble(
                sumForAllCategoriesBudget * _monthsPerYear,
                DataWidgetSize.title,
              ),
            ),
            Expanded(
              child: WidgetFromData.fromDouble(
                sumForAllCategories / widget.numberOfYears,
                DataWidgetSize.title,
              ),
            ),
            verticalLine(dividersColor),
            const Expanded(child: Text('')),
            Expanded(
              child: WidgetFromData.fromDouble(
                sumForAllCategories,
                DataWidgetSize.title,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the suggested budget list for categories based on observed transactions.
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
            Expanded(flex: _columnFlexDouble, child: TokenText(categoryBudget.key)),
            Expanded(child: Text(categoryBudget.value.frequency.name)),
            Expanded(
              child: WidgetFromData.fromDouble(
                categoryBudget.value.monthlyAmount.round().toDouble(),
              ),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: _suggestionsMaxWidth),
        height: _suggestionsHeight,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widgets,
          ),
        ),
      ),
    );
  }

  /// Builds the context menu for a category row.
  Widget _categoryContextMenu(final Category category) {
    return buildMenuButton(context, <MenuEntry>[
      // View - Transactions
      MenuEntry.toTransactions(
        transactionId: _unsetId,
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

  /// Updates the active sort column and direction, then re-sorts the list.
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

  /// Sorts the budget items according to the selected column and direction.
  void _sort() {
    items.sort((RecurringExpenses a, RecurringExpenses b) {
      switch (_sortColumnIndex) {
        case _sortColumnCategory:
          return sortByString(a.category.name, b.category.name, _sortAscending);
        case _sortColumnAllTime:
          return sortByValue(
            a.sumOfAllTransactions,
            b.sumOfAllTransactions,
            _sortAscending,
          );
        case _sortColumnActualYear:
          return sortByValue(
            a.sumOfAllTransactions,
            b.sumOfAllTransactions,
            _sortAscending,
          );
        case _sortColumnActualMonth:
          return sortByValue(
            a.sumOfAllTransactions,
            b.sumOfAllTransactions,
            _sortAscending,
          );
        case _sortColumnBudget:
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
