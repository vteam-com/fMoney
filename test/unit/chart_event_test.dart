import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets_data/charts/chart_event.dart';

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
      expect(chartEvent.colorToUse, Colors.orange);
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
      expect(chartEvent.colorToUse, Colors.blue);
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
