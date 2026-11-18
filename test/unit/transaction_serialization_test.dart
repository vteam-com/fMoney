import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_domain.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';

void main() {
  setUp(() {
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
  });

  group('Transaction persistence', () {
    test('ReconciledDate and BudgetBalanceDate are saved under their own columns', () {
      final DateTime reconciled = DateTime(2024, 3, 15);
      final DateTime budgetBalance = DateTime(2024, 4, 1);

      final Transaction transaction = Transaction(date: DateTime(2024, 3, 10));
      transaction.fieldReconciledDate.value = reconciled;
      transaction.fieldBudgetBalanceDate.value = budgetBalance;

      final MyJson json = transaction.getPersistableJSon();

      // same text format as MyMoney.Net writes
      expect(json[SharedDomainStrings.domainString116], '2024-03-15 00:00:00');
      expect(json[SharedDomainStrings.domainString025], '2024-04-01 00:00:00');

      final Transaction reloaded = Transaction.fromJSon(json, 0);
      expect(reloaded.fieldReconciledDate.value, reconciled);
      expect(reloaded.fieldBudgetBalanceDate.value, budgetBalance);
    });
  });
}
