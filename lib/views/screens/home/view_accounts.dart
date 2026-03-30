import 'package:collection/collection.dart';
import 'package:money/data/models/field_filter.dart';
import 'package:money/data/models/stock_summary.dart';
import 'package:money/helpers/account_types_enum.dart';
import 'package:money/helpers/accumulator.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/investment_types.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/pair_xyz.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/helpers/transaction_types.dart';
import 'package:money/providers/investment_import_fields.dart';
import 'package:money/shared/domain/account.dart';
import 'package:money/shared/domain/accounts.dart';
import 'package:money/shared/domain/data.dart';
import 'package:money/shared/domain/data_abstract.dart';
import 'package:money/shared/domain/investment.dart';
import 'package:money/shared/domain/investments.dart';
import 'package:money/shared/domain/loan_payment.dart';
import 'package:money/shared/domain/loan_payments.dart';
import 'package:money/shared/domain/money_objects.dart';
import 'package:money/shared/domain/security.dart';
import 'package:money/shared/domain/transaction.dart';
import 'package:money/shared/presentation/app_scope.dart';
import 'package:money/shared/presentation/dialog_mutate_money_object.dart';
import 'package:money/shared/presentation/menu_entry.dart';
import 'package:money/shared/presentation/money_object_card.dart';
import 'package:money/shared/presentation/provider_data_file_controller.dart';
import 'package:money/shared/presentation/service_stock_cache_lookup.dart';
import 'package:money/views/imports/core/import_investment.dart';
import 'package:money/views/imports/core/import_wizard.dart';
import 'package:money/views/panels/core/list_view_transactions.dart';
import 'package:money/views/panels/core/side_panel_support.dart';
import 'package:money/views/panels/core/view_money_objects.dart';
import 'package:money/widgets/charts/chart.dart';
import 'package:money/widgets/components/box_with_scrolling_content.dart';
import 'package:money/widgets/components/label_and_amount.dart';
import 'package:money/widgets/components/label_and_quantity.dart';
import 'package:money/widgets/components/text_title.dart';
import 'package:money/widgets/components/three_part_label.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/list/adaptive_columns_or_rows_single_selection.dart';
import 'package:money/widgets/pure/center_message.dart';
import 'package:money/widgets/pure/gaps.dart';
import 'package:money/widgets/pure/pivot_toggle_row.dart';
import 'package:money/widgets/pure/snack_bar.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/state/selection_controller.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/field_filters.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const int _zeroInt = 0;
const int _oneInt = 1;
const double _zeroDouble = 0.0;
const double _oneDouble = 1.0;
const double _negativeMultiplier = -1.0;
const int _accountTypeIndexBank = 0;
const int _accountTypeIndexInvestment = 1;
const int _accountTypeIndexCredit = 2;
const int _accountTypeIndexAssets = 3;
const int _accountTypeIndexAll = -1;
const int _approxDateOffsetDays = 1;
const double _toggleMinHeight = 40.0;
const double _toggleMinWidth = 100.0;
const double _pivotSpacing = 10.0;
const double _stockPanelHeight = 180.0;
const double _summaryPanelHeight = 150.0;
const int _chartMaxPointsLarge = 100;
const int _chartMaxPointsSmall = 10;
const int _symbolTokenIndex = 1;

/// Main view for all Accounts
class ViewAccounts extends ViewForMoneyObjects {
  const ViewAccounts({super.key, super.includeClosedAccount});

  @override
  State<ViewForMoneyObjects> createState() => _ViewAccountsState();
}

class _ViewAccountsState extends ViewForMoneyObjectsState {
  _ViewAccountsState() {
    viewId = ViewId.viewAccounts;
  }

  final List<Widget> _pivots = <Widget>[];

  // Footer related
  final DateRange _footerColumnDate = DateRange();

  // Filter related
  final List<bool> _selectedPivot = <bool>[false, false, false, false, true];

