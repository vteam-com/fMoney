import 'package:money/data/models/data_simulator_constants.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/shared/domain/account.dart';
import 'package:money/shared/domain/category.dart';
import 'package:money/shared/domain/data.dart';
import 'package:money/shared/domain/payee.dart';
import 'package:money/shared/domain/transaction.dart';
import 'package:money/shared/domain/transaction_split.dart';

/// Callback for generating evenly spaced monthly expenses.
typedef GenerateMonthlyExpensesCallback =
    void Function({
      required Account account,
      required String payeeName,
      required Category category,
      required double amount,
      required int yearMin,
      required int yearMax,
      required int dayOfTheMonth,
    });

/// Callback for adding a transaction with account/date/payee/category details.
typedef AddTransactionCallback =
    Transaction Function({
      required Account account,
      required DateTime date,
      int payeeId,
      int categoryId,
      double amount,
      String memo,
    });

/// Callback for creating linked transfer transactions.
typedef CreateTransferTransactionCallback =
    Transaction Function({
      required Account accountSource,
      required Account accountDestination,
      required DateTime date,
      required double amount,
      required String memo,
      int categoryId,
    });

/// Callback for buying a home and creating initial related entries.
typedef BuyHomeCallback = void Function(Payee payeeForHomeLoan, DateTime date);

/// Callback for getting an amount within a min/max range.
///
/// Arguments:
/// - `minValue`: Inclusive minimum value.
/// - `maxValue`: Inclusive maximum value.
typedef AmountRangeCallback = double Function(int minValue, int maxValue);

/// Callback for generating a random amount up to a maximum.
///
/// Arguments:
/// - `maxValue`: Inclusive maximum value.
typedef RandomAmountCallback = double Function(int maxValue);

/// Callback for creating random dates in a given year.
///
/// Arguments:
/// - `year`: Number of years in the past to generate dates for.
/// - `howManyPerMonths`: Number of random dates generated per month.
typedef GenerateListOfDatesRandomCallback =
    List<DateTime> Function({
      required int year,
      required int howManyPerMonths,
    });

/// Callback for creating scheduled dates at fixed frequency.
///
/// Arguments:
/// - `yearInThePast`: Number of years back from today to start generation.
/// - `stopDate`: Optional upper date boundary; if omitted, generation uses current date.
/// - `howManyPerYear`: Number of generated dates per year.
/// - `dayOfTheMonth`: Day-of-month to use for generated entries.
typedef GenerateListOfDatesCallback =
    List<DateTime> Function({
      required int yearInThePast,
      DateTime? stopDate,
      required int howManyPerYear,
      required int dayOfTheMonth,
    });

/// Transaction/subscription data generator domain for the simulator.
class DataSimulatorTransactionsDomain {
  /// Creates a transaction-domain generator with model dependencies.
  DataSimulatorTransactionsDomain({
    required this.today,
    required this.numberOfYearInThePast,
    required this.monthlyRent,
    required this.monthlyHomeLoan,
    required this.accountBankUSA,
    required this.accountCreditCardUSD,
    required this.categoryBillsElectricity,
    required this.categoryBillsPhone,
    required this.categoryBillsInternet,
    required this.categoryBillsTV,
    required this.categorySubscriptionsGym,
    required this.categorySubscriptionsStreaming,
    required this.categorySubscriptionTransport,
    required this.categoryFoodGrocery,
    required this.categoryFoodRestaurant,
    required this.categorySalaryPaycheck,
    required this.categorySalaryBonus,
    required this.categoryHomeLoanMortgagePrincipal,
    required this.categoryHomeLoanMortgageInterest,
    required this.startingYearlySalaryFirstJob,
    required this.startingYearlySalarySecondJob,
    required this.yearlyInflation,
  });

