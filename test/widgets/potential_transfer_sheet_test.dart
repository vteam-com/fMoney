import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/entity_widgets/transaction_widgets_helper.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';

/// Creates and appends an open account fixture.
Account _createAccount(String name) {
  final Account account = Account();
  account.fieldName.value = name;
  account.fieldCurrency.value = 'USD';
  account.isOpen = true;
  return Data().accounts.appendNewMoneyObject(account, fireNotification: false) as Account;
}

/// Creates and appends a disconnected transaction fixture.
Transaction _createTransaction({required Account account, required double amount}) {
  final Transaction transaction = Transaction(date: DateTime(2025, 2, 3));
  transaction.fieldAccountId.value = account.uniqueId;
  transaction.fieldAmount.value.setAmount(amount);
  transaction.fieldTransfer.value = -1;
  transaction.fieldTransferSplit.value = -1;
  Data().appendNewTransaction(transaction, fireNotification: false);
  return transaction;
}

void main() {
  setUp(() {
    // Wires DataAccess.trackMutations and the entity widget providers.
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
  });

  tearDown(() {
    Data().clearExistingData();
    DataFileController.instance = null;
  });

  testWidgets('the payee hint opens the transfer sheet and links the best match', (WidgetTester tester) async {
    final Transaction outgoing = _createTransaction(account: _createAccount('Checking'), amount: -42);
    final Transaction incoming = _createTransaction(account: _createAccount('Savings'), amount: 42);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Builder(builder: (_) => transactionBuildPayeeOrTransferWidget(outgoing))),
      ),
    );
    await tester.tap(find.byIcon(Icons.lightbulb_outline));
    await tester.pumpAndSettle();

    expect(find.text(AppL10n.tr(AppTranslationKeys.matchingTransaction)), findsOneWidget);
    expect(find.text(AppL10n.tr(AppTranslationKeys.sender)), findsOneWidget);
    expect(find.text(AppL10n.tr(AppTranslationKeys.receiver)), findsOneWidget);

    await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.recordATransferBetweenTwoAccounts)));
    await tester.pumpAndSettle();

    expect(outgoing.fieldTransfer.value, incoming.uniqueId);
    expect(incoming.fieldTransfer.value, outgoing.uniqueId);
    expect(find.text(AppL10n.tr(AppTranslationKeys.recordATransferBetweenTwoAccounts)), findsNothing);
  });
}
