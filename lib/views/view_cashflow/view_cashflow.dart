import 'package:get/get.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/views/data.dart';
import 'package:money/views/panels/view_header.dart';
import 'package:money/views/providers/account.dart';
import 'package:money/views/providers/category.dart';
import 'package:money/views/providers/event.dart';
import 'package:money/views/view_cashflow/net_worth_chart.dart';
import 'package:money/views/view_cashflow/recurring/panel_budget.dart';
import 'package:money/views/view_cashflow/recurring/panel_trend.dart';
import 'package:money/views/view_cashflow/sankey_panel.dart';
import 'package:money/widgets/my_segment.dart';
import 'package:money/widgets/pick_number.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/pure/center_message.dart';
import 'package:money/widgets/pure/view.dart';
import 'package:money/widgets/years_range_selector.dart';

const double _headerPadding = 8.0;
const double _zeroDouble = 0.0;
const double _defaultPadding = 10.0;
const int _eventToleranceMin = 0;
const int _eventToleranceMax = 12;

/// Represents view cash flow.
class ViewCashFlow extends ViewWidget {
  const ViewCashFlow({super.key});

  @override
  State<ViewWidget> createState() => _ViewCashFlowState();

  @override
  String getClassNamePlural() => '';

  @override
  String getClassNameSingular() => '';

  @override
  String getDescription() => '';
}

// ignore: always_specify_types
class _ViewCashFlowState extends ViewWidgetState {
  _ViewCashFlowState();

  List<Account> accountsOpened = Data().accounts.getOpenAccounts();
  late DateRange dateRangeTransactions;
  Map<Category, double> mapOfExpenses = <Category, double>{};
  Map<Category, double> mapOfIncomes = <Category, double>{};
  double padding = _defaultPadding;
  late int selectedYearEnd;
  late int selectedYearStart;
  double totalExpenses = _zeroDouble;
  double totalHeight = _zeroDouble;
  double totalIncomes = _zeroDouble;
  double totalInvestments = _zeroDouble;
  double totalNones = _zeroDouble;
  double totalSavings = _zeroDouble;

  final Debouncer _debouncer = Debouncer();

  @override
  Widget buildHeader([final Widget? child]) {
    return const SizedBox();
  }

  @override
  Widget buildViewContent(final Widget child) => const SizedBox();

  @override
  void initState() {
    super.initState();
    dateRangeTransactions = DateRange.fromStarEndYears(
      Data().transactions.dateRangeActiveAccount.min?.year ?? DateTime.now().year,
      Data().transactions.dateRangeActiveAccount.max?.year ?? DateTime.now().year,
    );

    for (final Event event in Data().events.iterableList()) {
      dateRangeTransactions.inflate(event.fieldDateBegin.value);
      dateRangeTransactions.inflate(event.fieldDateEnd.value);
    }

    this.selectedYearStart = dateRangeTransactions.min!.year;
    this.selectedYearEnd = dateRangeTransactions.max!.year;
  }

