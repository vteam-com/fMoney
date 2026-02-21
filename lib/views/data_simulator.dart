import 'dart:math';

import 'package:money/data/models/alias_types.dart';
import 'package:money/helpers/account_types_enum.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/investment_types.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/views/data.dart';
import 'package:money/views/providers/account.dart';
import 'package:money/views/providers/account_alias.dart';
import 'package:money/views/providers/alias.dart';
import 'package:money/views/providers/category.dart';
import 'package:money/views/providers/currency.dart';
import 'package:money/views/providers/investment.dart';
import 'package:money/views/providers/loan_payment.dart';
import 'package:money/views/providers/online_account.dart';
import 'package:money/views/providers/payee.dart';
import 'package:money/views/providers/security.dart';
import 'package:money/views/providers/stock_split.dart';
import 'package:money/views/providers/transaction.dart';
import 'package:money/views/providers/transaction_split.dart';

const int _stockAppleId = 0;
const int _stockFordId = 1;
const int _monthsPerYear = 12;
const int _firstDayOfMonth = 1;
const int _oneMonthOffset = 1;
const int _lastDayOfPreviousMonth = 0;
const int _maxDaysInMonth = 31;
const int _daysPerYear = 365;
const double _averageDaysPerYear = 365.25;
const int _currencyRoundingDecimals = 2;
const int _unsetId = -1;
const int _defaultFlags = 0;
const int _taxableFalse = 0;
const double _zeroAmount = 0.0;
const int _zeroInt = 0;
const double _initialRunningBalance = 0.0;
const int _midpointDivisor = 2;
const int _listIndexFirst = 0;
const int _listIndexSecond = 1;
const int _negativeMultiplier = -1;
const int _maxRandomIncomeAmount = 2500;
const int _maxRandomExpenseAmount = -500;
const int _initialDepositYearsBack = -21;
const double _initialDepositAmount = 100000;
const double _homePurchaseValue = 250000;
const double _homeDownPaymentAmount = -30000;
const double _monthlyHomeLoanAmount = -2000;
const double _monthlyRentAmount = -600;
const int _yearsInPast = 20;
const double _startingYearlySalaryFirstJobAmount = 15000.0;
const double _startingYearlySalarySecondJobAmount = 50000.0;
const double _yearlyInflationPercent = 3.0;
const double _categoryBillsBudget = 100.0;
const double _categorySalaryPaycheckBudget = 900.0;
const double _usdRatio = 1.09;
const double _usdLastRatio = 1.12;
const double _cadRatio = 0.75;
const double _cadLastRatio = 0.85;
const double _eurRatio = 1.15;
const double _eurLastRatio = 1.11;
const double _gbpRatio = 1.25;
const double _gbpLastRatio = 1.21;
const double _jpyRatio = 1 / 147.72;
const double _jpyLastRatio = 0.0;
const int _eventIdCondo = 0;
const int _eventIdWedding = 1;
const int _eventIdHome = 2;
const int _eventIdDivorce = 3;
const int _eventIdSoldHouse = 4;
const int _eventIdVegas = 5;
const double _appleTradeQuantity = 100;
const double _appleBuyPriceFirst = 199.99;
const double _appleSellPrice = 300.0;
const double _appleDividendQuantity = 1;
const double _appleDividendPrice = 5000.0;
const double _appleBuyPriceSecond = 400.0;
const double _fordTradeQuantity = 1000;
const double _fordBuyPrice = 8.86;
const double _fordSellPrice = 14.14;
const double _loanInitialAmount = 20000.0;
const double _loanRatePercent = 4.0;
const double _loanMonthlyPayment = 500.0;
const int _loanStartYearsBack = -6;
const int _loanStartMonth = DateTime.november;
const int _loanStartDay = 11;
const int _loanScheduleYearsBack = 5;
const int _loanPaymentDay = 9;
const int _onlineAccountIdFirst = 0;
const int _onlineAccountIdSecond = 1;
const int _payeeIdBurgerKing = 0;
const int _payeeIdNasa = 1;
const int _payeeIdLotteryWin = 2;
const int _payeeIdBroker = 3;
const int _rentBuildingId = 0;
const int _rentUnitBuildingId = 0;
const int _rentUnitId = 0;
const int _rentUnitAlternateId = 0;
const double _appleStockPrice = 200.0;
const double _appleStockLastPrice = 201.0;
const int _appleStockPriceYear = 2015;
const int _appleStockPriceMonth = DateTime.january;
const int _appleStockPriceDay = 1;
const double _fordStockPrice = 7.0;
const double _fordStockLastPrice = 7.10;
const int _fordStockPriceYear = 2020;
const int _fordStockPriceMonth = DateTime.january;
const int _fordStockPriceDay = 1;
const int _stockSplitNumerator = 2;
const int _stockSplitDenominator = 1;
const int _electricityMin = 40;
const int _electricityMax = 100;
const int _phoneMin = 40;
const int _phoneMax = 55;
const double _internetAmount = -40.0;
const double _tvAmount = -80.0;
const double _gymAmount = -50.0;
const double _netflixAmount = -8.99;
const int _subscriptionElectricityDay = 11;
const int _subscriptionPhoneDay = 12;
const int _subscriptionInternetDay = 13;
const int _subscriptionTvDay = 13;
const int _subscriptionGymDay = 23;
const int _subscriptionNetflixDay = 19;
const int _gymYearsBack = 8;
const int _gymDurationYears = 4;
const int _netflixYearsBack = 5;
const int _transactionExtraIdFirst = 0;
const int _transactionExtraIdSecond = 1;
const int _transactionExtraYearFirst = 2010;
const int _transactionExtraYearSecond = 2020;
const int _transactionExtraMonth = DateTime.january;
const int _transactionExtraDay = 1;
const int _creditCardTransactionsPerMonth = 4;
const int _spendMultiplierAfterPromotion = 3;
const int _transportCityBusMax = 3;
const int _transportTaxiMax = 20;
const int _transportUberMax = 30;
const int _groceryStoreMax = 50;
const int _grocerySafewayMax = 80;
const int _groceryWholeFoodMax = 200;
const int _restaurantStarbucksMax = 10;
const int _restaurantAppleBeesMax = 100;
const int _restaurantPizzaHutMax = 20;
const int _salaryPaymentDay = 5;
const int _inflationPercentDivisor = 100;
const double _signOnBonusAmount = 22000.0;
const int _holidayBonusMonth = DateTime.december;
const int _holidayBonusDayOffset = 10;
const double _holidayBonusAmount = 3500.0;
const int _rentAndHomePaymentDay = 10;
const double _mortgageSplitPrincipalOffset = 200.0;
const int _buyHomeDelayDays = 180;

