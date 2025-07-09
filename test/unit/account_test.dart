import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/money_objects/accounts/account.dart';
import 'package:money/data/models/money_objects/accounts/account_types_enum.dart';
import 'package:money/data/models/constants.dart'; // For Constants.defaultCurrency

void main() {
  group('Account.fromJson', () {
    test('should correctly parse a minimal valid JSON', () {
      final json = {
        'Id': 1,
        'Name': 'Test Account',
        'Type': AccountType.checking.index,
        // Other fields will use defaults or be null/0
      };
      final account = Account.fromJson(json);

      expect(account.uniqueId, 1);
      expect(account.fieldName.value, 'Test Account');
      expect(account.fieldType.value, AccountType.checking);
      expect(account.fieldOpeningBalance.value.asDouble(), 0.0);
      expect(account.fieldCurrency.value, Constants.defaultCurrency);
      expect(account.fieldDescription.value, ''); // Default for missing string
      expect(account.isClosed(), false); // Default flag should mean open
    });

    test('should correctly parse a JSON with all typical fields', () {
      final now = DateTime.now();
      final json = {
        'Id': 2,
        'AccountId': 'ACC123',
        'OfxAccountId': 'OFX456',
        'Name': 'Full Test Account',
        'Description': 'A detailed description',
        'Type': AccountType.savings.index,
        'OpeningBalance': 1000.50,
        'Currency': 'EUR',
        'OnlineAccount': 1,
        'WebSite': 'http://example.com',
        'ReconcileWarning': 0,
        'LastSync': dateToIso8601OrDefaultString(now),
        'SyncGuid': 'some-guid',
        'Flags': AccountFlags.closed.index, // Closed account
        'LastBalance': dateToIso8601OrDefaultString(now.subtract(Duration(days: 1))),
        'CategoryIdForPrincipal': 10,
        'CategoryIdForInterest': 12,
      };
      final account = Account.fromJson(json);

      expect(account.uniqueId, 2);
      expect(account.fieldAccountId.value, 'ACC123');
      expect(account.fieldOfxAccountId.value, 'OFX456');
      expect(account.fieldName.value, 'Full Test Account');
      expect(account.fieldDescription.value, 'A detailed description');
      expect(account.fieldType.value, AccountType.savings);
      expect(account.fieldOpeningBalance.value.asDouble(), 1000.50);
      expect(account.fieldCurrency.value, 'EUR');
      expect(account.fieldOnlineAccount.value, 1);
      expect(account.fieldWebSite.value, 'http://example.com');
      expect(account.fieldReconcileWarning.value, 0);
      expect(account.fieldLastSync.value, isA<DateTime>());
      // expect(account.fieldLastSync.value?.toIso8601String().substring(0,10), now.toIso8601String().substring(0,10)); // Compare date part
      expect(account.fieldSyncGuid.value, 'some-guid');
      expect(account.fieldFlags.value, AccountFlags.closed.index);
      expect(account.isClosed(), true);
      expect(account.fieldLastBalance.value, isA<DateTime>());
      // expect(account.fieldLastBalance.value?.toIso8601String().substring(0,10), now.subtract(Duration(days: 1)).toIso8601String().substring(0,10));
      expect(account.fieldCategoryIdForPrincipal.value, 10);
      expect(account.fieldCategoryIdForInterest.value, 12);
    });

    test('should use default currency when Currency is missing', () {
      final json = {
        'Id': 3,
        'Name': 'Currency Test',
        'Type': AccountType.cash.index,
      };
      final account = Account.fromJson(json);
      expect(account.fieldCurrency.value, Constants.defaultCurrency);
    });

    test('should use default -1 for CategoryIdForPrincipal when missing', () {
      final json = {
        'Id': 4,
        'Name': 'Principal Test',
        'Type': AccountType.loan.index,
      };
      final account = Account.fromJson(json);
      expect(account.fieldCategoryIdForPrincipal.value, -1);
    });

    test('should use default -1 for CategoryIdForInterest when missing', () {
      final json = {
        'Id': 5,
        'Name': 'Interest Test',
        'Type': AccountType.loan.index,
      };
      final account = Account.fromJson(json);
      expect(account.fieldCategoryIdForInterest.value, -1);
    });

    test('handles null date strings gracefully', () {
      final json = {
        'Id': 1,
        'Name': 'Null Date Test',
        'Type': AccountType.checking.index,
        'LastSync': null,
        'LastBalance': null,
      };
      final account = Account.fromJson(json);
      expect(account.fieldLastSync.value, isNull);
      expect(account.fieldLastBalance.value, isNull);
    });
  });

  group('Account Utility Methods', () {
    test('getRepresentation returns fieldName.value', () {
      final account = Account()..fieldName.value = 'My Test Account';
      expect(account.getRepresentation(), 'My Test Account');
    });

    test('isClosed and isOpen work correctly', () {
      final account = Account();

      // Initially, flags should be -1 as per FieldInt default
      expect(account.fieldFlags.value, -1);
      // With flags = -1 (all bits set for common int sizes),
      // AccountFlags.closed.index (which is 1) will be set.
      // So, an account with default flags of -1 is considered closed.
      expect(account.isClosed(), true, reason: "Default flags of -1 means closed bit is set");
      expect(account.isOpen, false, reason: "Default flags of -1 means closed bit is set");

      // Set as closed (it's already closed, but let's test the setter)
      account.isOpen = false;
      // Check if the closed flag is set. Other bits of -1 will remain.
      expect((account.fieldFlags.value & AccountFlags.closed.index), AccountFlags.closed.index);
      expect(account.isClosed(), true);
      expect(account.isOpen, false);

      // Set as open again
      account.isOpen = true;
      // Check if the flag is cleared. If other flags could be present,
      // this check needs to be (account.fieldFlags.value & AccountFlags.closed.index) == 0
      // For simplicity, assuming AccountFlags.closed.index is the only flag being manipulated here or flags start at 0.
      // A more robust check:
      expect((account.fieldFlags.value & AccountFlags.closed.index), 0);
      expect(account.isClosed(), false);
      expect(account.isOpen, true);

      // Test direct manipulation of flags for completeness
      account.fieldFlags.value = AccountFlags.closed.index;
      expect(account.isClosed(), true);
      expect(account.isOpen, false);

      account.fieldFlags.value = 0; // Assuming 0 means no flags / open
      expect(account.isClosed(), false);
      expect(account.isOpen, true);
    });

    test('isBankAccount identifies bank account types', () {
      final checkingAccount = Account()..fieldType.value = AccountType.checking;
      final savingsAccount = Account()..fieldType.value = AccountType.savings;
      final cashAccount = Account()..fieldType.value = AccountType.cash;
      final investmentAccount = Account()..fieldType.value = AccountType.investment;

      expect(checkingAccount.isBankAccount(), isTrue);
      expect(savingsAccount.isBankAccount(), isTrue);
      expect(cashAccount.isBankAccount(), isTrue);
      expect(investmentAccount.isBankAccount(), isFalse);
    });

    test('isInvestmentAccount identifies investment account types', () {
      final investmentAccount = Account()..fieldType.value = AccountType.investment;
      final retirementAccount = Account()..fieldType.value = AccountType.retirement;
      final moneyMarketAccount = Account()..fieldType.value = AccountType.moneyMarket;
      final checkingAccount = Account()..fieldType.value = AccountType.checking;

      expect(investmentAccount.isInvestmentAccount(), isTrue);
      expect(retirementAccount.isInvestmentAccount(), isTrue);
      expect(moneyMarketAccount.isInvestmentAccount(), isTrue);
      expect(checkingAccount.isInvestmentAccount(), isFalse);
    });

    test('isAssetAccount identifies asset account type', () {
      final assetAccount = Account()..fieldType.value = AccountType.asset;
      final checkingAccount = Account()..fieldType.value = AccountType.checking;
      expect(assetAccount.isAssetAccount, isTrue);
      expect(checkingAccount.isAssetAccount, isFalse);
    });

    test('isFakeAccount identifies fake account types', () {
      final notUsedAccount = Account()..fieldType.value = AccountType.notUsed_7;
      final categoryFundAccount = Account()..fieldType.value = AccountType.categoryFund;
      final checkingAccount = Account()..fieldType.value = AccountType.checking;

      expect(notUsedAccount.isFakeAccount(), isTrue);
      expect(categoryFundAccount.isFakeAccount(), isTrue);
      expect(checkingAccount.isFakeAccount(), isFalse);
    });

    test('matchType works correctly', () {
      final checkingAccount = Account()..fieldType.value = AccountType.checking;

      expect(checkingAccount.matchType([]), isTrue, reason: 'Empty list should match non-fake accounts');
      expect(checkingAccount.matchType([AccountType.checking, AccountType.savings]), isTrue);
      expect(checkingAccount.matchType([AccountType.savings, AccountType.investment]), isFalse);

      final fakeAccount = Account()..fieldType.value = AccountType.notUsed_7;
      expect(fakeAccount.matchType([]), isFalse, reason: 'Empty list should not match fake accounts');
      expect(fakeAccount.matchType([AccountType.notUsed_7]), isTrue);
    });

    // Note: isActiveBankAccount depends on isOpen, which was tested, and isBankAccount, also tested.
    // A combined test could be:
    test('isActiveBankAccount works correctly', () {
      final openChecking = Account()
        ..fieldType.value = AccountType.checking
        ..isOpen = true;
      final closedChecking = Account()
        ..fieldType.value = AccountType.checking
        ..isOpen = false;
      final openInvestment = Account()
        ..fieldType.value = AccountType.investment
        ..isOpen = true;

      expect(openChecking.isActiveBankAccount(), isTrue);
      expect(closedChecking.isActiveBankAccount(), isFalse);
      expect(openInvestment.isActiveBankAccount(), isFalse);
    });

    // Test for fieldIsAccountOpen Field
    // This field's getValueForDisplay directly uses isClosed.
    // Its setValue involves Data().notifyMutationChanged which is harder to unit test without mocking.
    // We'll focus on the getValueForDisplay part which reflects the isOpen state.
    test('fieldIsAccountOpen reflects account open status', () {
        final account = Account();
        account.isOpen = true;
        expect(account.fieldIsAccountOpen.getValueForDisplay(account), isTrue);

        account.isOpen = false;
        expect(account.fieldIsAccountOpen.getValueForDisplay(account), isFalse);
    });

  });
}

