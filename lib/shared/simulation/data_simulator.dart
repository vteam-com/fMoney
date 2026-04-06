import 'package:money/data/models/account_types_enum.dart';
import 'package:money/data/models/category_types.dart';
import 'package:money/data/models/data_simulator_constants.dart';
import 'package:money/data/models/investment_types.dart';
import 'package:money/helpers/data_simulator_utils.dart' as simulator_utils;
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/account_domain.dart';
import 'package:money/shared/domain/category_domain.dart';
import 'package:money/shared/domain/data_domain.dart';
import 'package:money/shared/domain/investment_domain.dart';
import 'package:money/shared/domain/payee_domain.dart';
import 'package:money/shared/domain/security_domain.dart';
import 'package:money/shared/domain/transaction_domain.dart';
import 'package:money/shared/simulation/data_simulator_accounts.dart';
import 'package:money/shared/simulation/data_simulator_categories.dart';
import 'package:money/shared/simulation/data_simulator_investments.dart';
import 'package:money/shared/simulation/data_simulator_reference_data.dart';
import 'package:money/shared/simulation/data_simulator_transactions.dart';

/// Generates sample data for the MoneyFlutter app.
class DataSimulator {
  int idStockApple = DataSimulatorConstants.stockAppleId;
  int idStockFord = DataSimulatorConstants.stockFordId;

  late final Account _accountBankCanada;
  late final Account _accountBankUSA;
  late final Account _accountCreditCardUSD;
  late final Account _accountForInvestments;
  late final Account _accountStartupLoan;
  late final Category _categoryBillsElectricity;
  late final Category _categoryBillsInternet;
  late final Category _categoryBillsPhone;
  late final Category _categoryBillsTV;
  late final Category _categoryFoodGrocery;
  late final Category _categoryFoodRestaurant;
  late final Category _categoryHomeLoanDownPayment;
  late final Category _categoryHomeLoanMortgageInterest;
  late final Category _categoryHomeLoanMortgagePrincipal;
  late final Category _categoryInvestmentTrades;
  late final Category _categorySalaryBonus;
  late final Category _categorySalaryPaycheck;
  late final Category _categorySubscriptionTransport;
  late final Category _categorySubscriptionsGym;
  late final Category _categorySubscriptionsStreaming;
  final double _monthlyHomeLoan = DataSimulatorConstants.monthlyHomeLoanAmount;
  final double _monthlyRent = DataSimulatorConstants.monthlyRentAmount;
  final int _numberOFYearInThePast = DataSimulatorConstants.yearsInPast;
  final double _startingYearlySalaryFirstJob = DataSimulatorConstants.startingYearlySalaryFirstJobAmount;
  final double _startingYearlySalarySecondJob = DataSimulatorConstants.startingYearlySalarySecondJobAmount;
  final DateTime _today = DateTime.now();
  final double _yearlyInflation = DataSimulatorConstants.yearlyInflationPercent;

  late DateTime _dateOfFirstBigJob;
  final DataSimulatorReferenceDataDomain _referenceDataDomain = DataSimulatorReferenceDataDomain();

