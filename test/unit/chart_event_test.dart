import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/ranges_model.dart';
import 'package:money/widgets/charts/chart_event_model.dart';

void main() {
  group('ChartEvent', () {
    test('creates ChartEvent with valid data', () {
      final ChartEvent chartEvent = ChartEvent(
        dates: DateRange(min: DateTime(2023, 1, 1)),
        amount: 100.0,
        quantity: 1,
        description: 'Test Event',
        colorBasedOnQuantity: true,
      );

      expect(chartEvent.dates.min, DateTime(2023, 1, 1));
      expect(chartEvent.amount, 100.0);
      expect(chartEvent.isBuy, true);
      // Same as the theme's quantityPositive color used by QuantityWidget.
      expect(chartEvent.colorToUse, Colors.blue);
    });

    test('creates ChartEvent with zero value', () {
      final ChartEvent chartEvent = ChartEvent(
        dates: DateRange(min: DateTime(2023, 1, 1)),
        amount: 0.0,
        quantity: 0,
        description: 'Zero Event',
        colorBasedOnQuantity: true,
      );

      expect(chartEvent.amount, 0.0);
    });

    test('creates ChartEvent with negative value', () {
      final ChartEvent chartEvent = ChartEvent(
        dates: DateRange(min: DateTime(2023, 1, 1)),
        amount: -100.0,
        quantity: -1,
        description: 'Negative Event',
        colorBasedOnQuantity: true,
      );

      expect(chartEvent.amount, -100.0);
      expect(chartEvent.isSell, true);
      // Same as the theme's quantityNegative color used by QuantityWidget.
      expect(chartEvent.colorToUse, Colors.orange);
    });

    test('compares ChartEvents correctly', () {
      final ChartEvent event1 = ChartEvent(
        dates: DateRange(min: DateTime(2023, 1, 1)),
        amount: 100.0,
        quantity: 1,
        description: 'Event 1',
        colorBasedOnQuantity: true,
      );

      final ChartEvent event2 = ChartEvent(
        dates: DateRange(min: DateTime(2023, 1, 1)),
        amount: 100.0,
        quantity: 1,
        description: 'Event 1',
        colorBasedOnQuantity: true,
      );

      final ChartEvent event3 = ChartEvent(
        dates: DateRange(min: DateTime(2023, 1, 2)),
        amount: 200.0,
        quantity: 2,
        description: 'Event 2',
        colorBasedOnQuantity: true,
      );

      expect(event1 == event2, true);
      expect(event1 == event3, false);
    });
  });
}
