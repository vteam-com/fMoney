import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/entity_widgets/alias_widgets_helper.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/home/aliases/aliases_view.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/state/theme_controller.dart';

/// Hosts [ViewAliases] with the app-scope services list views need.
class AliasesTestHost extends StatelessWidget {
  /// Creates a host wrapper with the provided [services].
  const AliasesTestHost({required this.services, super.key});

  /// Shared services for app-scoped controllers.
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: MaterialApp(
        navigatorKey: AppRouter.navigatorKey,
        scaffoldMessengerKey: SnackBarService.scaffoldKey,
        theme: services.themeController.themeData,
        home: const Scaffold(
          body: SizedBox(height: 700, width: 1100, child: ViewAliases()),
        ),
      ),
    );
  }
}

/// Returns the picker built for [field] of [alias], with an [onEdited] that records it was called.
PickerEditBox _picker(Alias alias, Field<dynamic> field, List<bool> edits) =>
    buildAliasFieldEditWidget(alias, field, edits.add)! as PickerEditBox;

void main() {
  late ListControllerMain listControllerMain;
  late ListControllerSidePanel listControllerSidePanel;
  late AppServices services;

  setUp(() {
    Data().clearExistingData();
    listControllerMain = ListControllerMain();
    listControllerSidePanel = ListControllerSidePanel();
    DataFileController.instance = DataFileController();
    services = AppServices(
      listControllerMain: listControllerMain,
      listControllerSidePanel: listControllerSidePanel,
      preferenceController: PreferenceController(),
      themeController: ThemeController(),
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

  testWidgets('the add button creates an alias and opens it with payee and type pickers', (WidgetTester tester) async {
    await tester.pumpWidget(AliasesTestHost(services: services));
    await tester.pumpAndSettle();
    expect(Data().aliases.length, 0);

    await tester.tap(find.byKey(Constants.keyAddNewItem));
    await tester.pumpAndSettle();

    expect(Data().aliases.length, 1);
    expect(find.byKey(const Key('key_pick_alias_payee')), findsOneWidget);
    expect(find.byKey(const Key('key_pick_alias_type')), findsOneWidget);
  });

  testWidgets('the apply button moves matching transactions to the selected alias payee', (WidgetTester tester) async {
    final Payee att = Data().payees.getOrCreate('AT&T');
    final Alias alias = Data().aliases.appendNewMoneyObject(
      Alias(id: -1, pattern: 'ATT.*', flags: AliasType.regex.index, payeeId: att.uniqueId, data: Data()),
      fireNotification: false,
    ) as Alias;
    final Account account = Account();
    account.fieldName.value = 'Checking';
    Data().accounts.appendNewMoneyObject(account, fireNotification: false);
    final Transaction transaction = Transaction(date: DateTime(2024));
    transaction.fieldAccountId.value = account.uniqueId;
    transaction.fieldPayee.value = Data().payees.getOrCreate('ATT*BILL').uniqueId;
    transaction.fieldTransfer.value = -1;
    Data().appendNewTransaction(transaction, fireNotification: false);

    await tester.pumpWidget(AliasesTestHost(services: services));
    await tester.pumpAndSettle();
    expect(find.byKey(Constants.keyApplyAliasButton), findsNothing);

    tester.state<ViewForMoneyObjectsState>(find.byType(ViewAliases)).updateListAndSelect(alias.uniqueId);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Constants.keyApplyAliasButton));
    await tester.pump();

    expect(transaction.fieldPayee.value, att.uniqueId);
    expect(
      find.text(AppL10n.tr(AppTranslationKeys.transactionsUpdatedCount, params: <String, String>{'count': '1'})),
      findsOneWidget,
    );
    SnackBarService.clearQueue();
    await tester.pumpAndSettle(const Duration(seconds: 10));
  });

  test('the payee picker selects an existing payee or creates a new one', () {
    final Payee att = Data().payees.getOrCreate('AT&T');
    final Alias alias = Data().aliases.addNewAlias();
    final List<bool> edits = <bool>[];
    final PickerEditBox picker = _picker(alias, alias.fieldPayeeId, edits);

    picker.onChanged('Not a payee');
    expect(alias.fieldPayeeId.value, -1);
    expect(edits, isEmpty);

    picker.onChanged('AT&T');
    expect(alias.fieldPayeeId.value, att.uniqueId);

    picker.onAddNew!('Verizon');
    expect(Data().payees.getByName('Verizon')!.uniqueId, alias.fieldPayeeId.value);
    expect(edits, <bool>[true, true]);
  });

  test('the type picker switches between plain and regex', () {
    final Alias alias = Data().aliases.addNewAlias();
    final List<bool> edits = <bool>[];
    final PickerEditBox picker = _picker(alias, alias.fieldFlags, edits);

    picker.onChanged(getAliasTypeAsString(AliasType.regex));
    expect(alias.type, AliasType.regex);
    picker.onChanged(getAliasTypeAsString(AliasType.none));
    expect(alias.type, AliasType.none);
    expect(edits, <bool>[true, true]);
  });

  test('the pattern keeps the generic text editor', () {
    final Alias alias = Data().aliases.addNewAlias();
    expect(buildAliasFieldEditWidget(alias, alias.fieldPattern, (bool _) {}), isNull);
  });
}
