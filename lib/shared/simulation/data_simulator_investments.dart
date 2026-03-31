import 'package:money/data/models/data_simulator_constants.dart';
import 'package:money/helpers/investment_types.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/shared/domain/account.dart';
import 'package:money/shared/domain/category.dart';
import 'package:money/shared/domain/data.dart';
import 'package:money/shared/domain/loan_payment.dart';
import 'package:money/shared/domain/security.dart';
import 'package:money/shared/domain/stock_split.dart';
import 'package:money/shared/domain/transaction.dart';

/// Callback for creating an investment transaction entry.
typedef AddInvestmentCallback =
    void Function(
      Account account,
      String dateAsString,
      int stockId,
      InvestmentType activity,
      double quantity,
      double tradePrice,
    );

/// Callback for creating account-linked transaction entries.
typedef AddTransactionGenericCallback =
    Transaction Function({
      required Account account,
      required DateTime date,
      int payeeId,
      int categoryId,
      double amount,
      String memo,
    });

/// Callback for creating a transfer transaction pair.
typedef CreateTransferGenericCallback =
    Transaction Function({
      required Account accountSource,
      required Account accountDestination,
      required DateTime date,
      required double amount,
      required String memo,
      int categoryId,
    });

/// Callback to generate recurring dates.
typedef GenerateDatesCallback =
    List<DateTime> Function({
      required int yearInThePast,
      DateTime? stopDate,
      required int howManyPerYear,
      required int dayOfTheMonth,
    });

/// Callback to compute shifted dates by years.
typedef ShiftedDateCallback = DateTime Function(int yearsToShift, int month, int day);

/// Generates investment, stock, and loan domain data.
class DataSimulatorInvestmentsDomain {
  /// Creates the domain generator.
  DataSimulatorInvestmentsDomain({
    required this.idStockApple,
    required this.idStockFord,
    required this.accountForInvestments,
    required this.accountBankCanada,
    required this.accountStartupLoan,
    required this.categoryInvestmentTrades,
  });

  final int idStockApple;
  final int idStockFord;
  final Account accountForInvestments;
  final Account accountBankCanada;
  final Account accountStartupLoan;
  final Category categoryInvestmentTrades;

  /// Generates sample stock data.
  void generateStocks() {
    Data().securities.appendMoneyObject(
      Security(
        id: idStockApple,
        name: 'Apple Inc',
        symbol: SharedSimulationStrings.simStockSymbolAapl,
        price: DataSimulatorConstants.appleStockPrice,
        lastPrice: DataSimulatorConstants.appleStockLastPrice,
        cuspid: '',
        securityType: SecurityType.equity.index,
        taxable: DataSimulatorConstants.taxableFalse,
        priceDate: DateTime(
          DataSimulatorConstants.appleStockPriceYear,
          DataSimulatorConstants.appleStockPriceMonth,
          DataSimulatorConstants.appleStockPriceDay,
        ),
      ),
    );
    Data().securities.appendMoneyObject(
      Security(
        id: idStockFord,
        name: 'Ford',
        symbol: SharedSimulationStrings.simStockSymbolF,
        price: DataSimulatorConstants.fordStockPrice,
        lastPrice: DataSimulatorConstants.fordStockLastPrice,
        cuspid: '',
        securityType: SecurityType.equity.index,
        taxable: DataSimulatorConstants.taxableFalse,
        priceDate: DateTime(
          DataSimulatorConstants.fordStockPriceYear,
          DataSimulatorConstants.fordStockPriceMonth,
          DataSimulatorConstants.fordStockPriceDay,
        ),
      ),
    );

    Data().stockSplits.appendNewMoneyObject(
      StockSplit.fromJson(<String, dynamic>{
        'Date': '2005-05-05',
        'Security': idStockApple,
        'Numerator': DataSimulatorConstants.stockSplitNumerator,
        'Denominator': DataSimulatorConstants.stockSplitDenominator,
      }, Data()),
    );
  }