  /// Returns the transaction-domain generator bound to current simulator state.
  DataSimulatorTransactionsDomain get _transactionsDomain => DataSimulatorTransactionsDomain(
    today: _today,
    numberOfYearInThePast: _numberOFYearInThePast,
    monthlyRent: _monthlyRent,
    monthlyHomeLoan: _monthlyHomeLoan,
    accountBankUSA: _accountBankUSA,
    accountCreditCardUSD: _accountCreditCardUSD,
    categoryBillsElectricity: _categoryBillsElectricity,
    categoryBillsPhone: _categoryBillsPhone,
    categoryBillsInternet: _categoryBillsInternet,
    categoryBillsTV: _categoryBillsTV,
    categorySubscriptionsGym: _categorySubscriptionsGym,
    categorySubscriptionsStreaming: _categorySubscriptionsStreaming,
    categorySubscriptionTransport: _categorySubscriptionTransport,
    categoryFoodGrocery: _categoryFoodGrocery,
    categoryFoodRestaurant: _categoryFoodRestaurant,
    categorySalaryPaycheck: _categorySalaryPaycheck,
    categorySalaryBonus: _categorySalaryBonus,
    categoryHomeLoanMortgagePrincipal: _categoryHomeLoanMortgagePrincipal,
    categoryHomeLoanMortgageInterest: _categoryHomeLoanMortgageInterest,
    startingYearlySalaryFirstJob: _startingYearlySalaryFirstJob,
    startingYearlySalarySecondJob: _startingYearlySalarySecondJob,
    yearlyInflation: _yearlyInflation,
  );

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
    return simulator_utils.generateListOfDates(
      yearInThePast: yearInThePast,
      stopDate: stopDate,
      howManyPerYear: howManyPerYear,
      dayOfTheMonth: dayOfTheMonth,
    );
  }

  /// Generates random list of dates for specified year and frequency.
  List<DateTime> generateListOfDatesRandom({
    required int year,
    required int howManyPerMonths,
  }) {
    return simulator_utils.generateListOfDatesRandom(
      year: year,
      howManyPerMonths: howManyPerMonths,
    );
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
    return simulator_utils.getAmount(minValue, maxValue);
  }

  /// Returns DateTime shifted by specified number of years.
  DateTime getDateShiftedByYears(int yearsToShift, int month, int day) {
    return simulator_utils.getDateShiftedByYears(yearsToShift, month, day);
  }

  /// Returns the last day of the previous month for a given date.
  DateTime getLastDayOfPreviousMonth(DateTime date) {
    return simulator_utils.getLastDayOfPreviousMonth(date).endOfDay;
  }

  /// Generates random amount up to specified maximum value.
  double getRandomAmount(final int maxValue) {
    return simulator_utils.getRandomAmount(maxValue);
  }

  /// Returns year shifted from today by specified number of years.
  int getShiftedYearFromNow(int numberOfYearFromToday) {
    return simulator_utils.getShiftedYearFromNow(numberOfYearFromToday);
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
      action = SharedSimulationStrings.simVerbBought;
      transactionAmount *= DataSimulatorConstants.negativeMultiplier;
    }
    final Payee payee = Data().payees.getOrCreate(SharedSimulationStrings.simPayeeBroker);

    final Transaction t = _addTransactionAccountDatePayeeCategory(
      account: account,
      date: date,
      amount: transactionAmount,
      payeeId: payee.uniqueId,
      categoryId: _categoryInvestmentTrades.uniqueId,
      memo:
          '${SharedSimulationStrings.simMemoYou}$action ${formatDoubleTrimZeros(quantity)}${SharedSimulationStrings.simMemoSharesOf}${stock!.fieldName.value}${SharedSimulationStrings.simMemoWithSymbolClose}${stock.fieldSymbol.value}${SharedSimulationStrings.simMemoEndQuote}',
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
    if (id == DataSimulatorConstants.unsetId) {
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
    int payeeId = DataSimulatorConstants.unsetId,
    int categoryId = DataSimulatorConstants.unsetId,
    double amount = DataSimulatorConstants.zeroAmount,
    String memo = '',
  }) {
    // generate an amount
    // Expenses should be a negative value and smaller range than Revenue;
    int maxValue = DataSimulatorConstants.maxRandomIncomeAmount;
    if (Data().categories.isCategoryAnExpense(categoryId)) {
      maxValue = DataSimulatorConstants.maxRandomExpenseAmount;
    }

    if (amount == DataSimulatorConstants.zeroAmount) {
      amount = getRandomAmount(maxValue);
    }

    final MyJson demoJson = <String, dynamic>{
      'Id': DataSimulatorConstants.unsetId,
      'Account': account.fieldId.value,
      'Date': date,
      'Payee': payeeId,
      'Category': categoryId,
      'Amount': amount,
      'Memo': memo,
    };

    final Transaction t = Transaction.fromJSon(demoJson, DataSimulatorConstants.initialRunningBalance);

    Data().transactions.appendNewMoneyObject(t, fireNotification: false);
    return t;
  }

  /// Buys a home and adds related transactions.
  void _buyHome(final Payee payeeForHomeLoan, final DateTime date) {
    final Account accountAssetHome = _addNewAccount(
      DataSimulatorConstants.unsetId,
      SharedSimulationStrings.simAccountMainHome,
      'A0001',
      AccountType.asset.index,
      SharedStrings.currencyUsd,
    );

    _addTransactionAccountDatePayeeCategory(
      account: accountAssetHome,
      date: date,
      amount: DataSimulatorConstants.homePurchaseValue,
      categoryId: Data().categories
          .addNewCategory(
            name: 'Investment:PropertyValue',
            type: CategoryType.investment,
          )
          .uniqueId,
      memo: SharedSimulationStrings.simMemoHomePurchase,
    );

    _addTransactionAccountDatePayeeCategory(
      account: _accountBankUSA,
      date: date,
      payeeId: payeeForHomeLoan.uniqueId,
      categoryId: _categoryHomeLoanDownPayment.uniqueId,
      amount: DataSimulatorConstants.homeDownPaymentAmount,
      memo: SharedSimulationStrings.simMemoDownPayment,
    );
  }

  /// Creates a transfer between two accounts by creating a source transaction and linking the related transaction.
  Transaction _createTransferTransaction({
    required final Account accountSource,
    required final Account accountDestination,
    required final DateTime date,
    required final double amount,
    required final String memo,
    int categoryId = DataSimulatorConstants.unsetId,
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
    _referenceDataDomain.generateAccountAliases();
  }

  /// Generates sample accounts.
  void _generateAccounts() {
    final DataSimulatorAccountsBundle bundle = generateSimulatorAccounts(
      addNewAccount: _addNewAccount,
      addTransaction: _addTransactionAccountDatePayeeCategory,
      getDateShiftedByYears: getDateShiftedByYears,
    );
    _accountBankUSA = bundle.bankUsa;
    _accountBankCanada = bundle.bankCanada;
    _accountCreditCardUSD = bundle.creditCardUsd;
    _accountForInvestments = bundle.forInvestments;
    _accountStartupLoan = bundle.startupLoan;
  }

  /// Generates sample aliases.
  void _generateAliases() {
    _referenceDataDomain.generateAliases();
  }

  /// Generates sample categories.
  void _generateCategories() {
    final DataSimulatorCategoriesBundle bundle = generateSimulatorCategories();
    _categoryBillsElectricity = bundle.billsElectricity;
    _categoryBillsInternet = bundle.billsInternet;
    _categoryBillsPhone = bundle.billsPhone;
    _categoryBillsTV = bundle.billsTv;
    _categoryFoodGrocery = bundle.foodGrocery;
    _categoryFoodRestaurant = bundle.foodRestaurant;
    _categoryHomeLoanDownPayment = bundle.homeLoanDownPayment;
    _categoryHomeLoanMortgageInterest = bundle.homeLoanMortgageInterest;
    _categoryHomeLoanMortgagePrincipal = bundle.homeLoanMortgagePrincipal;
    _categoryInvestmentTrades = bundle.investmentTrades;
    _categorySalaryBonus = bundle.salaryBonus;
    _categorySalaryPaycheck = bundle.salaryPaycheck;
    _categorySubscriptionTransport = bundle.subscriptionTransport;
    _categorySubscriptionsGym = bundle.subscriptionsGym;
    _categorySubscriptionsStreaming = bundle.subscriptionsStreaming;
  }

  /// Generates sample currencies.
  void _generateCurrencies() {
    _referenceDataDomain.generateCurrencies();
  }

  /// Populates the events collection with a fixed set of demo events.
  void _generateEvents() {
    _referenceDataDomain.generateEvents();
  }

  /// Generates sample investments.
  void _generateInvestments() {
    DataSimulatorInvestmentsDomain(
      idStockApple: idStockApple,
      idStockFord: idStockFord,
      accountForInvestments: _accountForInvestments,
      accountBankCanada: _accountBankCanada,
      accountStartupLoan: _accountStartupLoan,
      categoryInvestmentTrades: _categoryInvestmentTrades,
    ).generateInvestments(
      addInvestment: _addInvestment,
    );
  }

  /// Generates sample loan payments.
  void _generateLoans() {
    DataSimulatorInvestmentsDomain(
      idStockApple: idStockApple,
      idStockFord: idStockFord,
      accountForInvestments: _accountForInvestments,
      accountBankCanada: _accountBankCanada,
      accountStartupLoan: _accountStartupLoan,
      categoryInvestmentTrades: _categoryInvestmentTrades,
    ).generateLoans(
      createTransferTransaction: _createTransferTransaction,
      getDateShiftedByYears: getDateShiftedByYears,
      generateListOfDates: generateListOfDates,
      addTransaction: _addTransactionAccountDatePayeeCategory,
    );
  }

  /// Generates sample online accounts.
  void _generateOnlineAccounts() {
    _referenceDataDomain.generateOnlineAccounts();
  }

  /// Populates the payees collection with a fixed set of demo payees.
  void _generatePayees() {
    _referenceDataDomain.generatePayees();
  }

  /// Generates sample rental data.
  void _generateRentals() {
    _referenceDataDomain.generateRentals();
  }

  /// 4 years of GYM and Netflix
  void _generateSubscriptionsOnCheckingAccount() {
    _transactionsDomain.generateSubscriptionsOnCheckingAccount(
      generateTransactionsMonthlyExpenses: generateTransactionsMonthlyExpenses,
      getAmount: getAmount,
    );
  }

  /// 4 years of GYM and Netflix
  void _generateSubscriptionsOnCreditCard() {
    _transactionsDomain.generateSubscriptionsOnCreditCard(
      generateTransactionsMonthlyExpenses: generateTransactionsMonthlyExpenses,
    );
  }

  // Create 2 random TransactionsExtra entries, mainly for code coverage.
  void _generateTransactionExtra() {
    _transactionsDomain.generateTransactionExtra();
  }

  /// Generates credit card transactions for the past 20 years.
  void _generateTransactionsForCreditCard() {
    _transactionsDomain.generateTransactionsForCreditCard(
      dateOfFirstBigJob: _dateOfFirstBigJob,
      generateListOfDatesRandom: generateListOfDatesRandom,
      addTransaction: _addTransactionAccountDatePayeeCategory,
      getRandomAmount: getRandomAmount,
    );
  }

  /// Generates salary and bonus transactions across multiple years with a mid-point job change.
  void _generateTransactionsSalary() {
    _dateOfFirstBigJob = _transactionsDomain.generateTransactionsSalary(
      generateListOfDates: generateListOfDates,
      addTransaction: _addTransactionAccountDatePayeeCategory,
    );
  }

  // Transfer 100 USD  Bank to CreditCard Account
  void _generateTransfersToCreditCardPayment() {
    _transactionsDomain.generateTransfersToCreditCardPayment(
      createTransferTransaction: _createTransferTransaction,
      getLastDayOfPreviousMonth: getLastDayOfPreviousMonth,
    );
  }

  /// The demo data tries to demonstrate a person that had a rent for the first part of their journey and a house on the second half
  void _generateTransfersToRentAndHomeLoan() {
    _transactionsDomain.generateTransfersToRentAndHomeLoan(
      generateListOfDates: generateListOfDates,
      addTransaction: _addTransactionAccountDatePayeeCategory,
      buyHome: _buyHome,
    );
  }
}
