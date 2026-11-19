import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/dividend_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/ranges_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/investments_collection.dart';
import 'package:money/shared/domain/security_entity.dart';
import 'package:money/shared/domain/stock_split_entity.dart';
import 'package:money/shared/presentation/dialogs/mutate_money_object_dialog.dart';
import 'package:money/shared/presentation/helpers/menu_entry_model.dart';
import 'package:money/shared/presentation/widgets/money_object_card_widget.dart';
import 'package:money/views/panels/charts/stock_chart.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/views/panels/list/side_panel_lists_helper.dart';
import 'package:money/widgets/charts/chart_event_model.dart';
import 'package:money/widgets/pure/box_widget.dart';
import 'package:money/widgets/pure/center_message_widget.dart';

export 'package:money/views/panels/charts/stock_chart.dart';

const double _zeroDouble = 0.0;

/// Pivot toggles in order: label translation key and whether the toggle lists a security, from the shares it holds.
final List<(String, bool Function(Security))> _pivots = <(String, bool Function(Security))>[
  (AppTranslationKeys.closedLabel, (Security security) => isConsideredZero(security.fieldHoldingShares.value)),
  (AppTranslationKeys.activeLabel, (Security security) => !isConsideredZero(security.fieldHoldingShares.value)),
  (AppTranslationKeys.allLabel, (Security _) => true),
];

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

  // Filter related
  final List<bool> _selectedPivot = <bool>[false, false, true];

  /// Adds the pivot toggles, each with the profit of the securities it lists.
  @override
  Widget buildHeader([Widget? child]) {
    final List<Security> securities = getList(
      includeDeleted: false,
      applyFilter: false,
    );
    return super.buildHeader(
      buildStandardPivotToggleRow(
        selectedPivot: _selectedPivot,
        pivots: <(Key?, String, String)>[
          for (final (String labelKey, bool Function(Security) isListed) in _pivots)
            (
              null,
              AppL10n.tr(labelKey),
              getAmountAsStringUsingCurrency(
                securities.where(isListed).fold(_zeroDouble, (double sum, Security security) => sum + security.profit),
              ),
            ),
        ],
      ),
    );
  }

  /// add more top menu or Side panel action buttons
  @override
  List<Widget> getActionsButtons(bool forSidePanelTransactions) {
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
    return AppL10n.tr(AppTranslationKeys.stocks);
  }

  @override
  String getClassNameSingular() {
    return AppL10n.tr(AppTranslationKeys.stock);
  }

  @override
  String getDescription() {
    return AppL10n.tr(AppTranslationKeys.stocksTrackingDescription);
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
            (Security instance) => isMatchingFilters(instance) && isMatchingPivot(instance),
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

  /// Returns the investments in the selected security, none when no security is selected.
  @override
  List<Investment> getSidePanelTransactions() {
    final Security? security = getFirstSelectedItem() as Security?;
    return security == null ? <Investment>[] : getListOfInvestment(security);
  }

  /// Shows the security's splits and dividends next to its card.
  @override
  List<Widget> getSidePanelDetailsExtraPanels(DataObject selectedItem) {
    final Security security = selectedItem as Security;
    return <Widget>[_buildPanelForSplits(context, security), _buildPanelForDividend(context, security)];
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
  bool isMatchingPivot(Security instance) => _pivots[_selectedPivot.indexOf(true)].$2(instance);

  /// Builds the dividend panel showing all dividend payments for the selected security.
  Widget _buildPanelForDividend(
    BuildContext context,
    Security security,
  ) {
    final double totalDividend = security.dividends.fold(
      _zeroDouble,
      (double sum, Dividend dividend) => sum + dividend.amount,
    );

    return buildAdaptiveBox(
      context: context,
      title: AppL10n.tr(AppTranslationKeys.dividend),
      count: security.dividends.length,
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
      footer: Box.buildFooter(
        getAmountAsStringUsingCurrency(totalDividend),
      ),
    );
  }

  /// Builds the stock split history panel for the selected security.
  Widget _buildPanelForSplits(
    BuildContext context,
    Security security,
  ) {
    final List<StockSplit> splits = security.splitsHistory;

    return buildAdaptiveBox(
      context: context,
      title: AppL10n.tr(AppTranslationKeys.splits),
      count: splits.length,
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
    );
  }

  /// Returns the set of investment fields to show in the side panel transactions list.
  List<Field<dynamic>> _getFieldsToDisplayForSidePanelTransactions(
    bool includeSplitColumns,
  ) {
    final List<String> included = <String>[
      SharedStrings.investmentFieldDate,
      SharedStrings.investmentFieldAccount,
      SharedStrings.investmentFieldActivity,
      SharedStrings.investmentFieldUnits,
      if (includeSplitColumns) SharedStrings.investmentFieldSplit,
      if (includeSplitColumns) SharedStrings.investmentFieldUnitsAdjusted,
      SharedStrings.investmentFieldHolding,
      SharedStrings.investmentFieldPrice,
      if (includeSplitColumns) SharedStrings.investmentFieldPriceAdjusted,
      SharedStrings.investmentFieldHoldingValue,
      SharedStrings.investmentFieldCommission,
      SharedStrings.investmentFieldActivityAmount,
    ];
    final List<Field<dynamic>> fieldsToDisplay = Investment.fields.definitions
        .where((Field<dynamic> element) => included.contains(element.name))
        .toList();
    return fieldsToDisplay;
  }

  /// Builds the side panel chart subview for the selected security.
  Widget _getSidePanelViewChart({
    required List<int> selectedIds,
    required bool showAsNativeCurrency,
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

  /// Builds the side panel list of the investments in the selected security.
  Widget _getSidePanelViewTransactions({
    required List<int> selectedIds,
    required bool showAsNativeCurrency,
  }) {
    keepUnused(selectedIds, showAsNativeCurrency);
    final Security? security = getFirstSelectedItem() as Security?;
    if (security == null) {
      return CenterMessage(message: AppL10n.tr(AppTranslationKeys.noSecuritySelected));
    }

    return buildSidePanelList<Investment>(
      columns: _getFieldsToDisplayForSidePanelTransactions(security.splitsHistory.isNotEmpty),
      getList: getSidePanelTransactions,
      sortAscendingByDefault: false,
      // the side panel jump menu follows the selected investment
      onUserChoiceChanged: () => setState(() {}),
      onItemLongPress: (BuildContext _, Investment investment) => myShowDialogAndActionsForMoneyObject(
        title: AppL10n.tr(AppTranslationKeys.investment),
        moneyObject: investment,
      ),
    );
  }
}