  @override
  Widget buildHeader([final Widget? child]) {
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
  List<Widget> getActionsButtons(final bool forSidePanelTransactions) {
    final List<Widget> list = super.getActionsButtons(forSidePanelTransactions);

    if (forSidePanelTransactions) {
      list.add(
        buildJumpToButton(context, <MenuEntry>[
          MenuEntry(
            icon: ViewId.viewTransactions.getIconData(),
            title: 'Matching Transaction',
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
                message: 'No matching transactions',
              );
            },
          ),
        ]),
      );
    } else {
      // Place this in front off all the other actions button
      list.insert(
        _zeroInt,
        buildAddItemButton(() {
          // add a new Account
          final Account newItem = Data().accounts.addNewAccount(
            'New Bank Account',
          );
          updateListAndSelect(newItem.uniqueId);
        }, 'Add new account'),
      );

      // this can go last
      final Account? account = getFirstSelectedItem() as Account?;
      if (account != null) {
        list.add(
          buildJumpToButton(context, <MenuEntry>[
            MenuEntry.toTransactions(
              transactionId: _accountTypeIndexAll,
              // Prepare the Transaction view Filter to show only the selected account
              filters: FieldFilters(<FieldFilter>[
                FieldFilter(
                  fieldName: Constants.viewTransactionFieldNameAccount,
                  strings: <String>[account.fieldName.value],
                ),
              ]),
            ),
            MenuEntry.toInvestments(accountName: account.fieldName.value),
          ]),
        );
      }
    }