  final DateTime today;
  final int numberOfYearInThePast;
  final double monthlyRent;
  final double monthlyHomeLoan;
  final Account accountBankUSA;
  final Account accountCreditCardUSD;
  final Category categoryBillsElectricity;
  final Category categoryBillsPhone;
  final Category categoryBillsInternet;
  final Category categoryBillsTV;
  final Category categorySubscriptionsGym;
  final Category categorySubscriptionsStreaming;
  final Category categorySubscriptionTransport;
  final Category categoryFoodGrocery;
  final Category categoryFoodRestaurant;
  final Category categorySalaryPaycheck;
  final Category categorySalaryBonus;
  final Category categoryHomeLoanMortgagePrincipal;
  final Category categoryHomeLoanMortgageInterest;
  final double startingYearlySalaryFirstJob;
  final double startingYearlySalarySecondJob;
  final double yearlyInflation;

  /// Generates subscriptions paid from the checking account.
  void generateSubscriptionsOnCheckingAccount({
    required GenerateMonthlyExpensesCallback generateTransactionsMonthlyExpenses,
    required AmountRangeCallback getAmount,
  }) {
    final DateTime startDate = today.subtract(
      Duration(days: (DataSimulatorConstants.averageDaysPerYear * numberOfYearInThePast).toInt()),
    );

    generateTransactionsMonthlyExpenses(
      account: accountBankUSA,
      payeeName: SharedSimulationStrings.simPayeeElectricCity,
      category: categoryBillsElectricity,
      amount: -getAmount(DataSimulatorConstants.electricityMin, DataSimulatorConstants.electricityMax),
      yearMin: startDate.year,
      yearMax: today.year,
      dayOfTheMonth: DataSimulatorConstants.subscriptionElectricityDay,
    );

    generateTransactionsMonthlyExpenses(
      account: accountBankUSA,
      payeeName: SharedSimulationStrings.simPayeeTMobile,
      category: categoryBillsPhone,
      amount: -getAmount(DataSimulatorConstants.phoneMin, DataSimulatorConstants.phoneMax),
      yearMin: startDate.year,
      yearMax: today.year,
      dayOfTheMonth: DataSimulatorConstants.subscriptionPhoneDay,
    );

    generateTransactionsMonthlyExpenses(
      account: accountBankUSA,
      payeeName: SharedSimulationStrings.simPayeeFastIsp,
      category: categoryBillsInternet,
      amount: DataSimulatorConstants.internetAmount,
      yearMin: startDate.year,
      yearMax: today.year,
      dayOfTheMonth: DataSimulatorConstants.subscriptionInternetDay,
    );

    generateTransactionsMonthlyExpenses(
      account: accountBankUSA,
      payeeName: SharedSimulationStrings.simPayeeComcast,
      category: categoryBillsTV,
      amount: DataSimulatorConstants.tvAmount,
      yearMin: startDate.year,
      yearMax: today.year,
      dayOfTheMonth: DataSimulatorConstants.subscriptionTvDay,
    );
  }

  /// Generates subscriptions paid from the credit-card account.
  void generateSubscriptionsOnCreditCard({
    required GenerateMonthlyExpensesCallback generateTransactionsMonthlyExpenses,
  }) {
    final DateTime dateForGym = today.subtract(
      const Duration(days: DataSimulatorConstants.daysPerYear * DataSimulatorConstants.gymYearsBack),
    );
    generateTransactionsMonthlyExpenses(
      account: accountCreditCardUSD,
      payeeName: SharedSimulationStrings.simPayeeGoldGym,
      category: categorySubscriptionsGym,
      amount: DataSimulatorConstants.gymAmount,
      yearMin: dateForGym.year,
      yearMax: dateForGym
          .add(const Duration(days: DataSimulatorConstants.daysPerYear * DataSimulatorConstants.gymDurationYears))
          .year,
      dayOfTheMonth: DataSimulatorConstants.subscriptionGymDay,
    );

    final DateTime dateForNetflix = today.subtract(
      const Duration(days: DataSimulatorConstants.daysPerYear * DataSimulatorConstants.netflixYearsBack),
    );
    generateTransactionsMonthlyExpenses(
      account: accountCreditCardUSD,
      payeeName: SharedSimulationStrings.simPayeeNetflix,
      category: categorySubscriptionsStreaming,
      amount: DataSimulatorConstants.netflixAmount,
      yearMin: dateForNetflix.year,
      yearMax: today.year,
      dayOfTheMonth: DataSimulatorConstants.subscriptionNetflixDay,
    );
  }