/// Generates sample data for the MoneyFlutter app.
class DataSimulator {
  int idStockApple = _stockAppleId;
  int idStockFord = _stockFordId;

  late final Account _accountBankCanada;
  late final Account _accountBankUSA;
  late final Account _accountCreditCardUSD;
  late final Account _accountForInvestments;
  late final Account _accountStartupLoan;
  late final Category _categoryBills;
  late final Category _categoryBillsElectricity;
  late final Category _categoryBillsInternet;
  late final Category _categoryBillsPhone;
  late final Category _categoryBillsTV;
  late final Category _categoryFood;
  late final Category _categoryFoodGrocery;
  late final Category _categoryFoodRestaurant;
  late final Category _categoryHomeLoanDownPayment;
  late final Category _categoryHomeLoanMortgageInterest;
  late final Category _categoryHomeLoanMortgagePrincipal;
  late final Category _categoryInvestmentTrades;
  late final Category _categorySalary;
  late final Category _categorySalaryBonus;
  late final Category _categorySalaryPaycheck;
  late final Category _categorySubscriptionTransport;
  late final Category _categorySubscriptions;
  late final Category _categorySubscriptionsGym;
  late final Category _categorySubscriptionsStreaming;
  final double _monthlyHomeLoan = _monthlyHomeLoanAmount;
  final double _monthlyRent = _monthlyRentAmount;
  final int _numberOFYearInThePast = _yearsInPast;
  final double _startingYearlySalaryFirstJob = _startingYearlySalaryFirstJobAmount;
  final double _startingYearlySalarySecondJob = _startingYearlySalarySecondJobAmount;
  final DateTime _today = DateTime.now();
  final double _yearlyInflation = _yearlyInflationPercent;

  late DateTime _dateOfFirstBigJob;

  /// Generates sample data for the MoneyFlutter app.
  void generateData() {
    Data().clearExistingData();

    _generateCurrencies();
    _generatePayees();
    _generateAccounts();
    _generateOnlineAccounts();
    _generateAccountAliases();
    _generateAliases();
    _generateCategories();
    _generateInvestments();

    _generateRentals();
    _generateTransactionsSalary();
    _generateLoans();
    _generateTransfersToRentAndHomeLoan();
    _generateEvents();

    _generateSubscriptionsOnCheckingAccount();
    _generateSubscriptionsOnCreditCard();

    _generateTransactionsForCreditCard();
    _generateTransfersToCreditCardPayment();
    _generateTransactionExtra();
  }

  /// Generates list of dates for specified years and frequency.
  List<DateTime> generateListOfDates({
    required int yearInThePast,
    DateTime? stopDate,
    required int howManyPerYear,
    required int dayOfTheMonth,
  }) {
    final List<DateTime> dates = <DateTime>[];

    final DateTime whenToStop = stopDate ?? DateTime.now();
    for (int i = yearInThePast * howManyPerYear; i >= _zeroInt; i--) {
      // Subtract the current month index from today's date
      final DateTime date = DateTime(
        whenToStop.year,
        whenToStop.month - i,
        dayOfTheMonth,
      );
      dates.add(date);
    }
    return dates;
  }

  /// Generates random list of dates for specified year and frequency.
  List<DateTime> generateListOfDatesRandom({
    required int year,
    required int howManyPerMonths,
  }) {
    final List<DateTime> dates = <DateTime>[];

    final DateTime today = DateTime.now();
    for (int i = year * _monthsPerYear; i >= _zeroInt; i--) {
      // Subtract the current month index from today's date
      DateTime date = DateTime(today.year, today.month - i, _firstDayOfMonth);
      // Now we have a Year and Month
      // generate on random date of the month
      for (int event = _zeroInt; event < howManyPerMonths; event++) {
        final int day = Random().nextInt(_maxDaysInMonth);
        date = date.add(Duration(days: day));
        dates.add(date);
      }
    }
    return dates;
  }

  /// Generates monthly expenses for a given account, payee, category, and amount.
  void generateTransactionsMonthlyExpenses({
    required Account account,
    required String payeeName,
    required Category category,
    required double amount,
    required int yearMin,
    required int yearMax,
    required int dayOfTheMonth,
  }) {
    final Payee payee = Data().payees.getOrCreate(payeeName);

    for (int year = yearMin; year <= yearMax; year++) {
      for (int month = DateTime.january; month <= DateTime.december; month++) {
        _addTransactionAccountDatePayeeCategory(
          account: account,
          date: DateTime(year, month, dayOfTheMonth),
          payeeId: payee.uniqueId,
          categoryId: category.uniqueId,
          amount: amount,
        );
      }
    }
  }

  /// Generates a random amount between a minimum and maximum value.
  double getAmount(final int minValue, final int maxValue) {
    final double amount = minValue + Random().nextDouble() * (maxValue - minValue);
    return roundDouble(amount, _currencyRoundingDecimals);
  }

  /// Returns DateTime shifted by specified number of years.
  DateTime getDateShiftedByYears(int yearsToShift, int month, int day) {
    final int yearShifted = getShiftedYearFromNow(yearsToShift);
    return DateTime(yearShifted, month, day);
  }

  /// Returns the last day of the previous month for a given date.
  DateTime getLastDayOfPreviousMonth(DateTime date) {
    final DateTime previousMonth = DateTime(date.year, date.month - _oneMonthOffset);
    final int daysInPreviousMonth = DateTime(
      previousMonth.year,
      previousMonth.month + _oneMonthOffset,
      _lastDayOfPreviousMonth,
    ).day;
    return DateTime(
      previousMonth.year,
      previousMonth.month,
      daysInPreviousMonth,
    ).endOfDay;
  }

  /// Generates random amount up to specified maximum value.
  double getRandomAmount(final int maxValue) {
    final double amount = Random().nextDouble() * maxValue;
    return roundDouble(amount, _currencyRoundingDecimals);
  }

  /// Returns year shifted from today by specified number of years.
  int getShiftedYearFromNow(int numberOfYearFromToday) {
    final DateTime today = DateTime.now();
    return DateTime(
      today.year + numberOfYearFromToday,
      today.month,
      today.day,
    ).year;
  }

