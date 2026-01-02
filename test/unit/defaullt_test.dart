import 'package:flutter_test/flutter_test.dart';
import 'package:money/fields/default_values.dart';

void main() {
  group('valueOrDefaultBool', () {
    test('boolValueOrDefault', () {
      expect(valueOrDefaultBool(null), false);
      expect(valueOrDefaultBool(null, defaultValueIfNull: false), false);
      expect(valueOrDefaultBool(null, defaultValueIfNull: true), true);

      expect(valueOrDefaultBool(false), false);
      expect(valueOrDefaultBool(true), true);
    });

    test('returns the provided value if it is not null', () {
      expect(valueOrDefaultBool(true), true);
      expect(valueOrDefaultBool(false), false);
    });

    test('returns the default value if the provided value is null', () {
      expect(valueOrDefaultBool(null), false);
      expect(valueOrDefaultBool(null, defaultValueIfNull: true), true);
    });
  });

  group('valueOrDefaultDate', () {
    test('returns the provided value if it is not null', () {
      final DateTime now = DateTime.now();
      expect(valueOrDefaultDate(now), now);
    });

    test('returns the default value if the provided value is null', () {
      final DateTime defaultDate = DateTime(2023, 6, 1);
      expect(
        valueOrDefaultDate(null, defaultValueIfNull: defaultDate),
        defaultDate,
      );
    });
  });

  group('valueOrDefaultDouble', () {
    test('returns the provided value if it is not null', () {
      expect(valueOrDefaultDouble(10.5), 10.5);
    });

    test('returns the default value if the provided value is null', () {
      expect(valueOrDefaultDouble(null), 0.0);
      expect(valueOrDefaultDouble(null, defaultValueIfNull: 9.99), 9.99);
    });
  });

  group('valueOrDefaultInt', () {
    test('returns the provided value if it is not null', () {
      expect(valueOrDefaultInt(25), 25);
    });

    test('returns the default value if the provided value is null', () {
      expect(valueOrDefaultInt(null), 0);
      expect(valueOrDefaultInt(null, defaultValueIfNull: 10), 10);
    });
  });

  group('numValueOrDefault', () {
    test('returns the provided value if it is not null', () {
      expect(numValueOrDefault(10), 10);
      expect(numValueOrDefault(10.5), 10.5);
    });

    test('returns the default value if the provided value is null', () {
      expect(numValueOrDefault(null), 0);
      expect(numValueOrDefault(null, defaultValueIfNull: 5), 5);
    });
  });

  group('valueOrDefaultString', () {
    test('returns the provided value if it is not null', () {
      expect(valueOrDefaultString('hello'), 'hello');
    });

    test('returns the default value if the provided value is null', () {
      expect(valueOrDefaultString(null), '');
      expect(
        valueOrDefaultString(null, defaultValueIfNull: 'unknown'),
        'unknown',
      );
    });
  });
}
