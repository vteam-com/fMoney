import 'package:money/app/app_scope.dart';
import 'package:money/data/models/dividend.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/providers/investment.dart';
import 'package:money/providers/security.dart';
import 'package:money/providers/stock_split.dart';
import 'package:money/views/adaptive_view/view_money_objects.dart';
import 'package:money/views/data.dart';
import 'package:money/views/dialog_mutate_money_object.dart';
import 'package:money/views/investments.dart';
import 'package:money/views/menu_entry.dart';
import 'package:money/views/money_object_card.dart';
import 'package:money/views/money_objects.dart';
import 'package:money/views/panels/side_panel/side_panel_support.dart';
import 'package:money/views/view_stocks/stock_chart.dart';
import 'package:money/widgets/adaptive_list/adaptive_columns_or_rows_single_selection.dart';
import 'package:money/widgets/charts/chart_event.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/pure/box.dart';
import 'package:money/widgets/pure/center_message.dart';
import 'package:money/widgets/three_part_label.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/field_filters.dart';

export 'package:money/views/view_stocks/stock_chart.dart';

const int _pivotIndexClosed = 0;
const int _pivotIndexActive = 1;
const int _pivotIndexAll = 2;
const int _defaultSortIndex = 0;
const double _zeroDouble = 0.0;
const double _pivotSpacing = 30.0;
const int _dividerAlpha = 100;
const double _toggleMinHeight = 40.0;
const double _toggleMinWidth = 100.0;

/// Represents view stocks.
class ViewStocks extends ViewForMoneyObjects {
  const ViewStocks({super.key});

  @override
  State<ViewForMoneyObjects> createState() => _ViewStocksState();
}

class _ViewStocksState extends ViewForMoneyObjectsState {
  _ViewStocksState() {
    viewId = ViewId.viewStocks;
  }

  final List<Widget> _pivots = <Widget>[];

  // Filter related
  final List<bool> _selectedPivot = <bool>[false, false, true];

  Security? _lastSecuritySelected;

  @override
  Widget buildHeader([final Widget? child]) {
    final List<Security> list = getList(
      includeDeleted: false,
      applyFilter: false,
    );

    double sumActive = _zeroDouble;
    double sumClosed = _zeroDouble;
    double sumAll = _zeroDouble;

    for (final Security security in list) {
      final double profit = security.profit;
      sumAll += profit;

      if (isConsideredZero(security.fieldHoldingShares.value)) {
        sumClosed += profit;
      } else {
        sumActive += profit;
      }
    }

    _pivots.clear();
    _pivots.add(
      ThreePartLabel(
        text1: 'Closed',
        small: true,
        isVertical: true,
        text2: getAmountAsStringUsingCurrency(sumClosed),
      ),
    );

    _pivots.add(
      ThreePartLabel(
        text1: 'Active',
        small: true,
        isVertical: true,
        text2: getAmountAsStringUsingCurrency(sumActive),
      ),
    );

    _pivots.add(
      ThreePartLabel(
        text1: 'All',
        small: true,
        isVertical: true,
        text2: getAmountAsStringUsingCurrency(sumAll),
      ),
    );
    return super.buildHeader(_renderToggles());
  }

  /// add more top menu or Side panel action buttons
  @override
  List<Widget> getActionsButtons(final bool forSidePanelTransactions) {
    final List<Widget> list = super.getActionsButtons(forSidePanelTransactions);
    if (forSidePanelTransactions) {
      final Investment? selectedInvestment = getSidePanelLastSelectedItem<Investment>(Data().investments);
      if (selectedInvestment != null) {
        list.add(
          buildJumpToButton(context, <MenuEntry>[
            MenuEntry.toAccounts(
              accountId: selectedInvestment.transactionInstance!.fieldAccountId.value as int,
            ),
            MenuEntry.toTransactions(
              transactionId: selectedInvestment.uniqueId,
            ),
          ]),
        );
      }
    } else {
      final Security? selectedSecurity = getFirstSelectedItem() as Security?;
      // this can go last
      if (selectedSecurity != null) {
        list.add(
          buildJumpToButton(context, <MenuEntry>[
            // Jump to Investment view
            MenuEntry.toInvestments(symbol: selectedSecurity.fieldSymbol.value),
          ]),
        );
      }
    }
    return list;
  }

  @override
  String getClassNamePlural() {
    return 'Stocks';
  }

  @override
  String getClassNameSingular() {
    return 'Stock';
  }

  @override
  String getDescription() {
    return 'Stocks tracking.';
  }

  @override
  Fields<Security> getFieldsForTable() {
    return Security.fieldsForColumnView;
  }

