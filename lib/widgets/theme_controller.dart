// ignore: fcheck_one_class_per_file
// ignore: fcheck_dead_code
import 'package:flutter/material.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/my_window_manager.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/pure/theme_custom.dart';

/// Represents themes.
class Themes {
  static final List<Color> themeAsColors = <Color>[
    Colors.deepPurple,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.pink,
  ];

  static final List<String> themeColorNames = <String>[
    'Purple',
    'Blue',
    'Teal',
    'Green',
    'Yellow',
    'Orange',
    'Pink',
  ];
}

const int _defaultThemeIndex = 0;
const double _fontScaleStep = 0.10;
const int _fontScalePercentFactor = 100;
const double _fontScalePercentDivisor = 100.0;
const int _fontScaleMinPercent = 40;
const int _fontScaleMaxPercent = 400;
const double _appWindowHeight = 900.0;

/// Controller for managing app theme settings including:
/// - Light/dark mode switching
/// - Primary color scheme selection
/// - Device width responsive breakpoints
/// - Font scaling
/// - Window size management
/// - Theme persistence
class ThemeController extends ChangeNotifier {
  ThemeController() {
    ThemeController.instance = this;
  }

  int colorSelected = _defaultThemeIndex;
  bool isDarkTheme = false;
  bool isDeviceWidthLarge = false;
  bool isDeviceWidthMedium = true;
  bool isDeviceWidthSmall = false;
  Color primaryColor = Colors.grey;
  PreferenceController? _preferenceController;

  /// Global access to the live theme controller.
  static ThemeController? instance;

  /// Attaches the preference controller dependency needed for theme persistence.
  void attachPreferenceController(PreferenceController preferenceController) {
    _preferenceController = preferenceController;
    loadThemeFromPreferences();
  }

  //--------------------------------------------------------
  // Font scaling

  /// Adjusts the global font scale by [delta] and persists it.
  void adjustFontScale(double delta) {
    final double newScale = PreferenceController.to.textScale + delta;
    setFontScaleTo(newScale);
  }

  /// Increases the global font scale by one step.
  void fontScaleIncrease() => adjustFontScale(_fontScaleStep);

  /// Decreases the global font scale by one step.
  void fontScaleDecrease() => adjustFontScale(-_fontScaleStep);

  /// Loads theme mode and color index from persisted preferences.
  void loadThemeFromPreferences() async {
    final PreferenceController preferenceController = _preferenceController ?? PreferenceController.to;
    if (!preferenceController.isReady) {
      await preferenceController.init();
    }
    isDarkTheme = preferenceController.getBool(
      settingKeyDarkMode,
      false,
    );
    colorSelected = preferenceController.getInt(settingKeyTheme, _defaultThemeIndex);
    updateTheme();
  }

  /// Persists theme mode and color index to preferences.
  void saveThemeToPreferences() async {
    PreferenceController.to.setBool(settingKeyDarkMode, isDarkTheme);
    PreferenceController.to.setInt(settingKeyTheme, colorSelected);
  }

  /// Sets the app window size to the predefined small width.
  void setAppSizeToSmall() => MyWindowManager.setAppWindowSize(Constants.screenWidthSmall, _appWindowHeight);

  /// Sets the app window size to the predefined medium width.
  void setAppSizeToMedium() => MyWindowManager.setAppWindowSize(Constants.screenWidthMedium, _appWindowHeight);

  /// Sets the app window size to the predefined large width.
  void setAppSizeToLarge() => MyWindowManager.setAppWindowSize(Constants.screenWidthLarge, _appWindowHeight);

  /// Attempts to set the global font scale to [newScale] and persists it.
  bool setFontScaleTo(final double newScale) {
    final int cleanValue = (newScale * _fontScalePercentFactor).round();
    if (isBetweenOrEqual(cleanValue, _fontScaleMinPercent, _fontScaleMaxPercent)) {
      PreferenceController.to.textScale = cleanValue / _fontScalePercentDivisor;

      return true;
    }
    return false;
  }

  /// Sets the active theme color by [index] and persists the choice.
  void setThemeColor(final int index) {
    colorSelected = index;
    primaryColor = themeData.colorScheme.primary;
    saveThemeToPreferences();
    updateTheme();
  }

  /// Returns the current theme data (light or dark) based on the mode.
  ThemeData get themeData => isDarkTheme ? themeDataDark : themeDataLight;

  /// Ensures [colorSelected] points to a valid index in [Themes.themeAsColors].
  void _ensureValidColorSelection() {
    if (!isIndexInRange(Themes.themeAsColors, colorSelected)) {
      colorSelected = _defaultThemeIndex;
    }
  }

  /// Builds a [ThemeData] from brightness and custom money color roles.
  ThemeData _buildThemeData({
    required Brightness brightness,
    required MoneyThemeData moneyThemeData,
  }) {
    _ensureValidColorSelection();
    return ThemeData(
      colorSchemeSeed: Themes.themeAsColors[colorSelected],
      brightness: brightness,
      extensions: <ThemeExtension<dynamic>>[
        moneyThemeData,
      ],
    );
  }

  /// Builds color-role values for [MoneyThemeData] based on [brightness].
  MoneyThemeData _buildMoneyThemeData(Brightness brightness) {
    final bool isDarkBrightness = brightness == Brightness.dark;
    Color pickByBrightness(Color dark, Color light) => isDarkBrightness ? dark : light;

    return MoneyThemeData(
      success: pickByBrightness(Colors.green.shade300, Colors.green.shade800),
      warning: pickByBrightness(Colors.amber.shade300, Colors.amber.shade800),
      error: pickByBrightness(Colors.red.shade200, Colors.red.shade800),
      disabled: pickByBrightness(Colors.grey.shade500, Colors.grey.shade600),
      quantityPositive: pickByBrightness(Colors.blue.shade300, Colors.blue.shade600),
      quantityNegative: pickByBrightness(Colors.orange.shade300, Colors.orange.shade600),
      info: pickByBrightness(Colors.blue.shade200, Colors.blue.shade700),
    );
  }

  /// Builds and returns the dark theme data for the selected color seed.
  ThemeData get themeDataDark {
    return _buildThemeData(
      brightness: Brightness.dark,
      moneyThemeData: _buildMoneyThemeData(Brightness.dark),
    );
  }

  /// Builds and returns the light theme data for the selected color seed.
  ThemeData get themeDataLight {
    return _buildThemeData(
      brightness: Brightness.light,
      moneyThemeData: _buildMoneyThemeData(Brightness.light),
    );
  }

  /// Singleton accessor for the registered ThemeController instance.
  static ThemeController get to => instance ??= ThemeController();

  /// Toggles between light and dark theme modes and persists the change.
  void toggleThemeMode() {
    isDarkTheme = !isDarkTheme;
    primaryColor = themeData.colorScheme.primary;
    saveThemeToPreferences();
    updateTheme();
  }

  /// this will rebuild the app to use the current theme
  void updateTheme() {
    primaryColor = themeData.colorScheme.primary;
    notifyListeners();
  }

  /// Stores the latest responsive width classification for non-widget callers.
  void setDeviceWidthBreakpoints({
    required bool isSmall,
    required bool isMedium,
    required bool isLarge,
  }) {
    final bool hasChanged =
        isDeviceWidthSmall != isSmall || isDeviceWidthMedium != isMedium || isDeviceWidthLarge != isLarge;
    if (!hasChanged) {
      return;
    }
    isDeviceWidthSmall = isSmall;
    isDeviceWidthMedium = isMedium;
    isDeviceWidthLarge = isLarge;
    notifyListeners();
  }

  //--------------------------------------------------------
  // Color Helpers
}
