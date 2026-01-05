import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/views/data/categories.dart';
import 'package:money/views/data/data.dart';
import 'package:money/views/data/data_controller.dart';

void main() {
  setUp(() {
    // ignore: unused_local_variable
    final DataController dataController = Get.put(DataController());
  });

  test('Category', () {
    final Categories categories = Data().categories;
    expect(
      categories.interestEarned.getTypeAsText(),
      CategoryType.income.asString(),
    );
    expect(
      categories.salesTax.getTypeAsText(),
      CategoryType.expense.asString(),
    );
    expect(
      categories.salesTax.getTypeAsText(),
      CategoryType.expense.asString(),
    );
    expect(
      categories.savings.getTypeAsText(),
      CategoryType.income.asString(),
    );
    expect(
      categories.transferFromDeletedAccount.getTypeAsText(),
      CategoryType.none.asString(),
    );
    expect(
      categories.transferToDeletedAccount.getTypeAsText(),
      CategoryType.none.asString(),
    );
    expect(
      categories.unassignedSplit.getTypeAsText(),
      CategoryType.none.asString(),
    );
    expect(
      categories.unknown.getTypeAsText(),
      CategoryType.none.asString(),
    );

    // standard categories for investments
    expect(
      categories.investmentBonds.getTypeAsText(),
      CategoryType.expense.asString(),
    );
    expect(
      categories.investmentCredit.getTypeAsText(),
      CategoryType.income.asString(),
    );
    expect(
      categories.investmentDebit.getTypeAsText(),
      CategoryType.expense.asString(),
    );
    expect(
      categories.investmentDividends.getTypeAsText(),
      CategoryType.income.asString(),
    );
    expect(
      categories.investmentFees.getTypeAsText(),
      CategoryType.expense.asString(),
    );
    expect(
      categories.investmentInterest.getTypeAsText(),
      CategoryType.income.asString(),
    );
    expect(
      categories.investmentLongTermCapitalGainsDistribution.getTypeAsText(),
      CategoryType.income.asString(),
    );
    expect(
      categories.investmentMiscellaneous.getTypeAsText(),
      CategoryType.expense.asString(),
    );
    expect(
      categories.investmentOptions.getTypeAsText(),
      CategoryType.expense.asString(),
    );
    expect(
      categories.investmentOther.getTypeAsText(),
      CategoryType.expense.asString(),
    );
    expect(
      categories.investmentReinvest.getTypeAsText(),
      CategoryType.none.asString(),
    );
    expect(
      categories.investmentStocks.getTypeAsText(),
      CategoryType.expense.asString(),
    );
    expect(
      categories.investmentTransfer.getTypeAsText(),
      CategoryType.none.asString(),
    );
  });
}
