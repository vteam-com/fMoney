import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/rent_building_entity.dart';
import 'package:money/shared/domain/rental_category_role_enum.dart';
import 'package:money/shared/domain/rental_pnl_model.dart';
import 'package:money/shared/domain/rental_unit_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  late Account checking;
  late Category rent;
  late Category airbnb;
  late Category taxes;
  late RentBuilding building;

  /// Adds a transaction of [amount] in [category] dated in [year].
  Transaction addTransaction(Category category, double amount, int year) {
    final Transaction transaction = createTestTransaction(checking, 'Tenant', category: category);
    transaction.fieldDateTime.value = DateTime(year, 6, 1);
    transaction.fieldAmount.value.setAmount(amount);
    return transaction;
  }

  setUp(() {
    resetTestData();
    rent = Data().categories.addNewCategory(name: 'Rent', type: CategoryType.income);
    airbnb = Data().categories.addNewCategory(parentId: rent.uniqueId, name: 'Airbnb');
    taxes = Data().categories.addNewCategory(name: 'Taxes', type: CategoryType.expense);
    checking = createTestAccount();
    building = RentBuilding.fromJson(<String, dynamic>{
      'Id': 1,
      'Name': 'Bldg',
      'CategoryForIncome': rent.uniqueId,
      'CategoryForTaxes': taxes.uniqueId,
    }, Data());
    Data().rentBuildings.appendMoneyObject(building);
    Data().rentUnits.appendMoneyObject(RentUnit.fromJson(<String, dynamic>{'Id': 1, 'Building': 1, 'Name': 'A'}));
  });

  tearDown(() => Data().clearExistingData());

  test('each role reads and writes its own column', () {
    expect(rent.uniqueId, 0);
    expect(building.categoryFieldOf(RentalCategoryRole.income).value, rent.uniqueId);
    expect(building.categoryFieldOf(RentalCategoryRole.taxes).value, taxes.uniqueId);
    expect(building.categoryFieldOf(RentalCategoryRole.repairs).value, -1);
    expect(building.getPersistableJSon()['CategoryForTaxes'], taxes.uniqueId);
    expect(building.categoryForIncome.getValueForDisplay(building), 'Rent');
    expect(RentalCategoryRole.income.isExpense, isFalse);
    expect(RentalCategoryRole.taxes.isExpense, isTrue);
  });

  test('recalculating rebuilds the category trees, totals, counters and units instead of adding to them', () {
    addTransaction(airbnb, 100, 2023);
    final Transaction tax = addTransaction(taxes, -30, 2024);
    addTransaction(Data().categories.addNewCategory(name: 'Other'), -5, 2024);

    Data().rentBuildings.onAllDataLoaded();
    Data().rentBuildings.onAllDataLoaded();

    expect(building.categoryTreeIdsOf(RentalCategoryRole.income), <int>[rent.uniqueId, airbnb.uniqueId]);
    expect(building.isTransactionAssociatedWithThisRental(airbnb.uniqueId), isTrue);
    expect(building.isTransactionOrSplitAssociatedWithThisRental(tax), isTrue);
    expect(building.fieldTransactionsForIncomes.value, 1);
    expect(building.fieldTransactionsForExpenses.value, 1);
    expect(building.units.length, 1);
    expect(building.account, same(checking));
    expect(building.lifeTimePnL.income, 100);
    expect(building.lifeTimePnL.expenseTaxes, -30);
    expect(building.lifeTimePnL.profit, 70);
    expect(building.dateRangeOfOperation.max!.year, 2024);

    tax.mutation = MutationType.deleted;
    Data().rentBuildings.onAllDataLoaded();

    expect(building.fieldTransactionsForExpenses.value, 0);
    expect(building.dateRangeOfOperation.max!.year, 2023);
  });

  test('a building keeps its categories from being deleted', () {
    expect(Data().countBlockingReferences(<DataObject>[taxes]), 1);
  });

  test('the P&L totals each role, expenses being every role but income', () {
    final RentalPnL pnl = RentalPnL(date: DateTime(2024));
    for (final RentalCategoryRole role in RentalCategoryRole.values) {
      pnl.add(role, -1);
    }
    pnl.add(RentalCategoryRole.income, 11);

    expect(pnl.income, 10);
    expect(pnl.amountOf(RentalCategoryRole.repairs), -1);
    expect(
      <double>[
        pnl.expenseInterest,
        pnl.expenseMaintenance,
        pnl.expenseManagement,
        pnl.expenseRepairs,
        pnl.expenseTaxes,
      ],
      <double>[-1, -1, -1, -1, -1],
    );
    expect(pnl.expenses, -5);
    expect(pnl.profit, 5);
  });
}
