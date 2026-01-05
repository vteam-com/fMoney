import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:money/controller/data_controller.dart';
import 'package:money/controller/my_window_manager.dart';
import 'package:money/controller/preferences_controller.dart';
import 'package:money/controller/theme_controller.dart';
import 'package:money/helpers/app_intents.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/import/import_transactions_from_text.dart';
import 'package:money/views/data/data.dart';
import 'package:money/views/home/home_routes.dart';
import 'package:money/views/platforms/platforms_routes.dart';
import 'package:money/views/policies/policy_routes.dart';
import 'package:money/views/settings/settings_routes.dart';
import 'package:money/views/splash_page.dart';
import 'package:money/views/welcome/welcome_page.dart';
import 'package:money/views/welcome/welcome_routes.dart';
import 'package:money/widgets/snack_bar.dart';

import 'helpers/application_bindings.dart';
import 'widgets/misc_widgets.dart';

/// The main entry point for the MoneyFlutter application.
/// Sets up the app structure, theming, and initial routes.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MyWindowManager.setupMainWindow();

  runApp(MyApp());
}

/// Root widget of the application.
/// Configures the overall app theme and initial route.
class MyApp extends StatelessWidget {
  MyApp({super.key});

  final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    RebalanceIntent: CallbackAction<RebalanceIntent>(
      onInvoke: (RebalanceIntent intent) {
        Data().recalculateBalances();
        SnackBarService.displayInfo(
          message: 'Balances recalculated',
          title: 'Rebalance',
        );
        return null;
      },
    ),
    ZoomInIntent: CallbackAction<ZoomInIntent>(
      onInvoke: (ZoomInIntent intent) {
        ThemeController.to.fontScaleIncrease();
        return null;
      },
    ),
    ZoomOutIntent: CallbackAction<ZoomOutIntent>(
      onInvoke: (ZoomOutIntent intent) {
        ThemeController.to.fontScaleDecrease();
        return null;
      },
    ),
    ZoomResetIntent: CallbackAction<ZoomResetIntent>(
      onInvoke: (ZoomResetIntent intent) {
        ThemeController.to.setFontScaleTo(1);
        return null;
      },
    ),

    NewTransactionIntent: CallbackAction<NewTransactionIntent>(
      onInvoke: (NewTransactionIntent intent) {
        showImportTransactionsFromTextInput(Get.context!);
        return null;
      },
    ),
  };

  final Map<ShortcutActivator, Intent> _shortcuts = <ShortcutActivator, Intent>{
    ...MyApp._dualShortcut(LogicalKeyboardKey.keyR, const RebalanceIntent()),
    ...MyApp._dualShortcut(LogicalKeyboardKey.equal, const ZoomInIntent()),
    ...MyApp._dualShortcut(LogicalKeyboardKey.minus, const ZoomOutIntent()),
    ...MyApp._dualShortcut(LogicalKeyboardKey.digit0, const ZoomResetIntent()),
    ...MyApp._dualShortcut(LogicalKeyboardKey.keyT, const NewTransactionIntent()),
  };

  final DataController dataController = Get.put(DataController());

  final ListControllerMain listControllerMain = Get.put(ListControllerMain());

  final ListControllerSidePanel listControllerSidePanel = Get.put(
    ListControllerSidePanel(),
  );

  final PreferenceController preferenceController = Get.put(
    PreferenceController(),
  );

  final ThemeController themeController = Get.put(ThemeController());

  @override
  Widget build(BuildContext context) {
    // Get.updateLocale(const Locale('en', 'US'));

    // Cache the S/M/L width for Widget that do not have access to BuildContext
    themeController.isDeviceWidthSmall.value = context.isWidthSmall;
    themeController.isDeviceWidthMedium.value = context.isWidthMedium;
    themeController.isDeviceWidthLarge.value = context.isWidthLarge;

    return Obx(() {
      final String k = preferenceController.getUniqueState;

      return Shortcuts(
        shortcuts: _shortcuts,
        child: Actions(
          actions: _actions,
          child: Focus(
            autofocus: true,
            child: ScaffoldMessenger(
              key: SnackBarService.scaffoldKey,
              child: GetMaterialApp(
                key: Key(k),
                debugShowCheckedModeBanner: false,
                theme: themeController.themeDataLight,
                darkTheme: themeController.themeDataDark,
                themeMode: themeController.isDarkTheme.value ? ThemeMode.dark : ThemeMode.light,
                title: 'fMoney by VTeam',
                initialBinding: ApplicationBindings(),
                initialRoute: '/',
                getPages: <GetPage<dynamic>>[
                  GetPage<dynamic>(
                    name: '/',
                    page: () {
                      final PreferenceController preferenceController = Get.find();
                      if (preferenceController.isReady.value) {
                        return const WelcomePage();
                      }
                      return const SplashScreen();
                    },
                  ),
                  ...HomeRoutes.routes,
                  ...WelcomeRoutes.routes,
                  ...SettingsRoutes.routes,
                  ...PlatformsRoutes.routes,
                  ...PolicyRoutes.routes,
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  static Map<ShortcutActivator, Intent> _dualShortcut(LogicalKeyboardKey key, Intent intent) {
    return <ShortcutActivator, Intent>{
      LogicalKeySet(LogicalKeyboardKey.control, key): intent,
      LogicalKeySet(LogicalKeyboardKey.meta, key): intent,
    };
  }
}