  /// Creates two transaction-extra entries for test/demo coverage.
  void generateTransactionExtra() {
    Data().transactionExtras.loadFromJson(<Map<String, dynamic>>[
      <String, dynamic>{
        'Id': '0',
        'TaxDate': DateTime(
          DataSimulatorConstants.transactionExtraYearFirst,
          DataSimulatorConstants.transactionExtraMonth,
          DataSimulatorConstants.transactionExtraDay,
        ),
        'TaxYear': DataSimulatorConstants.transactionExtraYearFirst,
        'Transaction': DataSimulatorConstants.transactionExtraIdFirst,
      },
      <String, dynamic>{
        'Id': '1',
        'TaxDate': DateTime(
          DataSimulatorConstants.transactionExtraYearSecond,
          DataSimulatorConstants.transactionExtraMonth,
          DataSimulatorConstants.transactionExtraDay,
        ),
        'TaxYear': DataSimulatorConstants.transactionExtraYearSecond,
        'Transaction': DataSimulatorConstants.transactionExtraIdSecond,
      },
    ]);
  }

  /// Generates randomized credit-card transactions across the demo period.
  void generateTransactionsForCreditCard({
    required DateTime dateOfFirstBigJob,
    required GenerateListOfDatesRandomCallback generateListOfDatesRandom,
    required AddTransactionCallback addTransaction,
    required RandomAmountCallback getRandomAmount,
  }) {
    final List<DateTime> dates = generateListOfDatesRandom(
      year: numberOfYearInThePast,
      howManyPerMonths: DataSimulatorConstants.creditCardTransactionsPerMonth,
    );

    for (final DateTime date in dates) {
      final List<Object> selectedCategory = <List<Object>>[
        <Object>[
          categorySubscriptionTransport,
          <List<Object>>[
            <Object>[SharedSimulationStrings.simPayeeCityBus, DataSimulatorConstants.transportCityBusMax],
            <Object>[SharedSimulationStrings.simPayeeTaxi, DataSimulatorConstants.transportTaxiMax],
            <Object>[SharedSimulationStrings.simPayeeUber, DataSimulatorConstants.transportUberMax],
          ],
        ],
        <Object>[
          categoryFoodGrocery,
          <List<Object>>[
            <Object>[SharedSimulationStrings.simPayeeTheFoodStore, DataSimulatorConstants.groceryStoreMax],
            <Object>[SharedSimulationStrings.simPayeeSafeWay, DataSimulatorConstants.grocerySafewayMax],
            <Object>[SharedSimulationStrings.simPayeeWholeFood, DataSimulatorConstants.groceryWholeFoodMax],
          ],
        ],
        <Object>[
          categoryFoodRestaurant,
          <List<Object>>[
            <Object>[SharedSimulationStrings.simPayeeStarbucks, DataSimulatorConstants.restaurantStarbucksMax],
            <Object>[SharedSimulationStrings.simPayeeAppleBees, DataSimulatorConstants.restaurantAppleBeesMax],
            <Object>[SharedSimulationStrings.simPayeePizzaHut, DataSimulatorConstants.restaurantPizzaHutMax],
          ],
        ],
      ].getRandomItem();

      final Category category = selectedCategory[DataSimulatorConstants.listIndexFirst] as Category;
      final dynamic payeeAndMaxAmount = (selectedCategory[DataSimulatorConstants.listIndexSecond] as List<Object>)
          .getRandomItem();
      double maxSpendingOnCreditCard = (payeeAndMaxAmount[DataSimulatorConstants.listIndexSecond] as num).toDouble();

      final Transaction source = addTransaction(
        account: accountCreditCardUSD,
        date: date,
        payeeId: Data().payees.getOrCreate(payeeAndMaxAmount[DataSimulatorConstants.listIndexFirst] as String).uniqueId,
        categoryId: category.uniqueId,
      );
      if (date.isAfter(dateOfFirstBigJob)) {
        maxSpendingOnCreditCard *= DataSimulatorConstants.spendMultiplierAfterPromotion;
      }
      source.fieldAmount.setAmount(
        -getRandomAmount(maxSpendingOnCreditCard.toInt()),
      );
    }
  }

