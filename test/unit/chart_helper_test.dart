import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/chart_helper.dart';

void main() {
  group('chartXPosition', () {
    test('maps the axis span onto the plot width', () {
      expect(chartXPosition(100, 100, 200, 400), 0);
      expect(chartXPosition(150, 100, 200, 400), 200);
      expect(chartXPosition(200, 100, 200, 400), 400);
    });

    test('puts values before the axis start at the left edge', () {
      expect(chartXPosition(50, 100, 200, 400), 0);
    });

    test('puts every value at the left edge when the axis has no span', () {
      expect(chartXPosition(100, 100, 100, 400), 0);
      expect(chartXPosition(150, 100, 100, 400), 0);
    });
  });
}
