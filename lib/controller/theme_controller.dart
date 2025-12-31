import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money/constants.dart';
import 'package:money/controller/my_window_manager.dart';
import 'package:money/controller/preferences_controller.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/misc_helpers.dart';

export 'package:flutter/material.dart';

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
    if (!isIndexInRange(themeAsColors, colorSelected.value)) {
      colorSelected = 0.obs;
    }

    final ThemeData themeData = ThemeData(
      colorSchemeSeed: themeAsColors[colorSelected.value],
      brightness: Brightness.dark,
    );
    return themeData;
  }

  ThemeData get themeDataLight {
    // Validate color range
    if (!isIndexInRange(themeAsColors, colorSelected.value)) {
      colorSelected = 0.obs;
    }
    final ThemeData themeData = ThemeData(
      colorSchemeSeed: themeAsColors[colorSelected.value],
      brightness: Brightness.light,
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
}

Color getColorFromState(final ColorState state) {
  final bool isDarkModeOne = ThemeController.to.isDarkTheme.value;

  switch (state) {
    case ColorState.success:
      return isDarkModeOne ? Colors.green.shade300 : Colors.green.shade800;

    case ColorState.warning:
      return isDarkModeOne ? Colors.amber.shade300 : Colors.amber.shade800;

    case ColorState.error:
      return isDarkModeOne ? Colors.red.shade200 : Colors.red.shade800;

    case ColorState.disabled:
      return isDarkModeOne ? Colors.grey.shade500 : Colors.grey.shade600;
    case ColorState.quantityNegative:
      return isDarkModeOne ? Colors.orange.shade300 : Colors.orange.shade600;
    case ColorState.quantityPositive:
      return isDarkModeOne ? Colors.blue.shade300 : Colors.blue.shade600;
    case ColorState.info:
      return isDarkModeOne ? Colors.blue.shade200 : Colors.blue.shade700;
  }
}

Color colorBasedOnValue(final num value) {
  if (value > 0) {
    return getColorFromState(ColorState.success);
  }
  if (value < 0) {
    return getColorFromState(ColorState.error);
  }
  // value == 0
  return getColorFromState(ColorState.disabled);
}

Color? getTextColorToUse(final num value, [final bool autoColor = true]) {
  if (autoColor) {
    if (isConsideredZero(value)) {
      return getColorFromState(ColorState.disabled);
    }
    if (value < 0) {
      return getColorFromState(ColorState.error);
    } else {
      return getColorFromState(ColorState.success);
    }
  }
  return null;
}

Color? getTextColorToUseQuantity(final num value) {
  if (isConsideredZero(value)) {
    return getColorFromState(ColorState.disabled);
  }
  if (value < 0) {
    return getColorFromState(ColorState.quantityNegative);
  } else {
    return getColorFromState(ColorState.quantityPositive);
  }
}

enum ColorState {
  success,
  warning,
  error,
  disabled,
  quantityPositive,
  quantityNegative,
  info,
}