  @override
  List<Security> getList({
    bool includeDeleted = false,
    bool applyFilter = true,
  }) {
    List<Security> list = Data().securities.iterableList(includeDeleted: includeDeleted).toList();

    if (applyFilter) {
      list = list
          .where(
            (final Security instance) => isMatchingFilters(instance) && isMatchingPivot(instance),
          )
          .toList();
    }

    return list;
  }

  @override
  SidePanelSupport getSidePanelSupport() {
    return SidePanelSupport(
      onDetails: getSidePanelViewDetails,
      onChart: _getSidePanelViewChart,
      onTransactions: _getSidePanelViewTransactions,
    );
  }

  @override
  List<DataObject> getSidePanelTransactions() {
    return getListOfInvestment(_lastSecuritySelected!);
  }

  @override
  Widget getSidePanelViewDetails({required final List<int> selectedIds}) {
    keepUnused(selectedIds);
    final Security? selectedSecurity = getFirstSelectedItem() as Security?;
    return buildStandardSidePanelDetailsWrap<Security>(
      selectedItem: selectedSecurity,
      spacing: _pivotSpacing,
      extraPanels: <Widget>[
        if (selectedSecurity != null) ...<Widget>[
          _buildPanelForSplits(context, selectedSecurity),
          _buildPanelForDividend(context, selectedSecurity),
        ],
      ],
    );
  }

  /// Returns investments for the specified security with split adjustments applied.
  List<Investment> getListOfInvestment(Security security) {
    final List<Investment> list = Investments.getInvestmentsForThisSecurity(
      security.uniqueId,
      Data(),
    );
    Investments.applyHoldingSharesAdjustedForSplits(list);
    return list;
  }

  /// Returns true if the security holding matches the selected pivot for closed status.
  bool isMatchingPivot(final Security instance) {
    if (_selectedPivot[_pivotIndexClosed]) {
      // No holding of stock
      return isConsideredZero(instance.fieldHoldingShares.value);
    }
    if (_selectedPivot[_pivotIndexActive]) {
      // Still have holding
      return !isConsideredZero(instance.fieldHoldingShares.value);
    }
    if (_selectedPivot[_pivotIndexAll]) {
      // All, no filter needed
    }
    return true;
  }

