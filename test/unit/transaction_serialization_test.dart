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

      expect(json[SharedDomainStrings.domainString116], reconciled.toIso8601String());
      expect(json[SharedDomainStrings.domainString025], budgetBalance.toIso8601String());

      final Transaction reloaded = Transaction.fromJSon(json, 0);
      expect(reloaded.fieldReconciledDate.value, reconciled);
      expect(reloaded.fieldBudgetBalanceDate.value, budgetBalance);
    });
  });
}
