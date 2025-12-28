import 'dart:math';
import 'package:money/core/helpers/date_helper.dart';
import 'package:money/core/helpers/list_helper.dart';
import 'package:money/core/helpers/string_helper.dart';
import 'package:money/data/models/money_objects/account_aliases/account_alias.dart';
import 'package:money/data/models/money_objects/accounts/account.dart';
import 'package:money/data/models/money_objects/accounts/account_types_enum.dart';
import 'package:money/data/models/money_objects/aliases/alias.dart';
import 'package:money/data/models/money_objects/categories/category.dart';
import 'package:money/data/models/money_objects/currencies/currency.dart';
import 'package:money/data/models/money_objects/investments/investment.dart';
import 'package:money/data/models/money_objects/investments/investment_types.dart';
import 'package:money/data/models/money_objects/investments/picker_investment_trade_type.dart';
import 'package:money/data/models/money_objects/loan_payments/loan_payment.dart';
import 'package:money/data/models/money_objects/online_accounts/online_account.dart';
import 'package:money/data/models/money_objects/payees/payee.dart';
import 'package:money/data/models/money_objects/securities/security.dart';
import 'package:money/data/models/money_objects/splits/money_split.dart';
import 'package:money/data/models/money_objects/stock_splits/stock_split.dart';
import 'package:money/data/models/money_objects/transactions/transaction.dart';
import 'package:money/data/models/money_objects/transfers/transfer.dart';
import 'package:money/data/storage/data/data.dart';

/// Generates sample data for the MoneyFlutter app.
class DataSimulator {
  int idStockApple = 0;
  int idStockFord = 1;

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
  final double _monthlyHomeLoan = -2000;
  final double _monthlyRent = -600;
  final int _numberOFYearInThePast = 20;
  final double _startingYearlySalaryFirstJob = 15000.00;
  final double _startingYearlySalarySecondJob = 50000.00;
  final DateTime _today = DateTime.now();
  final double _yearlyInflation = 3.00;

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