  /// Builds the dividend panel showing all dividend payments for the selected security.
  Widget _buildPanelForDividend(
    final BuildContext context,
    final Security security,
  ) {
    final double totalDividend = security.dividends.fold(
      _zeroDouble,
      (double sum, Dividend dividend) => sum + dividend.amount,
    );

    return buildAdaptiveBox(
      context: context,
      title: 'Dividend',
      count: security.dividends.length,
      content: ListView.separated(
        itemCount: security.dividends.length,
        itemBuilder: (BuildContext _, int index) {
          final Dividend dividend = security.dividends[index];
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(dividend.date.toString()),
              Text(getAmountAsStringUsingCurrency(dividend.amount)),
            ],
          );
        },
        separatorBuilder: (BuildContext context, int _ /* index */) => Divider(
          color: getColorTheme(context).onPrimaryContainer.withAlpha(_dividerAlpha),
        ),
      ),
      footer: Box.buildFooter(
        getAmountAsStringUsingCurrency(totalDividend),
      ),
    );
  }

  /// Builds the stock split history panel for the selected security.
  Widget _buildPanelForSplits(
    final BuildContext context,
    final Security security,
  ) {
    final List<StockSplit> splits = security.splitsHistory;

    return buildAdaptiveBox(
      context: context,
      title: 'Splits',
      count: splits.length,
      content: ListView.separated(
        itemCount: splits.length,
        itemBuilder: (BuildContext _, int index) {
          final StockSplit split = splits[index];
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(split.fieldDate.getValueForDisplay(split).toString()),
              Text(split.fieldNumerator.value.toString()),
              Text(AppL10n.tr(AppTranslationKeys.forSpacer)),
              Text(split.fieldDenominator.value.toString()),
            ],
          );
        },
        separatorBuilder: (BuildContext context, int _ /* index */) => Divider(
          color: getColorTheme(context).onPrimaryContainer.withAlpha(_dividerAlpha),
        ),
      ),
    );
  }

  /// Returns the set of investment fields to show in the side panel transactions list.
  List<Field<dynamic>> _getFieldsToDisplayForSidePanelTransactions(
    bool includeSplitColumns,
  ) {
    final List<String> included = <String>[
      'Date',
      'Account',
      'Activity',
      'Units',
      if (includeSplitColumns) 'Split',
      if (includeSplitColumns) 'Units A.S.',
      'Holding',
      'Price',
      if (includeSplitColumns) 'Price A.S.',
      'HoldingValue',
      'Commission',
      'ActivityAmount',
    ];
    final List<Field<dynamic>> fieldsToDisplay = Investment.fields.definitions
        .where((Field<dynamic> element) => included.contains(element.name))
        .toList();
    return fieldsToDisplay;
  }

  /// Builds the side panel chart subview for the selected security.
  Widget _getSidePanelViewChart({
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency,
  }) {
    keepUnused(selectedIds, showAsNativeCurrency);
    final Security? security = getFirstSelectedItem() as Security?;
    if (security != null) {
      final String symbol = security.fieldSymbol.value;
      final List<Investment> list = getListOfInvestment(security);

      final List<ChartEvent> events = <ChartEvent>[];
      for (final Investment activity in list) {
        if (activity.effectiveUnits != _zeroDouble) {
          events.add(
            ChartEvent(
              dates: DateRange(
                min: activity.transactionInstance!.fieldDateTime.value! as DateTime,
              ),
              amount: activity.unitPriceAdjusted,
              quantity: activity.effectiveUnitsAdjusted,
              colorBasedOnQuantity: true,
              description: activity.fieldInvestmentType.getValueForDisplay(activity) as String,
            ),
          );
        }
      }

      if (symbol.isNotEmpty) {
        return StockChartWidget(
          key: Key('stock_symbol_$symbol'),
          symbol: symbol,
          splits: Data().stockSplits.getStockSplitsForSecurity(security),
          dividends: security.dividends,
          holdingsActivities: events,
        );
      }
    }
    return Center(child: Text(AppL10n.tr(AppTranslationKeys.noStockSelected)));
  }

  /// Builds the side panel transactions subview for the selected security.
  Widget _getSidePanelViewTransactions({
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency,
  }) {
    keepUnused(selectedIds, showAsNativeCurrency);
    _lastSecuritySelected = getFirstSelectedItem() as Security?;

    if (_lastSecuritySelected == null) {
      return CenterMessage(message: AppL10n.tr(AppTranslationKeys.noSecuritySelected));
    }

    final List<Investment> listOfInvestmentsForThisStock = getListOfInvestment(
      _lastSecuritySelected!,
    );

    int sortByFieldIndex = PreferenceController.to.getInt(
      getPreferenceKey(settingKeySidePanel + settingKeySortBy),
      _defaultSortIndex,
    );
    bool sortAscending = PreferenceController.to.getBool(
      getPreferenceKey(settingKeySidePanel + settingKeySortAscending),
      false,
    );

    final List<Field<dynamic>> fields = _getFieldsToDisplayForSidePanelTransactions(
      _lastSecuritySelected!.splitsHistory.isNotEmpty,
    );

    MoneyObjects.sortList(
      listOfInvestmentsForThisStock,
      fields,
      sortByFieldIndex,
      sortAscending,
    );

    return AdaptiveListColumnsOrRowsSingleSelection(
      // list related
      list: listOfInvestmentsForThisStock,
      fieldDefinitions: _getFieldsToDisplayForSidePanelTransactions(
        _lastSecuritySelected!.splitsHistory.isNotEmpty,
      ),
      filters: FieldFilters(),
      sortByFieldIndex: sortByFieldIndex,
      sortAscending: sortAscending,
      listController: AppScope.instance.listControllerMain,
      selectedId: getSidePanelLastSelectedItemId(),
      // Field & Columns related
      displayAsColumns: true,
      backgroundColorForHeaderFooter: Colors.transparent,
      onColumnHeaderTap: (int columnHeaderIndex) {
        setState(() {
          if (columnHeaderIndex == sortByFieldIndex) {
            // toggle order
            sortAscending = !sortAscending;
            PreferenceController.to.setBool(
              getPreferenceKey(settingKeySidePanel + settingKeySortAscending),
              sortAscending,
            );
          } else {
            sortByFieldIndex = columnHeaderIndex;
            PreferenceController.to.setInt(
              getPreferenceKey(settingKeySidePanel + settingKeySortBy),
              sortByFieldIndex,
            );
          }
        });
      },
      onSelectionChanged: (int uniqueId) {
        setState(() {
          PreferenceController.to.setInt(
            getPreferenceKey(
              settingKeySidePanel + settingKeySelectedListItemId,
            ),
            uniqueId,
          );
        });
      },
      onItemLongPress: (BuildContext _, int itemId) {
        final Investment? instance = Data().investments.get(itemId);
        if (instance != null) {
          myShowDialogAndActionsForMoneyObject(
            title: 'Investment',
            moneyObject: instance,
          );
        }
      },
    );
  }

  /// Builds the pivot toggle row used to filter securities (active/closed/all).
  Widget _renderToggles() {
    return buildStandardPivotToggleRow(
      selectedPivot: _selectedPivot,
      pivotChildren: _pivots,
      padding: const EdgeInsets.only(bottom: SizeForPadding.medium),
      borderRadius: const BorderRadius.all(Radius.circular(SizeForPadding.normal)),
      minHeight: _toggleMinHeight,
      minWidth: _toggleMinWidth,
    );
  }
}
