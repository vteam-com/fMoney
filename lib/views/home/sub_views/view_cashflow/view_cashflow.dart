import 'package:get/get.dart';
import 'package:money/controller/preferences_controller.dart';
import 'package:money/data/data.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/models/money_objects/accounts/account.dart';
import 'package:money/models/money_objects/categories/category.dart';
import 'package:money/models/money_objects/events/event.dart';
import 'package:money/views/home/sub_views/view.dart';
import 'package:money/views/home/sub_views/view_cashflow/net_worth_chart.dart';
import 'package:money/views/home/sub_views/view_cashflow/recurring/panel_budget.dart';
import 'package:money/views/home/sub_views/view_cashflow/recurring/panel_trend.dart';
import 'package:money/views/home/sub_views/view_cashflow/sankey_panel.dart';
import 'package:money/views/home/sub_views/view_header.dart';
import 'package:money/widgets/center_message.dart';
import 'package:money/widgets/my_segment.dart';
import 'package:money/widgets/pick_number.dart';
import 'package:money/widgets/years_range_selector.dart';

class ViewCashFlow extends ViewWidget {
  const ViewCashFlow({super.key});

  @override
  State<ViewWidget> createState() => ViewCashFlowState();

  @override
  String getClassNamePlural() => '';

  @override
  String getClassNameSingular() => '';

  @override
  String getDescription() => '';
}

// ignore: always_specify_types
class ViewCashFlowState extends ViewWidgetState {
  ViewCashFlowState();

  List<Account> accountsOpened = Data().accounts.getOpenAccounts();
  late DateRange dateRangeTransactions;
  Map<Category, double> mapOfExpenses = <Category, double>{};
  Map<Category, double> mapOfIncomes = <Category, double>{};
  double padding = 10.0;
  late int selectedYearEnd;
  late int selectedYearStart;
  double totalExpenses = 0.00;
  double totalHeight = 0.0;
  double totalIncomes = 0.00;
  double totalInvestments = 0.00;
  double totalNones = 0.00;
  double totalSavings = 0.00;

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
                minValue: 0,
                maxValue: 12,
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
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