  List<DateTime> generateListOfDates({
    required int yearInThePast,
    DateTime? stopDate,
    required int howManyPerYear,
    required int dayOfTheMonth,
  }) {
    final List<DateTime> dates = <DateTime>[];

    final DateTime whenToStop = stopDate ?? DateTime.now();
    for (int i = yearInThePast * howManyPerYear; i >= 0; i--) {
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

  List<DateTime> generateListOfDatesRandom({
    required int year,
    required int howManyPerMonths,
  }) {
    final List<DateTime> dates = <DateTime>[];

    final DateTime today = DateTime.now();
    for (int i = year * 12; i >= 0; i--) {
      // Subtract the current month index from today's date
      DateTime date = DateTime(today.year, today.month - i, 1);
      // Now we have a Year and Month
      // generate on random date of the month
      for (int event = 0; event < howManyPerMonths; event++) {
        final int day = Random().nextInt(31);
        date = date.add(Duration(days: day));
        dates.add(date);
      }
    }
    return dates;
  }

  // ignore: unused_element
  List<DateTime> generateRandomDates(int count) {
    final DateTime tenYearsAgo = _today.subtract(
      Duration(days: 365 * _numberOFYearInThePast),
    ); // Adjust for leap years if needed

    final Random random = Random();
    final List<DateTime> dates = List<DateTime>.generate(count, (int index) {
      final int randomDaysSinceTenYearsAgo = random.nextInt(
        365 * _numberOFYearInThePast,
      );
      return tenYearsAgo.add(Duration(days: randomDaysSinceTenYearsAgo));
    });
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
      for (int month = 1; month <= 12; month++) {
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
    return roundDouble(amount, 2);
  }

  DateTime getDateShiftedByYears(int yearsToShift, int month, int day) {
    final int yearShifted = getShiftedYearFromNow(yearsToShift);
    return DateTime(yearShifted, month, day);
  }

  /// Returns the last day of the previous month for a given date.
  DateTime getLastDayOfPreviousMonth(DateTime date) {
    final DateTime previousMonth = DateTime(date.year, date.month - 1);
    final int daysInPreviousMonth = DateTime(previousMonth.year, previousMonth.month + 1, 0).day;
    return DateTime(
      previousMonth.year,
      previousMonth.month,
      daysInPreviousMonth,
    ).endOfDay;
  }

  double getRandomAmount(final int maxValue) {
    final double amount = Random().nextDouble() * maxValue;
    return roundDouble(amount, 2);
  }

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
      transactionAmount *= -1;
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
    if (id == -1) {
      Data().accounts.appendNewMoneyObject(account, fireNotification: false);
    } else {
      Data().accounts.appendMoneyObject(account);
    }

    return account;
  }

  Transaction _addTransactionAccountDatePayeeCategory({
    required Account account,
    required DateTime date,
    int payeeId = -1,
    int categoryId = -1,
    double amount = 0.00,
    String memo = '',
  }) {
    // generate an amount
    // Expenses should be a negative value and smaller range than Revenue;
    int maxValue = 2500;
    if (Data().categories.isCategoryAnExpense(categoryId)) {
      maxValue = -500;
    }

    if (amount == 0) {
      amount = getRandomAmount(maxValue);
    }

    final MyJson demoJson = <String, dynamic>{
      'Id': -1,
      'Account': account.fieldId.value,
      'Date': date,
      'Payee': payeeId,
      'Category': categoryId,
      'Amount': amount,
      'Memo': memo,
    };

    final Transaction t = Transaction.fromJSon(demoJson, 0);

    Data().transactions.appendNewMoneyObject(t, fireNotification: false);
    return t;
  }

  /// Buys a home and adds related transactions.
  void _buyHome(final Payee payeeForHomeLoan, final DateTime date) {
    final Account accountAssetHome = _addNewAccount(
      -1,
      'Main Home',
      'A0001',
      AccountType.asset.index,
      'USD',
    );

    _addTransactionAccountDatePayeeCategory(
      account: accountAssetHome,
      date: date,
      amount: 250000,
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
      amount: -30000,
      memo: 'Down payment',
    );
  }

  Transaction _createTransferTransaction({
    required final Account accountSource,
    required final Account accountDestination,
    required final DateTime date,
    required final double amount,
    required final String memo,
    int categoryId = -1,
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
        'Flag': 0,
        'AccountId': 'A12345',
      }),
      fireNotification: false,
    );
    Data().accountAliases.appendNewMoneyObject(
      AccountAlias.fromJson(<String, dynamic>{
        'Pattern': '*bar*',
        'Flag': 0,
        'AccountId': 'B987654',
      }),
      fireNotification: false,
    );
  }