    return list;
  }

  @override
  String getClassNamePlural() {
    return 'Accounts';
  }

  @override
  String getClassNameSingular() {
    return 'Account';
  }

  // default currency for this view
  @override
  List<String> getCurrencyChoices(
    final SidePanelSubViewEnum subViewId,
    final List<int> selectedItems,
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
    return 'Your main assets.';
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
      list = list.where((final Account instance) => isMatchingFilters(instance)).toList();
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
      onDetails: _getSidePanelViewDetails,
      onChart: _getSubViewContentForChart,
      onTransactions: _getSidePanelViewTransactions,
    );
  }

  @override
  List<DataObject> getSidePanelTransactions() {
    final Account? account = getFirstSelectedItem() as Account?;
    if (account != null) {
      return getTransactionForLastSelectedAccount(account);
    }
    return <DataObject>[];
  }

  @override
  void initState() {
    super.initState();

    onAddTransaction = () {
      showImportTransactionsWizard();
    };

    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_bank'),
        text1: 'Banks',
        small: true,
        isVertical: true,
        text2: getAmountAsStringUsingCurrency(
          getTotalBalanceOfAccounts(getSelectedAccountTypesByIndex(_accountTypeIndexBank)),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_investment'),
        text1: AppL10n.tr(AppTranslationKeys.investments),
        small: true,
        isVertical: true,
        text2: getAmountAsStringUsingCurrency(
          getTotalBalanceOfAccounts(getSelectedAccountTypesByIndex(_accountTypeIndexInvestment)),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_credit'),
        text1: 'Credit',
        small: true,
        isVertical: true,
        text2: getAmountAsStringUsingCurrency(
          getTotalBalanceOfAccounts(getSelectedAccountTypesByIndex(_accountTypeIndexCredit)),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_assets'),
        text1: 'Assets',
        small: true,
        isVertical: true,
        text2: getAmountAsStringUsingCurrency(
          getTotalBalanceOfAccounts(getSelectedAccountTypesByIndex(_accountTypeIndexAssets)),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_all'),
        text1: 'All',
        small: true,
        isVertical: true,
        text2: getAmountAsStringUsingCurrency(
          getTotalBalanceOfAccounts(getSelectedAccountTypesByIndex(_accountTypeIndexAll)),
        ),
      ),
    );
  }

  /// Calculates the total balance of the specified account types.
  double getTotalBalanceOfAccounts(final List<AccountType> types) {
    double total = _zeroDouble;
    Data().accounts
        .activeAccounts(types)
        .forEach(
          (final Account x) => total += (x.fieldBalanceNormalized.getValueForDisplay(x) as AmountModel).asDouble(),
        );
    return total;
  }

  /// Filters a [Transaction] by the specified [accountId].
  bool filterByAccountId(final Transaction t, final num accountId) {
    return t.fieldAccountId.value == accountId;
  }

  /// Returns the selected account types based on UI pivot selections.
  List<AccountType> getSelectedAccountType() {
    if (_selectedPivot[_accountTypeIndexBank]) {
      return getSelectedAccountTypesByIndex(_accountTypeIndexBank);
    }

    if (_selectedPivot[_accountTypeIndexInvestment]) {
      return getSelectedAccountTypesByIndex(_accountTypeIndexInvestment);
    }

    if (_selectedPivot[_accountTypeIndexCredit]) {
      return getSelectedAccountTypesByIndex(_accountTypeIndexCredit);
    }

    if (_selectedPivot[_accountTypeIndexAssets]) {
      return getSelectedAccountTypesByIndex(_accountTypeIndexAssets);
    }

    return getSelectedAccountTypesByIndex(_accountTypeIndexAll);
  }

  /// Returns a list of [AccountType] based on the provided [index].
  List<AccountType> getSelectedAccountTypesByIndex(final int index) {
    switch (index) {
      case _accountTypeIndexBank:
        return <AccountType>[AccountType.checking, AccountType.savings];

      case _accountTypeIndexInvestment:
        return <AccountType>[AccountType.investment, AccountType.retirement];

      case _accountTypeIndexCredit:
        return <AccountType>[AccountType.credit, AccountType.creditLine];

      case _accountTypeIndexAssets:
        return <AccountType>[
          AccountType.asset,
          AccountType.cash,
          AccountType.loan,
        ];

      default: // all
        return <AccountType>[];
    }
  }

  /// Builds the horizontal toggle row used to select account type pivots.
  Widget _renderToggles() {
    return buildPivotToggleRow(
      key: const Key('view_accounts_pivots'),
      isSelected: _selectedPivot,
      children: _pivots,
      padding: const EdgeInsets.only(bottom: SizeForPadding.medium),
      borderRadius: const BorderRadius.all(Radius.circular(SizeForPadding.normal)),
      minHeight: _toggleMinHeight,
      minWidth: _toggleMinWidth,
      onPressed: (int index) {
        updatePivotSelectionAndRefresh(_selectedPivot, index);
      },
    );
  }

  /// Builds the side panel details view for the currently selected account.
  Widget _getSidePanelViewDetails({
    required final List<int> selectedIds,
  }) {
    keepUnused(selectedIds);
    final Account? selectedAccount = getFirstSelectedItem() as Account?;
    if (selectedAccount == null) {
      return CenterMessage(message: AppL10n.tr(AppTranslationKeys.noItemSelected));
    }

    if (selectedAccount.isInvestmentAccount()) {
      return SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(SizeForPadding.large),
              child: MoneyObjectCard(
                title: getClassNameSingular(),
                moneyObject: selectedAccount,
              ),
            ),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.center,
                runSpacing: _pivotSpacing,
                spacing: _pivotSpacing,
                children: _buildStockHoldingCards(selectedAccount),
              ),
            ),
          ],
        ),
      );
    } else {
      return SingleChildScrollView(
        child: Center(
          child: MoneyObjectCard(
            title: getClassNameSingular(),
            moneyObject: selectedAccount,
          ),
        ),
      );
    }
  }

  /// Builds holding summary cards for an investment account grouped by stock symbol.
  List<Widget> _buildStockHoldingCards(final Account account) {
    final AccumulatorList<String, Investment> groupBySymbol = AccumulatorList<String, Investment>();
    Accounts.groupAccountStockSymbols(account, groupBySymbol, Data());

    if (groupBySymbol.getKeys().isEmpty) {
      return <Widget>[];
    }

    final List<StockSummary> stockSummaries = <StockSummary>[];

    groupBySymbol.values.forEach((
      String key,
      Set<Investment> listOfInvestmentsForAccount,
    ) {
      final double sharesForThisStock = Investments.applyHoldingSharesAdjustedForSplits(
        listOfInvestmentsForAccount.toList(),
      );

      if (isConsideredZero(sharesForThisStock) == false) {
        //  "123|MSFT" >> "MSFT"
        // tally the cost of the stock
        double totalCost = _zeroDouble;
        for (final Investment investment in listOfInvestmentsForAccount.toList()) {
          totalCost += investment.costForShares;
        }

        final String symbol = key.split('|')[_symbolTokenIndex];

        final Security? stock = Data().securities.getBySymbol(symbol);
        double stockPrice = _oneDouble;

        if (stock != null) {
          stockPrice = stock.fieldPrice.value.asDouble();
        }

        stockSummaries.add(
          StockSummary(
            symbol: symbol,
            shares: sharesForThisStock,
            sharePrice: stockPrice,
            averageCost: totalCost / sharesForThisStock,
          ),
        );
      }
    });

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
                      text: 'Get latest price',
                      onPressed: () async {
                        await loadFomBackendAndSaveToCache(summary.symbol);
                      },
                    ),
                    MenuEntry.customAction(
                      icon: Icons.add,
                      text: 'Add investment',
                      onPressed: () async {
                        showImportInvestment(
                          inputData: InvestmentImportFields(
                            account: Data().accounts.getMostRecentlySelectedAccount(),
                            date: DateTime.now(),
                            // inverse the position
                            investmentType: summary.shares > 0 ? InvestmentType.sell : InvestmentType.buy,
                            category: Data().categories.investmentOther,
                            symbol: summary.symbol,
                            units: summary.shares,
                            amountPerUnit: summary.sharePrice,
                            transactionAmount: summary.shares * summary.sharePrice,
                            description: 'Close Position',
                          ),
                        );
                      },
                    ),
                  ]),
                ],
              ),
              gapMedium(),

              // number of shares
              LabelAndQuantity(caption: 'Shares', quantity: summary.shares),

              // Average cost price
              LabelAndAmount(
                caption: 'Average cost',
                amount: summary.averageCost,
              ),

              // Price per share
              LabelAndAmount(
                caption: 'Market price',
                amount: summary.sharePrice,
              ),

              // Hold value
              gapMedium(),
              const Divider(),
              LabelAndAmount(
                caption: 'Value',
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
          LabelAndAmount(caption: 'Value', amount: account.balance),
        ],
      ),
    );

    return stockPanels;
  }

  /// Details panels Chart panel for Accounts
  Widget _getSubViewContentForChart({
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency,
  }) {
    final List<PairXYY> listOfPairXY = <PairXYY>[];

    if (selectedIds.length == _oneInt) {
      final Account? account = getFirstSelectedItemFromSelectedList(selectedIds) as Account?;
      if (account == null) {
        // this should not happen
        return Text(AppL10n.tr(AppTranslationKeys.noAccountSelected));
      }

      account.maxBalancePerYears.forEach((int key, double value) {
        final double valueCurrencyChoice = showAsNativeCurrency ? value : value * account.getCurrencyRatio();

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
                  : account.fieldBalanceNormalized.getValueForDisplay(account) as num,
            ),
          );
        }
      }

      listOfPairXY.sort(
        (final PairXYY a, final PairXYY b) => (b.yValue1.abs() - a.yValue1.abs()).toInt(),
      );

      return Chart(
        key: Key(selectedIds.toString()),
        list: listOfPairXY.take(_chartMaxPointsSmall).toList(),
      );
    }
  }

  /// Builds the side panel transactions subview for the selected account.
  Widget _getSidePanelViewTransactions({
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency,
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
    required final Account account,
    required final bool showAsNativeCurrency,
  }) {
    int sortFieldIndex = PreferenceController.to.getSidePanelSortBy();
    final bool sortAscending = PreferenceController.to.getSidePanelSortAscending();

    final SelectionController selectionController = SelectionController(
      getPreferenceKey(settingKeySidePanel + settingKeySelectedListItemId),
    );

    selectionController.load();

    final FieldDefinitions columnsToDisplay = <Field<dynamic>>[
      Transaction.fields.getFieldByName(columnIdDate),
      Transaction.fields.getFieldByName(columnIdPayee),
      Transaction.fields.getFieldByName(columnIdCategory),
      Transaction.fields.getFieldByName(columnIdMemo),
      Transaction.fields.getFieldByName(columnIdStatus),
      Transaction.fields.getFieldByName(
        showAsNativeCurrency ? columnIdAmount : columnIdAmountNormalized,
      ),
      Transaction.fields.getFieldByName(
        showAsNativeCurrency ? columnIdBalance : columnIdBalanceNormalized,
      ),
      // Credit Card account has a PaidOn column to help with balancing Statements
      if (account.fieldType.value == AccountType.credit) Transaction.fields.getFieldByName(columnIdPaidOn),
    ];

    return ListenableBuilder(
      listenable: DataFileController.to,
      builder: (final BuildContext _, final Widget? _) {
        return ListViewTransactions(
          key: Key(
            'transaction_list_currency_${showAsNativeCurrency}_changedOn${DataFileController.to.lastUpdateAsString}',
          ),
          columnsToInclude: columnsToDisplay,
          getList: () => getTransactionForLastSelectedAccount(account),
          sortFieldIndex: sortFieldIndex,
          sortAscending: sortAscending,
          listController: AppScope.instance.listControllerSidePanel,
          selectionController: selectionController,
          onUserChoiceChanged:
              (
                int sortByFieldIndex,
                bool sortAscending,
                final int selectedTransactionId,
              ) {
                // keep track of user choice
                sortFieldIndex = sortByFieldIndex;
                sortAscending = sortAscending;

                // Save user choices

                // Select Column
                PreferenceController.to.setSidePanelSortBy(sortByFieldIndex);
                // Sort
                PreferenceController.to.setSidePanelSortAscending(sortAscending);

                // last item selected
                PreferenceController.to.setSidePanelSelectedItemId(selectedTransactionId);
              },
        );
      },
    );
  }

  // Details Panel for Transactions
  Widget _getSubViewContentForTransactionsForLoans({
    required final Account account,
    required final bool showAsNativeCurrency,
    required final DataAbstract data,
  }) {
    int sortFieldIndex = PreferenceController.to.getSidePanelSortBy();
    final bool sortAscending = PreferenceController.to.getSidePanelSortAscending();

    final SelectionController selectionController = SelectionController(
      getPreferenceKey(settingKeySidePanel + settingKeySelectedListItemId),
    );

    selectionController.load();

    return ListenableBuilder(
      listenable: DataFileController.to,
      builder: (final BuildContext _, final Widget? _) {
        final List<LoanPayment> aggregatedList = getAccountLoanPayments(account, data);

        MoneyObjects.sortList(
          aggregatedList,
          LoanPayment.fieldsForColumnView.definitions,
          sortFieldIndex,
          sortAscending,
        );

        return AdaptiveListColumnsOrRowsSingleSelection(
          key: Key(
            'loan_payment_list_currency_${showAsNativeCurrency}_changedOn${DataFileController.to.lastUpdateAsString}',
          ),
          list: aggregatedList,
          fieldDefinitions: LoanPayment.fieldsForColumnView.definitions,
          filters: FieldFilters(),
          sortByFieldIndex: sortFieldIndex,
          sortAscending: sortAscending,
          selectedId: selectionController.firstSelectedId,
          listController: AppScope.instance.listControllerSidePanel,
          displayAsColumns: true,
          backgroundColorForHeaderFooter: Colors.transparent,
          onSelectionChanged: (int uniqueId) {
            sortFieldIndex = sortFieldIndex;
            selectionController.select(uniqueId);
            PreferenceController.to.setSidePanelSelectedItemId(uniqueId);
          },
          onColumnHeaderTap: (int columnHeaderIndex) {
            // ignore: invalid_use_of_protected_member
            setState(() {
              if (columnHeaderIndex == sortFieldIndex) {
                // toggle order
                sortFieldIndex = sortFieldIndex;
              } else {
                sortFieldIndex = columnHeaderIndex;
              }
              PreferenceController.to.setSidePanelSortBy(sortFieldIndex);
            });
          },
          onItemLongPress: (BuildContext _, int itemId) {
            final LoanPayment instance = findObjectById(itemId, aggregatedList) as LoanPayment;
            myShowDialogAndActionsForMoneyObject(
              title: 'Loan Payment',
              moneyObject: instance,
            );
            selectionController.select(itemId);
            PreferenceController.to.setSidePanelSelectedItemId(itemId);
          },
        );
      },
    );
  }

  /// Returns transactions for the last selected account with optional filtering.
  List<Transaction> getTransactionForLastSelectedAccount(
    final Account account,
  ) {
    return getTransactions(
      filter: (Transaction transaction) {
        return filterByAccountId(transaction, account.uniqueId);
      },
    );
  }
}
