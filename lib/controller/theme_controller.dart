import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money/controller/my_window_manager.dart';
import 'package:money/controller/preferences_controller.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/widgets/theme_custom.dart';

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

/// Controller for managing app theme settings including:
/// - Light/dark mode switching
/// - Primary color scheme selection
/// - Device width responsive breakpoints
/// - Font scaling
/// - Window size management
/// - Theme persistence
class ThemeController extends GetxController {
  RxInt colorSelected = 0.obs;
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

  void adjustFontScale(double delta) {
    final double newScale = PreferenceController.to.textScale + delta;
    setFontScaleTo(newScale);
  }

  void fontScaleIncrease() => adjustFontScale(0.10);
  void fontScaleDecrease() => adjustFontScale(-0.10);

  void loadThemeFromPreferences() async {
    if (!PreferenceController.to.isReady.value) {
      await PreferenceController.to.init();
    }
    isDarkTheme.value = PreferenceController.to.getBool(
      settingKeyDarkMode,
      false,
    );
    colorSelected.value = PreferenceController.to.getInt(settingKeyTheme, 0);
    updateTheme();
  }

  void saveThemeToPreferences() async {
    PreferenceController.to.setBool(settingKeyDarkMode, isDarkTheme.value);
    PreferenceController.to.setInt(settingKeyTheme, colorSelected.value);
  }

  void setAppSizeToSmall() => MyWindowManager.setAppWindowSize(Constants.screenWidthSmall, 900);
  void setAppSizeToMedium() => MyWindowManager.setAppWindowSize(Constants.screenWidthMedium, 900);
  void setAppSizeToLarge() => MyWindowManager.setAppWindowSize(Constants.screenWidthLarge, 900);

  bool setFontScaleTo(final double newScale) {
    final int cleanValue = (newScale * 100).round();
    if (isBetweenOrEqual(cleanValue, 40, 400)) {
      PreferenceController.to.textScale = cleanValue / 100.0;

      return true;
    }
    return false;
  }

  void setThemeColor(final int index) {
    colorSelected.value = index;
    primaryColor = themeData.colorScheme.primary;
    saveThemeToPreferences();
    updateTheme();
  }

  ThemeData get themeData => isDarkTheme.value ? themeDataDark : themeDataLight;

  ThemeData get themeDataDark {
    // Validate color range
    if (!isIndexInRange(Themes.themeAsColors, colorSelected.value)) {
      colorSelected = 0.obs;
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

  ThemeData get themeDataLight {
    // Validate color range
    if (!isIndexInRange(Themes.themeAsColors, colorSelected.value)) {
      colorSelected = 0.obs;
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

  static ThemeController get to => Get.find();

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
