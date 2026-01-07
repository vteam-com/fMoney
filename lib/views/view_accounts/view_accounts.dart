import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:money/data/accounts.dart';
import 'package:money/data/data.dart';
import 'package:money/data/data_file_controller.dart';
import 'package:money/data/data_interface.dart';
import 'package:money/data/dialog_mutate_money_object.dart';
import 'package:money/data/domain_buttons.dart';
import 'package:money/data/get_stock_from_cache_or_backend.dart';
import 'package:money/data/investment.dart';
import 'package:money/data/investments.dart';
import 'package:money/data/loan_payment.dart';
import 'package:money/data/loan_payments.dart';
import 'package:money/data/menu_entry.dart';
import 'package:money/data/security.dart';
import 'package:money/data/transaction.dart';
import 'package:money/helpers/account_types_enum.dart';
import 'package:money/helpers/accumulator.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/investment_types.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/helpers/transaction_types.dart';
import 'package:money/models/account.dart';
import 'package:money/models/money_objects.dart';
import 'package:money/views/adaptive_view/view_money_objects.dart';
import 'package:money/views/import/import_investment.dart';
import 'package:money/views/import/import_investment_panel.dart';
import 'package:money/views/import/import_wizard.dart';
import 'package:money/views/list_view_transactions.dart';
import 'package:money/views/money_object_card.dart';
import 'package:money/views/panels/side_panel/side_panel_support.dart';
import 'package:money/widgets/adaptive_list/adaptive_columns_or_rows_single_selection.dart';
import 'package:money/widgets/box.dart';
import 'package:money/widgets/center_message.dart';
import 'package:money/widgets/charts/chart.dart';
import 'package:money/widgets/dialog_button.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/label_and_amount.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/selection_controller.dart';
import 'package:money/widgets/snack_bar.dart';
import 'package:money/widgets/text_title.dart';
import 'package:money/widgets/three_part_label.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/field_filter.dart';
import 'package:money/widgets/widgets_domain/field_filters.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

/// Main view for all Accounts
class ViewAccounts extends ViewForMoneyObjects {
  const ViewAccounts({super.key, super.includeClosedAccount});

  @override
  State<ViewForMoneyObjects> createState() => ViewAccountsState();
}

class ViewAccountsState extends ViewForMoneyObjectsState {
  ViewAccountsState() {
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
                  min: selectedInfoTransaction.fieldDateTime.value!.add(const Duration(days: -1)).startOfDay,
                  max: selectedInfoTransaction.fieldDateTime.value!.add(const Duration(days: 1)).endOfDay,
                );
                // we are looking for the reverse transaction
                final double amountToFind = selectedInfoTransaction.fieldAmount.value.asDouble() * -1;

