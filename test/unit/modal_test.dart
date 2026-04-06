import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/shared/domain/categories_collection.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';

void main() {
  setUp(() {
    DataFileController.instance = DataFileController();
  });

  tearDown(() {
    DataFileController.instance = null;
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