// Helper to mimic MyJson behavior for tests if needed, or rely on Map<String,dynamic>
// For now, Map<String, dynamic> is used directly as MyJson is dynamic anyway.
// MyJson extension methods are simple getters like getString, getInt, getDate, getDouble.
// We can add a simple MyJson wrapper if complex logic from it is needed.

// Simplified dateToIso8601OrDefaultString for test setup clarity
String? dateToIso8601OrDefaultString(DateTime? date, {String defaultValue = ''}) {
  if (date == null) {
    return defaultValue;
  }
  return date.toIso8601String();
}

// AccountFlags enum as defined in the app (assuming its location or define locally for test)
// enum AccountFlags {
//   none, // 0
//   closed, // 1
//   // ... other flags if any
// }
// We'll rely on the imported AccountFlags enum from account_types_enum.dart
// For `fieldFlags.value` tests, it's good to ensure this enum is correctly used.
// The Account class already imports 'account_types_enum.dart'
// so AccountFlags.closed.index should work.

// Minimal MyJson mock for testing
extension TestJsonHelpers on Map<String, dynamic> { // Named the extension
  String getString(String key, [String defaultValue = '']) {
    return this[key] as String? ?? defaultValue;
  }

  int getInt(String key, [int defaultValue = 0]) {
    return this[key] as int? ?? defaultValue;
  }

