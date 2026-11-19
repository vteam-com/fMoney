import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/panels/layout/pending_changes_badge_widget.dart';
import 'package:money/widgets/dialogs/mutation_type_display_helper.dart';
import 'package:money/widgets/pure/theme_custom_model.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  late AppServices services;

  setUp(() {
    resetTestData();
    services = createTestServices();
  });

  tearDown(() => disposeTestServices(services));

  /// Returns the colour of the badge counter reading [text].
  Color? counterColor(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style?.color;

  testWidgets('the badge shows the counts it is given, in the theme colour of each kind of change', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      services,
      const BadgePendingChanges(itemsAdded: 2, itemsChanged: 0, itemsDeleted: 1),
    );
    final BuildContext context = tester.element(find.byType(BadgePendingChanges));

    expect(DataFileController.to.trackMutations.numberOfChanges(), 0);
    expect(counterColor(tester, '+2'), context.colorTheme.getColorForState(ColorState.success));
    expect(counterColor(tester, '-1'), context.colorTheme.getColorForState(ColorState.error));
    expect(find.textContaining('='), findsNothing);
    final BadgePendingChanges badge = tester.widget<BadgePendingChanges>(find.byType(BadgePendingChanges));
    expect(badge.getTooltipText(), startsWith('${AppL10n.tr(AppTranslationKeys.mutationAdded)}: 2\n'));
  });

  testWidgets('the shared badge builder follows the tracked changes', (WidgetTester tester) async {
    await pumpTestApp(tester, services, buildPendingChangesBadge(DataFileController.to));
    expect(find.byType(ElevatedButton), findsNothing);

    DataFileController.to.trackMutations.increaseNumber(increaseChanged: 3);
    await tester.pump();

    expect(find.text('=3'), findsOneWidget);
  });

  testWidgets('each pending kind of change has its own theme colour, label and prefix', (WidgetTester tester) async {
    await pumpTestApp(tester, services, const SizedBox());
    final BuildContext context = tester.element(find.byType(SizedBox));

    expect(pendingMutationTypes.map((MutationType type) => type.prefix), <String>['+', '=', '-']);
    expect(pendingMutationTypes.map((MutationType type) => AppL10n.tr(type.labelKey)), <String>[
      AppL10n.tr(AppTranslationKeys.mutationAdded),
      AppL10n.tr(AppTranslationKeys.mutationModified),
      AppL10n.tr(AppTranslationKeys.mutationDeleted),
    ]);
    expect(MutationType.changed.getColor(context), context.colorTheme.getColorForState(ColorState.warning));
    expect(MutationType.none.getColor(context), Colors.transparent);
    expect(MutationType.none.labelKey, isEmpty);
    expect(MutationType.none.prefix, isEmpty);
  });
}