                final Transaction? matchingTransaction = Data().transactions.findExistingTransaction(
                  accountId: -1,
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
        0,
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
              transactionId: -1,
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
          getTotalBalanceOfAccounts(getSelectedAccountTypesByIndex(0)),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_investment'),
        text1: 'Investments',
        small: true,
        isVertical: true,
        text2: getAmountAsStringUsingCurrency(
          getTotalBalanceOfAccounts(getSelectedAccountTypesByIndex(1)),
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
          getTotalBalanceOfAccounts(getSelectedAccountTypesByIndex(2)),
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
          getTotalBalanceOfAccounts(getSelectedAccountTypesByIndex(3)),
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
          getTotalBalanceOfAccounts(getSelectedAccountTypesByIndex(-1)),
        ),
      ),
    );
  }

  /// Calculates the total balance of the specified account types.
  double getTotalBalanceOfAccounts(final List<AccountType> types) {
    double total = 0.0;
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

  List<AccountType> getSelectedAccountType() {
    if (_selectedPivot[0]) {
      return getSelectedAccountTypesByIndex(0);
    }

    if (_selectedPivot[1]) {
      return getSelectedAccountTypesByIndex(1);
    }

    if (_selectedPivot[2]) {
      return getSelectedAccountTypesByIndex(2);
    }

    if (_selectedPivot[3]) {
      return getSelectedAccountTypesByIndex(3);
    }

    return getSelectedAccountTypesByIndex(-1);
  }

  /// Returns a list of [AccountType] based on the provided [index].
  List<AccountType> getSelectedAccountTypesByIndex(final int index) {
    switch (index) {
      case 0:
        return <AccountType>[AccountType.checking, AccountType.savings];

      case 1:
        return <AccountType>[AccountType.investment, AccountType.retirement];

      case 2:
        return <AccountType>[AccountType.credit, AccountType.creditLine];

      case 3:
        return <AccountType>[
          AccountType.asset,
          AccountType.cash,
          AccountType.loan,
        ];

      default: // all
        return <AccountType>[];
    }
  }

  Widget _renderToggles() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
      child: ToggleButtons(
        key: const Key('view_accounts_pivots'),
        direction: Axis.horizontal,
        onPressed: (final int index) {
          // ignore: invalid_use_of_protected_member
          setState(() {
            for (int i = 0; i < _selectedPivot.length; i++) {
              _selectedPivot[i] = i == index;
            }
            list = getList();
            clearSelection();
          });
        },
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        constraints: const BoxConstraints(minHeight: 40.0, minWidth: 100.0),
        isSelected: _selectedPivot,
        children: _pivots,
      ),
    );
  }

  Widget _getSidePanelViewDetails({
    required final List<int> selectedIds,
    required final bool isReadOnly,
  }) {
    final Account? selectedAccount = getFirstSelectedItem() as Account?;
    if (selectedAccount == null) {
      return const CenterMessage(message: 'No item selected.');
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
                runSpacing: 10,
                spacing: 10,
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
        double totalCost = 0.0;
        for (final Investment investment in listOfInvestmentsForAccount.toList()) {
          totalCost += investment.costForShares;
        }

        final String symbol = key.split('|')[1];

        final Security? stock = Data().securities.getBySymbol(symbol);
        double stockPrice = 1.00;

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
            height: 180,
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
    double totalInvestment = 0.0;
    for (StockSummary element in stockSummaries) {
      totalInvestment += element.holdingValue;
    }

    final double totalCash = account.balance - totalInvestment;

    stockPanels.insert(
      0,
      BoxWithScrollingContent(
        height: 150,
        children: <Widget>[
          gapMedium(),
          // Cash
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const TextTitle('Cash'),
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
              const TextTitle('Investments'),
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

    if (selectedIds.length == 1) {
      final Account? account = getFirstSelectedItemFromSelectedList(selectedIds) as Account?;
      if (account == null) {
        // this should not happen
        return const Text('No account selected');
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
        list: listOfPairXY.take(100).toList(),
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
        list: listOfPairXY.take(10).toList(),
      );
    }
  }

  Widget _getSidePanelViewTransactions({
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency,
  }) {
    final Account? account = getFirstSelectedItem() as Account?;
    if (account == null) {
      return const CenterMessage(message: 'No account selected.');
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

    final SelectionController selectionController = Get.put(
      SelectionController(
        getPreferenceKey(settingKeySidePanel + settingKeySelectedListItemId),
      ),
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

    return Obx(() {
      return ListViewTransactions(
        key: Key(
          'transaction_list_currency_${showAsNativeCurrency}_changedOn${DataFileController.to.lastUpdateAsString}',
        ),
        columnsToInclude: columnsToDisplay,
        getList: () => getTransactionForLastSelectedAccount(account),
        sortFieldIndex: sortFieldIndex,
        sortAscending: sortAscending,
        listController: Get.find<ListControllerSidePanel>(),
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
    });
  }

  // Details Panel for Transactions
  Widget _getSubViewContentForTransactionsForLoans({
    required final Account account,
    required final bool showAsNativeCurrency,
    required final DataInterface data,
  }) {
    int sortFieldIndex = PreferenceController.to.getSidePanelSortBy();
    final bool sortAscending = PreferenceController.to.getSidePanelSortAscending();

    final SelectionController selectionController = Get.put(
      SelectionController(
        getPreferenceKey(settingKeySidePanel + settingKeySelectedListItemId),
      ),
    );

    selectionController.load();

    return Obx(() {
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
        listController: Get.find<ListControllerSidePanel>(),
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
        onItemLongPress: (BuildContext context2, int itemId) {
          final LoanPayment instance = findObjectById(itemId, aggregatedList) as LoanPayment;
          myShowDialogAndActionsForMoneyObject(
            title: 'Loan Payment',
            moneyObject: instance,
          );
          selectionController.select(itemId);
          PreferenceController.to.setSidePanelSelectedItemId(itemId);
        },
      );
    });
  }

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

class StockSummary {
  StockSummary({
    required this.symbol,
    required this.shares,
    required this.sharePrice,
    required this.averageCost,
  });

  final double averageCost;
  final double sharePrice;
  final double shares;
  final String symbol;

  double get holdingValue => shares * sharePrice;
}