  /// Generates salary and bonus transactions and returns the first-big-job date.
  DateTime generateTransactionsSalary({
    required GenerateListOfDatesCallback generateListOfDates,
    required AddTransactionCallback addTransaction,
  }) {
    final List<DateTime> dates = generateListOfDates(
      yearInThePast: numberOfYearInThePast,
      howManyPerYear: DataSimulatorConstants.monthsPerYear,
      dayOfTheMonth: DataSimulatorConstants.salaryPaymentDay,
    );
    final DateTime dateOfFirstBigJob = dates[dates.length ~/ DataSimulatorConstants.midpointDivisor];

    double yearlySalary = startingYearlySalaryFirstJob;
    final double increaseRatePerYear = yearlyInflation / DataSimulatorConstants.inflationPercentDivisor;
    int iterationYear = DataSimulatorConstants.unsetId;

    final Payee employer1 = Data().payees.get(DataSimulatorConstants.payeeIdBurgerKing)!;
    final Payee employer2 = Data().payees.get(DataSimulatorConstants.payeeIdNasa)!;
    bool switchedJob = false;

    for (final DateTime date in dates) {
      if (iterationYear == DataSimulatorConstants.unsetId) {
        iterationYear = date.year;
      } else if (iterationYear != date.year) {
        iterationYear = date.year;
        yearlySalary += yearlySalary * increaseRatePerYear;
      }

      if (date.isBefore(dateOfFirstBigJob)) {
        addTransaction(
          account: accountBankUSA,
          date: date,
          payeeId: employer1.uniqueId,
          categoryId: categorySalaryPaycheck.uniqueId,
          amount: yearlySalary / DataSimulatorConstants.monthsPerYear,
        );
      } else {
        if (!switchedJob) {
          switchedJob = true;
          yearlySalary = startingYearlySalarySecondJob;
          addTransaction(
            account: accountBankUSA,
            date: date,
            payeeId: employer2.uniqueId,
            categoryId: categorySalaryBonus.uniqueId,
            amount: DataSimulatorConstants.signOnBonusAmount,
            memo: 'Sign-On Bonus',
          );
        }

        addTransaction(
          account: accountBankUSA,
          date: date,
          payeeId: employer2.uniqueId,
          categoryId: categorySalaryPaycheck.uniqueId,
          amount: yearlySalary / DataSimulatorConstants.monthsPerYear,
        );

        if (date.month == DataSimulatorConstants.holidayBonusMonth) {
          addTransaction(
            account: accountBankUSA,
            date: date.add(const Duration(days: DataSimulatorConstants.holidayBonusDayOffset)),
            payeeId: employer2.uniqueId,
            categoryId: categorySalaryBonus.uniqueId,
            amount: DataSimulatorConstants.holidayBonusAmount,
            memo: SharedSimulationStrings.simMemoHolidayBonus,
          );
        }
      }
    }

    return dateOfFirstBigJob;
  }

  /// Generates monthly transfers used to settle credit-card balances.
  void generateTransfersToCreditCardPayment({
    required CreateTransferTransactionCallback createTransferTransaction,
    required DateTime Function(DateTime) getLastDayOfPreviousMonth,
  }) {
    double rollingBalance = DataSimulatorConstants.zeroAmount;

    final List<Transaction> list = Data().accounts.getTransactions(accountCreditCardUSD).toList();
    list.sort((Transaction a, Transaction b) => sortByDate(a.fieldDateTime.value, b.fieldDateTime.value, true));
    int lastMonth = list.first.fieldDateTime.value!.month;

    for (final Transaction transaction in list) {
      if (transaction.fieldDateTime.value!.month != lastMonth && rollingBalance != DataSimulatorConstants.zeroAmount) {
        createTransferTransaction(
          accountSource: accountBankUSA,
          accountDestination: accountCreditCardUSD,
          date: getLastDayOfPreviousMonth(transaction.fieldDateTime.value!),
          amount: rollingBalance,
          memo: SharedSimulationStrings.simMemoPayCreditCard,
        );
        rollingBalance = DataSimulatorConstants.zeroAmount;
        lastMonth = transaction.fieldDateTime.value!.month;
      }
      rollingBalance += transaction.fieldAmount.value.asDouble();
    }
  }