  /// Adds an investment transaction to the account.
  void _addInvestment(
    final Account account,
    final String dateAsString,
    final int stockId,
    final InvestmentType activity,
    final double quantity,
    final double tradePrice,
  ) {
    final DateTime date = DateTime.parse(dateAsString);
    double transactionAmount = tradePrice * quantity;
    String action = 'sold';
    final Security? stock = Data().securities.get(stockId);

    if (activity == InvestmentType.buy) {
      action = 'bought';
      transactionAmount *= _negativeMultiplier;
    }
    final Payee payee = Data().payees.getOrCreate('Broker');

    final Transaction t = _addTransactionAccountDatePayeeCategory(
      account: account,
      date: date,
      amount: transactionAmount,
      payeeId: payee.uniqueId,
      categoryId: _categoryInvestmentTrades.uniqueId,
      memo:
          'You $action ${formatDoubleTrimZeros(quantity)} shares of "${stock!.fieldName.value} (${stock.fieldSymbol.value})"',
    );

    Data().investments.appendMoneyObject(
      Investment(
        id: t.uniqueId,
        investmentType: activity.index,
        security: stockId,
        unitPrice: tradePrice,
        units: quantity,
        tradeType: InvestmentTradeType.none.index,
      ),
    );
  }

  /// Adds a new account to the data.
  Account _addNewAccount(
    final int id,
    final String name,
    final String accountId,
    final int type,
    final String currency,
  ) {
    final Account account = Account.fromJson(<String, dynamic>{
      'Id': id,
      'Name': name,
      'AccountId': accountId,
      'Type': type,
      'Currency': currency,
    });
    if (id == _unsetId) {
      Data().accounts.appendNewMoneyObject(account, fireNotification: false);
    } else {
      Data().accounts.appendMoneyObject(account);
    }

    return account;
  }

  /// Creates and appends a transaction for the given account/date with optional payee/category and amount.
  Transaction _addTransactionAccountDatePayeeCategory({
    required Account account,
    required DateTime date,
    int payeeId = _unsetId,
    int categoryId = _unsetId,
    double amount = _zeroAmount,
    String memo = '',
  }) {
    // generate an amount
    // Expenses should be a negative value and smaller range than Revenue;
    int maxValue = _maxRandomIncomeAmount;
    if (Data().categories.isCategoryAnExpense(categoryId)) {
      maxValue = _maxRandomExpenseAmount;
    }

    if (amount == _zeroAmount) {
      amount = getRandomAmount(maxValue);
    }

    final MyJson demoJson = <String, dynamic>{
      'Id': _unsetId,
      'Account': account.fieldId.value,
      'Date': date,
      'Payee': payeeId,
      'Category': categoryId,
      'Amount': amount,
      'Memo': memo,
    };

    final Transaction t = Transaction.fromJSon(demoJson, _initialRunningBalance);

    Data().transactions.appendNewMoneyObject(t, fireNotification: false);
    return t;
  }

  /// Buys a home and adds related transactions.
  void _buyHome(final Payee payeeForHomeLoan, final DateTime date) {
    final Account accountAssetHome = _addNewAccount(
      _unsetId,
      'Main Home',
      'A0001',
      AccountType.asset.index,
      'USD',
    );

    _addTransactionAccountDatePayeeCategory(
      account: accountAssetHome,
      date: date,
      amount: _homePurchaseValue,
      categoryId: Data().categories
          .addNewCategory(
            name: 'Investment:PropertyValue',
            type: CategoryType.investment,
          )
          .uniqueId,
      memo: 'Purchase house valued at 250K',
    );

    _addTransactionAccountDatePayeeCategory(
      account: _accountBankUSA,
      date: date,
      payeeId: payeeForHomeLoan.uniqueId,
      categoryId: _categoryHomeLoanDownPayment.uniqueId,
      amount: _homeDownPaymentAmount,
      memo: 'Down payment',
    );
  }

  /// Creates a transfer between two accounts by creating a source transaction and linking the related transaction.
  Transaction _createTransferTransaction({
    required final Account accountSource,
    required final Account accountDestination,
    required final DateTime date,
    required final double amount,
    required final String memo,
    int categoryId = _unsetId,
  }) {
    final Transaction source = _addTransactionAccountDatePayeeCategory(
      account: accountSource,
      date: date,
      categoryId: categoryId,
      amount: amount,
      memo: memo,
    );

    final Transaction relatedTransaction = Data().makeTransferLinkage(
      transactionSource: source,
      destinationAccount: accountDestination,
    );

    linkTransfer(source, relatedTransaction);

    return relatedTransaction;
  }

  /// Generates sample account aliases.
  void _generateAccountAliases() {
    Data().accountAliases.appendNewMoneyObject(
      AccountAlias.fromJson(<String, dynamic>{
        'Pattern': '*foo*',
        'Flag': _defaultFlags,
        'AccountId': 'A12345',
      }),
      fireNotification: false,
    );
    Data().accountAliases.appendNewMoneyObject(
      AccountAlias.fromJson(<String, dynamic>{
        'Pattern': '*bar*',
        'Flag': _defaultFlags,
        'AccountId': 'B987654',
      }),
      fireNotification: false,
    );
  }

  /// Generates sample accounts.
  void _generateAccounts() {
    _accountBankUSA = _addNewAccount(
      _unsetId,
      'Bank Of America',
      'B0001',
      AccountType.checking.index,
      'USD',
    );

    // Canadian Bank Account
    _accountBankCanada = _addNewAccount(
      _unsetId,
      'Bank Of Montreal',
      'B0002',
      AccountType.savings.index,
      'CAD',
    );

    // Fund that account
    _addTransactionAccountDatePayeeCategory(
      account: _accountBankCanada,
      date: getDateShiftedByYears(_initialDepositYearsBack, DateTime.january, _firstDayOfMonth),
      amount: _initialDepositAmount,
      payeeId: Data().payees.getByName('Lottery Win')!.uniqueId,
      categoryId: Data().categories
          .addNewCategory(
            name: 'Misc Incomes',
            type: CategoryType.income,
            color: '#004400',
          )
          .uniqueId,
      memo: 'Initial opening of account',
    );

    _accountCreditCardUSD = _addNewAccount(
      _unsetId,
      'VisaCard',
      '0002',
      AccountType.credit.index,
      'USD',
    );

    _accountForInvestments = _addNewAccount(
      _unsetId,
      'Fidelity',
      '0003',
      AccountType.investment.index,
      'USD',
    );
    _accountStartupLoan = _addNewAccount(
      _unsetId,
      'Startup',
      '0004',
      AccountType.loan.index,
      'CAD',
    );

    /// Setup categories for this loans
    Data().categories.appendNewMoneyObject(
      Category(
        id: _unsetId,
        name: 'Lend',
        description: '',
        type: CategoryType.investment,
        color: '#FFAAFFAA',
      ),
    );
    _accountStartupLoan.fieldCategoryIdForInterest.value = Data().categories
        .getOrCreate('Lend:Interest:Startup', CategoryType.investment)
        .uniqueId;
    _accountStartupLoan.fieldCategoryIdForPrincipal.value = Data().categories
        .getOrCreate('Lend:Principal:Startup', CategoryType.investment)
        .uniqueId;
  }

