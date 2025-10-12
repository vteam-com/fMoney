part of 'view_accounts.dart';

extension ViewAccountsSidePanel on ViewAccountsState {
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
    Accounts.groupAccountStockSymbols(account, groupBySymbol);

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
                  buildMenuButton(<MenuEntry>[
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
    stockSummaries.forEach(
      (StockSummary element) => totalInvestment += element.holdingValue,
    );

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
              MoneyWidget(
                amountModel: MoneyModel(
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
              MoneyWidget(
                amountModel: MoneyModel(
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
      for (final MoneyObject item in getList()) {
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
          'transaction_list_currency_${showAsNativeCurrency}_changedOn${DataController.to.lastUpdateAsString}',
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
      final List<LoanPayment> aggregatedList = getAccountLoanPayments(account);

      MoneyObjects.sortList(
        aggregatedList,
        LoanPayment.fieldsForColumnView.definitions,
        sortFieldIndex,
        sortAscending,
      );

      return AdaptiveListColumnsOrRowsSingleSelection(
        key: Key(
          'loan_payment_list_currency_${showAsNativeCurrency}_changedOn${DataController.to.lastUpdateAsString}',
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
