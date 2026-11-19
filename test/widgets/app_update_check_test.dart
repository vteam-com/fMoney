import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/generated_app_version_data.dart';
import 'package:money/helpers/github_release_model.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/main.dart';
import 'package:money/widgets/components/app_update_banner_widget.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/state/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A release tagged [tagName] with an archive for every desktop platform.
GitHubRelease _release(String tagName) => GitHubRelease(
  tagName: tagName,
  pageUrl: 'https://example.invalid/release',
  assetUrls: <String, String>{
    for (final String key in <String>[
      SharedStrings.platformKeyMacos,
      SharedStrings.platformKeyWindows,
      SharedStrings.platformKeyLinux,
    ])
      key: 'https://example.invalid/$key.zip',
  },
);

void main() {
  tearDown(() {
    SnackBarService.clearQueue();
    ThemeController.instance = null;
    PreferenceController.instance = null;
  });

  /// Pumps a page laid out like the app: snack bars and banners go through MaterialApp's messenger.
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppRouter.navigatorKey,
        scaffoldMessengerKey: SnackBarService.scaffoldKey,
        theme: ThemeController().themeData,
        home: const Scaffold(body: Text('home')),
      ),
    );
  }

  /// The banner text for an update to [version].
  String updateMessage(String version) => AppL10n.tr(
    AppTranslationKeys.updateAvailableMessage,
    params: <String, String>{'version': version, 'currentVersion': GeneratedAppVersionData.version},
  );

  testWidgets('a newer release shows the update banner, once even when checked twice', (WidgetTester tester) async {
    await pumpPage(tester);

    showUpdateCheckResult(_release('v999.0.0'), fromMenu: true);
    showUpdateCheckResult(_release('v999.0.0'), fromMenu: true);
    await tester.pumpAndSettle();

    expect(find.text(updateMessage('999.0.0')), findsOneWidget);
    expect(find.text(AppL10n.tr(AppTranslationKeys.download)), findsOneWidget, reason: 'a test build cannot install');
  });

  testWidgets('from the menu, says when the app is up to date', (WidgetTester tester) async {
    await pumpPage(tester);

    showUpdateCheckResult(_release('v${GeneratedAppVersionData.version}'), fromMenu: true);
    await tester.pump();

    expect(
      find.text(
        AppL10n.tr(
          AppTranslationKeys.appIsUpToDate,
          params: <String, String>{'version': GeneratedAppVersionData.version},
        ),
      ),
      findsOneWidget,
    );
    SnackBarService.clearQueue();
    await tester.pumpAndSettle(const Duration(seconds: 10));
  });

  testWidgets('from the menu, says when GitHub could not be reached', (WidgetTester tester) async {
    await pumpPage(tester);

    showUpdateCheckResult(null, fromMenu: true);
    await tester.pump();

    expect(find.text(AppL10n.tr(AppTranslationKeys.updateCheckFailed)), findsOneWidget);
    SnackBarService.clearQueue();
    await tester.pumpAndSettle(const Duration(seconds: 10));
  });

  testWidgets('the launch check stays quiet when there is no update', (WidgetTester tester) async {
    await pumpPage(tester);

    showUpdateCheckResult(_release('v${GeneratedAppVersionData.version}'), fromMenu: false);
    showUpdateCheckResult(null, fromMenu: false);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('the app gives snack bars and banners a Scaffold to show in', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(MyApp());
    await tester.pump();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).scaffoldMessengerKey,
      same(SnackBarService.scaffoldKey),
    );
    // let the startup timers finish once the app is gone
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 1));
  });
}
