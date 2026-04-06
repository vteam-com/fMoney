import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/data/models/ranges_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/event_entity.dart';
import 'package:money/views/panels/charts/net_worth_chart.dart';
import 'package:money/views/panels/charts/sankey_panel.dart';
import 'package:money/views/panels/charts/trend_panel.dart';
import 'package:money/views/panels/recurring/views/budget_panel.dart';
import 'package:money/widgets/components/my_segment_widget.dart';
import 'package:money/widgets/list/view_header_widget.dart';
import 'package:money/widgets/pickers/number_picker_widget.dart';
import 'package:money/widgets/pure/center_message_widget.dart';
import 'package:money/widgets/pure/view_widget.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/timeline/years_range_selector.dart';

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
    return ListenableBuilder(
      listenable: PreferenceController.to,
      builder: (BuildContext context, Widget? _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Header
            ViewHeader.buildViewHeaderContainer(context, _buildHeaderContent()),
            // View
            Expanded(
              child: Container(
                key: Key(
                  PreferenceController.to.cashflowViewAs.toString() +
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
      },
    );
  }

  /// Builds the trend asset-account toggle.
  Widget _buildIncludeAssetAccountsToggle() {
    return Row(
      children: <Widget>[
        Checkbox.adaptive(
          value: PreferenceController.to.trendIncludeAssetAccounts,
          onChanged: (bool? newValue) {
            if (newValue != null) {
              PreferenceController.to.setTrendIncludeAssetAccounts(newValue);
            }
          },
        ),
        Text(AppL10n.tr(AppTranslationKeys.includeAssetAccounts)),
      ],
    );
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
              AppL10n.tr(AppTranslationKeys.cashFlow),
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
            if (CashflowViewAs.netWorthOverTime == PreferenceController.to.cashflowViewAs)
              NumberPicker(
                title: AppL10n.tr(AppTranslationKeys.eventTolerances),
                minValue: _eventToleranceMin,
                maxValue: _eventToleranceMax,
                selectedNumber: PreferenceController.to.netWorthEventThreshold,
                onChanged: (int value) {
                  PreferenceController.to.setNetWorthEventThreshold(value);
                },
              ),
            if (CashflowViewAs.trend == PreferenceController.to.cashflowViewAs)
              IntrinsicWidth(
                child: _buildIncludeAssetAccountsToggle(),
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
          label: Text(AppL10n.tr(AppTranslationKeys.sankey)),
        ),
        ButtonSegment<int>(
          value: CashflowViewAs.netWorthOverTime.index,
          label: Text(AppL10n.tr(AppTranslationKeys.networth)),
        ),
        ButtonSegment<int>(
          value: CashflowViewAs.trend.index,
          label: Text(AppL10n.tr(AppTranslationKeys.trend)),
        ),
        ButtonSegment<int>(
          value: CashflowViewAs.budget.index,
          label: Text(AppL10n.tr(AppTranslationKeys.budget)),
        ),
      ],
      selectedId: PreferenceController.to.cashflowViewAs.index,
      onSelectionChanged: (final int newSelection) {
        PreferenceController.to.setCashflowViewAs(CashflowViewAs.values[newSelection]);
      },
    );
  }

  /// Builds the selected cashflow view for the current year range.
  Widget _buildView() {
    if (Data().transactions.isEmpty) {
      return CenterMessage.noTransaction();
    }

    switch (PreferenceController.to.cashflowViewAs) {
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
                title: AppL10n.tr(AppTranslationKeys.incomes),
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
                title: AppL10n.tr(AppTranslationKeys.expenses),
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
        return PanelTrend(
          dateRangeSearch: dateRangeTransactions,
          minYear: this.selectedYearStart,
          maxYear: this.selectedYearEnd,
          viewRecurringAs: PreferenceController.to.cashflowViewAs,
          includeAssetAccounts: PreferenceController.to.trendIncludeAssetAccounts,
        );
    }
  }
}
