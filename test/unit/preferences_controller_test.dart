import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/state/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the saved text zoom is restored at launch', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{settingKeyTextScale: 1.5});
    final PreferenceController controller = PreferenceController();

    await controller.init();

    expect(controller.textScale, 1.5);
  });

  test('a stale saved view index falls back to the default instead of throwing', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      settingKeyCashflowView: 99,
      settingKeyBudgetViewAsIncomes: -1,
    });
    final PreferenceController controller = PreferenceController();

    await controller.init();

    expect(controller.cashflowViewAs, CashflowViewAs.sankey);
    expect(controller.budgetViewAsForIncomes, BudgetViewAs.list);
  });

  test('the net worth event threshold is saved and restored at launch', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final PreferenceController controller = PreferenceController();
    await controller.init();

    controller.setNetWorthEventThreshold(3);

    final PreferenceController relaunched = PreferenceController();
    await relaunched.init();
    expect(relaunched.netWorthEventThreshold, 3);
  });

  test('the trend asset-accounts choice is saved and restored at launch', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final PreferenceController controller = PreferenceController();
    await controller.init();

    controller.setTrendIncludeAssetAccounts(true);

    final PreferenceController relaunched = PreferenceController();
    await relaunched.init();
    expect(relaunched.trendIncludeAssetAccounts, isTrue);
  });

  test('the locale accepts supported languages and falls back to English otherwise', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final PreferenceController controller = PreferenceController();
    await controller.init();

    controller.localeCode = 'fr';
    expect(controller.localeCode, 'fr');
    controller.localeCode = 'xx';
    expect(controller.localeCode, 'en');
  });

  test('the theme is saved to the attached preference controller it was loaded from', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final PreferenceController attached = PreferenceController();
    await attached.init();
    // A newer, never-initialized controller becomes PreferenceController.to and cannot save anything.
    PreferenceController();
    final ThemeController themeController = ThemeController()..attachPreferenceController(attached);

    themeController.isDarkTheme = true;
    await themeController.saveThemeToPreferences();

    expect(attached.getBool(settingKeyDarkMode), isTrue);
    PreferenceController.instance = null;
    ThemeController.instance = null;
  });
}
