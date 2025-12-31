import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';

void main() {
  final MyJson myMap = <String, dynamic>{
    'name': 'John',
    'age': 25,
    'city': 'New York',
    'isHuman': true,
    'birthday': '1999-12-25',
  };

  group('JSon:', () {
    test('Value lookup with exception', () {
      expect(myMap.getValue<String>('name'), 'John');
      expect(myMap.getValue<int>('age'), 25);
      expect(myMap.getValue<bool>('isStudent', defaultValue: false), false);
      expect(myMap.getValue<bool>('isHuman', defaultValue: false), true);

      // test the exception
      try {
        myMap.getValue<DateTime>('birthday');
        // this line shall not be reached
        expect(true, false);
      } catch (_) {
        // as expected this will throw an exception
        expect(true, true);
      }
    });
    test('Value lookup no exceptions', () {
      expect(myMap.getString('name'), 'John');
      expect(myMap.getInt('age'), 25);
      expect(myMap.getBool('isStudent'), false);
      expect(myMap.getBool('isHuman'), true);
      expect(
        dateToIso8601OrDefaultString(myMap.getDate('birthday')),
        '1999-12-25T00:00:00.000',
      );
    });
  });
}
