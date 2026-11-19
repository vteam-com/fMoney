import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/panels/charts/sankey_panel.dart';
import 'package:money/widgets/sankey/sankey_painter_widget.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  late AppServices services;

  setUp(() {
    resetTestData();
    services = createTestServices();
  });

  tearDown(() => disposeTestServices(services));

  /// Adds a transaction of [amount] in [category] to [account].
  Transaction addTransaction(Account account, Category? category, double amount) =>
      createTestTransaction(account, 'Payee', category: category)..fieldAmount.value.setAmount(amount);

  testWidgets('Sankey sorts by exact amount, drops categories on the wrong side and expands splits', (
    WidgetTester tester,
  ) async {
    final Account account = createTestAccount();
    final Category salary = Data().categories.addNewCategory(name: 'Salary', type: CategoryType.income);
    final Category bonus = Data().categories.addNewCategory(name: 'Bonus', type: CategoryType.income);
    final Category rent = Data().categories.addNewCategory(name: 'Rent', type: CategoryType.expense);
    final Category refunds = Data().categories.addNewCategory(name: 'Refunds', type: CategoryType.expense);

    addTransaction(account, salary, 10.4);
    addTransaction(account, bonus, 10.9);
    addTransaction(account, rent, -100);
    addTransaction(account, refunds, 5);
    final Transaction split = addTransaction(account, null, -50);
    Data().splits.appendMoneyObject(
      TransactionSplit(
        id: 1,
        transactionId: split.uniqueId,
        categoryId: rent.uniqueId,
        payeeId: -1,
        amount: -50,
        transferId: -1,
        memo: '',
        flags: 0,
        budgetBalanceDate: null,
        data: Data(),
      ),
    );

    await pumpTestApp(tester, services, const SankeyPanel(minYear: 2024, maxYear: 2024));

    final SankeyWidget sankey = tester.widget<SankeyWidget>(find.byType(SankeyWidget));
    expect(sankey.leftEntries.map((SanKeyEntry e) => e.name), <String>['Bonus', 'Salary']);
    expect(sankey.rightEntries.map((SanKeyEntry e) => e.name), <String>['Rent']);
    expect(sankey.rightEntries.single.value, -150);
  });
}
