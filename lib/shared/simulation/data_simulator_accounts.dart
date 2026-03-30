import 'package:money/data/models/data_simulator_constants.dart';
import 'package:money/helpers/account_types_enum.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/shared/domain/account.dart';
import 'package:money/shared/domain/category.dart';
import 'package:money/shared/domain/data.dart';
import 'package:money/shared/domain/transaction.dart';

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
    'Bank Of America',
    'B0001',
    AccountType.checking.index,
    'USD',
  );

  final Account accountBankCanada = addNewAccount(
    DataSimulatorConstants.unsetId,
    'Bank Of Montreal',
    'B0002',
    AccountType.savings.index,
    'CAD',
  );

  addTransaction(
    account: accountBankCanada,
    date: getDateShiftedByYears(
      DataSimulatorConstants.initialDepositYearsBack,
      DateTime.january,
      DataSimulatorConstants.firstDayOfMonth,
    ),
    amount: DataSimulatorConstants.initialDepositAmount,
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

  final Account accountCreditCardUSD = addNewAccount(
    DataSimulatorConstants.unsetId,
    'VisaCard',
    '0002',
    AccountType.credit.index,
    'USD',
  );

  final Account accountForInvestments = addNewAccount(
    DataSimulatorConstants.unsetId,
    'Fidelity',
    '0003',
    AccountType.investment.index,
    'USD',
  );

  final Account accountStartupLoan = addNewAccount(
    DataSimulatorConstants.unsetId,
    'Startup',
    '0004',
    AccountType.loan.index,
    'CAD',
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
      .getOrCreate('Lend:Interest:Startup', CategoryType.investment)
      .uniqueId;
  accountStartupLoan.fieldCategoryIdForPrincipal.value = Data().categories
      .getOrCreate('Lend:Principal:Startup', CategoryType.investment)
      .uniqueId;

  return DataSimulatorAccountsBundle(
    bankUsa: accountBankUSA,
    bankCanada: accountBankCanada,
    creditCardUsd: accountCreditCardUSD,
    forInvestments: accountForInvestments,
    startupLoan: accountStartupLoan,
  );
}