  /// Generates sample aliases.
  void _generateAliases() {
    Data().aliases.appendNewMoneyObject(
      Alias(
        id: _unsetId,
        payeeId: _payeeIdLotteryWin,
        pattern: 'ABC',
        flags: AliasType.none.index,
        data: Data(),
      ),
      fireNotification: false,
    );
    Data().aliases.appendNewMoneyObject(
      Alias(
        id: _unsetId,
        payeeId: _payeeIdLotteryWin,
        pattern: 'abc',
        flags: AliasType.none.index,
        data: Data(),
      ),
      fireNotification: false,
    );
    Data().aliases.appendNewMoneyObject(
      Alias(
        id: _unsetId,
        payeeId: _payeeIdBroker,
        pattern: '.*starbucks.*',
        flags: AliasType.regex.index,
        data: Data(),
      ),
      fireNotification: false,
    );
  }

  /// Generates sample categories.
  void _generateCategories() {
    // add the standard categories
    Data().categories.interestEarned;
    Data().categories.salesTax;
    Data().categories.savings;
    Data().categories.transferFromDeletedAccount;
    Data().categories.transferToDeletedAccount;
    Data().categories.unassignedSplit;
    Data().categories.unknown;

    // standard categories for investments
    Data().categories.investmentBonds;
    Data().categories.investmentCredit;
    Data().categories.investmentDebit;
    Data().categories.investmentDividends;
    Data().categories.investmentFees;
    Data().categories.investmentInterest;
    Data().categories.investmentShortTermCapitalGainsDistribution;
    Data().categories.investmentLongTermCapitalGainsDistribution;
    Data().categories.investmentMiscellaneous;
    Data().categories.investmentMutualFunds;
    Data().categories.investmentOptions;
    Data().categories.investmentOther;
    Data().categories.investmentReinvest;
    Data().categories.investmentStocks;
    Data().categories.investmentTransfer;

    // Bills
    {
      _categoryBills = Data().categories.addNewCategory(
        name: 'Bills',
        type: CategoryType.expense,
        color: '#FFFF0000',
      );
      _categoryBills.fieldBudget.value.setAmount(_categoryBillsBudget);
      _categoryBillsElectricity = Data().categories.addNewCategory(
        parentId: _categoryBills.uniqueId,
        name: 'Electricity',
        type: CategoryType.recurringExpense,
      );

      Data().categories.addNewCategory(
        parentId: _categoryBills.uniqueId,
        name: 'School',
        description: '',
        type: CategoryType.expense,
      );

      _categoryBillsPhone = Data().categories.addNewCategory(
        parentId: _categoryBills.uniqueId,
        name: 'Phone',
        type: CategoryType.recurringExpense,
      );

      _categoryBillsTV = Data().categories.addNewCategory(
        parentId: _categoryBills.uniqueId,
        name: 'TV',
        type: CategoryType.recurringExpense,
      );

      _categoryBillsInternet = Data().categories.addNewCategory(
        parentId: _categoryBills.uniqueId,
        name: 'Internet',
        type: CategoryType.recurringExpense,
      );
    }

    // Food
    {
      _categoryFood = Data().categories.addNewCategory(
        name: 'Food',
        type: CategoryType.expense,
        color: '#FFFF22FF',
      );

      _categoryFoodGrocery = Data().categories.addNewCategory(
        parentId: _categoryFood.uniqueId,
        name: 'Grocery',
        type: CategoryType.recurringExpense,
      );

      _categoryFoodRestaurant = Data().categories.addNewCategory(
        parentId: _categoryFood.uniqueId,
        name: 'Restaurant',
        type: CategoryType.recurringExpense,
      );
    }

    // Subscriptions
    {
      _categorySubscriptions = Data().categories.addNewCategory(
        name: 'Subscriptions',
        type: CategoryType.expense,
        color: '#FFFFaaaa',
      );

      _categorySubscriptionsGym = Data().categories.addNewCategory(
        parentId: _categorySubscriptions.uniqueId,
        name: 'Gym',
        type: CategoryType.recurringExpense,
      );

      _categorySubscriptionsStreaming = Data().categories.addNewCategory(
        parentId: _categorySubscriptions.uniqueId,
        name: 'Streaming',
        type: CategoryType.recurringExpense,
      );

      _categorySubscriptionTransport = Data().categories.addNewCategory(
        parentId: _categorySubscriptions.uniqueId,
        name: 'Transportation',
        type: CategoryType.recurringExpense,
      );
    }

    // Salary
    {
      _categorySalary = Data().categories.addNewCategory(
        parentId: _categoryFood.uniqueId,
        name: 'Salary',
        type: CategoryType.income,
        color: '#FF00FF00',
        description: 'Main income',
      );

      _categorySalaryPaycheck = Data().categories.addNewCategory(
        parentId: _categorySalary.uniqueId,
        name: 'Paycheck',
      );
      _categorySalaryPaycheck.fieldBudget.value.setAmount(_categorySalaryPaycheckBudget);

      _categorySalaryBonus = Data().categories.addNewCategory(
        parentId: _categorySalary.uniqueId,
        name: 'Bonus',
      );
    }

    // Investment
    {
      Data().categories.addNewCategory(
        name: 'Investment',
        description: '',
        type: CategoryType.investment,
        color: '#FF1122DD',
      );

      _categoryInvestmentTrades = Data().categories.addNewCategory(
        name: 'Investment:Trades',
      );

      Data().categories.addNewCategory(
        name: 'Properties',
        description: '',
        type: CategoryType.investment,
        color: '#FF11FFDD',
      );
    }

    Data().categories.addNewCategory(
      name: 'Rental',
      description: '',
      type: CategoryType.income,
      color: '#FF11FF33',
    );

    // Loans
    {
      final Category homeLoan = Data().categories.addNewCategory(
        name: 'HomeLoans',
        description: '',
        type: CategoryType.expense,
        color: '#FFBB2233',
      );

      _categoryHomeLoanDownPayment = Data().categories.addNewCategory(
        parentId: homeLoan.uniqueId,
        name: 'DownPayment',
        type: CategoryType.investment,
      );

      _categoryHomeLoanMortgagePrincipal = Data().categories.addNewCategory(
        name: 'HomeLoans:Mortgage:Principal',
        type: CategoryType.investment,
      );

      _categoryHomeLoanMortgageInterest = Data().categories.addNewCategory(
        name: 'HomeLoans:Mortgage:Interest',
        type: CategoryType.expense,
      );
    }

    Data().categories.addNewCategory(
      name: 'Saving',
      description: '',
      type: CategoryType.income,
      color: '#FFBB2233',
    );

    Data().categories.addNewCategory(
      name: 'Travel',
      description: '',
      type: CategoryType.expense,
      color: '#FFBB22FF',
    );

    {
      Data().categories.addNewCategory(
        name: 'Taxes',
        type: CategoryType.expense,
        color: '#FFA1A2A3',
      );
      Data().categories.addNewCategory(name: 'Taxes:IRS');
      Data().categories.addNewCategory(name: 'Taxes:Property');
      Data().categories.addNewCategory(name: 'Taxes:School');
    }
  }

