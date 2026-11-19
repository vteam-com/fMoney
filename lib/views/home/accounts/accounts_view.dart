import 'package:collection/collection.dart';
import 'package:money/data/helpers/investment_type_helper.dart';
import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/pair_xyz_model.dart';
import 'package:money/data/models/ranges_model.dart';
import 'package:money/data/models/stock_summary_model.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/investment_import_fields_helper.dart';
import 'package:money/shared/domain/loan_payment_entity.dart';
import 'package:money/shared/domain/loan_payments_collection.dart';
import 'package:money/shared/domain/reconcile_service.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/dialogs/mutate_money_object_dialog.dart';
import 'package:money/shared/presentation/helpers/menu_entry_model.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/shared/presentation/services/stock_cache_lookup_service.dart';
import 'package:money/views/imports/import_wizard_view.dart';
import 'package:money/views/imports/investment/investment_import_view.dart';
import 'package:money/views/panels/dialogs/reconcile_dialog.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/list/add_new_item_button_mixin.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/views/panels/list/reconcile_bar_widget.dart';
import 'package:money/views/panels/list/side_panel_lists_helper.dart';
import 'package:money/views/panels/list/transactions_list_view.dart';
import 'package:money/widgets/charts/chart_widget.dart';
import 'package:money/widgets/components/box_with_scrolling_content_widget.dart';
import 'package:money/widgets/components/label_and_amount_widget.dart';
import 'package:money/widgets/components/label_and_quantity_widget.dart';
import 'package:money/widgets/components/text_title_widget.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/pure/center_message_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const int _zeroInt = 0;
const int _oneInt = 1;
const double _zeroDouble = 0.0;
const double _negativeMultiplier = -1.0;
const int _accountTypeIndexAll = -1;
const int _approxDateOffsetDays = 1;
const double _stockPanelHeight = 180.0;
const double _summaryPanelHeight = 150.0;
const int _chartMaxPointsLarge = 100;
const int _chartMaxPointsSmall = 10;

/// Side panel list id keeping the loan payments sort apart from the transactions sort.
const String _loanPaymentsListId = 'loan_payments_';

/// Pivot toggles in order: widget key (the integration tests tap them), label translation key
/// and the account types listed (all when empty).
const List<(Key, String, List<AccountType>)> _pivots = <(Key, String, List<AccountType>)>[
  (Key('key_toggle_show_bank'), AppTranslationKeys.banks, <AccountType>[AccountType.checking, AccountType.savings]),
  (
    Key('key_toggle_show_investment'),
    AppTranslationKeys.investments,
    <AccountType>[AccountType.investment, AccountType.retirement],
  ),
  (Key('key_toggle_show_credit'), AppTranslationKeys.credit, <AccountType>[AccountType.credit, AccountType.creditLine]),
  (
    Key('key_toggle_show_assets'),
    AppTranslationKeys.assets,
    <AccountType>[AccountType.asset, AccountType.cash, AccountType.loan],
  ),
  (Key('key_toggle_show_all'), AppTranslationKeys.allLabel, <AccountType>[]),
];

/// Main view for all Accounts
class ViewAccounts extends ViewForMoneyObjects {
  const ViewAccounts({super.key, super.includeClosedAccount});

  @override
  State<ViewForMoneyObjects> createState() => _ViewAccountsState();
}

class _ViewAccountsState extends ViewForMoneyObjectsState with AddNewItemButtonMixin {
  _ViewAccountsState() {
    viewId = ViewId.viewAccounts;
  }

  // Footer related
  final DateRange _footerColumnDate = DateRange();

  // Filter related
  final List<bool> _selectedPivot = <bool>[false, false, false, false, true];

  /// Reconciliation in progress, shown in its account's side panel transactions.
  ReconcileService? _reconcile;

  @override
  String get addNewItemTooltip => AppL10n.tr(AppTranslationKeys.addNewAccount);

  /// Creates a bank account.
  @override
  DataObject createNewItem() => Data().accounts.addNewAccount(AppL10n.tr(AppTranslationKeys.newBankAccount));

  @override
  Widget buildHeader([Widget? child]) {
    return super.buildHeader(_renderToggles());
  }

  @override
  void didUpdateWidget(ViewAccounts oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle changes in widget properties
    if (oldWidget.includeClosedAccount != widget.includeClosedAccount) {
      list = getList();
    }
  }

