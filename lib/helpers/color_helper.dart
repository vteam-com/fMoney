import 'package:flutter/material.dart';
import 'package:money/helpers/list_helper.dart';

// Exports
export 'package:flutter/material.dart';

/// Collection of color utility functions for:
/// - Color manipulation (tinting, brightness, opacity)
/// - Format conversion (hex, HSL, RGB)
/// - Contrast calculation
/// - Theme-aware color selection
/// - Color state management

/// Adds a tint of red to a given color.
///
/// This function takes a `Color` object and an integer value representing the
/// strength of the red tint to be added. It returns a new `Color` object with
/// the red component adjusted by the specified tint strength.
///
/// The green and blue components of the original color remain unchanged. The
/// alpha component (opacity) of the new color is set to the same value as the
/// original color.
///
/// If the resulting red value exceeds the valid range (0 to 255), it is clamped
/// to the nearest valid value (0 or 255).
///
/// Example usage:
///
/// ```dart
/// Color originalColor = const Color(0xFF00FF00); // Green color
/// Color tintedColor = addTintOfRed(originalColor, 50); // Adds a tint of 50 to the red component
/// print(tintedColor.value.toRadixString(16)); // Output: 0xFF7FFF00 (Greenish-yellow color)
/// ```
///
/// Parameters:
///   originalColor (Color): The original color to which the red tint will be added.
///   tintStrength (int): The strength of the red tint to be added (0 to 255).
///
/// Returns:
///   A new `Color` object with the red component adjusted by the specified tint strength.
Color addTintOfRed(Color originalColor, int tintStrength) {
  // Add the tint strength to the red component
  int red = (originalColor.r * 255).toInt() + tintStrength;

  // Keep the green and blue components unchanged
  final int green = (originalColor.g * 255).toInt();
  final int blue = (originalColor.b * 255).toInt();

  // Ensure red value stays within the valid range (0 to 255)
  red = red.clamp(0, 255);

  // Create a new Color object with the adjusted red component
  return Color.fromARGB((originalColor.a * 255).toInt(), red, green, blue);
}

/// Adds a tint of blue to the original color.
///
/// The [originalColor] parameter represents the original color to which the tint of blue will be added.
/// The [tintStrength] parameter determines the strength of the tint of blue to be added. It should be an integer value.
///
/// Returns a new [Color] object with the tint of blue added to the original color. The red and green values of the original color remain unchanged, while the blue value is increased by the [tintStrength] amount.
/// If the resulting blue value exceeds 255, it will be clamped to 255 to ensure it stays within the valid range (0 to 255).
///
Color addTintOfBlue(Color originalColor, int tintStrength) {
  final int red = (originalColor.r * 255).toInt();
  final int green = (originalColor.g * 255).toInt();
  int blue = (originalColor.b * 255).toInt() + tintStrength;

  // Ensure blue value stays within the valid range (0 to 255)
  blue = blue.clamp(0, 255);

  return Color.fromARGB((originalColor.a * 255).toInt(), red, green, blue);
}

/// Adds a tint of green to the original color.
///
/// The [originalColor] parameter represents the original color to which the tint of green will be added.
/// The [tintStrength] parameter determines the strength of the tint of blue to be added. It should be an integer value.
///
/// Returns a new [Color] object with the tint of green added to the original color. The red and blue values of the original color remain unchanged, while the blue value is increased by the [tintStrength] amount.
/// If the resulting green value exceeds 255, it will be clamped to 255 to ensure it stays within the valid range (0 to 255).
///
Color addTintOfGreen(Color originalColor, int tintStrength) {
  final int red = (originalColor.r * 255).toInt();
  int green = (originalColor.g * 255).toInt() + tintStrength;
  final int blue = (originalColor.b * 255).toInt();

  // Ensure green value stays within the valid range (0 to 255)
  green = green.clamp(0, 255);

  return Color.fromARGB((originalColor.a * 255).toInt(), red, green, blue);
}