  /// Generates sample currencies.
  void _generateCurrencies() {
    final List<MyJson> demoCurrencies = <MyJson>[
      <String, dynamic>{
        'Id': _unsetId,
        'Name': 'USA',
        'Symbol': 'USD',
        'CultureCode': 'en-US',
        'Ratio': _usdRatio,
        'LastRatio': _usdLastRatio,
      },
      <String, dynamic>{
        'Id': _unsetId,
        'Name': 'Canada',
        'Symbol': 'CAD',
        'CultureCode': 'en-CA',
        'Ratio': _cadRatio,
        'LastRatio': _cadLastRatio,
      },
      <String, dynamic>{
        'Id': _unsetId,
        'Name': 'Euro',
        'Symbol': 'EUR',
        'CultureCode': 'en-ES',
        'Ratio': _eurRatio,
        'LastRatio': _eurLastRatio,
      },
      <String, dynamic>{
        'Id': _unsetId,
        'Name': 'UK',
        'Symbol': 'GBP',
        'CultureCode': 'en-GB',
        'Ratio': _gbpRatio,
        'LastRatio': _gbpLastRatio,
      },
      <String, dynamic>{
        'Id': _unsetId,
        'Name': 'Japan',
        'Symbol': 'JPY',
        'CultureCode': 'en-JP',
        'Ratio': _jpyRatio,
        'LastRatio': _jpyLastRatio,
      },
    ];
    for (final MyJson demoCurrency in demoCurrencies) {
      Data().currencies.appendNewMoneyObject(Currency.fromJson(demoCurrency));
    }
  }

  /// Populates the events collection with a fixed set of demo events.
  void _generateEvents() {
    final Category categoryIdForProperties = Data().categories.getByName('Properties')!;

    final Category categoryIdForTravels = Data().categories.getByName('Travel')!;

    Data().events.loadFromJson(<MyJson>[
      <String, dynamic>{
        'Id': _eventIdCondo,
        'Name': 'Condo in Chicago',
        'Category': categoryIdForProperties.uniqueId,
        'Begin': '1987-03-04',
        'End': '1999-12-04',
        'Memo': 'My first property',
      },
      <String, dynamic>{
        'Id': _eventIdWedding,
        'Name': 'Wedding and honeymoon',
        'Category': categoryIdForTravels.uniqueId,
        'Begin': '1995-06-20',
        'End': '1995-06-30',
        'People': 'Karen; Bob; Yoko',
        'Memo': 'It was raining, see photos here http://example.com',
      },
      <String, dynamic>{
        'Id': _eventIdHome,
        'Name': 'Home in Springfield',
        'Category': categoryIdForProperties.uniqueId,
        'Begin': '1997-01-04',
        'End': '2016-01-04',
        'Memo': 'Our first home',
      },
      <String, dynamic>{
        'Id': _eventIdDivorce,
        'Name': 'Divorce',
        'Begin': '2020-01-01',
        'End': '2020-04-13',
        'People': 'Karen; Bob',
        'Memo': 'Our friendly divorce',
      },
      <String, dynamic>{
        'Id': _eventIdSoldHouse,
        'Name': 'Sold house',
        'Category': categoryIdForProperties.uniqueId,
        'Begin': '2020-03-01',
        'End': '2020-03-05',
        'Memo': 'My trip to Vegas',
      },
      <String, dynamic>{
        'Id': _eventIdVegas,
        'Name': 'Vegas',
        'Category': categoryIdForTravels.uniqueId,
        'Begin': '2020-07-01',
        'End': '2020-07-05',
        'People': 'Bob, John, Paul, Ringo',
        'Memo': 'My trip to Vegas with buddies',
      },
    ]);
  }

  /// Generates sample investments.
  void _generateInvestments() {
    _generateStocks();

    // Trade Apple 'AAPL'
    {
      // Buy
      _addInvestment(
        _accountForInvestments,
        '2010-06-20',
        idStockApple,
        InvestmentType.buy,
        _appleTradeQuantity,
        _appleBuyPriceFirst,
      );
      // Sell
      _addInvestment(
        _accountForInvestments,
        '2000-07-21',
        idStockApple,
        InvestmentType.sell,
        _appleTradeQuantity,
        _appleSellPrice,
      );

      // add Dividends
      _addInvestment(
        _accountForInvestments,
        '2012-01-01',
        idStockApple,
        InvestmentType.dividend,
        _appleDividendQuantity,
        _appleDividendPrice,
      );

      // Buy
      _addInvestment(
        _accountForInvestments,
        '2020-08-22',
        idStockApple,
        InvestmentType.buy,
        _appleTradeQuantity,
        _appleBuyPriceSecond,
      );
    }
    // Trade Ford 'F'
    {
      // Buy
      _addInvestment(
        _accountForInvestments,
        '2012-07-26',
        idStockFord,
        InvestmentType.buy,
        _fordTradeQuantity,
        _fordBuyPrice,
      );

      // Sell
      _addInvestment(
        _accountForInvestments,
        '2013-01-15',
        idStockFord,
        InvestmentType.sell,
        _fordTradeQuantity,
        _fordSellPrice,
      );
    }
  }

