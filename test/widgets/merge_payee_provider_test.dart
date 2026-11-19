import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/dialogs/merge_payees_dialog.dart';
import 'package:money/shared/presentation/entity_widgets/entity_widget_providers_model.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  late AppServices services;

  setUp(() {
    resetTestData();
    services = createTestServices();
  });

  tearDown(() => disposeTestServices(services));

  testWidgets('the Merge payee action of the transaction editor opens the merge dialog', (WidgetTester tester) async {
    final Payee payee = Data().payees.getOrCreate('Coffee', fireNotification: false);
    await pumpTestApp(
      tester,
      services,
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => EntityWidgetProviders.mergePayee!.showMergePayee<Transaction>(
            context,
            payee,
            <Transaction>[],
            Data(),
          ),
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(MergeTransactionsDialog<Transaction>), findsOneWidget);
  });
}
