import 'package:fl_chart/fl_chart.dart';
import 'package:money/controller/list_controller.dart';
import 'package:money/controller/selection_controller.dart';
import 'package:money/data/data.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/models/money_objects/investments/investments.dart';
import 'package:money/models/money_objects/securities/security.dart';
import 'package:money/models/money_objects/transactions/transaction.dart';
import 'package:money/views/home/sub_views/adaptive_view/adaptive_list/transactions/list_view_transactions.dart';
import 'package:money/views/home/sub_views/adaptive_view/menu_entry.dart';
import 'package:money/views/side_panel/side_panel_support.dart';
import 'package:money/widgets/center_message.dart';
import 'package:money/widgets/charts/my_line_chart.dart';
import 'package:money/widgets/dialog/dialog_button.dart';

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
          buildJumpToButton(context, <MenuEntry>[
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

  /// Details panels Chart panel for Payees
  Widget _getSubViewContentForChart({
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency,
  }) {
    double balance = 0.00;

    final List<Investment> investments = getList();
    investments.sort(
      (Investment a, Investment b) => sortByDate(a.date, b.date, true),
    );

    final List<FlSpot> dataPoints = <FlSpot>[];
    if (investments.isEmpty) {
      return const CenterMessage(message: 'No data');
    }

    for (final Investment investment in investments) {
      balance += investment.activityAmount;
      dataPoints.add(
        FlSpot(investment.date.millisecondsSinceEpoch.toDouble(), balance),
      );
    }

    return MyLineChart(dataPoints: dataPoints, showDots: true);
  }

  int _getAccountIdForInvestment(final int investmentTransactionId) {
    final Transaction? transactionFound = Data().transactions.get(
      investmentTransactionId,
    );
    if (transactionFound != null) {
      return transactionFound.fieldAccountId.value;
    }
    return -1;
  }

  bool _isSameSecurityFromTheSameAccount(
    final Investment investment,
    final int securityId,
    int accountId,
  ) {
    if (investment.fieldSecurity.value != securityId) {
      return false;
    }
    if (_getAccountIdForInvestment(investment.uniqueId) != accountId) {
      return false;
    }
    return true;
  }

  // Details Panel for Transactions Payees
  Widget _getSubViewContentForTransactions({
    required final List<int> selectedIds,
    required bool showAsNativeCurrency,
  }) {
    final Investment? instance = getMoneyObjectFromFirstSelectedId<Investment>(
      selectedIds,
      list,
    );

    if (instance == null) {
      return CenterMessage.noTransaction();
    }

    // get the related Transaction in order to get the associated Account
    final List<int> listOfInvestmentIdForThisSecurityAndAccount = Data().investments
        .iterableList()
        .where(
          (Investment i) => _isSameSecurityFromTheSameAccount(
            i,
            instance.fieldSecurity.value,
            _getAccountIdForInvestment(instance.uniqueId),
          ),
        )
        .map((Investment i) => i.uniqueId)
        .toList();

    final List<Transaction> listOfTransactions = getTransactions(
      filter: (final Transaction transaction) => listOfInvestmentIdForThisSecurityAndAccount.contains(
        transaction.uniqueId,
      ),
    );
    final SelectionController selectionController = Get.put(
      SelectionController(),
    );
    return ListViewTransactions(
      key: Key(instance.uniqueId.toString()),
      listController: Get.find<ListControllerSidePanel>(),
      columnsToInclude: <Field<dynamic>>[
        Transaction.fields.getFieldByName(columnIdDate),
        Transaction.fields.getFieldByName(columnIdAccount),
        Transaction.fields.getFieldByName(columnIdPayee),
        Transaction.fields.getFieldByName(columnIdCategory),
        Transaction.fields.getFieldByName(columnIdMemo),
        Transaction.fields.getFieldByName(columnIdAmount),
      ],
      getList: () => listOfTransactions,
      selectionController: selectionController,
    );
  }
}