  /// Generates sample loan payments.
  void _generateLoans() {
    double loanAmount = _loanInitialAmount; // 20K
    final double loanRate = _loanRatePercent / _inflationPercentDivisor; // 4%
    double monthlyPayment = _loanMonthlyPayment;

    //
    // First lend the initial loan of 20K
    //
    _createTransferTransaction(
      accountSource: _accountBankCanada,
      accountDestination: _accountStartupLoan,
      date: getDateShiftedByYears(_loanStartYearsBack, _loanStartMonth, _loanStartDay),
      categoryId: _accountStartupLoan.fieldCategoryIdForPrincipal.value,
      amount: -loanAmount,
      memo: 'Invest in project goto Mars',
    );

    final List<DateTime> dates = generateListOfDates(
      yearInThePast: _loanScheduleYearsBack,
      howManyPerYear: _monthsPerYear,
      dayOfTheMonth: _loanPaymentDay,
    );

    for (final DateTime date in dates) {
      if (loanAmount < _zeroAmount) {
        break; // done paying back the loan
      }

      final double annuallyInterest = loanAmount * loanRate;
      double monthlyInterest = annuallyInterest / _monthsPerYear;
      double principalForThisMonday = monthlyPayment - monthlyInterest;
      if (isConsideredZero(monthlyInterest)) {
        monthlyInterest = _zeroAmount;
        principalForThisMonday = loanAmount;
        monthlyPayment = principalForThisMonday;
        loanAmount = _zeroAmount;
      }

      // reduce the remaining balance
      loanAmount -= principalForThisMonday;

      Data().loanPayments.appendNewMoneyObject(
        LoanPayment(
          id: _unsetId,
          accountId: _accountStartupLoan.uniqueId,
          date: date,
          principal: -principalForThisMonday,
          interest: monthlyInterest,
          memo: '',
          data: Data(),
        ),
      );

      // Show the payment to the lender
      _addTransactionAccountDatePayeeCategory(
        account: _accountBankCanada,
        date: date,
        payeeId: Data().payees.getOrCreate('MarsProject').uniqueId,
        amount: monthlyPayment,
        memo: 'Pay back investment',
      );
    }
  }

  /// Generates sample online accounts.
  void _generateOnlineAccounts() {
    // Pretend to load
    Data().onlineAccounts.loadFromJson(<MyJson>[
      <String, dynamic>{'Id': _onlineAccountIdFirst, 'Name': 'test1'},
      <String, dynamic>{'Id': _onlineAccountIdSecond, 'Name': 'test2'},
    ]);

    // Also add a new one
    Data().onlineAccounts.appendNewMoneyObject(
      OnlineAccount.fromJson(<String, dynamic>{'Name': 'test3'}),
      fireNotification: false,
    );
  }

  /// Populates the payees collection with a fixed set of demo payees.
  void _generatePayees() {
    Data().payees.loadFromJson(<MyJson>[
      <String, dynamic>{'Id': _payeeIdBurgerKing, 'Name': 'Job At BurgerKing'},
      <String, dynamic>{'Id': _payeeIdNasa, 'Name': 'NASA'},
      <String, dynamic>{'Id': _payeeIdLotteryWin, 'Name': 'Lottery Win'},
      <String, dynamic>{'Id': _payeeIdBroker, 'Name': 'Broker'},
    ]);
  }

  /// Generates sample rental data.
  void _generateRentals() {
    Data().rentBuildings.loadFromJson(<MyJson>[
      <String, dynamic>{
        'Id': _rentBuildingId,
        'Name': 'AirBnB',
        'Address': 'One Washington DC',
        'CategoryForIncome': Data().categories.getOrCreate('RentalIncome', CategoryType.income).uniqueId,
        'CategoryForInterest': Data().categories.getOrCreate('RentalInterest', CategoryType.expense).uniqueId,
        'CategoryForTaxes': Data().categories.getOrCreate('RentalTaxes', CategoryType.expense).uniqueId,
        'CategoryForMaintenance': Data().categories.getOrCreate('RentalMaintenance', CategoryType.expense).uniqueId,
        'CategoryForManagement': Data().categories.getOrCreate('RentalManagement', CategoryType.expense).uniqueId,
      },
    ]);

    // Rent Units
    Data().rentUnits.loadFromJson(<MyJson>[
      <String, dynamic>{
        'Id': _rentUnitId,
        'Name': 'roomA',
        'Building': _rentUnitBuildingId,
        'Renter': 'Bob Smith',
        'Note': 'Renting for 1 year',
      },
      <String, dynamic>{
        'Id': _rentUnitAlternateId,
        'Name': 'roomB',
        'Building': _rentUnitBuildingId,
        'Renter': 'Sue Richard',
        'Note': 'Renting for 6 months',
      },
    ]);
  }

  /// Generates sample stock data.
  void _generateStocks() {
    Data().securities.appendMoneyObject(
      Security(
        id: idStockApple,
        name: 'Apple Inc',
        symbol: 'AAPL',
        price: _appleStockPrice,
        lastPrice: _appleStockLastPrice,
        cuspid: '',
        securityType: SecurityType.equity.index,
        taxable: _taxableFalse,
        priceDate: DateTime(_appleStockPriceYear, _appleStockPriceMonth, _appleStockPriceDay),
      ),
    );
    Data().securities.appendMoneyObject(
      Security(
        id: idStockFord,
        name: 'Ford',
        symbol: 'F',
        price: _fordStockPrice,
        lastPrice: _fordStockLastPrice,
        cuspid: '',
        securityType: SecurityType.equity.index,
        taxable: _taxableFalse,
        priceDate: DateTime(_fordStockPriceYear, _fordStockPriceMonth, _fordStockPriceDay),
      ),
    );

    Data().stockSplits.appendNewMoneyObject(
      StockSplit.fromJson(<String, dynamic>{
        'Date': '2005-05-05',
        'Security': idStockApple, // AAPL
        'Numerator': _stockSplitNumerator,
        'Denominator': _stockSplitDenominator,
      }, Data()),
    );
  }

