import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/aliases_collection.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/entity_widgets/alias_widgets_helper.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/home/aliases/aliases_view.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';

import '../helpers/test_fixtures_helper.dart';

/// Returns the picker built for [field] of [alias], with an [onEdited] that records it was called.
PickerEditBox _picker(Alias alias, Field<dynamic> field, List<bool> edits) =>
    buildAliasFieldEditWidget(alias, field, edits.add)! as PickerEditBox;

void main() {
  late AppServices services;

  setUp(() {
    resetTestData();
    services = createTestServices();
  });

  tearDown(() => disposeTestServices(services));

  testWidgets('the add button creates an alias and opens it with payee and type pickers', (WidgetTester tester) async {
    await pumpTestApp(tester, services, const ViewAliases());
    expect(Data().aliases.length, 0);

    await tester.tap(find.byKey(Constants.keyAddNewItem));
    await tester.pumpAndSettle();

    expect(Data().aliases.length, 1);
    expect(find.byKey(const Key('key_pick_alias_payee')), findsOneWidget);
    expect(find.byKey(const Key('key_pick_alias_type')), findsOneWidget);
  });

  testWidgets('the apply button moves matching transactions to the selected alias payee', (WidgetTester tester) async {
    final Payee att = Data().payees.getOrCreate('AT&T');
    final Alias alias = createTestAlias('ATT.*', att);
    final Transaction transaction = createTestTransaction(createTestAccount(), 'ATT*BILL');

    await pumpTestApp(tester, services, const ViewAliases());
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
    await dismissSnackBars(tester);
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

  group('grouping by payee', () {
    /// Appends a plain alias mapping [pattern] to the payee named [payeeName].
    Alias addAlias(String payeeName, String pattern) =>
        createTestAlias(pattern, Data().payees.getOrCreate(payeeName), type: AliasType.none);

    test('the payee comes first in the view, while stored fields keep their order', () {
      expect(Alias.fieldsForColumnView.definitions.map((Field<dynamic> f) => f.name), <String>[
        'Payee',
        'Pattern',
        'Flags',
        'Patterns',
      ]);
      expect(Alias.fields.definitions.map((Field<dynamic> f) => f.name), <String>['Id', 'Pattern', 'Flags', 'Payee']);
    });

    test('sorting by payee keeps each payee patterns together, in pattern order', () {
      final List<Alias> aliases = <Alias>[addAlias('B', 'z'), addAlias('A', 'y'), addAlias('B', 'a')];
      final Field<dynamic> payeeField = Alias.fieldsForColumnView.definitions.first;

      aliases.sort((Alias a, Alias b) => payeeField.sort!(a, b, true));

      expect(aliases.map((Alias a) => '${a.payeeName}:${a.fieldPattern.value}'), <String>['A:y', 'B:a', 'B:z']);
    });

    test('pattern counts and one row per payee', () {
      final Alias attB = addAlias('AT&T', 'B');
      final Alias attA = addAlias('AT&T', 'A');
      final Alias grocer = addAlias('Grocer', 'G');

      Data().aliases.updatePatternCounts();

      expect(
        <int>[attB.fieldPatternCount.value, attA.fieldPatternCount.value, grocer.fieldPatternCount.value],
        <int>[
          2,
          2,
          1,
        ],
      );
      expect(Aliases.firstPerPayee(<Alias>[attB, attA, grocer]), <Alias>[attA, grocer]);
    });

    testWidgets('the toggle collapses each payee to one row and back', (WidgetTester tester) async {
      addAlias('AT&T', 'B');
      addAlias('AT&T', 'A');
      addAlias('Grocer', 'G');
      await pumpTestApp(tester, services, const ViewAliases());
      final ViewForMoneyObjectsState state = tester.state<ViewForMoneyObjectsState>(find.byType(ViewAliases));
      expect(state.list.length, 3);

      await tester.tap(find.byKey(const Key('key_toggle_alias_rows')));
      await tester.pumpAndSettle();
      expect(state.list.length, 2);

      await tester.tap(find.byKey(const Key('key_toggle_alias_rows')));
      await tester.pumpAndSettle();
      expect(state.list.length, 3);
    });
  });
}
