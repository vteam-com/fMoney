import 'package:money/helpers/account_types.dart';
import 'package:money/helpers/account_types_enum.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/locale.dart';
import 'package:money/widgets/adaptive_list/list_item_card.dart';
import 'package:money/widgets/picker_account_type.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/pure/mutation_types.dart';
import 'package:money/widgets/token_text.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/field_type.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

/// Accounts like Banks
class Account extends DataObject {
  /// Constructor
  Account();

  /// Constructor from a SQLite row
  factory Account.fromJson(final MyJson row) {
    return Account()
      ..fieldId.value = row.getInt('Id')
      ..fieldAccountId.value = row.getString('AccountId')
      ..fieldOfxAccountId.value = row.getString('OfxAccountId')
      ..fieldName.value = row.getString('Name')
      ..fieldDescription.value = row.getString('Description')
      ..fieldType.value = AccountType.values[row.getInt('Type')]
      ..fieldOpeningBalance.value.setAmount(row.getDouble('OpeningBalance'))
      ..fieldCurrency.value = row.getString(
        'Currency',
        Constants.defaultCurrency,
      )
      ..fieldOnlineAccount.value = row.getInt('OnlineAccount')
      ..fieldWebSite.value = row.getString('WebSite')
      ..fieldReconcileWarning.value = row.getInt('ReconcileWarning')
      ..fieldLastSync.value = row.getDate('LastSync')
      ..fieldSyncGuid.value = row.getString('SyncGuid')
      ..fieldFlags.value = row.getInt('Flags')
      ..fieldLastBalance.value = row.getDate('LastBalance')
      ..fieldCategoryIdForPrincipal.value = row.getInt(
        'CategoryIdForPrincipal',
        -1,
      )
      ..fieldCategoryIdForInterest.value = row.getInt(
        'CategoryIdForInterest',
        -1,
      );
  }

  /// Balance
  double balance = 0.00;

