// ignore: fcheck_one_class_per_file
import 'package:flutter/widgets.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/state/theme_controller.dart';

/// Holds the app-scoped controller instances
class AppServices {
  /// Creates a bundle of long-lived controller instances for the app.
  AppServices({
    required this.listControllerMain,
    required this.listControllerSidePanel,
    required this.preferenceController,
    required this.themeController,
  });

  /// Controller for scrolling state in the main list area.
  final ListControllerMain listControllerMain;

  /// Controller for scrolling state in the side panel area.
  final ListControllerSidePanel listControllerSidePanel;

  /// Controller for persisted user preferences.
  final PreferenceController preferenceController;

  /// Controller for theme and window-size state.
  final ThemeController themeController;
}

/// Exposes [AppServices] to the widget tree using Flutter's inherited widget system.
class AppScope extends InheritedWidget {
  /// Creates an [AppScope] with the provided app services.
  const AppScope({
    super.key,
    required this.services,
    required super.child,
  });

  /// The app-scoped services exposed to descendants.
  final AppServices services;

  static AppServices? _instance;

  /// Returns the nearest [AppServices] from the widget tree.
  static AppServices of(BuildContext context) {
    final AppScope? scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree.');
    return scope!.services;
  }

  /// Returns the registered app services for non-widget callers in the UI layer.
  static AppServices get instance {
    assert(_instance != null, 'AppScope instance is not available yet.');
    return _instance!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => !identical(oldWidget.services, services);

  /// Registers the current app services bundle for non-widget callers.
  static void register(AppServices services) {
    _instance = services;
  }
}
