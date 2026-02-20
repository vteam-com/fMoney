import 'package:flutter/material.dart';
import 'package:money/helpers/misc_helpers.dart';

enum ColorState {
  success,
  warning,
  error,
  disabled,
  quantityPositive,
  quantityNegative,
  info,
}

/// Represents money theme data.
class MoneyThemeData extends ThemeExtension<MoneyThemeData> {
  const MoneyThemeData({
    required this.success,
    required this.warning,
    required this.error,
    required this.disabled,
    required this.quantityPositive,
    required this.quantityNegative,
    required this.info,
  });
  final Color success;
  final Color warning;
  final Color error;
  final Color disabled;
  final Color quantityPositive;
  final Color quantityNegative;
  final Color info;

  @override
  MoneyThemeData copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? disabled,
    Color? quantityPositive,
    Color? quantityNegative,
    Color? info,
  }) {
    return MoneyThemeData(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      disabled: disabled ?? this.disabled,
      quantityPositive: quantityPositive ?? this.quantityPositive,
      quantityNegative: quantityNegative ?? this.quantityNegative,
      info: info ?? this.info,
    );
  }

  @override
  MoneyThemeData lerp(ThemeExtension<MoneyThemeData>? other, double t) {
    if (other is! MoneyThemeData) {
      return this;
    }
    return MoneyThemeData(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      quantityPositive: Color.lerp(quantityPositive, other.quantityPositive, t)!,
      quantityNegative: Color.lerp(quantityNegative, other.quantityNegative, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }

  // Helper methods to replace ThemeController logic
  Color getColorForState(final ColorState state) {
    switch (state) {
      case ColorState.success:
        return success;
      case ColorState.warning:
        return warning;
      case ColorState.error:
        return error;
      case ColorState.disabled:
        return disabled;
      case ColorState.quantityNegative:
        return quantityNegative;
      case ColorState.quantityPositive:
        return quantityPositive;
      case ColorState.info:
        return info;
    }
  }

  Color colorBasedOnValue(final num value) {
    if (value > 0) {
      return success;
    }
    if (value < 0) {
      return error;
    }
    // value == 0
    return disabled;
  }

  Color? getTextColorToUse(final num value, [final bool autoColor = true]) {
    if (autoColor) {
      if (isConsideredZero(value)) {
        return disabled;
      }
      if (value < 0) {
        return error;
      } else {
        return success;
      }
    }
    return null;
  }

  Color? getTextColorToUseQuantity(final num value) {
    if (isConsideredZero(value)) {
      return disabled;
    }
    if (value < 0) {
      return quantityNegative;
    } else {
      return quantityPositive;
    }
  }
}

/// Extension for easy access to MoneyThemeData from BuildContext
extension MoneyThemeContext on BuildContext {
  MoneyThemeData get colorTheme {
    final MoneyThemeData? theme = Theme.of(this).extension<MoneyThemeData>();
    // Fallback if theme extension is not found (should not happen if setup correctly)
    // Return a default instance or throw error
    if (theme == null) {
      // Return default/fallback colors to avoid crash?
      // Or throw to alert developer?
      // Given existing codebase, let's assume it's always there.
      // But for safety during refactor, maybe return a default.
      return const MoneyThemeData(
        success: Colors.green,
        warning: Colors.amber,
        error: Colors.red,
        disabled: Colors.grey,
        quantityPositive: Colors.blue,
        quantityNegative: Colors.orange,
        info: Colors.blue,
      );
    }
    return theme;
  }
}
