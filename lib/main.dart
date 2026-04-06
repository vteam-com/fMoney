import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:money/helpers/app_intents.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_router.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/helpers/my_window_manager.dart';
import 'package:money/l10n/app_localizations.dart';
import 'package:money/shared/domain/data_domain.dart';
import 'package:money/shared/presentation/app_scope.dart';
import 'package:money/shared/presentation/provider_data_file_controller.dart';
import 'package:money/views/imports/import_transactions_from_text.dart';
import 'package:money/views/pages/about_page.dart';
import 'package:money/views/pages/home_page.dart';
import 'package:money/views/pages/platforms_page.dart';
import 'package:money/views/pages/policy_page.dart';
import 'package:money/views/pages/settings_page.dart';
import 'package:money/views/pages/splash_page.dart';
import 'package:money/views/pages/welcome_page.dart';
import 'package:money/widgets/pure/scale_down.dart';
import 'package:money/widgets/pure/snack_bar.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/state/theme_controller.dart';

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
  MyApp({super.key}) {
    DataFileController();
    _services.themeController.attachPreferenceController(
      _services.preferenceController,
    );
    _services.preferenceController.start();
  }
  final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    RebalanceIntent: CallbackAction<RebalanceIntent>(
      onInvoke: (RebalanceIntent _) {
        Data().recalculateBalances();
        SnackBarService.displayInfo(
          message: AppL10n.tr(AppTranslationKeys.success),
          title: AppL10n.tr(AppTranslationKeys.rebalanceMenuItem),
        );
        return null;
      },
    ),
    ZoomInIntent: CallbackAction<ZoomInIntent>(
      onInvoke: (ZoomInIntent _) {
        ThemeController.to.fontScaleIncrease();
        return null;
      },
    ),
    ZoomOutIntent: CallbackAction<ZoomOutIntent>(
      onInvoke: (ZoomOutIntent _) {
        ThemeController.to.fontScaleDecrease();
        return null;
      },
    ),
    ZoomResetIntent: CallbackAction<ZoomResetIntent>(
      onInvoke: (ZoomResetIntent _) {
        ThemeController.to.setFontScaleTo(1);
        return null;
      },
    ),

    NewTransactionIntent: CallbackAction<NewTransactionIntent>(
      onInvoke: (NewTransactionIntent _) {
        showImportTransactionsFromTextInput(AppRouter.context!);
        return null;
      },
    ),
  };
  final AppServices _services = AppServices(
    listControllerMain: ListControllerMain(),
    listControllerSidePanel: ListControllerSidePanel(),
    preferenceController: PreferenceController(),
    themeController: ThemeController(),
  );
  final Map<ShortcutActivator, Intent> _shortcuts = <ShortcutActivator, Intent>{
    ...MyApp._dualShortcut(LogicalKeyboardKey.keyR, const RebalanceIntent()),
    ...MyApp._dualShortcut(LogicalKeyboardKey.equal, const ZoomInIntent()),
    ...MyApp._dualShortcut(LogicalKeyboardKey.minus, const ZoomOutIntent()),
    ...MyApp._dualShortcut(LogicalKeyboardKey.digit0, const ZoomResetIntent()),
    ...MyApp._dualShortcut(LogicalKeyboardKey.keyT, const NewTransactionIntent()),
  };
  @override
  Widget build(BuildContext context) {
    AppScope.register(_services);

    // Cache the S/M/L width for Widget that do not have access to BuildContext
    _services.themeController.setDeviceWidthBreakpoints(
      isSmall: context.isWidthSmall,
      isMedium: context.isWidthMedium,
      isLarge: context.isWidthLarge,
    );

    return AppScope(
      services: _services,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _services.preferenceController,
          _services.themeController,
        ]),
        builder: (BuildContext _, Widget? _) {
          final Widget app = _WebStartupFocusGuard(
            child: ScaffoldMessenger(
              key: SnackBarService.scaffoldKey,
              child: MaterialApp(
                navigatorKey: AppRouter.navigatorKey,
                debugShowCheckedModeBanner: false,
                theme: _services.themeController.themeDataLight,
                darkTheme: _services.themeController.themeDataDark,
                themeMode: _services.themeController.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
                onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)!.appTitle,
                locale: Locale(_services.preferenceController.localeCode),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                initialRoute: '/',
                onGenerateRoute: _onGenerateRoute,
              ),
            ),
          );

          return Shortcuts(
            shortcuts: _shortcuts,
            child: Actions(
              actions: _actions,
              child: kIsWeb
                  ? app
                  : Focus(
                      autofocus: true,
                      child: app,
                    ),
            ),
          );
        },
      ),
    );
  }

  static Map<ShortcutActivator, Intent> _dualShortcut(LogicalKeyboardKey key, Intent intent) {
    return <ShortcutActivator, Intent>{
      LogicalKeySet(LogicalKeyboardKey.control, key): intent,
      LogicalKeySet(LogicalKeyboardKey.meta, key): intent,
    };
  }

  /// Builds named routes for the standard Flutter navigator.
  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final String? routeName = settings.name;
    late final Widget page;
    if (routeName == '/') {
      page = _services.preferenceController.isReady ? const WelcomePage() : const SplashScreen();
    } else if (routeName == Constants.routeHomePage) {
      page = const HomePage();
    } else if (routeName == Constants.routeWelcomePage) {
      page = const WelcomePage();
    } else if (routeName == Constants.routeSettingsPage) {
      page = const SettingsPage();
    } else if (routeName == Constants.routeInstallPlatformsPage) {
      page = const PlatformsPage();
    } else if (routeName == Constants.routePolicyPage) {
      page = const PolicyPage();
    } else if (routeName == Constants.routeAboutPage) {
      page = const AboutPage();
    } else {
      page = const WelcomePage();
    }

    return MaterialPageRoute<dynamic>(
      builder: (BuildContext _) => page,
      settings: settings,
    );
  }
}

/// Delays focus eligibility on web until after the first frame has completed.
class _WebStartupFocusGuard extends StatefulWidget {
  /// Creates a focus guard for app startup.
  const _WebStartupFocusGuard({required this.child});

  /// The subtree that should be protected from early web focus traversal.
  final Widget child;

  @override
  State<_WebStartupFocusGuard> createState() => _WebStartupFocusGuardState();
}

class _WebStartupFocusGuardState extends State<_WebStartupFocusGuard> {
  bool _allowFocus = !kIsWeb;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _allowFocus = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      excluding: !_allowFocus,
      child: widget.child,
    );
  }
}