  @override
  List<Widget> getActionsButtons(bool forSidePanelTransactions) {
    final List<Widget> list = super.getActionsButtons(forSidePanelTransactions);

    if (forSidePanelTransactions) {
      final Account? account = getFirstSelectedItem() as Account?;
      if (account != null &&
          PreferenceController.to.selectedSidePanelTabId == SidePanelSubViewEnum.transactions &&
          ReconcileService.supportsAccount(account) &&
          _reconcileSessionFor(account) == null) {
        list.add(
          IconButton(
            icon: const Icon(Icons.fact_check_outlined),
            tooltip: AppL10n.tr(AppTranslationKeys.reconcileWithStatement),
            onPressed: () => _startReconcile(account),
          ),
        );
      }
      list.add(
        buildJumpToButton(context, <MenuEntry>[
          MenuEntry(
            icon: ViewId.viewTransactions.getIconData(),
            title: AppL10n.tr(AppTranslationKeys.matchingTransaction),
            onPressed: () {
              final Transaction? selectedInfoTransaction = getSidePanelLastSelectedTransaction();

              if (selectedInfoTransaction != null) {
                // Look for transaction matching -1 to +1 date from this transaction
                final DateRange approximationDates = DateRange(
                  min: selectedInfoTransaction.fieldDateTime.value!
                      .add(const Duration(days: -_approxDateOffsetDays))
                      .startOfDay,
                  max: selectedInfoTransaction.fieldDateTime.value!
                      .add(const Duration(days: _approxDateOffsetDays))
                      .endOfDay,
                );
                // we are looking for the reverse transaction
                final double amountToFind = selectedInfoTransaction.fieldAmount.value.asDouble() * _negativeMultiplier;

                final Transaction? matchingTransaction = Data().transactions.findExistingTransaction(
                  accountId: _accountTypeIndexAll,
                  dateRange: approximationDates,
                  amount: amountToFind,
                );
                // Switch view
                if (matchingTransaction != null) {
                  PreferenceController.to.jumpToView(
                    viewId: ViewId.viewTransactions,
                    selectedId: matchingTransaction.uniqueId,
                    textFilter: '',
                    columnFilters: null,
                  );
                  return;
                }
              }
              SnackBarService.displayWarning(
                message: AppL10n.tr(AppTranslationKeys.noMatchingTransactions),
              );
            },
          ),
        ]),
      );
    } else {
      // this can go last
      final Account? account = getFirstSelectedItem() as Account?;
      if (account != null) {
        list.add(
          buildJumpToButton(context, <MenuEntry>[
            MenuEntry.toTransactionsOfAccount(account: account),
            MenuEntry.toInvestments(accountName: account.fieldName.value),
          ]),
        );
      }
    }

    return list;
  }

  @override
  String getClassNamePlural() {
    return AppL10n.tr(AppTranslationKeys.accounts);
  }

  @override
  String getClassNameSingular() {
    return AppL10n.tr(AppTranslationKeys.account);
  }

  // default currency for this view
  @override
  List<String> getCurrencyChoices(
    SidePanelSubViewEnum subViewId,
    List<int> selectedItems,
  ) {
    switch (subViewId) {
      case SidePanelSubViewEnum.chart: // Chart
      case SidePanelSubViewEnum.transactions: // Transactions
        final Account? account = getFirstSelectedItemFromSelectedList(selectedItems) as Account?;
        if (account != null) {
          if (account.fieldCurrency.value != Constants.defaultCurrency) {
            // only offer currency toggle if the account is not USD based
            return <String>[
              account.fieldCurrency.value,
              Constants.defaultCurrency,
            ];
          }
        }

        return <String>[Constants.defaultCurrency];
      default:
        return <String>[];
    }
  }

  @override
  String getDescription() {
    return AppL10n.tr(AppTranslationKeys.accountsDescription);
  }

  @override
  Fields<Account> getFieldsForTable() {
    return Account.fieldsForColumnView;
  }

  @override
  List<Account> getList({
    bool includeDeleted = false,
    bool applyFilter = true,
  }) {
    List<Account> list = Data().accounts.activeAccounts(
      getSelectedAccountType(),
      isActive: PreferenceController.to.includeClosedAccounts ? null : true,
    );

    if (applyFilter) {
      list = list.where((Account instance) => isMatchingFilters(instance)).toList();
    } else {
      list = list.toList();
    }

    _footerColumnDate.clear();

    for (final Account account in list) {
      _footerColumnDate.inflate(account.fieldUpdatedOn.value);
    }
    return list;
  }

