import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/simulation/data_simulator_constants.dart';

/// Holds generated account references for simulator flows.
class DataSimulatorAccountsBundle {
  /// Creates a bundle with generated simulator accounts.
  DataSimulatorAccountsBundle({
    required this.bankUsa,
    required this.bankCanada,
    required this.creditCardUsd,
    required this.forInvestments,
    required this.startupLoan,
  });

  final Account bankUsa;
  final Account bankCanada;
  final Account creditCardUsd;
  final Account forInvestments;
  final Account startupLoan;
}

/// Callback for adding a new account instance.
typedef AddNewAccountCallback =
    Account Function(
      int id,
      String name,
      String accountId,
      int type,
      String currency,
    );

/// Callback for adding an account transaction with optional attributes.
typedef AddTransactionForAccountCallback =
    Transaction Function({
      required Account account,
      required DateTime date,
      int payeeId,
      int categoryId,
      double amount,
      String memo,
    });

/// Callback for deriving a date by shifting the current year.
///
/// Arguments:
/// - `yearsToShift`: Number of years to subtract from the current year.
/// - `month`: Month for the resulting date (`DateTime.january` to `DateTime.december`).
/// - `day`: Day of month for the resulting date.
typedef ShiftedDateCallback = DateTime Function(int yearsToShift, int month, int day);

/// Generates simulator accounts and returns required references.
DataSimulatorAccountsBundle generateSimulatorAccounts({
  required AddNewAccountCallback addNewAccount,
  required AddTransactionForAccountCallback addTransaction,
  required ShiftedDateCallback getDateShiftedByYears,
}) {
  final Account accountBankUSA = addNewAccount(
    DataSimulatorConstants.unsetId,
    SharedSimulationStrings.simBankOfAmerica,
    'B0001',
    AccountType.checking.index,
    SharedStrings.currencyUsd,
  );

  final Account accountBankCanada = addNewAccount(
    DataSimulatorConstants.unsetId,
    SharedSimulationStrings.simBankOfMontreal,
    'B0002',
    AccountType.savings.index,
    SharedSimulationStrings.simCurrencyCad,
  );

  addTransaction(
    account: accountBankCanada,
    date: getDateShiftedByYears(
      DataSimulatorConstants.initialDepositYearsBack,
      DateTime.january,
      DataSimulatorConstants.firstDayOfMonth,
    ),
    amount: DataSimulatorConstants.initialDepositAmount,
    payeeId: Data().payees.getByName(SharedSimulationStrings.simPayeeLotteryWin)!.uniqueId,
    categoryId: Data().categories
        .addNewCategory(
          name: 'Misc Incomes',
          type: CategoryType.income,
          color: '#004400',
        )
        .uniqueId,
    memo: SharedSimulationStrings.simMemoInitialOpening,
  );

  final Account accountCreditCardUSD = addNewAccount(
    DataSimulatorConstants.unsetId,
    SharedSimulationStrings.simAccountVisaCard,
    '0002',
    AccountType.credit.index,
    SharedStrings.currencyUsd,
  );

  final Account accountForInvestments = addNewAccount(
    DataSimulatorConstants.unsetId,
    SharedSimulationStrings.simAccountFidelity,
    '0003',
    AccountType.investment.index,
    SharedStrings.currencyUsd,
  );

  final Account accountStartupLoan = addNewAccount(
    DataSimulatorConstants.unsetId,
    SharedSimulationStrings.simAccountStartup,
    '0004',
    AccountType.loan.index,
    SharedSimulationStrings.simCurrencyCad,
  );

  Data().categories.appendNewMoneyObject(
    Category(
      id: DataSimulatorConstants.unsetId,
      name: 'Lend',
      description: '',
      type: CategoryType.investment,
      color: '#FFAAFFAA',
    ),
  );

  accountStartupLoan.fieldCategoryIdForInterest.value = Data().categories
      .getOrCreate(SharedSimulationStrings.simCategoryLendInterestStartup, CategoryType.investment)
      .uniqueId;
  accountStartupLoan.fieldCategoryIdForPrincipal.value = Data().categories
      .getOrCreate(SharedSimulationStrings.simCategoryLendPrincipalStartup, CategoryType.investment)
      .uniqueId;

  return DataSimulatorAccountsBundle(
    bankUsa: accountBankUSA,
    bankCanada: accountBankCanada,
    creditCardUsd: accountCreditCardUSD,
    forInvestments: accountForInvestments,
    startupLoan: accountStartupLoan,
  );
}