  /// 4 years of GYM and Netflix
  void _generateSubscriptionsOnCheckingAccount() {
    final DateTime startDate = _today.subtract(
      Duration(days: (_averageDaysPerYear * _numberOFYearInThePast).toInt()),
    );

    // Electricity
    generateTransactionsMonthlyExpenses(
      account: _accountBankUSA,
      payeeName: 'ElectricCity',
      category: _categoryBillsElectricity,
      amount: -getAmount(_electricityMin, _electricityMax), //
      yearMin: startDate.year,
      yearMax: _today.year,
      dayOfTheMonth: _subscriptionElectricityDay,
    );

    // Phone
    generateTransactionsMonthlyExpenses(
      account: _accountBankUSA,
      payeeName: 'TMobile',
      category: _categoryBillsPhone,
      amount: -getAmount(_phoneMin, _phoneMax), //
      yearMin: startDate.year,
      yearMax: _today.year,
      dayOfTheMonth: _subscriptionPhoneDay,
    );

    // Internet
    generateTransactionsMonthlyExpenses(
      account: _accountBankUSA,
      payeeName: 'FastISP',
      category: _categoryBillsInternet,
      amount: _internetAmount,
      yearMin: startDate.year,
      yearMax: _today.year,
      dayOfTheMonth: _subscriptionInternetDay,
    );

    // TV
    generateTransactionsMonthlyExpenses(
      account: _accountBankUSA,
      payeeName: 'Comcast',
      category: _categoryBillsTV,
      amount: _tvAmount,
      yearMin: startDate.year,
      yearMax: _today.year,
      dayOfTheMonth: _subscriptionTvDay,
    );
  }

  /// 4 years of GYM and Netflix
  void _generateSubscriptionsOnCreditCard() {
    final DateTime dateForGym = _today.subtract(
      const Duration(days: _daysPerYear * _gymYearsBack),
    );
    generateTransactionsMonthlyExpenses(
      account: _accountCreditCardUSD,
      payeeName: 'Gold Gym',
      category: _categorySubscriptionsGym,
      amount: _gymAmount,
      yearMin: dateForGym.year,
      yearMax: dateForGym.add(const Duration(days: _daysPerYear * _gymDurationYears)).year,
      dayOfTheMonth: _subscriptionGymDay,
    );

    // 5 years of netflix
    final DateTime dateForNetflix = _today.subtract(
      const Duration(days: _daysPerYear * _netflixYearsBack),
    );
    generateTransactionsMonthlyExpenses(
      account: _accountCreditCardUSD,
      payeeName: 'Netflix',
      category: _categorySubscriptionsStreaming,
      amount: _netflixAmount,
      yearMin: dateForNetflix.year,
      yearMax: _today.year,
      dayOfTheMonth: _subscriptionNetflixDay,
    );
  }

  // Create 2 random TransactionsExtra entries, mainly for code coverage.
  void _generateTransactionExtra() {
    Data().transactionExtras.loadFromJson(<MyJson>[
      <String, dynamic>{
        'Id': '0',
        'TaxDate': DateTime(
          _transactionExtraYearFirst,
          _transactionExtraMonth,
          _transactionExtraDay,
        ),
        'TaxYear': _transactionExtraYearFirst,
        'Transaction': _transactionExtraIdFirst,
      },
      <String, dynamic>{
        'Id': '1',
        'TaxDate': DateTime(
          _transactionExtraYearSecond,
          _transactionExtraMonth,
          _transactionExtraDay,
        ),
        'TaxYear': _transactionExtraYearSecond,
        'Transaction': _transactionExtraIdSecond,
      },
    ]);
  }

  /// Generates credit card transactions for the past 20 years.
  void _generateTransactionsForCreditCard() {
    final List<DateTime> dates = generateListOfDatesRandom(
      year: _numberOFYearInThePast,
      howManyPerMonths: _creditCardTransactionsPerMonth,
    );

    for (final DateTime date in dates) {
      final List<Object> selectedCategory = <List<Object>>[
        <Object>[
          _categorySubscriptionTransport,
          <List<Object>>[
            <Object>['City Bus', _transportCityBusMax],
            <Object>['Taxi', _transportTaxiMax],
            <Object>['Uber', _transportUberMax],
          ],
        ],
        <Object>[
          _categoryFoodGrocery,
          <List<Object>>[
            <Object>['TheFoodStore', _groceryStoreMax],
            <Object>['SafeWay', _grocerySafewayMax],
            <Object>['WholeFood', _groceryWholeFoodMax],
          ],
        ],
        <Object>[
          _categoryFoodRestaurant,
          <List<Object>>[
            <Object>['Starbucks', _restaurantStarbucksMax],
            <Object>['AppleBees', _restaurantAppleBeesMax],
            <Object>['PizzaHut', _restaurantPizzaHutMax],
          ],
        ],
      ].getRandomItem();

      final Category category = selectedCategory[_listIndexFirst] as Category;

      final dynamic payeeAndMaxAmount = (selectedCategory[_listIndexSecond] as List<Object>).getRandomItem();
      double maxSpendingOnCreditCard = (payeeAndMaxAmount[_listIndexSecond] as num).toDouble();

      final Transaction source = _addTransactionAccountDatePayeeCategory(
        account: _accountCreditCardUSD,
        date: date,
        payeeId: Data().payees.getOrCreate(payeeAndMaxAmount[_listIndexFirst] as String).uniqueId,
        categoryId: category.uniqueId,
      );
      if (date.isAfter(_dateOfFirstBigJob)) {
        // big job and spends more
        maxSpendingOnCreditCard = maxSpendingOnCreditCard * _spendMultiplierAfterPromotion;
      }
      source.fieldAmount.setAmount(
        -getRandomAmount(maxSpendingOnCreditCard.toInt()),
      );
    }
  }

