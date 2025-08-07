import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/money_objects/aliases/alias.dart';
import 'package:money/data/models/money_objects/payees/payee.dart'; // Needed for Payee mock/instances
import 'package:money/data/models/money_objects/payees/payees.dart'; // Import for the Payees class itself
// import 'package:money/data/storage/data/data.dart'; // Unused import removed

// Mock classes
class MockPayees extends Payees {
  final Map<int, Payee> _payees = <int, Payee>{}; // Explicit type args for map literal

  void addPayee(Payee payee) {
    _payees[payee.uniqueId] = payee;
  }

  @override
  Payee? get(final int id, {final bool autoAdd = false}) {
    return _payees[id];
  }

  // Implement other methods if needed by tests, though get() is primary for Alias
}

// Helper to set a mock Data instance if Data becomes non-static or injectable
// For now, we might need to rely on direct mocking if Data() is a hard singleton.
// Or, we can test methods that don't call Data() first.
// Let's assume for now we can set a test instance for Data().payees if needed,
// or we test around it. The `payeeInstance` getter is the main challenge.

void main() {
  group('Alias.fromJson', () {
    test('should correctly parse JSON', () {
      final Map<String, dynamic> json = <String, dynamic>{ // Added type
        'Id': 1,
        'Pattern': 'Test Pattern',
        'Flags': 1, // Regex
        'Payee': 10,
      };
      final Alias alias = Alias.fromJson(json); // Added type

      expect(alias.uniqueId, 1);
      expect(alias.fieldPattern.value, 'Test Pattern');
      expect(alias.fieldFlags.value, 1);
      expect(alias.fieldPayeeId.value, 10);
    });

    test('should use default -1 for Id and Payee if missing', () {
      final Map<String, dynamic> json = <String, dynamic>{ // Added type
        // Id is missing
        'Pattern': 'Default ID Pattern',
        'Flags': 0, // None
        // Payee is missing
      };
      final Alias alias = Alias.fromJson(json); // Added type
      expect(alias.uniqueId, -1); // Default from Alias.fromJson
      expect(alias.fieldPayeeId.value, -1); // Default from Alias.fromJson
    });
  });

  group('Alias.type getter', () {
    test('should return AliasType.none when flags is 0', () {
      final Alias alias = Alias(id: 1, pattern: 'p', flags: 0, payeeId: 1); // Added type
      expect(alias.type, AliasType.none);
    });

    test('should return AliasType.regex when flags is not 0', () {
      final Alias alias = Alias(id: 1, pattern: 'p', flags: 1, payeeId: 1); // Added type
      expect(alias.type, AliasType.regex);

      final Alias alias2 = Alias(id: 1, pattern: 'p', flags: -1, payeeId: 1); // Added type
      expect(alias2.type, AliasType.regex);
    });
  });

  group('Alias.getRepresentation', () {
    test('should return fieldPattern.value', () {
      final Alias alias = Alias(id: 1, pattern: 'My Pattern', flags: 0, payeeId: 1); // Added type
      expect(alias.getRepresentation(), 'My Pattern');
    });
  });

  group('Alias.isMatch', () {
    test('matches non-regex type with case-insensitive string comparison', () {
      final Alias alias = Alias(id: 1, pattern: 'Hello World', flags: AliasType.none.index, payeeId: 1); // Added type
      expect(alias.isMatch('Hello World'), isTrue);
      expect(alias.isMatch('hello world'), isTrue);
      expect(alias.isMatch('HELLO WORLD'), isTrue);
      expect(alias.isMatch('Hello Friend'), isFalse);
    });

    test('matches regex type using RegExp', () {
      final Alias alias = Alias(id: 1, pattern: r'^Hel?lo\sW\w*d$', flags: AliasType.regex.index, payeeId: 1); // Added type
      expect(alias.isMatch('Hello World'), isTrue);
      expect(alias.isMatch('Helo Wold'), isTrue); // ? makes l optional
      expect(alias.isMatch('Hello Word'), isTrue); // * allows zero or more word chars after W
      expect(alias.isMatch('Hi World'), isFalse);
      expect(alias.isMatch('Hello   World'), isFalse); // \s is single space
    });

    test('regex is cached after first match attempt for regex type', () {
      final Alias alias = Alias(id: 1, pattern: r'^\d+$', flags: AliasType.regex.index, payeeId: 1); // Added type
      expect(alias.regex, isNull);
      alias.isMatch('123'); // First match
      expect(alias.regex, isNotNull);
      final RegExp? firstRegexInstance = alias.regex; // Added type
      alias.isMatch('456'); // Second match
      expect(alias.regex, same(firstRegexInstance)); // Should be the same instance
    });

    test('regex is not created for non-regex type', () {
      final Alias alias = Alias(id: 1, pattern: 'abc', flags: AliasType.none.index, payeeId: 1); // Added type
      alias.isMatch('abc');
      expect(alias.regex, isNull);
    });
  });

  // Tests for payeeInstance and fields that depend on Data() will require more setup.
  // For now, this covers fromJson, type, getRepresentation, and isMatch.
}

// Minimal MyJson mock for testing (already in account_test.dart, but duplicated for standalone clarity if needed)
// If these tests are run together, this extension might cause a conflict if not guarded.
// For simplicity in this step, I'm assuming it's okay or these files are tested separately.
// A shared test_helper.dart would be better for such extensions.
extension AliasTestJsonHelpers on Map<String, dynamic> { // Named extension
  String getString(String key, [String defaultValue = '']) {
    final dynamic value = this[key]; // Added type
    return value as String? ?? defaultValue;
  }

  int getInt(String key, [int defaultValue = 0]) {
    return this[key] as int? ?? defaultValue;
  }

  // getDouble and getDate not used by Alias.fromJson directly, but good to have for completeness
  // if this were a shared helper.
}

// It seems `Data` is a singleton accessed via `Data()`.
// To mock `Data().payees`, we'd typically need:
// 1. A way to set a mock instance for `Data()` itself (e.g., a static setter `Data.instance = mockData`).
// 2. Or, if `Data` uses a DI framework, use that.
// 3. Or, refactor `Alias` to take `PayeesCollection` as a dependency.
// Without these, testing `payeeInstance` getter in isolation is hard.
// For now, I've focused on methods testable without significant Data mocking.
// The `MockPayees` class is prepared for when we can inject it.