  /// Generates sample accounts.
  void _generateAccounts() {
    _accountBankUSA = _addNewAccount(
      -1,
      'Bank Of America',
      'B0001',
      AccountType.checking.index,
      'USD',
    );

    // Canadian Bank Account
    _accountBankCanada = _addNewAccount(
      -1,
      'Bank Of Montreal',
      'B0002',
      AccountType.savings.index,
      'CAD',
    );

    // Fund that account
    _addTransactionAccountDatePayeeCategory(
      account: _accountBankCanada,
      date: getDateShiftedByYears(-21, 1, 1),
      amount: 100000,
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
      -1,
      'VisaCard',
      '0002',
      AccountType.credit.index,
      'USD',
    );

    _accountForInvestments = _addNewAccount(
      -1,
      'Fidelity',
      '0003',
      AccountType.investment.index,
      'USD',
    );
    _accountStartupLoan = _addNewAccount(
      -1,
      'Startup',
      '0004',
      AccountType.loan.index,
      'CAD',
    );

    /// Setup categories for this loans
    Data().categories.appendNewMoneyObject(
      Category(
        id: -1,
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
      Alias(id: -1, payeeId: 2, pattern: 'ABC', flags: AliasType.none.index),
      fireNotification: false,
    );
    Data().aliases.appendNewMoneyObject(
      Alias(id: -1, payeeId: 2, pattern: 'abc', flags: AliasType.none.index),
      fireNotification: false,
    );
    Data().aliases.appendNewMoneyObject(
      Alias(
        id: -1,
        payeeId: 3,
        pattern: '.*starbucks.*',
        flags: AliasType.regex.index,
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
    Data().categories.investmentLongTermCapitalGainsDistribution;
    Data().categories.investmentMiscellaneous;
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
      _categoryBills.fieldBudget.value.setAmount(100.00);
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
      _categorySalaryPaycheck.fieldBudget.value.setAmount(900);

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
        'Id': -1,
        'Name': 'USA',
        'Symbol': 'USD',
        'CultureCode': 'en-US',
        'Ratio': 1.09,
        'LastRatio': 1.12,
      },
      <String, dynamic>{
        'Id': -1,
        'Name': 'Canada',
        'Symbol': 'CAD',
        'CultureCode': 'en-CA',
        'Ratio': 0.75,
        'LastRatio': 0.85,
      },
      <String, dynamic>{
        'Id': -1,
        'Name': 'Euro',
        'Symbol': 'EUR',
        'CultureCode': 'en-ES',
        'Ratio': 1.15,
        'LastRatio': 1.11,
      },
      <String, dynamic>{
        'Id': -1,
        'Name': 'UK',
        'Symbol': 'GBP',
        'CultureCode': 'en-GB',
        'Ratio': 1.25,
        'LastRatio': 1.21,
      },
      <String, dynamic>{
        'Id': -1,
        'Name': 'Japan',
        'Symbol': 'JPY',
        'CultureCode': 'en-JP',
        'Ratio': 1 / 147.72,
        'LastRatio': 0,
      },
    ];
    for (final MyJson demoCurrency in demoCurrencies) {
      Data().currencies.appendNewMoneyObject(Currency.fromJson(demoCurrency));
    }
  }

  void _generateEvents() {
    final Category categoryIdForProperties = Data().categories.getByName('Properties')!;

    final Category categoryIdForTravels = Data().categories.getByName('Travel')!;

    Data().events.loadFromJson(<MyJson>[
      <String, dynamic>{
        'Id': 0,
        'Name': 'Condo in Chicago',
        'Category': categoryIdForProperties.uniqueId,
        'Begin': '1987-03-04',
        'End': '1999-12-04',
        'Memo': 'My first property',
      },
      <String, dynamic>{
        'Id': 1,
        'Name': 'Wedding and honeymoon',
        'Category': categoryIdForTravels.uniqueId,
        'Begin': '1995-06-20',
        'End': '1995-06-30',
        'People': 'Karen; Bob; Yoko',
        'Memo': 'It was raining, see photos here http://example.com',
      },
      <String, dynamic>{
        'Id': 2,
        'Name': 'Home in Springfield',
        'Category': categoryIdForProperties.uniqueId,
        'Begin': '1997-01-04',
        'End': '2016-01-04',
        'Memo': 'Our first home',
      },
      <String, dynamic>{
        'Id': 3,
        'Name': 'Divorce',
        'Begin': '2020-01-01',
        'End': '2020-04-13',
        'People': 'Karen; Bob',
        'Memo': 'Our friendly divorce',
      },
      <String, dynamic>{
        'Id': 4,
        'Name': 'Sold house',
        'Category': categoryIdForProperties.uniqueId,
        'Begin': '2020-03-01',
        'End': '2020-03-05',
        'Memo': 'My trip to Vegas',
      },
      <String, dynamic>{
        'Id': 5,
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
        100,
        199.99,
      );
      // Sell
      _addInvestment(
        _accountForInvestments,
        '2000-07-21',
        idStockApple,
        InvestmentType.sell,
        100,
        300.00,
      );

      // add Dividends
      _addInvestment(
        _accountForInvestments,
        '2012-01-01',
        idStockApple,
        InvestmentType.dividend,
        1,
        5000.00,
      );

      // Buy
      _addInvestment(
        _accountForInvestments,
        '2020-08-22',
        idStockApple,
        InvestmentType.buy,
        100,
        400.00,
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
        1000,
        8.86,
      );

      // Sell
      _addInvestment(
        _accountForInvestments,
        '2013-01-15',
        idStockFord,
        InvestmentType.sell,
        1000,
        14.14,
      );
    }
  }

  /// Generates sample loan payments.
  void _generateLoans() {
    double loanAmount = 20000; // 20K
    final double loanRate = 4 / 100; // 4%
    double monthlyPayment = 500;

    //
    // First lend the initial loan of 20K
    //
    _createTransferTransaction(
      accountSource: _accountBankCanada,
      accountDestination: _accountStartupLoan,
      date: getDateShiftedByYears(-6, 11, 11),
      categoryId: _accountStartupLoan.fieldCategoryIdForPrincipal.value,
      amount: -loanAmount,
      memo: 'Invest in project goto Mars',
    );

    final List<DateTime> dates = generateListOfDates(
      yearInThePast: 5,
      howManyPerYear: 12,
      dayOfTheMonth: 9,
    );

    for (final DateTime date in dates) {
      if (loanAmount < 0) {
        break; // done paying back the loan
      }

      final double annuallyInterest = loanAmount * loanRate;
      double monthlyInterest = annuallyInterest / 12;
      double principalForThisMonday = monthlyPayment - monthlyInterest;
      if (isConsideredZero(monthlyInterest)) {
        monthlyInterest = 0;
        principalForThisMonday = loanAmount;
        monthlyPayment = principalForThisMonday;
        loanAmount = 0;
      }

      // reduce the remaining balance
      loanAmount -= principalForThisMonday;

      Data().loanPayments.appendNewMoneyObject(
        LoanPayment(
          id: -1,
          accountId: _accountStartupLoan.uniqueId,
          date: date,
          principal: -principalForThisMonday,
          interest: monthlyInterest,
          memo: '',
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
      <String, dynamic>{'Id': 0, 'Name': 'test1'},
      <String, dynamic>{'Id': 1, 'Name': 'test2'},
    ]);

    // Also add a new one
    Data().onlineAccounts.appendNewMoneyObject(
      OnlineAccount.fromJson(<String, dynamic>{'Name': 'test3'}),
      fireNotification: false,
    );
  }

  void _generatePayees() {
    Data().payees.loadFromJson(<MyJson>[
      <String, dynamic>{'Id': 0, 'Name': 'Job At BurgerKing'},
      <String, dynamic>{'Id': 1, 'Name': 'NASA'},
      <String, dynamic>{'Id': 2, 'Name': 'Lottery Win'},
      <String, dynamic>{'Id': 3, 'Name': 'Broker'},
    ]);
  }

  /// Generates sample rental data.
  void _generateRentals() {
    Data().rentBuildings.loadFromJson(<MyJson>[
      <String, dynamic>{
        'Id': 0,
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
        'Id': 0,
        'Name': 'roomA',
        'Building': 0,
        'Renter': 'Bob Smith',
        'Note': 'Renting for 1 year',
      },
      <String, dynamic>{
        'Id': 0,
        'Name': 'roomB',
        'Building': 0,
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
        price: 200.0,
        lastPrice: 201.0,
        cuspid: '',
        securityType: SecurityType.equity.index,
        taxable: 0,
        priceDate: DateTime(2015, 1, 1),
      ),
    );
    Data().securities.appendMoneyObject(
      Security(
        id: idStockFord,
        name: 'Ford',
        symbol: 'F',
        price: 7.0,
        lastPrice: 7.10,
        cuspid: '',
        securityType: SecurityType.equity.index,
        taxable: 0,
        priceDate: DateTime(2020, 1, 1),
      ),
    );

    Data().stockSplits.appendNewMoneyObject(
      StockSplit.fromJson(<String, dynamic>{
        'Date': '2005-05-05',
        'Security': idStockApple, // AAPL
        'Numerator': 2,
        'Denominator': 1,
      }),
    );
  }

  /// 4 years of GYM and Netflix
  void _generateSubscriptionsOnCheckingAccount() {
    final DateTime startDate = _today.subtract(
      Duration(days: (365.25 * _numberOFYearInThePast).toInt()),
    );

    // Electricity
    generateTransactionsMonthlyExpenses(
      account: _accountBankUSA,
      payeeName: 'ElectricCity',
      category: _categoryBillsElectricity,
      amount: -getAmount(40, 100), //
      yearMin: startDate.year,
      yearMax: _today.year,
      dayOfTheMonth: 11,
    );

    // Phone
    generateTransactionsMonthlyExpenses(
      account: _accountBankUSA,
      payeeName: 'TMobile',
      category: _categoryBillsPhone,
      amount: -getAmount(40, 55), //
      yearMin: startDate.year,
      yearMax: _today.year,
      dayOfTheMonth: 12,
    );

    // Internet
    generateTransactionsMonthlyExpenses(
      account: _accountBankUSA,
      payeeName: 'FastISP',
      category: _categoryBillsInternet,
      amount: -40,
      yearMin: startDate.year,
      yearMax: _today.year,
      dayOfTheMonth: 13,
    );

    // TV
    generateTransactionsMonthlyExpenses(
      account: _accountBankUSA,
      payeeName: 'Comcast',
      category: _categoryBillsTV,
      amount: -80,
      yearMin: startDate.year,
      yearMax: _today.year,
      dayOfTheMonth: 13,
    );
  }

  /// 4 years of GYM and Netflix
  void _generateSubscriptionsOnCreditCard() {
    final DateTime dateForGym = _today.subtract(const Duration(days: 365 * 8));
    generateTransactionsMonthlyExpenses(
      account: _accountCreditCardUSD,
      payeeName: 'Gold Gym',
      category: _categorySubscriptionsGym,
      amount: -50,
      yearMin: dateForGym.year,
      yearMax: dateForGym.add(const Duration(days: 365 * 4)).year,
      dayOfTheMonth: 23,
    );

    // 5 years of netflix
    final DateTime dateForNetflix = _today.subtract(
      const Duration(days: 365 * 5),
    );
    generateTransactionsMonthlyExpenses(
      account: _accountCreditCardUSD,
      payeeName: 'Netflix',
      category: _categorySubscriptionsStreaming,
      amount: -8.99,
      yearMin: dateForNetflix.year,
      yearMax: _today.year,
      dayOfTheMonth: 19,
    );
  }

  // Create 2 random TransactionsExtra entries, mainly for code coverage.
  void _generateTransactionExtra() {
    Data().transactionExtras.loadFromJson(<MyJson>[
      <String, dynamic>{
        'Id': '0',
        'TaxDate': DateTime(2010, 1, 1),
        'TaxYear': 2010,
        'Transaction': 0,
      },
      <String, dynamic>{
        'Id': '1',
        'TaxDate': DateTime(2020, 1, 1),
        'TaxYear': 2020,
        'Transaction': 1,
      },
    ]);
  }

  /// Generates credit card transactions for the past 20 years.
  void _generateTransactionsForCreditCard() {
    final List<DateTime> dates = generateListOfDatesRandom(
      year: _numberOFYearInThePast,
      howManyPerMonths: 4,
    );

    for (final DateTime date in dates) {
      final List<Object> selectedCategory = <List<Object>>[
        <Object>[
          _categorySubscriptionTransport,
          <List<Object>>[
            <Object>['City Bus', 3],
            <Object>['Taxi', 20],
            <Object>['Uber', 30],
          ],
        ],
        <Object>[
          _categoryFoodGrocery,
          <List<Object>>[
            <Object>['TheFoodStore', 50],
            <Object>['SafeWay', 80],
            <Object>['WholeFood', 200],
          ],
        ],
        <Object>[
          _categoryFoodRestaurant,
          <List<Object>>[
            <Object>['Starbucks', 10],
            <Object>['AppleBees', 100],
            <Object>['PizzaHut', 20],
          ],
        ],
      ].getRandomItem();

      final Category category = selectedCategory[0] as Category;

      final dynamic payeeAndMaxAmount = (selectedCategory[1] as List<Object>).getRandomItem();
      double maxSpendingOnCreditCard = (payeeAndMaxAmount[1] as num).toDouble();

      final Transaction source = _addTransactionAccountDatePayeeCategory(
        account: _accountCreditCardUSD,
        date: date,
        payeeId: Data().payees.getOrCreate(payeeAndMaxAmount[0] as String).uniqueId,
        categoryId: category.uniqueId,
      );
      if (date.isAfter(_dateOfFirstBigJob)) {
        // big job and spends more
        maxSpendingOnCreditCard = maxSpendingOnCreditCard * 3;
      }
      source.fieldAmount.setAmount(
        -getRandomAmount(maxSpendingOnCreditCard.toInt()),
      );
    }
  }

  void _generateTransactionsSalary() {
    final List<DateTime> dates = generateListOfDates(
      yearInThePast: _numberOFYearInThePast,
      howManyPerYear: 12,
      dayOfTheMonth: 5,
    );
    _dateOfFirstBigJob = dates[dates.length ~/ 2];

    double yearlySalary = _startingYearlySalaryFirstJob;
    final double increaseRatePerYear = _yearlyInflation / 100;

    int iterationYear = -1;

    final Payee employer1 = Data().payees.get(0)!;
    final Payee employer2 = Data().payees.get(1)!;

    bool switchedJob = false;

    for (final DateTime date in dates) {
      if (iterationYear == -1) {
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
          amount: yearlySalary / 12,
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
            amount: 22000,
            memo: 'Sign-On Bonus',
          );
        }
        // Add Paycheck for NASA
        _addTransactionAccountDatePayeeCategory(
          account: _accountBankUSA,
          date: date,
          payeeId: employer2.uniqueId,
          categoryId: _categorySalaryPaycheck.uniqueId,
          amount: yearlySalary / 12,
        );

        // special holiday bonus to all employees
        if (date.month == 12) {
          _addTransactionAccountDatePayeeCategory(
            account: _accountBankUSA,
            date: date.add(const Duration(days: 10)),
            payeeId: employer2.uniqueId,
            categoryId: _categorySalaryBonus.uniqueId,
            amount: 3500,
            memo: 'Holiday Bonus',
          );
        }
      }
    }
  }

  // Transfer 100 USD  Bank to CreditCard Account
  void _generateTransfersToCreditCardPayment() {
    double rollingBalance = 0.00;

    final List<Transaction> list = Data().accounts.getTransactions(_accountCreditCardUSD).toList();

    list.sort(
      (Transaction a, Transaction b) => sortByDate(a.fieldDateTime.value, b.fieldDateTime.value, true),
    );
    int lastMonth = list.first.fieldDateTime.value!.month;

    for (final Transaction t in list) {
      if (t.fieldDateTime.value!.month != lastMonth && rollingBalance != 0) {
        _createTransferTransaction(
          accountSource: _accountBankUSA,
          accountDestination: _accountCreditCardUSD,
          date: getLastDayOfPreviousMonth(t.fieldDateTime.value!),
          amount: rollingBalance,
          memo: 'PAY CREDIT CARD',
        );
        rollingBalance = 0;
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
      howManyPerYear: 12,
      dayOfTheMonth: 10,
    );
    final DateTime midPointInTime = dates[dates.length ~/ 2];

    bool boughtHome = false;
    int numberOfRentPayment = 0;
    int numberOfMortgagePayment = 0;

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
          _buyHome(payeeForHomeLoan, date.add(const Duration(days: 180)));
        }

        final Transaction transaction = _addTransactionAccountDatePayeeCategory(
          account: _accountBankUSA,
          date: date,
          payeeId: payeeForHomeLoan.uniqueId,
          categoryId: Data().categories.split.uniqueId,
          amount: _monthlyHomeLoan,
          memo: 'Mortgage Payment #${++numberOfMortgagePayment}',
        );

        final MoneySplit splitMortgagePaymentPrincipal = MoneySplit(
          id: -1,
          amount: _monthlyHomeLoan - 200,
          transactionId: transaction.uniqueId,
          categoryId: _categoryHomeLoanMortgagePrincipal.uniqueId,
          payeeId: payeeForHomeLoan.uniqueId,
          transferId: -1,
          memo: '',
          flags: 0,
          budgetBalanceDate: null,
        );
        Data().splits.appendNewMoneyObject(splitMortgagePaymentPrincipal);

        final MoneySplit splitMortgagePaymentInterest = MoneySplit(
          id: -1,
          amount: 200,
          transactionId: transaction.uniqueId,
          categoryId: _categoryHomeLoanMortgageInterest.uniqueId,
          payeeId: payeeForHomeLoan.uniqueId,
          transferId: -1,
          memo: '',
          flags: 0,
          budgetBalanceDate: null,
        );
        Data().splits.appendNewMoneyObject(splitMortgagePaymentInterest);
      }
    }
  }
}

// --- Demo Extension Methods ---

void loadFromDemoData() {
  DataSimulator().generateData();
  Data().recalculateBalances();
}