  /// Generates salary and bonus transactions across multiple years with a mid-point job change.
  void _generateTransactionsSalary() {
    final List<DateTime> dates = generateListOfDates(
      yearInThePast: _numberOFYearInThePast,
      howManyPerYear: _monthsPerYear,
      dayOfTheMonth: _salaryPaymentDay,
    );
    _dateOfFirstBigJob = dates[dates.length ~/ _midpointDivisor];

    double yearlySalary = _startingYearlySalaryFirstJob;
    final double increaseRatePerYear = _yearlyInflation / _inflationPercentDivisor;

    int iterationYear = _unsetId;

    final Payee employer1 = Data().payees.get(_payeeIdBurgerKing)!;
    final Payee employer2 = Data().payees.get(_payeeIdNasa)!;

    bool switchedJob = false;

    for (final DateTime date in dates) {
      if (iterationYear == _unsetId) {
        iterationYear = date.year;
      } else {
        if (iterationYear != date.year) {
          // Increase yearly salary
          iterationYear = date.year;
          yearlySalary += yearlySalary * increaseRatePerYear;
        }
      }

      if (date.isBefore(_dateOfFirstBigJob)) {
        // Add Paycheck for BurgerKing
        _addTransactionAccountDatePayeeCategory(
          account: _accountBankUSA,
          date: date,
          payeeId: employer1.uniqueId,
          categoryId: _categorySalaryPaycheck.uniqueId,
          amount: yearlySalary / _monthsPerYear,
        );
      } else {
        if (switchedJob == false) {
          switchedJob = true;
          yearlySalary = _startingYearlySalarySecondJob;
          // one time signing bonus
          _addTransactionAccountDatePayeeCategory(
            account: _accountBankUSA,
            date: date,
            payeeId: employer2.uniqueId,
            categoryId: _categorySalaryBonus.uniqueId,
            amount: _signOnBonusAmount,
            memo: 'Sign-On Bonus',
          );
        }
        // Add Paycheck for NASA
        _addTransactionAccountDatePayeeCategory(
          account: _accountBankUSA,
          date: date,
          payeeId: employer2.uniqueId,
          categoryId: _categorySalaryPaycheck.uniqueId,
          amount: yearlySalary / _monthsPerYear,
        );

        // special holiday bonus to all employees
        if (date.month == _holidayBonusMonth) {
          _addTransactionAccountDatePayeeCategory(
            account: _accountBankUSA,
            date: date.add(const Duration(days: _holidayBonusDayOffset)),
            payeeId: employer2.uniqueId,
            categoryId: _categorySalaryBonus.uniqueId,
            amount: _holidayBonusAmount,
            memo: 'Holiday Bonus',
          );
        }
      }
    }
  }

  // Transfer 100 USD  Bank to CreditCard Account
  void _generateTransfersToCreditCardPayment() {
    double rollingBalance = _zeroAmount;

    final List<Transaction> list = Data().accounts.getTransactions(_accountCreditCardUSD).toList();

    list.sort(
      (Transaction a, Transaction b) => sortByDate(a.fieldDateTime.value, b.fieldDateTime.value, true),
    );
    int lastMonth = list.first.fieldDateTime.value!.month;

    for (final Transaction t in list) {
      if (t.fieldDateTime.value!.month != lastMonth && rollingBalance != _zeroAmount) {
        _createTransferTransaction(
          accountSource: _accountBankUSA,
          accountDestination: _accountCreditCardUSD,
          date: getLastDayOfPreviousMonth(t.fieldDateTime.value!),
          amount: rollingBalance,
          memo: 'PAY CREDIT CARD',
        );
        rollingBalance = _zeroAmount;
        lastMonth = t.fieldDateTime.value!.month;
      }
      rollingBalance += t.fieldAmount.value.asDouble();
    }
  }

  /// The demo data tries to demonstrate a person that had a rent for the first part of their journey and a house on the second half
  void _generateTransfersToRentAndHomeLoan() {
    final Payee payeeLandLord = Data().payees.getOrCreate('TheLandlord');
    final Payee payeeForHomeLoan = Data().payees.getOrCreate('HomeLoanBank');
    // Iterate over the last 'n' years of loan paid each month
    final List<DateTime> dates = generateListOfDates(
      yearInThePast: _numberOFYearInThePast,
      howManyPerYear: _monthsPerYear,
      dayOfTheMonth: _rentAndHomePaymentDay,
    );
    final DateTime midPointInTime = dates[dates.length ~/ _midpointDivisor];

    bool boughtHome = false;
    int numberOfRentPayment = _zeroInt;
    int numberOfMortgagePayment = _zeroInt;

    for (final DateTime date in dates) {
      if (date.isBefore(midPointInTime)) {
        _addTransactionAccountDatePayeeCategory(
          account: _accountBankUSA,
          date: date,
          payeeId: payeeLandLord.uniqueId,
          categoryId: Data().categories.getOrCreate('Bills:Rent', CategoryType.expense).uniqueId,
          amount: _monthlyRent,
          memo: 'Pay Rent #${++numberOfRentPayment}',
        );
      } else {
        if (boughtHome == false) {
          boughtHome = true;
          _buyHome(payeeForHomeLoan, date.add(const Duration(days: _buyHomeDelayDays)));
        }

        final Transaction transaction = _addTransactionAccountDatePayeeCategory(
          account: _accountBankUSA,
          date: date,
          payeeId: payeeForHomeLoan.uniqueId,
          categoryId: Data().categories.split.uniqueId,
          amount: _monthlyHomeLoan,
          memo: 'Mortgage Payment #${++numberOfMortgagePayment}',
        );

        final TransactionSplit splitMortgagePaymentPrincipal = TransactionSplit(
          id: _unsetId,
          amount: _monthlyHomeLoan - _mortgageSplitPrincipalOffset,
          transactionId: transaction.uniqueId,
          categoryId: _categoryHomeLoanMortgagePrincipal.uniqueId,
          payeeId: payeeForHomeLoan.uniqueId,
          transferId: _unsetId,
          memo: '',
          flags: _defaultFlags,
          budgetBalanceDate: null,
          data: Data(),
        );
        Data().splits.appendNewMoneyObject(splitMortgagePaymentPrincipal);

        final TransactionSplit splitMortgagePaymentInterest = TransactionSplit(
          id: _unsetId,
          amount: _mortgageSplitPrincipalOffset,
          transactionId: transaction.uniqueId,
          categoryId: _categoryHomeLoanMortgageInterest.uniqueId,
          payeeId: payeeForHomeLoan.uniqueId,
          transferId: _unsetId,
          memo: '',
          flags: _defaultFlags,
          budgetBalanceDate: null,
          data: Data(),
        );
        Data().splits.appendNewMoneyObject(splitMortgagePaymentInterest);
      }
    }
  }
}