  // Account ID
  // 1|AccountId|nchar(20)|0||0
  FieldString fieldAccountId = FieldString(
    name: 'Account ID',
    serializeName: 'AccountId',
    getValueForDisplay: (final DataInterface instance) => (instance as Account).fieldAccountId.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Account).fieldAccountId.value,
    setValue: (final DataInterface instance, dynamic value) =>
        (instance as Account).fieldAccountId.value = value as String,
  );

  /// Balance in Native currency
  FieldMoney fieldBalanceNative = FieldMoney(
    name: 'BalanceN',
    footer: FooterType.range,
    getValueForDisplay: (final DataInterface instance) {
      final Account accountInstance = instance as Account;
      return AmountModel(
        amount: accountInstance.balance,
        iso4217: accountInstance.getAccountCurrencyAsText(),
      );
    },
  );

  /// Balance Normalized use in the List view
  FieldMoney fieldBalanceNormalized = FieldMoney(
    name: 'Balance(USD)',
    footer: FooterType.range,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (final DataInterface instance) {
      final Account accountInstance = instance as Account;
      return AmountModel(
        amount: accountInstance.getCurrencyRatio() * accountInstance.balance,
        iso4217: Constants.defaultCurrency,
      );
    },
  );

  /// categoryIdForInterest
  /// 16|CategoryIdForInterest|INT|0||0
  FieldInt fieldCategoryIdForInterest = FieldInt(
    name: 'Category for Interest',
    serializeName: 'CategoryIdForInterest',
    type: FieldType.text,
    defaultValue: 0,
    useAsDetailPanels: (final DataInterface instance) => (instance as Account).fieldType.value == AccountType.loan,
    getValueForDisplay: (final DataInterface instance) => DataObject.getCategoryName(
      (instance as Account).fieldCategoryIdForInterest.value,
    ),
    getValueForSerialization: (final DataInterface instance) => (instance as Account).fieldCategoryIdForInterest.value,
  );

  /// categoryIdForPrincipal
  /// 15 | CategoryIdForPrincipal|INT|0||0
  FieldInt fieldCategoryIdForPrincipal = FieldInt(
    name: 'Category for Principal',
    serializeName: 'CategoryIdForPrincipal',
    type: FieldType.text,
    defaultValue: 0,
    useAsDetailPanels: (final DataInterface instance) => (instance as Account).fieldType.value == AccountType.loan,
    getValueForDisplay: (final DataInterface instance) => DataObject.getCategoryName(
      (instance as Account).fieldCategoryIdForPrincipal.value,
    ),
    getValueForSerialization: (final DataInterface instance) => (instance as Account).fieldCategoryIdForPrincipal.value,
  );

  // ------------------------------------------------
  // Properties that are not persisted

  /// Transaction Count
  FieldInt fieldCount = FieldInt(
    name: 'Transactions',
    columnWidth: ColumnWidth.tiny,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (final DataInterface instance) => (instance as Account).fieldCount.value,
  );

  /// Currency
  /// 7|Currency|nchar(3)|0||0
  FieldString fieldCurrency = FieldString(
    name: 'Currency',
    serializeName: 'Currency',
    align: TextAlign.center,
    columnWidth: ColumnWidth.tiny,
    type: FieldType.widget,
    getValueForDisplay: (final DataInterface instance) => buildCurrencyWidget(
      (instance as Account).getAccountCurrencyAsText(),
    ),
    getValueForSerialization: (final DataInterface instance) => (instance as Account).getAccountCurrencyAsText(),
    setValue: (final DataInterface instance, dynamic value) =>
        (instance as Account).fieldCurrency.value = value as String,
    sort: (final DataInterface a, final DataInterface b, final bool ascending) => sortByString(
      (a as Account).getAccountCurrencyAsText(),
      (b as Account).getAccountCurrencyAsText(),
      ascending,
    ),
  );

  // Description
  // 4|Description|nvarchar(255)|0||0
  FieldString fieldDescription = FieldString(
    name: 'Description',
    serializeName: 'Description',
    setValue: (final DataInterface instance, dynamic value) =>
        (instance as Account).fieldDescription.value = value as String,
    getValueForDisplay: (final DataInterface instance) => (instance as Account).fieldDescription.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Account).fieldDescription.value,
  );

  /// Flags
  /// 13|Flags|INT|0||0
  FieldInt fieldFlags = FieldInt(
    serializeName: 'Flags',
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (final DataInterface instance) => (instance as Account).fieldFlags.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Account).fieldFlags.value,
  );

  // Id
  // 0|Id|INT|0||1
  FieldId fieldId = FieldId(
    getValueForSerialization: (final DataInterface instance) => (instance as Account).uniqueId,
  );

  Field<bool> fieldIsAccountOpen = Field<bool>(
    name: 'Account is open',
    defaultValue: false,
    useAsDetailPanels: defaultCallbackValueTrue,
    type: FieldType.toggle,
    getValueForDisplay: (final DataInterface instance) => !(instance as Account).isClosed(),
    setValue: (final DataInterface instance, dynamic value) {
      (instance as Account).isOpen = value as bool;
      DataObject.onMutationChanged?.call(
        mutation: MutationType.changed,
        moneyObject: instance,
      );
    },
  );

  /// Last Balance date
  /// 14|LastBalance|datetime|0||0
  FieldDate fieldLastBalance = FieldDate(
    serializeName: 'LastBalance',
    getValueForDisplay: (final DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as Account).fieldLastBalance.value,
    ),
    getValueForSerialization: (final DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as Account).fieldLastBalance.value,
    ),
  );

  /// LastSync Date & Time
  /// 11|LastSync|datetime|0||0
  FieldDate fieldLastSync = FieldDate(
    serializeName: 'LastSync',
    getValueForDisplay: (final DataInterface instance) => (instance as Account).fieldLastSync.value,
    getValueForSerialization: (final DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as Account).fieldLastSync.value,
    ),
  );

  // Name
  // 3|Name|nvarchar(80)|1||0
  FieldString fieldName = FieldString(
    name: 'Name',
    serializeName: 'Name',
    columnWidth: ColumnWidth.large,
    type: FieldType.widget,
    getValueForDisplay: (final DataInterface instance) => TokenText((instance as Account).fieldName.value),
    getValueForSerialization: (final DataInterface instance) => (instance as Account).fieldName.value,
    setValue: (final DataInterface instance, dynamic value) => (instance as Account).fieldName.value = value as String,
    sort: (final DataInterface a, final DataInterface b, final bool ascending) => sortByString(
      (a as Account).fieldName.value,
      (b as Account).fieldName.value,
      ascending,
    ),
  );

  // OFX Account Id
  // 2|OfxAccountId|nvarchar(50)|0||0
  FieldString fieldOfxAccountId = FieldString(
    name: 'OfxAccountId',
    serializeName: 'OfxAccountId',
    getValueForDisplay: (final DataInterface instance) => (instance as Account).fieldOfxAccountId.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Account).fieldOfxAccountId.value,
    setValue: (final DataInterface instance, dynamic value) =>
        (instance as Account).fieldOfxAccountId.value = value as String,
  );

  /// OnlineAccount
  /// 8|OnlineAccount|INT|0||0
  FieldInt fieldOnlineAccount = FieldInt(
    name: 'OnlineAccount',
    serializeName: 'OnlineAccount',
    getValueForSerialization: (final DataInterface instance) => (instance as Account).fieldOnlineAccount.value,
  );

  // 6 Open Balance
  // 6|OpeningBalance|money|0||0
  FieldMoney fieldOpeningBalance = FieldMoney(
    name: 'Opening Balance',
    serializeName: 'OpeningBalance',
    getValueForDisplay: (final DataInterface instance) => (instance as Account).fieldOpeningBalance.value,
    getValueForSerialization: (final DataInterface instance) =>
        (instance as Account).fieldOpeningBalance.value.asDouble(),
  );

  /// ReconcileWarning
  /// 10|ReconcileWarning|INT|0||0
  FieldInt fieldReconcileWarning = FieldInt(
    serializeName: 'ReconcileWarning',
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForSerialization: (final DataInterface instance) => (instance as Account).fieldReconcileWarning.value,
  );

  FieldMoney fieldStockHoldingEstimation = FieldMoney(
    name: 'StockValue',
    getValueForDisplay: (final DataInterface instance) => (instance as Account).fieldStockHoldingEstimation.value,
  );

  /// SyncGuid
  /// 12|SyncGuid|uniqueidentifier|0||0
  FieldString fieldSyncGuid = FieldString(
    serializeName: 'SyncGuid',
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForSerialization: (final DataInterface instance) =>
        // this field can not be blank, it needs to be a valid GUID or Null
        (instance as Account).fieldSyncGuid.value.isEmpty ? null : instance.fieldSyncGuid.value.isEmpty,
  );

  // Type of account
  // 5|Type|INT|1||0
  Field<AccountType> fieldType = Field<AccountType>(
    type: FieldType.text,
    align: TextAlign.center,
    columnWidth: ColumnWidth.small,
    name: 'Type',
    serializeName: 'Type',
    defaultValue: AccountType.checking,
    getValueForDisplay: (final DataInterface instance) => getTypeAsText((instance as Account).fieldType.value),
    getValueForSerialization: (final DataInterface instance) => (instance as Account).fieldType.value.index,
    getEditWidget:
        (
          final DataInterface instance,
          void Function(bool /* wasModified */) onEdited,
        ) {
          return pickerAccountType(
            itemSelected: (instance as Account).fieldType.value,
            onSelected: (AccountType newSelection) {
              instance.fieldType.value = newSelection;
              onEdited(true); // notify container
            },
          );
        },
    setValue: (final DataInterface instance, dynamic value) {
      (instance as Account).fieldType.value = AccountType.values[value as int];
    },
  );

  FieldDate fieldUpdatedOn = FieldDate(
    name: 'Updated',
    columnWidth: ColumnWidth.tiny,
    getValueForDisplay: (final DataInterface instance) {
      if ((instance as Account).fieldLastSync.value == null) {
        return instance.fieldUpdatedOn.value;
      }
      return newestDate(
        instance.fieldLastSync.value,
        instance.fieldUpdatedOn.value,
      );
    },
  );

  /// WebSite
  /// 9|WebSite|nvarchar(512)|0||0
  FieldString fieldWebSite = FieldString(
    name: 'WebSite',
    serializeName: 'WebSite',
    getValueForDisplay: (final DataInterface instance) => (instance as Account).fieldWebSite.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Account).fieldWebSite.value,
  );

  Map</*year */ int, /*balance*/ double> maxBalancePerYears = <int, double>{};
  Map</*year */ int, /*balance*/ double> minBalancePerYears = <int, double>{};
  // cache the currency ratio
  double? ratio;

  @override
  Widget buildFieldsAsWidgetForSmallScreen() {
    Widget? originalCurrencyAndValue;

    if (fieldCurrency.value == Constants.defaultCurrency) {
      originalCurrencyAndValue = buildCurrencyWidget(
        fieldCurrency.value,
      );
    } else {
      final double ratioCurrency = getCurrencyRatio();
      originalCurrencyAndValue = Tooltip(
        message: ratioCurrency.toString(),
        child: Row(
          children: <Widget>[
            Text(
              getAmountAsStringUsingCurrency(
                balance / ratioCurrency,
                iso4217code: fieldCurrency.value,
              ),
            ),
            const SizedBox(width: 4),
            buildCurrencyWidget(fieldCurrency.value),
          ],
        ),
      );
    }

    return MyListItemAsCard(
      leftTopAsString: fieldName.value,
      leftBottomAsString: getTypeAsText(fieldType.value),
      rightTopAsString: getAmountAsStringUsingCurrency(balance),
      rightBottomAsWidget: originalCurrencyAndValue,
    );
  }

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  String getRepresentation() {
    return fieldName.value;
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<Account> _fields = Fields<Account>();
  static final Fields<Account> _fieldsForColumns = Fields<Account>();

  /// Returns field definitions for Account entities.
  static Fields<Account> get fields {
    if (_fields.isEmpty) {
      final Account tmp = Account.fromJson(<String, dynamic>{});
      _fields.setDefinitions(<Field<dynamic>>[
        tmp.fieldId,
        tmp.fieldName,
        tmp.fieldAccountId,
        tmp.fieldDescription,
        tmp.fieldType,
        tmp.fieldOpeningBalance,
        tmp.fieldOnlineAccount,
        tmp.fieldWebSite,
        tmp.fieldReconcileWarning,
        tmp.fieldLastSync,
        tmp.fieldSyncGuid,
        tmp.fieldUpdatedOn,
        tmp.fieldFlags,
        tmp.fieldLastBalance,
        tmp.fieldCategoryIdForPrincipal,
        tmp.fieldCategoryIdForInterest,
        tmp.fieldCount,
        tmp.fieldStockHoldingEstimation,
        tmp.fieldBalanceNative,
        tmp.fieldCurrency,
        tmp.fieldBalanceNormalized,
        tmp.fieldIsAccountOpen,
      ]);
    }
    return _fields;
  }

  /// Returns field definitions for Account column view.
  static Fields<Account> get fieldsForColumnView {
    if (_fieldsForColumns.isEmpty) {
      final Account tmp = Account.fromJson(<String, dynamic>{});
      _fieldsForColumns.setDefinitions(<Field<dynamic>>[
        tmp.fieldName,
        tmp.fieldAccountId,
        tmp.fieldDescription,
        tmp.fieldType,
        tmp.fieldUpdatedOn,
        tmp.fieldCount,
        tmp.fieldBalanceNative,
        tmp.fieldCurrency,
        tmp.fieldBalanceNormalized,
      ]);
    }
    return _fieldsForColumns;
  }

  /// Returns the account currency as a display string.
  String getAccountCurrencyAsText() {
    return getCurrencyAsString(fieldCurrency.value);
  }

  /// Returns a widget displaying the account currency.
  Widget getAccountCurrencyAsWidget() {
    return buildCurrencyWidget(getAccountCurrencyAsText());
  }

  /// Returns the currency ratio for the account's currency.
  double getCurrencyRatio() {
    return DataObject.getCurrencyRatio(fieldCurrency.value);
  }

  /// Returns the account name; empty string if null.
  static String getName(final Account? instance) {
    return instance == null ? '' : instance.fieldName.value;
  }

  /// True if the account is an active bank account.
  bool isActiveBankAccount() {
    return isBankAccount() && isOpen;
  }

  /// True if the account is an asset account.
  bool get isAssetAccount {
    return fieldType.value == AccountType.asset;
  }

  /// True if the account is a bank account.
  bool isBankAccount() {
    return fieldType.value == AccountType.savings ||
        fieldType.value == AccountType.checking ||
        fieldType.value == AccountType.cash;
  }

  /// Returns true if [bitIndex] is set in [value].
  bool isBitOn(final int value, final int bitIndex) {
    return (value & bitIndex) == bitIndex;
  }

  /// True if the account is closed.
  bool isClosed() {
    return isBitOn(fieldFlags.value, AccountFlags.closed.index);
  }

  /// True if the account is a fake/internal account.
  bool isFakeAccount() {
    return fieldType.value == AccountType.notUsed_7 || fieldType.value == AccountType.categoryFund;
  }

  /// True if the account is an investment account.
  bool isInvestmentAccount() {
    return fieldType.value == AccountType.investment ||
        fieldType.value == AccountType.retirement ||
        fieldType.value == AccountType.moneyMarket;
  }

  /// True if the account matches the user's filter choices (including closed).
  bool get isMatchingUserChoiceIncludingClosedAccount {
    if (PreferenceController.to.includeClosedAccounts) {
      return true;
    }
    return isOpen;
  }

  /// True if the account is open.
  bool get isOpen {
    return !isClosed();
  }

  /// Sets the open/closed state of the account.
  set isOpen(bool value) {
    if (value) {
      fieldFlags.value &= ~AccountFlags.closed.index; // Remove the bit at the specified position
    } else {
      fieldFlags.value |= AccountFlags.closed.index; // Set the bit at the specified position
    }
  }

  /// Returns true if the account type matches any of the given [types].
  bool matchType(final List<AccountType> types) {
    if (types.isEmpty) {
      // All accounts except the fake ones
      return !isFakeAccount();
    }
    return types.contains(fieldType.value);
  }
}
