import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transfer_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/home/transfers/transfers_view.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/widgets/pure/center_message_widget.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/state/theme_controller.dart';

/// Hosts [ViewTransfers] with app-scope services required by list views.
class TransfersTestHost extends StatelessWidget {
  /// Creates a host wrapper with the provided [services].
  const TransfersTestHost({
    required this.services,
    super.key,
  });

  /// Shared services for app-scoped controllers.
  final AppServices services;

  @override
  Widget build(final BuildContext context) {
    return AppScope(
      services: services,
      child: MaterialApp(
        navigatorKey: AppRouter.navigatorKey,
        theme: services.themeController.themeData,
        home: const Scaffold(
          body: SizedBox(
            height: 700,
            width: 1100,
            child: ViewTransfers(),
          ),
        ),
      ),
    );
  }
}

/// Creates and appends an account fixture.
Account _createAccount({
  required final String name,
  required final bool isOpen,
  final AccountType type = AccountType.checking,
}) {
  final Account account = Account();
  account.fieldName.value = name;
  account.fieldType.value = type;
  account.fieldCurrency.value = 'USD';
  account.isOpen = isOpen;
  return Data().accounts.appendNewMoneyObject(account, fireNotification: false) as Account;
}

/// Creates and appends a transaction fixture.
Transaction _createTransaction({
  required final Account account,
  required final double amount,
  required final DateTime date,
  final int transferId = -1,
}) {
  final Transaction transaction = Transaction(date: date);
  transaction.fieldAccountId.value = account.uniqueId;
  transaction.instanceOfAccount = account;
  transaction.fieldAmount.value.setAmount(amount);
  transaction.fieldTransfer.value = transferId;
  transaction.fieldTransferSplit.value = -1;
  Data().appendNewTransaction(transaction, fireNotification: false);
  return transaction;
}

/// Pumps the transfers view and returns its state.
Future<ViewForMoneyObjectsState> _pumpTransfers(
  final WidgetTester tester,
  final AppServices services,
) async {
  await tester.pumpWidget(TransfersTestHost(services: services));
  await tester.pumpAndSettle();
  return tester.state<ViewForMoneyObjectsState>(find.byType(ViewTransfers));
}

void main() {
  late PreferenceController preferenceController;
  late ThemeController themeController;
  late ListControllerMain listControllerMain;
  late ListControllerSidePanel listControllerSidePanel;
  late AppServices services;

  setUp(() {
    Data().clearExistingData();

    preferenceController = PreferenceController();
    themeController = ThemeController();
    listControllerMain = ListControllerMain();
    listControllerSidePanel = ListControllerSidePanel();
    DataFileController.instance = DataFileController();

    services = AppServices(
      listControllerMain: listControllerMain,
      listControllerSidePanel: listControllerSidePanel,
      preferenceController: preferenceController,
      themeController: themeController,
    );
    AppScope.register(services);
  });

  tearDown(() {
    Data().clearExistingData();
    listControllerMain.dispose();
    listControllerSidePanel.dispose();
    PreferenceController.instance = null;
    ThemeController.instance = null;
    DataFileController.instance = null;
  });

  testWidgets('getList returns one transfer for a valid sender/receiver pair', (final WidgetTester tester) async {
    final ViewForMoneyObjectsState state = await _pumpTransfers(tester, services);

    final Account senderAccount = _createAccount(name: 'Checking', isOpen: true);
    final Account receiverAccount = _createAccount(name: 'Savings', isOpen: true);

    final Transaction sender = _createTransaction(
      account: senderAccount,
      amount: -200.0,
      date: DateTime(2025, 1, 10),
    );
    final Transaction receiver = _createTransaction(
      account: receiverAccount,
      amount: 200.0,
      date: DateTime(2025, 1, 10),
    );
    sender.fieldTransfer.value = receiver.uniqueId;
    receiver.fieldTransfer.value = sender.uniqueId;

    final List<Transfer> transfers = state.getList(applyFilter: false).cast<Transfer>();

    expect(transfers, hasLength(1));
    expect(transfers.first.isOrphan, isFalse);
    expect(transfers.first.source.uniqueId, equals(sender.uniqueId));
    expect(transfers.first.relatedTransaction.uniqueId, equals(receiver.uniqueId));
  });

  testWidgets('getList excludes closed account transfers unless includeClosedAccounts is enabled', (
    final WidgetTester tester,
  ) async {
    final ViewForMoneyObjectsState state = await _pumpTransfers(tester, services);

    final Account senderAccount = _createAccount(name: 'Closed A', isOpen: false);
    final Account receiverAccount = _createAccount(name: 'Closed B', isOpen: false);

    final Transaction sender = _createTransaction(
      account: senderAccount,
      amount: -100.0,
      date: DateTime(2025, 1, 11),
    );
    final Transaction receiver = _createTransaction(
      account: receiverAccount,
      amount: 100.0,
      date: DateTime(2025, 1, 11),
    );
    sender.fieldTransfer.value = receiver.uniqueId;
    receiver.fieldTransfer.value = sender.uniqueId;

    preferenceController.includeClosedAccounts = false;
    expect(state.getList(applyFilter: false), isEmpty);

    preferenceController.includeClosedAccounts = true;
    expect(state.getList(applyFilter: false), hasLength(1));
  });

  testWidgets('side panel details returns empty message and transfer details widget for selection', (
    final WidgetTester tester,
  ) async {
    final ViewForMoneyObjectsState state = await _pumpTransfers(tester, services);

    final Account senderAccount = _createAccount(name: 'Wallet', isOpen: true);
    final Account receiverAccount = _createAccount(name: 'Brokerage', isOpen: true);

    final Transaction sender = _createTransaction(
      account: senderAccount,
      amount: -50.0,
      date: DateTime(2025, 1, 12),
    );
    final Transaction receiver = _createTransaction(
      account: receiverAccount,
      amount: 50.0,
      date: DateTime(2025, 1, 12),
    );
    sender.fieldTransfer.value = receiver.uniqueId;
    receiver.fieldTransfer.value = sender.uniqueId;

    final List<Transfer> transfers = state.getList(applyFilter: false).cast<Transfer>();
    state.list = transfers;

    final SidePanelSupport support = state.getSidePanelSupport();

    expect(
      support.onDetails!(selectedIds: <int>[]),
      isA<CenterMessage>(),
    );
    expect(
      support.onDetails!(selectedIds: <int>[transfers.first.uniqueId]),
      isNot(isA<CenterMessage>()),
    );
  });

  testWidgets('magic wand scan finds disconnected transfer candidates', (
    final WidgetTester tester,
  ) async {
    await _pumpTransfers(tester, services);

    final Account fromAccount = _createAccount(name: 'Main Checking', isOpen: true);
    final Account toAccount = _createAccount(name: 'Credit Card', isOpen: true, type: AccountType.credit);

    _createTransaction(
      account: fromAccount,
      amount: -123.45,
      date: DateTime(2025, 1, 15),
      transferId: -1,
    );
    _createTransaction(
      account: toAccount,
      amount: 123.45,
      date: DateTime(2025, 1, 16),
      transferId: -1,
    );

    await tester.tap(
      find.byTooltip(AppL10n.tr(AppTranslationKeys.findMissingTransfers)),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text(AppL10n.tr(AppTranslationKeys.possibleTransferMatches)), findsOneWidget);
    expect(find.text(AppL10n.tr(AppTranslationKeys.recordATransferBetweenTwoAccounts)), findsOneWidget);
  });
}
