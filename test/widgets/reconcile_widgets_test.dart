import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/reconcile_service.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/views/panels/dialogs/reconcile_dialog.dart';
import 'package:money/views/panels/list/reconcile_bar_widget.dart';

/// Creates and appends a checking account fixture with an opening balance of 100.
Account _createAccount() {
  final Account account = Account();
  account.fieldName.value = 'Checking';
  account.fieldCurrency.value = 'USD';
  account.fieldOpeningBalance.value.setAmount(100);
  return Data().accounts.appendNewMoneyObject(account, fireNotification: false) as Account;
}

void main() {
  late Account checking;

  setUp(() {
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
    checking = _createAccount();
  });

  testWidgets('the dialog starts a reconciliation once the statement date and balance are valid', (
    WidgetTester tester,
  ) async {
    ReconcileService? started;
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    showReconcileDialog(
      context: tester.element(find.byType(Scaffold)),
      account: checking,
      data: Data(),
      onStart: (ReconcileService session) => started = session,
    );
    await tester.pumpAndSettle();

    expect(find.text('Never'), findsOneWidget);
    expect(find.text('Start'), findsNothing);

    final Finder dateInput = find.byType(TextFormField).first;
    final Finder balanceInput = find.byType(TextFormField).last;
    await tester.enterText(balanceInput, '1,234.50');
    await tester.pump();
    expect(find.text('Start'), findsOneWidget);

    await tester.enterText(dateInput, 'not a date');
    await tester.pump();
    expect(find.text('Start'), findsNothing);

    await tester.enterText(dateInput, '2024-05-31');
    await tester.pump();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(started, isNotNull);
    expect(started!.account, same(checking));
    expect(started!.statementDate, DateTime(2024, 5, 31));
    expect(started!.statementBalance, 1234.50);
    expect(find.byType(ReconcileDialog), findsNothing);
  });

  testWidgets('the bar offers Finish only once the cleared balance matches the statement', (
    WidgetTester tester,
  ) async {
    final Transaction transaction = Transaction(
      date: DateTime(2024, 5, 10),
      status: TransactionStatus.none,
      accountId: checking.uniqueId,
    );
    transaction.fieldAmount.value.setAmount(20);
    Data().appendNewTransaction(transaction, fireNotification: false);

    int cancelled = 0;
    int finished = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReconcileBar(
            session: ReconcileService(
              account: checking,
              data: Data(),
              statementDate: DateTime(2024, 5, 31),
              statementBalance: 120,
            ),
            onCancel: () => cancelled++,
            onFinish: () => finished++,
          ),
        ),
      ),
    );

    expect(find.text(dateToString(DateTime(2024, 5, 31))), findsOneWidget);
    expect(find.text('Finish'), findsNothing);

    // What the status column does when the user clicks it
    transaction.mutateField(transaction.fieldStatus.name, TransactionStatus.cleared, false);
    await tester.pump();
    expect(find.text('Finish'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.tap(find.text('Cancel'));
    expect(finished, 1);
    expect(cancelled, 1);
  });
}