  @override
  Widget build(final BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header
          ViewHeader.buildViewHeaderContainer(context, _buildHeaderContent()),
          // View
          Expanded(
            child: Container(
              key: Key(
                PreferenceController.to.cashflowViewAs.value.toString() +
                    selectedYearStart.toString() +
                    selectedYearEnd.toString(),
              ),
              // rebuild if the date changes
              color: getColorTheme(context).surface,
              child: _buildView(),
            ),
          ),
        ],
      );
    });
  }

  /// Builds the cashflow view header including view selector and year range controls.
  Widget _buildHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: SizeForPadding.medium,
          spacing: SizeForPadding.large,
          children: <Widget>[
            Text(
              'Cash Flow',
              style: getTextTheme(context).titleLarge,
              textAlign: TextAlign.start,
            ),

            //
            // Select a view
            //
            _buildSelectView(),

            //
            // Optional settings for NetWorth
            //
            if (CashflowViewAs.netWorthOverTime == PreferenceController.to.cashflowViewAs.value)
              NumberPicker(
                title: 'Event Tolerances',
                minValue: _eventToleranceMin,
                maxValue: _eventToleranceMax,
                selectedNumber: PreferenceController.to.netWorthEventThreshold.value,
                onChanged: (int value) {
                  PreferenceController.to.netWorthEventThreshold.value = value;
                },
              ),
            if (CashflowViewAs.trend == PreferenceController.to.cashflowViewAs.value)
              IntrinsicWidth(
                child: Row(
                  children: <Widget>[
                    Obx(
                      () => Checkbox.adaptive(
                        value: PreferenceController.to.trendIncludeAssetAccounts.value,
                        onChanged: (bool? newValue) {
                          if (newValue != null) {
                            PreferenceController.to.trendIncludeAssetAccounts.value = newValue;
                          }
                        },
                      ),
                    ),
                    const Text('Include Asset Accounts'),
                  ],
                ),
              ),
          ],
        ),
        if (Data().transactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _headerPadding),
            child: YearRangeSlider(
              yearRange: NumRange(
                min: dateRangeTransactions.min!.year,
                max: dateRangeTransactions.max!.year,
              ),
              initialRange: NumRange(
                min: dateRangeTransactions.min!.year,
                max: dateRangeTransactions.max!.year,
              ),
              onChanged: (final NumRange updateRange) {
                _debouncer.run(() {
                  if (mounted) {
                    setState(() {
                      this.selectedYearStart = updateRange.min.toInt();
                      this.selectedYearEnd = updateRange.max.toInt();
                    });
                  }
                });
              },
            ),
          ),
      ],
    );
  }

  /// Builds the segmented selector used to choose the cashflow visualization.
  Widget _buildSelectView() {
    return mySegmentSelector(
      context: context,
      segments: <ButtonSegment<int>>[
        ButtonSegment<int>(
          value: CashflowViewAs.sankey.index,
          label: const Text('Sankey'),
        ),
        ButtonSegment<int>(
          value: CashflowViewAs.netWorthOverTime.index,
          label: const Text('NetWorth'),
        ),
        ButtonSegment<int>(
          value: CashflowViewAs.trend.index,
          label: const Text('Trend'),
        ),
        ButtonSegment<int>(
          value: CashflowViewAs.budget.index,
          label: const Text('Budget'),
        ),
      ],
      selectedId: PreferenceController.to.cashflowViewAs.value.index,
      onSelectionChanged: (final int newSelection) {
        PreferenceController.to.cashflowViewAs.value = CashflowViewAs.values[newSelection];
      },
    );
  }

  /// Builds the selected cashflow view for the current year range.
  Widget _buildView() {
    if (Data().transactions.isEmpty) {
      return CenterMessage.noTransaction();
    }

    switch (PreferenceController.to.cashflowViewAs.value) {
      case CashflowViewAs.sankey:
        return SankeyPanel(
          minYear: this.selectedYearStart,
          maxYear: this.selectedYearEnd,
        );

      case CashflowViewAs.netWorthOverTime:
        return NetWorthChart(
          minYear: this.selectedYearStart,
          maxYear: this.selectedYearEnd,
        );

      case CashflowViewAs.budget:
        return Column(
          children: <Widget>[
            Expanded(
              child: PanelBudget(
                title: 'Incomes',
                categoryTypes: <CategoryType>[
                  CategoryType.income,
                  CategoryType.investment,
                  CategoryType.saving,
                ],
                dateRangeSearch: dateRangeTransactions,
                minYear: this.selectedYearStart,
                maxYear: this.selectedYearEnd,
              ),
            ),
            Expanded(
              child: PanelBudget(
                title: 'Expenses',
                categoryTypes: <CategoryType>[
                  CategoryType.expense,
                  CategoryType.recurringExpense,
                ],
                dateRangeSearch: dateRangeTransactions,
                minYear: this.selectedYearStart,
                maxYear: this.selectedYearEnd,
              ),
            ),
          ],
        );
      case CashflowViewAs.trend:
        return Obx(() {
          return PanelTrend(
            dateRangeSearch: dateRangeTransactions,
            minYear: this.selectedYearStart,
            maxYear: this.selectedYearEnd,
            viewRecurringAs: PreferenceController.to.cashflowViewAs.value,
            includeAssetAccounts: PreferenceController.to.trendIncludeAssetAccounts.value,
          );
        });
    }
  }
}
