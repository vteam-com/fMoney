import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/misc_helpers.dart';

void main() {
  group('invertColor Function Tests', () {
    test('test_invert_color_correct_inversion', () {
      const Color color = Color.fromRGBO(100, 150, 200, 1.0);
      const Color expectedInvertedColor = Color.fromRGBO(155, 105, 55, 1.0);
      final Color invertedColor = invertColor(color);

      expect(invertedColor, equals(expectedInvertedColor));
    });

    test('test_invert_color_edge_cases', () {
      const Color black = Color.fromRGBO(0, 0, 0, 1.0);
      const Color white = Color.from(alpha: 1, red: 1, green: 1, blue: 1);
      final Color invertedBlack = invertColor(black);
      final Color invertedWhite = invertColor(white);

      expect(invertedBlack, equals(white));
      expect(invertedWhite, equals(black));
    });
  });

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

  group('getHueAndBrightness', () {
    test('returns correct hue and brightness for a given color', () {
      // Arrange
      const Color colorSource = Colors.purple;

      // Act
      final Pair<double, double> result = getHueAndBrightness(colorSource);

      // Assert
      expect(result.first.floor(), 291);
      expect((result.second * 100).truncate() / 100, 0.57);
    });

    test('handles opaque colors correctly', () {
      // Arrange
      const Color colorSource = Color(0xFFFF0000);

      // Act
      final Pair<double, double> result = getHueAndBrightness(colorSource);

      // Assert
      expect(result.first, 0.0);
      expect(result.second, 0.5);
    });

    test('handles transparent colors correctly', () {
      // Arrange
      const Color colorSource = Color(0x80FF0000);
      const double expectedHue = 0.0;
      const double expectedBrightness = 0.5;

      // Act
      final Pair<double, double> result = getHueAndBrightness(colorSource);

      // Assert
      expect(result.first, expectedHue);
      expect(result.second, expectedBrightness);
    });

    test('alter colors', () {
      {
        final Color result = addTintOfRed(Colors.grey, 200);
        expect(colorToHexString(result), '#ff9e9eff');
      }

      {
        final Color result = addTintOfGreen(Colors.grey, 200);
        expect(colorToHexString(result), '#9eff9eff');
      }
      {
        final Color result = addTintOfBlue(Colors.grey, 200);
        expect(colorToHexString(result), '#9e9effff');
      }
    });
  });
}