/// Adjusts the brightness of the input color to the specified value within the valid range (0.0 - 1.0).
Color adjustBrightness(Color color, double brightness) {
  // Ensure brightness is within valid range
  brightness = brightness.clamp(0.0, 1.0);

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
  final double opacity = 0.7,
]) {
  return textStyle.copyWith(color: textStyle.color!.withValues(alpha: opacity));
}

Widget colorBox(Color color, Color colorText) {
  return Container(
    color: color,
    width: 80,
    height: 80,
    margin: const EdgeInsets.all(10),
    child: Text(color.toString(), style: TextStyle(color: colorText)),
  );
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
  final String red = (color.r * 255).toInt().toRadixString(16).padLeft(2, '0');
  final String green = (color.g * 255).toInt().toRadixString(16).padLeft(2, '0');
  final String blue = (color.b * 255).toInt().toRadixString(16).padLeft(2, '0');
  final String alpha = (color.a * 255).toInt().toRadixString(16).padLeft(2, '0');
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
  final double luminance = (0.299 * (color.r * 255) + 0.587 * (color.g * 255) + 0.114 * (color.b * 255)) / 255;

  // Determine whether to make the contrast color black or white based on the luminance
  final Color contrastColor = luminance > 0.5 ? Colors.black : Colors.white;

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
  if (newHexColor.length == 6) {
    newHexColor = 'FF$newHexColor';
  }
  if (newHexColor.length == 8) {
    return Color(int.parse('0x$newHexColor'));
  }
  return Colors.transparent;
}

ColorScheme getColorTheme(final BuildContext context) {
  return getTheme(context).colorScheme;
}

/// Returns a Pair object containing the hue and brightness values of the given color.
///
/// The color is first converted to HSL using the HSLColor.fromColor() method.
/// The hue value is extracted from the HSLColor object using the hue property.
/// The brightness value is calculated by subtracting the lightness value from 1.
///
/// @param color The color to extract the hue and brightness values from.
/// @return A ```Pair<double, double>``` object containing the hue and brightness values.
///
Pair<double, double> getHueAndBrightness(Color color) {
  final HSLColor hslColor = HSLColor.fromColor(color);
  return Pair<double, double>(hslColor.hue, 1 - hslColor.lightness);
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

/// Retrieves the hue value from the given Color object in the HSL color space.
double getHueFromColor(Color color) {
  // Convert color to HSL
  final HSLColor hslColor = HSLColor.fromColor(color);

  // Extract hue value
  final double hue = hslColor.hue;

  return hue;
}

TextTheme getTextTheme(final BuildContext context) {
  return getTheme(context).textTheme;
}

ThemeData getTheme(final BuildContext context) {
  return Theme.of(context);
}

Color hsvToColor(double hue, double brightness) {
  final Color color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
  return adjustBrightness(color, brightness);
}

/// Returns the inverted color by subtracting each color channel from 255.
///
/// The [color] parameter represents the color to be inverted.
/// The red, green, and blue values of the [color] are subtracted from 255 to calculate the inverted color.
///
/// Returns the inverted color as a [Color] object.
/// The alpha value of the [color] is preserved in the inverted color.
/// The inverted color is created using the [Color.fromRGBO] constructor.
/// The [invertedRed], [invertedGreen], and [invertedBlue] values are used as the red, green, and blue channels of the inverted color, respectively.
/// The alpha value of the inverted color is set to 1.0.
///
Color invertColor(final Color color) {
  // Calculate inverted color by subtracting each color channel from 255
  final double invertedRed = 1.0 - color.r;
  final double invertedGreen = 1.0 - color.g;
  final double invertedBlue = 1.0 - color.b;

  // Return the inverted color
  return Color.fromRGBO(
    (invertedRed * 255).toInt(),
    (invertedGreen * 255).toInt(),
    (invertedBlue * 255).toInt(),
    1.0,
  );
}