  @override
  SidePanelSupport getSidePanelSupport() {
    return SidePanelSupport(
      onDetails: getSidePanelViewDetails,
      onChart: _getSubViewContentForChart,
      onTransactions: _getSidePanelViewTransactions,
    );
  }

  @override
  List<DataObject> getSidePanelTransactions() {
    final Account? account = getFirstSelectedItem() as Account?;
    if (account != null) {
      // Running balances are computed on all the account's transactions before keeping only those to reconcile
      final List<Transaction> transactions = getTransactionForLastSelectedAccount(account);
      final ReconcileService? session = _reconcileSessionFor(account);
      return session == null ? transactions : transactions.where(session.isPending).toList();
    }
    return <DataObject>[];
  }

  @override
  void initState() {
    super.initState();

    onAddTransaction = () {
      showImportTransactionsWizard();
    };
  }

  /// Calculates the total balance of the specified account types.
  double getTotalBalanceOfAccounts(List<AccountType> types) {
    double total = _zeroDouble;
    Data().accounts
        .activeAccounts(types)
        .forEach(
          (Account x) => total += (x.fieldBalanceNormalized.getValueForDisplay(x) as AmountModel).asDouble(),
        );
    return total;
  }

  /// Filters a [Transaction] by the specified [accountId].
  bool filterByAccountId(Transaction t, num accountId) {
    return t.fieldAccountId.value == accountId;
  }

  /// Returns the account types listed by the selected pivot toggle; all when empty.
  List<AccountType> getSelectedAccountType() => _pivots[_selectedPivot.indexOf(true)].$3;

  /// Builds the horizontal toggle row used to select account type pivots, each with its total balance.
  Widget _renderToggles() {
    return buildStandardPivotToggleRow(
      key: const Key('view_accounts_pivots'),
      selectedPivot: _selectedPivot,
      pivots: <(Key?, String, String)>[
        for (final (Key key, String labelKey, List<AccountType> types) in _pivots)
          (key, AppL10n.tr(labelKey), getAmountAsStringUsingCurrency(getTotalBalanceOfAccounts(types))),
      ],
    );
  }

  /// Shows the holdings of an investment account next to its card.
  @override
  List<Widget> getSidePanelDetailsExtraPanels(DataObject selectedItem) {
    final Account account = selectedItem as Account;
    return account.isInvestmentAccount() ? _buildStockHoldingCards(account) : <Widget>[];
  }

  /// Builds holding summary cards for an investment account grouped by stock symbol.
  List<Widget> _buildStockHoldingCards(Account account) {
    final List<StockSummary> stockSummaries = Data().accounts.holdingsOf(account);
    if (stockSummaries.isEmpty) {
      return <Widget>[];
    }

    // sort by descending holding-value
    stockSummaries.sort(
      (StockSummary a, StockSummary b) => b.holdingValue.compareTo(a.holdingValue),
    );

    final List<Widget> stockPanels = stockSummaries
        .map(
          (StockSummary summary) => BoxWithScrollingContent(
            height: _stockPanelHeight,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: TextTitle(summary.symbol)),
                  buildMenuButton(context, <MenuEntry>[
                    MenuEntry.toInvestments(
                      symbol: summary.symbol,
                      accountName: account.fieldName.value,
                    ),
                    MenuEntry.toStocks(symbol: summary.symbol),
                    MenuEntry.toWeb(
                      url: 'https://finance.yahoo.com/quote/${summary.symbol}/',
                    ),
                    MenuEntry.customAction(
                      icon: Icons.refresh,
                      text: AppL10n.tr(AppTranslationKeys.getLatestPrice),
                      onPressed: () async {
                        await loadFomBackendAndSaveToCache(summary.symbol);
                      },
                    ),
                    MenuEntry.customAction(
                      icon: Icons.add,
                      text: AppL10n.tr(AppTranslationKeys.addInvestment),
                      onPressed: () async {
                        showImportInvestment(
                          inputData: InvestmentImportFields(
                            account: account,
                            date: DateTime.now(),
                            // inverse the position
                            investmentType: summary.shares > 0 ? InvestmentType.sell : InvestmentType.buy,
                            category: Data().categories.investmentOther,
                            symbol: summary.symbol,
                            units: summary.shares,
                            amountPerUnit: summary.sharePrice,
                            transactionAmount: summary.shares * summary.sharePrice,
                            description: AppL10n.tr(AppTranslationKeys.closePosition),
                          ),
                        );
                      },
                    ),
                  ]),
                ],
              ),
              gapMedium(),

