import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/pairs_model.dart';

void main() {
  group('contrastColor Function Tests', () {
    test('test_contrast_color_luminance_threshold', () {
      const Color lightColor = Color.fromRGBO(200, 200, 200, 1.0);
      const Color darkColor = Color.fromRGBO(50, 50, 50, 1.0);
      final Color contrastForLight = contrastColor(lightColor);
      final Color contrastForDark = contrastColor(darkColor);

      expect(contrastForLight, equals(Colors.black));
      expect(contrastForDark, equals(Colors.white));
    });
  });

  group('getHueAndBrightnessFromColor Function Tests', () {
    test('test_getHueAndBrightnessFromColor', () {
      // Arrange
      final Color color = Colors.blue;

      // Act
      final Pair<double, double> result = getHueAndBrightnessFromColor(color);

      // Assert
      expect(roundToDecimalPlaces(result.first, 1), equals(206.6));
      expect(roundToDecimalPlaces(result.second, 1), equals(0.5));
    });
  });

  group('hsvToColor Test', () {
    group('colorToHexString', () {
      test('converts Color to hexadecimal string correctly', () {
        // Arrange
        const Color colorSource = Colors.purple;
        const String expectedHexString = '#9c27b0ff';

        // Act
        final String result = colorToHexString(colorSource);

        // Assert
        expect(result, expectedHexString);
      });

      test('handles opaque colors correctly', () {
        // Arrange
        const Color colorSource = Color(0xFFFF0000);
        const String expectedHexString = '#ff0000ff';

        // Act
        final String result = colorToHexString(colorSource);

        // Assert
        expect(result, expectedHexString);
      });

      test('handles transparent colors correctly', () {
        // Arrange
        const Color colorSource = Color(0x80FF0000);
        const String expectedHexString = '#ff000080';

        // Act
        final String result = colorToHexString(colorSource);

        // Assert
        expect(result, expectedHexString);
      });
    });
  });
}
