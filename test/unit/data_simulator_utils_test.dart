import 'package:flutter_test/flutter_test.dart';
import 'package:money/shared/simulation/data_simulator_utils.dart';

void main() {
  test('the last day of the previous month is in the month just before', () {
    expect(getLastDayOfPreviousMonth(DateTime(2024, 3, 15)), DateTime(2024, 2, 29));
    expect(getLastDayOfPreviousMonth(DateTime(2024, 1, 10)), DateTime(2023, 12, 31));
  });

  test('random amounts are positive cents up to the maximum, so callers choose the sign', () {
    for (int i = 0; i < 100; i++) {
      final double amount = getRandomAmount(50);
      expect(amount, inInclusiveRange(0, 50));
      expect((amount * 100).roundToDouble(), closeTo(amount * 100, 1e-6));
    }
  });
}
