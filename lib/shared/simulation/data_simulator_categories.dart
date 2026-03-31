import 'package:money/data/models/data_simulator_constants.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/shared/domain/category.dart';
import 'package:money/shared/domain/data.dart';

/// Holds category references generated for simulator domains.
class DataSimulatorCategoriesBundle {
  /// Creates a bundle of generated category references.
  DataSimulatorCategoriesBundle({
    required this.bills,
    required this.billsElectricity,
    required this.billsInternet,
    required this.billsPhone,
    required this.billsTv,
    required this.food,
    required this.foodGrocery,
    required this.foodRestaurant,
    required this.homeLoanDownPayment,
    required this.homeLoanMortgageInterest,
    required this.homeLoanMortgagePrincipal,
    required this.investmentTrades,
    required this.salary,
    required this.salaryBonus,
    required this.salaryPaycheck,
    required this.subscriptionTransport,
    required this.subscriptions,
    required this.subscriptionsGym,
    required this.subscriptionsStreaming,
  });

  final Category bills;
  final Category billsElectricity;
  final Category billsInternet;
  final Category billsPhone;
  final Category billsTv;
  final Category food;
  final Category foodGrocery;
  final Category foodRestaurant;
  final Category homeLoanDownPayment;
  final Category homeLoanMortgageInterest;
  final Category homeLoanMortgagePrincipal;
  final Category investmentTrades;
  final Category salary;
  final Category salaryBonus;
  final Category salaryPaycheck;
  final Category subscriptionTransport;
  final Category subscriptions;
  final Category subscriptionsGym;
  final Category subscriptionsStreaming;
}

/// Generates simulator category trees and returns required references.
DataSimulatorCategoriesBundle generateSimulatorCategories() {
  Data().categories.interestEarned;
  Data().categories.salesTax;
  Data().categories.savings;
  Data().categories.transferFromDeletedAccount;
  Data().categories.transferToDeletedAccount;
  Data().categories.unassignedSplit;
  Data().categories.unknown;

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

  final Category bills = Data().categories.addNewCategory(
    name: 'Bills',
    type: CategoryType.expense,
    color: '#FFFF0000',
  );
  bills.fieldBudget.value.setAmount(DataSimulatorConstants.categoryBillsBudget);
  final Category billsElectricity = Data().categories.addNewCategory(
    parentId: bills.uniqueId,
    name: 'Electricity',
    type: CategoryType.recurringExpense,
  );
  Data().categories.addNewCategory(
    parentId: bills.uniqueId,
    name: 'School',
    description: '',
    type: CategoryType.expense,
  );
  final Category billsPhone = Data().categories.addNewCategory(
    parentId: bills.uniqueId,
    name: 'Phone',
    type: CategoryType.recurringExpense,
  );
  final Category billsTv = Data().categories.addNewCategory(
    parentId: bills.uniqueId,
    name: 'TV',
    type: CategoryType.recurringExpense,
  );
  final Category billsInternet = Data().categories.addNewCategory(
    parentId: bills.uniqueId,
    name: 'Internet',
    type: CategoryType.recurringExpense,
  );

  final Category food = Data().categories.addNewCategory(
    name: 'Food',
    type: CategoryType.expense,
    color: '#FFFF22FF',
  );
  final Category foodGrocery = Data().categories.addNewCategory(
    parentId: food.uniqueId,
    name: 'Grocery',
    type: CategoryType.recurringExpense,
  );
  final Category foodRestaurant = Data().categories.addNewCategory(
    parentId: food.uniqueId,
    name: 'Restaurant',
    type: CategoryType.recurringExpense,
  );

  final Category subscriptions = Data().categories.addNewCategory(
    name: 'Subscriptions',
    type: CategoryType.expense,
    color: '#FFFFaaaa',
  );
  final Category subscriptionsGym = Data().categories.addNewCategory(
    parentId: subscriptions.uniqueId,
    name: 'Gym',
    type: CategoryType.recurringExpense,
  );
  final Category subscriptionsStreaming = Data().categories.addNewCategory(
    parentId: subscriptions.uniqueId,
    name: 'Streaming',
    type: CategoryType.recurringExpense,
  );
  final Category subscriptionTransport = Data().categories.addNewCategory(
    parentId: subscriptions.uniqueId,
    name: 'Transportation',
    type: CategoryType.recurringExpense,
  );

  final Category salary = Data().categories.addNewCategory(
    parentId: food.uniqueId,
    name: 'Salary',
    type: CategoryType.income,
    color: '#FF00FF00',
    description: SharedSimulationStrings.simDescriptionMainIncome,
  );
  final Category salaryPaycheck = Data().categories.addNewCategory(
    parentId: salary.uniqueId,
    name: 'Paycheck',
  );
  salaryPaycheck.fieldBudget.value.setAmount(DataSimulatorConstants.categorySalaryPaycheckBudget);
  final Category salaryBonus = Data().categories.addNewCategory(
    parentId: salary.uniqueId,
    name: 'Bonus',
  );

  Data().categories.addNewCategory(
    name: 'Investment',
    description: '',
    type: CategoryType.investment,
    color: '#FF1122DD',
  );
  final Category investmentTrades = Data().categories.addNewCategory(name: 'Investment:Trades');
  Data().categories.addNewCategory(
    name: 'Properties',
    description: '',
    type: CategoryType.investment,
    color: '#FF11FFDD',
  );

  Data().categories.addNewCategory(
    name: 'Rental',
    description: '',
    type: CategoryType.income,
    color: '#FF11FF33',
  );

  final Category homeLoan = Data().categories.addNewCategory(
    name: 'HomeLoans',
    description: '',
    type: CategoryType.expense,
    color: '#FFBB2233',
  );
  final Category homeLoanDownPayment = Data().categories.addNewCategory(
    parentId: homeLoan.uniqueId,
    name: 'DownPayment',
    type: CategoryType.investment,
  );
  final Category homeLoanMortgagePrincipal = Data().categories.addNewCategory(
    name: 'HomeLoans:Mortgage:Principal',
    type: CategoryType.investment,
  );
  final Category homeLoanMortgageInterest = Data().categories.addNewCategory(
    name: 'HomeLoans:Mortgage:Interest',
    type: CategoryType.expense,
  );

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
  Data().categories.addNewCategory(
    name: 'Taxes',
    type: CategoryType.expense,
    color: '#FFA1A2A3',
  );
  Data().categories.addNewCategory(name: 'Taxes:IRS');
  Data().categories.addNewCategory(name: 'Taxes:Property');
  Data().categories.addNewCategory(name: 'Taxes:School');

  return DataSimulatorCategoriesBundle(
    bills: bills,
    billsElectricity: billsElectricity,
    billsInternet: billsInternet,
    billsPhone: billsPhone,
    billsTv: billsTv,
    food: food,
    foodGrocery: foodGrocery,
    foodRestaurant: foodRestaurant,
    homeLoanDownPayment: homeLoanDownPayment,
    homeLoanMortgageInterest: homeLoanMortgageInterest,
    homeLoanMortgagePrincipal: homeLoanMortgagePrincipal,
    investmentTrades: investmentTrades,
    salary: salary,
    salaryBonus: salaryBonus,
    salaryPaycheck: salaryPaycheck,
    subscriptionTransport: subscriptionTransport,
    subscriptions: subscriptions,
    subscriptionsGym: subscriptionsGym,
    subscriptionsStreaming: subscriptionsStreaming,
  );
}