              // number of shares
              LabelAndQuantity(caption: AppL10n.tr(AppTranslationKeys.shares), quantity: summary.shares),

              // Average cost price
              LabelAndAmount(
                caption: AppL10n.tr(AppTranslationKeys.averageCost),
                amount: summary.averageCost,
              ),

              // Price per share
              LabelAndAmount(
                caption: AppL10n.tr(AppTranslationKeys.marketPrice),
                amount: summary.sharePrice,
              ),

              // Hold value
              gapMedium(),
              const Divider(),
              LabelAndAmount(
                caption: AppL10n.tr(AppTranslationKeys.value),
                amount: summary.holdingValue,
              ),
            ],
          ),
        )
        .toList();

    // also add Summary Cash and Stock
    double totalInvestment = _zeroDouble;
    for (StockSummary element in stockSummaries) {
      totalInvestment += element.holdingValue;
    }

    final double totalCash = account.balance - totalInvestment;

    stockPanels.insert(
      _zeroInt,
      BoxWithScrollingContent(
        height: _summaryPanelHeight,
        children: <Widget>[
          gapMedium(),
          // Cash
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              TextTitle(AppL10n.tr(AppTranslationKeys.cash)),
              WidgetFromData(
                amountModel: AmountModel(
                  amount: totalCash,
                  iso4217: account.getAccountCurrencyAsText(),
                  autoColor: true,
                ),
              ),
            ],
          ),
          gapMedium(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              TextTitle(AppL10n.tr(AppTranslationKeys.investments)),
              WidgetFromData(
                amountModel: AmountModel(
                  amount: totalInvestment,
                  iso4217: account.getAccountCurrencyAsText(),
                  autoColor: true,
                ),
              ),
            ],
          ),
          gapMedium(),
          const Divider(),
          LabelAndAmount(caption: AppL10n.tr(AppTranslationKeys.value), amount: account.balance),
        ],
      ),
    );

    return stockPanels;
  }

  /// Details panels Chart panel for Accounts
  Widget _getSubViewContentForChart({
    required List<int> selectedIds,
    required bool showAsNativeCurrency,
  }) {
    final List<PairXYY> listOfPairXY = <PairXYY>[];

    if (selectedIds.length == _oneInt) {
      final Account? account = getFirstSelectedItemFromSelectedList(selectedIds) as Account?;
      if (account == null) {
        // this should not happen
        return Text(AppL10n.tr(AppTranslationKeys.noAccountSelected));
      }

      account.maxBalancePerYears.forEach((int key, double value) {
        final double valueCurrencyChoice = showAsNativeCurrency ? value : account.toNormalized(value);

        listOfPairXY.add(PairXYY(key.toString(), valueCurrencyChoice));
      });
      listOfPairXY.sort(
        (PairXYY a, PairXYY b) => compareAsciiLowerCase(a.xText, b.xText),
      );

      return Chart(
        key: Key('$selectedIds $showAsNativeCurrency'),
        list: listOfPairXY.take(_chartMaxPointsLarge).toList(),
        currency: showAsNativeCurrency ? account.fieldCurrency.value : Constants.defaultCurrency,
      );
    } else {
      for (final DataObject item in getList()) {
        final Account account = item as Account;
        if (account.isOpen) {
          listOfPairXY.add(
            PairXYY(
              account.fieldName.value,
              showAsNativeCurrency
                  ? account.balance
                  : (account.fieldBalanceNormalized.getValueForDisplay(account) as AmountModel).asDouble(),
            ),
          );
        }
      }

      listOfPairXY.sort(
        (PairXYY a, PairXYY b) => (b.yValue1.abs() - a.yValue1.abs()).toInt(),
      );

      return Chart(
        key: Key(selectedIds.toString()),
        list: listOfPairXY.take(_chartMaxPointsSmall).toList(),
      );
    }
  }

  /// Builds the side panel transactions sub-view for the selected account.
  Widget _getSidePanelViewTransactions({
    required List<int> selectedIds,
    required bool showAsNativeCurrency,
  }) {
    keepUnused(selectedIds);
    final Account? account = getFirstSelectedItem() as Account?;
    if (account == null) {
      return CenterMessage(message: AppL10n.tr(AppTranslationKeys.noAccountSelectedPeriod));
    } else {
      if (account.fieldType.value == AccountType.loan) {
        return _getSubViewContentForTransactionsForLoans(
          account: account,
          showAsNativeCurrency: showAsNativeCurrency,
          data: Data(),
        );
      } else {
        return _getSubViewContentForTransactions(
          account: account,
          showAsNativeCurrency: showAsNativeCurrency,
        );
      }
    }
  }

  // Details Panel for Transactions
  Widget _getSubViewContentForTransactions({
    required Account account,
    required bool showAsNativeCurrency,
  }) {
    final List<String> columnsToDisplay = <String>[
      columnIdDate,
      columnIdPayee,
      columnIdCategory,
      columnIdMemo,
      columnIdStatus,
      showAsNativeCurrency ? columnIdAmount : columnIdAmountNormalized,
      showAsNativeCurrency ? columnIdBalance : columnIdBalanceNormalized,
      // Credit Card account has a PaidOn column to help with balancing Statements
      if (account.fieldType.value == AccountType.credit) columnIdPaidOn,
    ];

    final Widget transactionsList = ListenableBuilder(
      // Status toggles only notify the mutation tracker; listen to it too so the Status cells repaint
      listenable: Listenable.merge(<Listenable>[DataFileController.to, DataFileController.to.trackMutations]),
      builder: (BuildContext _, Widget? _) {
        return buildSidePanelTransactionsList(
          key: Key(
            'transaction_list_currency_${showAsNativeCurrency}_changedOn${DataFileController.to.lastUpdateAsString}',
          ),
          columnNames: columnsToDisplay,
          showRightAdornment: account.fieldType.value == AccountType.credit,
        );
      },
    );

    final ReconcileService? session = _reconcileSessionFor(account);
    if (session == null) {
      return transactionsList;
    }
    return Column(
      children: <Widget>[
        Expanded(child: transactionsList),
        ReconcileBar(session: session, onCancel: _stopReconcile, onFinish: _finishReconcile),
      ],
    );
  }

  // Details Panel for Transactions
  Widget _getSubViewContentForTransactionsForLoans({
    required Account account,
    required bool showAsNativeCurrency,
    required DataAbstract data,
  }) {
    return ListenableBuilder(
      listenable: DataFileController.to,
      builder: (BuildContext _, Widget? _) {
        return buildSidePanelList<LoanPayment>(
          key: Key(
            'loan_payment_list_currency_${showAsNativeCurrency}_changedOn${DataFileController.to.lastUpdateAsString}',
          ),
          listId: _loanPaymentsListId,
          columns: LoanPayment.fieldsForColumnView.definitions,
          getList: () => getAccountLoanPayments(account, data),
          onItemLongPress: (BuildContext _, LoanPayment payment) => myShowDialogAndActionsForMoneyObject(
            title: AppL10n.tr(AppTranslationKeys.loanPayment),
            moneyObject: payment,
          ),
        );
      },
    );
  }

  /// Reconciles the cleared transactions, leaves reconcile mode and reports how many were reconciled.
  void _finishReconcile() {
    final int count = _reconcile?.finish() ?? _zeroInt;
    _stopReconcile();
    SnackBarService.displaySuccess(
      message: AppL10n.tr(
        AppTranslationKeys.reconciledTransactionsCount,
        params: <String, String>{'count': getIntAsText(count)},
      ),
    );
  }

  /// Returns the reconciliation in progress for [account], or null when it is not being reconciled.
  ReconcileService? _reconcileSessionFor(Account account) {
    return identical(_reconcile?.account, account) ? _reconcile : null;
  }

  /// Asks for the statement date and balance, then shows [account]'s transactions in reconcile mode.
  void _startReconcile(Account account) {
    showReconcileDialog(
      context: context,
      account: account,
      data: Data(),
      onStart: (ReconcileService session) => setState(() => _reconcile = session),
    );
  }

  /// Leaves reconcile mode; the transactions the user cleared stay cleared.
  void _stopReconcile() {
    setState(() => _reconcile = null);
  }

  /// Returns transactions for the last selected account with optional filtering.
  List<Transaction> getTransactionForLastSelectedAccount(
    Account account,
  ) {
    return getTransactions(
      filter: (Transaction transaction) {
        return filterByAccountId(transaction, account.uniqueId);
      },
    );
  }
}
