// ignore: fcheck_one_class_per_file
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
class ThemeController extends GetxController {
  RxInt colorSelected = _defaultThemeIndex.obs;
  RxBool isDarkTheme = false.obs;
  RxBool isDeviceWidthLarge = false.obs;
  RxBool isDeviceWidthMedium = true.obs;
  RxBool isDeviceWidthSmall = false.obs;
  Color primaryColor = Colors.grey;

  @override
  void onInit() {
    super.onInit();
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
    if (!PreferenceController.to.isReady.value) {
      await PreferenceController.to.init();
    }
    isDarkTheme.value = PreferenceController.to.getBool(
      settingKeyDarkMode,
      false,
    );
    colorSelected.value = PreferenceController.to.getInt(settingKeyTheme, _defaultThemeIndex);
    updateTheme();
  }

  /// Persists theme mode and color index to preferences.
  void saveThemeToPreferences() async {
    PreferenceController.to.setBool(settingKeyDarkMode, isDarkTheme.value);
    PreferenceController.to.setInt(settingKeyTheme, colorSelected.value);
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
    colorSelected.value = index;
    primaryColor = themeData.colorScheme.primary;
    saveThemeToPreferences();
    updateTheme();
  }

  /// Returns the current theme data (light or dark) based on the mode.
  ThemeData get themeData => isDarkTheme.value ? themeDataDark : themeDataLight;

  /// Builds and returns the dark theme data for the selected color seed.
  ThemeData get themeDataDark {
    // Validate color range
    if (!isIndexInRange(Themes.themeAsColors, colorSelected.value)) {
      colorSelected = _defaultThemeIndex.obs;
    }

    final ThemeData themeData = ThemeData(
      colorSchemeSeed: Themes.themeAsColors[colorSelected.value],
      brightness: Brightness.dark,
      extensions: <ThemeExtension<dynamic>>[
        MoneyThemeData(
          success: Colors.green.shade300,
          warning: Colors.amber.shade300,
          error: Colors.red.shade200,
          disabled: Colors.grey.shade500,
          quantityPositive: Colors.blue.shade300,
          quantityNegative: Colors.orange.shade300,
          info: Colors.blue.shade200,
        ),
      ],
    );
    return themeData;
  }

  /// Builds and returns the light theme data for the selected color seed.
  ThemeData get themeDataLight {
    // Validate color range
    if (!isIndexInRange(Themes.themeAsColors, colorSelected.value)) {
      colorSelected = _defaultThemeIndex.obs;
    }
    final ThemeData themeData = ThemeData(
      colorSchemeSeed: Themes.themeAsColors[colorSelected.value],
      brightness: Brightness.light,
      extensions: <ThemeExtension<dynamic>>[
        MoneyThemeData(
          success: Colors.green.shade800,
          warning: Colors.amber.shade800,
          error: Colors.red.shade800,
          disabled: Colors.grey.shade600,
          quantityPositive: Colors.blue.shade600,
          quantityNegative: Colors.orange.shade600,
          info: Colors.blue.shade700,
        ),
      ],
    );
    return themeData;
  }

  /// Singleton accessor for the registered ThemeController instance.
  static ThemeController get to => Get.find();

  /// Toggles between light and dark theme modes and persists the change.
  void toggleThemeMode() {
    isDarkTheme.value = !isDarkTheme.value;
    primaryColor = themeData.colorScheme.primary;
    saveThemeToPreferences();
    updateTheme();
  }

  /// this will rebuild the app to use the current theme
  void updateTheme() {
    primaryColor = themeData.colorScheme.primary;
    Get.changeTheme(themeData);
  }

  //--------------------------------------------------------
  // Color Helpers
}
