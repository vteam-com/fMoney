import 'package:fl_chart/fl_chart.dart';
import 'package:money/core/controller/list_controller.dart';
import 'package:money/core/controller/selection_controller.dart';
import 'package:money/core/helpers/list_helper.dart';
import 'package:money/core/widgets/charts/my_line_chart.dart';
import 'package:money/core/widgets/dialog/dialog_button.dart';
import 'package:money/core/widgets/side_panel/side_panel_support.dart';
import 'package:money/data/models/money_objects/investments/investments.dart';
import 'package:money/data/models/money_objects/securities/security.dart';
import 'package:money/data/models/money_objects/transactions/transaction.dart';
import 'package:money/data/storage/data/data.dart';
import 'package:money/views/home/sub_views/adaptive_view/adaptive_list/transactions/list_view_transactions.dart';

part 'view_investments_side_panel.dart';

class ViewInvestments extends ViewForMoneyObjects {
  const ViewInvestments({super.key});

  @override
  State<ViewForMoneyObjects> createState() => ViewInvestmentsState();
}

class ViewInvestmentsState extends ViewForMoneyObjectsState {
  ViewInvestmentsState() {
    viewId = ViewId.viewInvestments;
  }

  /// add more top level action buttons
  @override
  List<Widget> getActionsButtons(final bool forSidePanelTransactions) {
    final List<Widget> list = super.getActionsButtons(forSidePanelTransactions);
    if (!forSidePanelTransactions) {
      final Investment? selectedInvestment = getFirstSelectedItem() as Investment?;

      // this can go last
      if (selectedInvestment != null) {
        final Transaction? relatedTransaction = Data().transactions.get(
          selectedInvestment.uniqueId,
        );
        list.add(
          buildJumpToButton(<MenuEntry>[
            // Jump to Account view
            MenuEntry.toAccounts(
              accountId: relatedTransaction!.fieldAccountId.value,
            ),

            // Jump to Transaction view
            MenuEntry.toTransactions(
              transactionId: relatedTransaction.uniqueId,
              filters: null,
            ),

            // Jump to Stock view
            MenuEntry(
              icon: ViewId.viewStocks.getIconData(),
              title: 'Switch to Stocks',
              onPressed: () {
                // Prepare the Stocks view
                // Filter by Stock Symbol
                final String symbol =
                    (selectedInvestment.fieldSecuritySymbol.getValueForDisplay(
                              selectedInvestment,
                            )
                            as String)
                        .toLowerCase();
                final Security? securityFound = Data().securities.getBySymbol(
                  symbol,
                );
                if (securityFound != null) {
                  PreferenceController.to.jumpToView(
                    viewId: ViewId.viewStocks,
                    selectedId: securityFound.uniqueId,
                    textFilter: '',
                    columnFilters: null,
                  );
                }
              },
            ),
          ]),
        );
      }
    }
    return list;
  }

  @override
  String getClassNamePlural() {
    return 'Investments';
  }

  @override
  String getClassNameSingular() {
    return 'Investment';
  }

  @override
  String getDescription() {
    return 'Track your stock portfolio.';
  }

  @override
  Fields<Investment> getFieldsForTable() {
    return Investment.fieldsForColumnView;
  }

  @override
  List<Investment> getList({
    bool includeDeleted = false,
    bool applyFilter = true,
  }) {
    final List<Investment> list = Data().investments
        .iterableList(includeDeleted: includeDeleted)
        .where(
          (Investment instance) => applyFilter == false || isMatchingFilters(instance),
        )
        .toList();
    Investments.applyHoldingSharesAdjustedForSplits(list);

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
}
