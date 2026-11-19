import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/shared/presentation/widgets/money_object_card_widget.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  late AppServices services;

  setUp(() {
    resetTestData();
    services = createTestServices();
  });

  tearDown(() => disposeTestServices(services));

  testWidgets('the card actions are the shared keyed buttons, with tooltips', (WidgetTester tester) async {
    final Account account = createTestAccount();
    final List<String> calls = <String>[];
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await pumpTestApp(
      tester,
      services,
      MoneyObjectCard(
        title: 'Account',
        moneyObject: account,
        onMergeWith: (BuildContext _, DataObject? _) => calls.add('merge'),
        onEdit: (BuildContext _, List<DataObject> _) => calls.add('edit'),
        onDelete: (BuildContext _, List<DataObject> _) => calls.add('delete'),
      ),
    );

    for (final Key key in <Key>[
      Constants.keyMergeButton,
      Constants.keyEditSelectedItems,
      Constants.keyDeleteSelectedItems,
    ]) {
      expect(tester.widget<IconButton>(find.byKey(key)).tooltip, isNotEmpty);
      await tester.tap(find.byKey(key));
    }
    expect(calls, <String>['merge', 'edit', 'delete']);

    final Finder copyButton = find.byKey(const Key('key_copy_money_object_card'));
    expect(tester.widget<IconButton>(copyButton).tooltip, AppL10n.tr(AppTranslationKeys.copyToClipboard));
    await tester.tap(copyButton);
    await tester.pump();
    expect(copied, account.getPersistableJSon().toString());
    await dismissSnackBars(tester);
  });
}