  /// Generates historical rent payments, home purchase, and mortgage split entries.
  void generateTransfersToRentAndHomeLoan({
    required GenerateListOfDatesCallback generateListOfDates,
    required AddTransactionCallback addTransaction,
    required BuyHomeCallback buyHome,
  }) {
    final Payee payeeLandLord = Data().payees.getOrCreate(SharedSimulationStrings.simPayeeTheLandlord);
    final Payee payeeForHomeLoan = Data().payees.getOrCreate(SharedSimulationStrings.simPayeeHomeLoanBank);

    final List<DateTime> dates = generateListOfDates(
      yearInThePast: numberOfYearInThePast,
      howManyPerYear: DataSimulatorConstants.monthsPerYear,
      dayOfTheMonth: DataSimulatorConstants.rentAndHomePaymentDay,
    );
    final DateTime midPointInTime = dates[dates.length ~/ DataSimulatorConstants.midpointDivisor];

    bool boughtHome = false;
    int numberOfRentPayment = DataSimulatorConstants.zeroInt;
    int numberOfMortgagePayment = DataSimulatorConstants.zeroInt;

    for (final DateTime date in dates) {
      if (date.isBefore(midPointInTime)) {
        addTransaction(
          account: accountBankUSA,
          date: date,
          payeeId: payeeLandLord.uniqueId,
          categoryId: Data().categories
              .getOrCreate(SharedSimulationStrings.simCategoryBillsRent, CategoryType.expense)
              .uniqueId,
          amount: monthlyRent,
          memo: '${SharedSimulationStrings.simMemoPayRentPrefix}${++numberOfRentPayment}',
        );
      } else {
        if (!boughtHome) {
          boughtHome = true;
          buyHome(payeeForHomeLoan, date.add(const Duration(days: DataSimulatorConstants.buyHomeDelayDays)));
        }

        final Transaction transaction = addTransaction(
          account: accountBankUSA,
          date: date,
          payeeId: payeeForHomeLoan.uniqueId,
          categoryId: Data().categories.split.uniqueId,
          amount: monthlyHomeLoan,
          memo: '${SharedSimulationStrings.simMemoMortgagePaymentPrefix}${++numberOfMortgagePayment}',
        );

        final TransactionSplit splitMortgagePaymentPrincipal = TransactionSplit(
          id: DataSimulatorConstants.unsetId,
          amount: monthlyHomeLoan - DataSimulatorConstants.mortgageSplitPrincipalOffset,
          transactionId: transaction.uniqueId,
          categoryId: categoryHomeLoanMortgagePrincipal.uniqueId,
          payeeId: payeeForHomeLoan.uniqueId,
          transferId: DataSimulatorConstants.unsetId,
          memo: '',
          flags: DataSimulatorConstants.defaultFlags,
          budgetBalanceDate: null,
          data: Data(),
        );
        Data().splits.appendNewMoneyObject(splitMortgagePaymentPrincipal);

        final TransactionSplit splitMortgagePaymentInterest = TransactionSplit(
          id: DataSimulatorConstants.unsetId,
          amount: DataSimulatorConstants.mortgageSplitPrincipalOffset,
          transactionId: transaction.uniqueId,
          categoryId: categoryHomeLoanMortgageInterest.uniqueId,
          payeeId: payeeForHomeLoan.uniqueId,
          transferId: DataSimulatorConstants.unsetId,
          memo: '',
          flags: DataSimulatorConstants.defaultFlags,
          budgetBalanceDate: null,
          data: Data(),
        );
        Data().splits.appendNewMoneyObject(splitMortgagePaymentInterest);
      }
    }
  }
}
