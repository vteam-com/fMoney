import 'package:flutter/material.dart';
import 'package:money/helpers/pairs_model.dart';

// Exports
export 'package:flutter/material.dart';

const double _minUnit = 0.0;
const double _maxUnit = 1.0;
const double _defaultTextOpacity = 0.7;
const double _colorMaxChannel = 255.0;
const int _hexRadix = 16;
const int _hexPadWidth = 2;
const int _hexLengthRgb = 6;
const int _hexLengthRgba = 8;
const String _opaqueAlphaHex = 'FF';
const double _luminanceRedWeight = 0.299;
const double _luminanceGreenWeight = 0.587;
const double _luminanceBlueWeight = 0.114;
const double _luminanceThreshold = 0.5;

/// Collection of color utility functions for:
/// - Color manipulation (tinting, brightness, opacity)
/// - Format conversion (hex, HSL, RGB)
/// - Contrast calculation
/// - Theme-aware color selection
/// - Color state management

/// Adjusts the brightness of the input color to the specified value within the valid range (0.0 - 1.0).
Color adjustBrightness(Color color, double brightness) {
  // Ensure brightness is within valid range
  brightness = brightness.clamp(_minUnit, _maxUnit);

  // Convert color to HSL
  HSLColor hslColor = HSLColor.fromColor(color);

  // Adjust lightness component
  hslColor = hslColor.withLightness(brightness);

  // Convert back to RGB
  return hslColor.toColor();
}

/// Adjusts the opacity of a [TextStyle] object.
///
/// The [textStyle] parameter represents the original [TextStyle] object.
/// The [opacity] parameter determines the opacity value to be applied to the [textStyle.color].
/// By default, the [opacity] is set to 0.7.
///
/// Returns a new [TextStyle] object with the adjusted opacity.
/// The [color] property of the new [TextStyle] object is set to the original [textStyle.color] with the specified [opacity] applied.
/// All other properties of the [textStyle] are preserved in the new [TextStyle] object.
///
TextStyle adjustOpacityOfTextStyle(
  final TextStyle textStyle, [
  final double opacity = _defaultTextOpacity,
]) {
  return textStyle.copyWith(color: textStyle.color!.withValues(alpha: opacity));
}

/// Converts a given [Color] object to a hexadecimal string representation.
///
/// The [color] parameter represents the color to be converted.
/// The [alphaFirst] parameter determines whether the alpha value should be placed before the RGB values in the hexadecimal string. By default, it is set to false.
/// The [includeAlpha] parameter determines whether the alpha value should be included in the hexadecimal string. By default, it is set to true.
///
/// Returns the hexadecimal string representation of the color, including the alpha value if specified.
/// If [includeAlpha] is false, the returned string will only contain the RGB values.
/// If [alphaFirst] is true, the returned string will have the alpha value placed before the RGB values.
/// Otherwise, the returned string will have the RGB values followed by the alpha value.
///
String colorToHexString(
  final Color color, {
  bool alphaFirst = false,
  bool includeAlpha = true,
}) {
  final String red = (color.r * _colorMaxChannel).toInt().toRadixString(_hexRadix).padLeft(_hexPadWidth, '0');
  final String green = (color.g * _colorMaxChannel).toInt().toRadixString(_hexRadix).padLeft(_hexPadWidth, '0');
  final String blue = (color.b * _colorMaxChannel).toInt().toRadixString(_hexRadix).padLeft(_hexPadWidth, '0');
  final String alpha = (color.a * _colorMaxChannel).toInt().toRadixString(_hexRadix).padLeft(_hexPadWidth, '0');
  if (includeAlpha == false) {
    return '#$red$green$blue';
  }
  if (alphaFirst) {
    return '#$alpha$red$green$blue';
  }
  return '#$red$green$blue$alpha';
}

/// Calculates the contrast color based on the luminance of the input color.
///
/// The [color] parameter represents the color for which the contrast color will be calculated.
/// The luminance of the [color] is calculated using the formula: (0.299 * red + 0.587 * green + 0.114 * blue) / 255.
/// If the calculated luminance is greater than 0.5, the contrast color is set to black. Otherwise, it is set to white.
///
/// Returns the contrast color as a [Color] object.
///
Color contrastColor(Color color) {
  // Calculate the luminance of the color
  final double luminance =
      (_luminanceRedWeight * (color.r * _colorMaxChannel) +
          _luminanceGreenWeight * (color.g * _colorMaxChannel) +
          _luminanceBlueWeight * (color.b * _colorMaxChannel)) /
      _colorMaxChannel;

  // Determine whether to make the contrast color black or white based on the luminance
  final Color contrastColor = luminance > _luminanceThreshold ? Colors.black : Colors.white;

  return contrastColor;
}

/// Returns a Color object based on a given hexadecimal color string.
///
/// The hexadecimal color string can be in the format "#RRGGBB" or "#AARRGGBB".
/// If the hexadecimal color string is in the format "#RRGGBB", the alpha value is set to 255 (fully opaque).
/// If the hexadecimal color string is in the format "#AARRGGBB", the alpha value is parsed from the string.
/// If the hexadecimal color string is not in a valid format, the function returns Colors.transparent.
///
/// @param hexColor The hexadecimal color string to convert to a Color object.
/// @return The Color object representing the given hexadecimal color string, or Colors.transparent if the string is not in a valid format.
///
Color getColorFromString(final String hexColor) {
  String newHexColor = hexColor.trim().replaceAll('#', '');
  if (newHexColor.length == _hexLengthRgb) {
    newHexColor = '$_opaqueAlphaHex$newHexColor';
  }
  if (newHexColor.length == _hexLengthRgba) {
    return Color(int.parse('0x$newHexColor'));
  }
  return Colors.transparent;
}

/// Returns the color scheme from the current theme.
ColorScheme getColorTheme(final BuildContext context) {
  return getTheme(context).colorScheme;
}

/// Retrieves the hue and brightness values from the given Color object in the HSL color space.
Pair<double, double> getHueAndBrightnessFromColor(Color color) {
  // Convert color to HSL
  final HSLColor hslColor = HSLColor.fromColor(color);

  // Extract hue and lightness values
  final double hue = hslColor.hue;
  final double brightness = hslColor.lightness;

  return Pair<double, double>(hue, brightness);
}

/// Returns the text theme from the current theme.
TextTheme getTextTheme(final BuildContext context) {
  return getTheme(context).textTheme;
}

/// Returns the current theme data.
ThemeData getTheme(final BuildContext context) {
  return Theme.of(context);
}

/// Converts HSV color values to RGB Color.
Color hsvToColor(double hue, double brightness) {
  final Color color = HSVColor.fromAHSV(_maxUnit, hue, _maxUnit, _maxUnit).toColor();
  return adjustBrightness(color, brightness);
}
