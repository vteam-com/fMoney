import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/ranges_model.dart';

void main() {
  test('durationInMonths is never 0, so per-month averages never divide by zero', () {
    expect(DateRange().durationInMonths, 1);
    expect(DateRange(min: DateTime(2024, 1, 1), max: DateTime(2024, 1, 10)).durationInMonths, 1);
    expect(DateRange(min: DateTime(2024, 1, 1), max: DateTime(2024, 12, 31)).durationInMonths, 12);
  });
}
