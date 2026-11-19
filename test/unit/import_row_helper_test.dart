import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/views/imports/shared/import_row_helper.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';

void main() {
  group('normalizeForPlaceholderCheck', () {
    test('lower-cases and collapses punctuation into single spaces', () {
      expect(normalizeForPlaceholderCheck('  No--Description!! '), 'no description');
    });
  });

  group('isDescriptionPlaceholder', () {
    test('treats empty text and "no description" variants as placeholders', () {
      expect(isDescriptionPlaceholder(''), isTrue);
      expect(isDescriptionPlaceholder('  - '), isTrue);
      expect(isDescriptionPlaceholder('No Description'), isTrue);
      expect(isDescriptionPlaceholder('no_description'), isTrue);
    });

    test('keeps real descriptions', () {
      expect(isDescriptionPlaceholder('Coffee shop'), isFalse);
    });
  });

  group('showSkippedRowsWarning', () {
    setUp(SnackBarService.clearQueue);

    testWidgets('shows how many rows were imported and skipped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: AppRouter.navigatorKey,
          scaffoldMessengerKey: SnackBarService.scaffoldKey,
          home: const Scaffold(),
        ),
      );

      showSkippedRowsWarning(fileType: 'PDF', imported: 3, skipped: 2);
      await tester.pump();

      final String message = AppL10n.tr(
        AppTranslationKeys.importRowsParsedAndSkipped,
        params: <String, String>{'fileType': 'PDF', 'imported': '3', 'skipped': '2'},
      );
      expect(find.text(message), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 10));
    });

    testWidgets('shows nothing when no row was skipped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: AppRouter.navigatorKey,
          scaffoldMessengerKey: SnackBarService.scaffoldKey,
          home: const Scaffold(),
        ),
      );

      showSkippedRowsWarning(fileType: 'CSV', imported: 3, skipped: 0);
      await tester.pump();

      expect(find.byKey(const Key('key_snackbar')), findsNothing);
    });
  });
}
