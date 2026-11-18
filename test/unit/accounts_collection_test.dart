import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';

void main() {
  setUp(() {
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
  });

  tearDown(() {
    Data().clearExistingData();
    DataFileController.instance = null;
  });

  test('loading links investments for every investment account type, including retirement', () {
    for (final AccountType type in <AccountType>[
      AccountType.investment,
      AccountType.moneyMarket,
      AccountType.retirement,
    ]) {
      final Account account = Data().accounts.appendNewMoneyObject(
        Account()..fieldType.value = type,
        fireNotification: false,
      ) as Account;
      final Transaction transaction = Transaction(date: DateTime(2024, 1, 15))..fieldAccountId.value = account.uniqueId;
      Data().appendNewTransaction(transaction, fireNotification: false);
      final Investment investment = Investment(
        id: transaction.uniqueId,
        security: -1,
        unitPrice: 10,
        units: 5,
        investmentType: 0,
        tradeType: 0,
        data: Data(),
      );
      Data().investments.appendMoneyObject(investment);

      Data().accounts.onAllDataLoaded();

      expect(transaction.instanceOfInvestment, same(investment), reason: type.name);
    }
  });
}