  /// Generates sample investment buy/sell/dividend activity.
  void generateInvestments({
    required AddInvestmentCallback addInvestment,
  }) {
    generateStocks();

    addInvestment(
      accountForInvestments,
      '2010-06-20',
      idStockApple,
      InvestmentType.buy,
      DataSimulatorConstants.appleTradeQuantity,
      DataSimulatorConstants.appleBuyPriceFirst,
    );
    addInvestment(
      accountForInvestments,
      '2000-07-21',
      idStockApple,
      InvestmentType.sell,
      DataSimulatorConstants.appleTradeQuantity,
      DataSimulatorConstants.appleSellPrice,
    );
    addInvestment(
      accountForInvestments,
      '2012-01-01',
      idStockApple,
      InvestmentType.dividend,
      DataSimulatorConstants.appleDividendQuantity,
      DataSimulatorConstants.appleDividendPrice,
    );
    addInvestment(
      accountForInvestments,
      '2020-08-22',
      idStockApple,
      InvestmentType.buy,
      DataSimulatorConstants.appleTradeQuantity,
      DataSimulatorConstants.appleBuyPriceSecond,
    );

    addInvestment(
      accountForInvestments,
      '2012-07-26',
      idStockFord,
      InvestmentType.buy,
      DataSimulatorConstants.fordTradeQuantity,
      DataSimulatorConstants.fordBuyPrice,
    );
    addInvestment(
      accountForInvestments,
      '2013-01-15',
      idStockFord,
      InvestmentType.sell,
      DataSimulatorConstants.fordTradeQuantity,
      DataSimulatorConstants.fordSellPrice,
    );
  }

  /// Generates sample loan transfer and repayment activity.
  void generateLoans({
    required CreateTransferGenericCallback createTransferTransaction,
    required ShiftedDateCallback getDateShiftedByYears,
    required GenerateDatesCallback generateListOfDates,
    required AddTransactionGenericCallback addTransaction,
  }) {
    double loanAmount = DataSimulatorConstants.loanInitialAmount;
    final double loanRate = DataSimulatorConstants.loanRatePercent / DataSimulatorConstants.inflationPercentDivisor;
    double monthlyPayment = DataSimulatorConstants.loanMonthlyPayment;

    createTransferTransaction(
      accountSource: accountBankCanada,
      accountDestination: accountStartupLoan,
      date: getDateShiftedByYears(
        DataSimulatorConstants.loanStartYearsBack,
        DataSimulatorConstants.loanStartMonth,
        DataSimulatorConstants.loanStartDay,
      ),
      categoryId: accountStartupLoan.fieldCategoryIdForPrincipal.value,
      amount: -loanAmount,
      memo: SharedSimulationStrings.simMemoInvestMars,
    );

    final List<DateTime> dates = generateListOfDates(
      yearInThePast: DataSimulatorConstants.loanScheduleYearsBack,
      howManyPerYear: DataSimulatorConstants.monthsPerYear,
      dayOfTheMonth: DataSimulatorConstants.loanPaymentDay,
    );

    for (final DateTime date in dates) {
      if (loanAmount < DataSimulatorConstants.zeroAmount) {
        break;
      }

      final double annuallyInterest = loanAmount * loanRate;
      double monthlyInterest = annuallyInterest / DataSimulatorConstants.monthsPerYear;
      double principalForThisMonday = monthlyPayment - monthlyInterest;
      if (isConsideredZero(monthlyInterest)) {
        monthlyInterest = DataSimulatorConstants.zeroAmount;
        principalForThisMonday = loanAmount;
        monthlyPayment = principalForThisMonday;
        loanAmount = DataSimulatorConstants.zeroAmount;
      }

      loanAmount -= principalForThisMonday;

      Data().loanPayments.appendNewMoneyObject(
        LoanPayment(
          id: DataSimulatorConstants.unsetId,
          accountId: accountStartupLoan.uniqueId,
          date: date,
          principal: -principalForThisMonday,
          interest: monthlyInterest,
          memo: '',
          data: Data(),
        ),
      );

      addTransaction(
        account: accountBankCanada,
        date: date,
        payeeId: Data().payees.getOrCreate(SharedSimulationStrings.simPayeeMarsProject).uniqueId,
        amount: monthlyPayment,
        memo: SharedSimulationStrings.simMemoPayBackInvestment,
      );
    }
  }
}