  double getDouble(String key, [double defaultValue = 0.0]) {
    // Handle int values that might come from JSON for double fields
    if (this[key] is int) {
      return (this[key] as int).toDouble();
    }
    return this[key] as double? ?? defaultValue;
  }

  DateTime? getDate(String key) {
    final value = this[key];
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

// Note: The `Data()` singleton is a dependency.
// Tests for fields like `fieldCategoryIdForPrincipal`'s `getValueForDisplay`
// which use `Data().categories.getNameFromId` will require mocking `Data()`
// or its components. For `fromJson` tests, we are primarily checking if the
// raw ID values are parsed and stored correctly.
// Similarly for `fieldCurrency`'s `getValueForDisplay` and `sort`.
// `fieldBalanceNormalized` also depends on `Data().currencies`.
// These will be addressed in subsequent tests for those specific methods/fields if needed.

// For `fieldIsAccountOpen` and its `setValue`:
// This involves `Data().notifyMutationChanged`, which might also need consideration for mocking
// if we want to verify that interaction. For now, focus on state change.

// For `buildFieldsAsWidgetForSmallScreen`:
// This returns a Widget and is more suited for widget tests.
// Unit tests will focus on the data and logic aspects.
// `getCurrencyRatio` also has `Data()` dependency.
// `getTransaction` has `Data()` dependency.
// `PreferenceController.to.includeClosedAccounts` is another global dependency.
// These will be handled as we get to testing those specific methods.
// The initial tests focus on `fromJson` and basic state.
