import 'package:money/data/models/account_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/locale_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/field_definition_cache_helper.dart';
import 'package:money/widgets/list/list_item_card.dart';
import 'package:money/widgets/pickers/picker_account_type.dart';
import 'package:money/widgets/pickers/token_text_widget.dart';
import 'package:money/widgets/pure/mutation_types.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

/// Accounts like Banks
class Account extends DataObject {
  /// Constructor
  Account();

  /// Constructor from a SQLite row
  factory Account.fromJson(MyJson row) {
    return Account()
      ..fieldId.value = row.getInt(SharedDomainStrings.domainString057)
      ..fieldAccountId.value = row.getString(SharedDomainStrings.domainString013)
      ..fieldOfxAccountId.value = row.getString(SharedDomainStrings.domainString095)
      ..fieldName.value = row.getString(SharedDomainStrings.domainString088)
      ..fieldDescription.value = row.getString(SharedDomainStrings.domainString046)
      ..fieldType.value = AccountType.values[row.getInt(SharedDomainStrings.domainString146)]
      ..fieldOpeningBalance.value.setAmount(row.getDouble(SharedDomainStrings.domainString099))
      ..fieldCurrency.value = row.getString(
        SharedDomainStrings.domainString042,
        Constants.defaultCurrency,
      )
      ..fieldOnlineAccount.value = row.getInt(SharedDomainStrings.domainString098)
      ..fieldWebSite.value = row.getString(SharedDomainStrings.domainString152)
      ..fieldReconcileWarning.value = row.getInt(SharedDomainStrings.domainString115)
      ..fieldLastSync.value = row.getDate(SharedDomainStrings.domainString081)
      ..fieldSyncGuid.value = row.getString(SharedDomainStrings.domainString132)
      ..fieldFlags.value = row.getInt(SharedDomainStrings.domainString055)
      ..fieldLastBalance.value = row.getDate(SharedDomainStrings.domainString078)
      ..fieldCategoryIdForPrincipal.value = row.getInt(
        SharedDomainStrings.domainString037,
        -1,
      )
      ..fieldCategoryIdForInterest.value = row.getInt(
        SharedDomainStrings.domainString036,
        -1,
      );
  }

  /// Balance
  double balance = 0.00;

  // Account ID
  // 1|AccountId|nchar(20)|0||0
  FieldString fieldAccountId = FieldString(
    name: 'Account ID',
    serializeName: SharedDomainStrings.domainString013,
    getValueForDisplay: (DataInterface instance) => (instance as Account).fieldAccountId.value,
    getValueForSerialization: (DataInterface instance) => (instance as Account).fieldAccountId.value,
    setValue: (DataInterface instance, dynamic value) => (instance as Account).fieldAccountId.value = value as String,
  );

  /// Balance in Native currency
  FieldMoney fieldBalanceNative = FieldMoney(
    name: 'BalanceN',
    footer: FooterType.range,
    getValueForDisplay: (DataInterface instance) {
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
    getValueForDisplay: (DataInterface instance) {
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
    serializeName: SharedDomainStrings.domainString036,
    type: FieldType.text,
    defaultValue: 0,
    useAsDetailPanels: (DataInterface instance) => (instance as Account).fieldType.value == AccountType.loan,
    getValueForDisplay: (DataInterface instance) => DataObject.getCategoryName(
      (instance as Account).fieldCategoryIdForInterest.value,
    ),
    getValueForSerialization: (DataInterface instance) => (instance as Account).fieldCategoryIdForInterest.value,
  );

  /// categoryIdForPrincipal
  /// 15 | CategoryIdForPrincipal|INT|0||0
  FieldInt fieldCategoryIdForPrincipal = FieldInt(
    name: 'Category for Principal',
    serializeName: SharedDomainStrings.domainString037,
    type: FieldType.text,
    defaultValue: 0,
    useAsDetailPanels: (DataInterface instance) => (instance as Account).fieldType.value == AccountType.loan,
    getValueForDisplay: (DataInterface instance) => DataObject.getCategoryName(
      (instance as Account).fieldCategoryIdForPrincipal.value,
    ),
    getValueForSerialization: (DataInterface instance) => (instance as Account).fieldCategoryIdForPrincipal.value,
  );

  // ------------------------------------------------
  // Properties that are not persisted

  /// Transaction Count
  FieldInt fieldCount = FieldInt(
    name: SharedDomainStrings.domainString143,
    columnWidth: ColumnWidth.tiny,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (DataInterface instance) => (instance as Account).fieldCount.value,
  );

  /// Currency
  /// 7|Currency|nchar(3)|0||0
  FieldString fieldCurrency = FieldString(
    name: SharedDomainStrings.domainString042,
    serializeName: SharedDomainStrings.domainString042,
    align: TextAlign.center,
    columnWidth: ColumnWidth.tiny,
    type: FieldType.widget,
    getValueForDisplay: (DataInterface instance) => buildCurrencyWidget(
      (instance as Account).getAccountCurrencyAsText(),
    ),
    getValueForSerialization: (DataInterface instance) => (instance as Account).getAccountCurrencyAsText(),
    setValue: (DataInterface instance, dynamic value) => (instance as Account).fieldCurrency.value = value as String,
    sort: (DataInterface a, DataInterface b, bool ascending) => sortByString(
      (a as Account).getAccountCurrencyAsText(),
      (b as Account).getAccountCurrencyAsText(),
      ascending,
    ),
  );

  // Description
  // 4|Description|nvarchar(255)|0||0
  FieldString fieldDescription = FieldString(
    name: SharedDomainStrings.domainString046,
    serializeName: SharedDomainStrings.domainString046,
    setValue: (DataInterface instance, dynamic value) => (instance as Account).fieldDescription.value = value as String,
    getValueForDisplay: (DataInterface instance) => (instance as Account).fieldDescription.value,
    getValueForSerialization: (DataInterface instance) => (instance as Account).fieldDescription.value,
  );

  /// Flags
  /// 13|Flags|INT|0||0
  FieldInt fieldFlags = FieldInt(
    serializeName: SharedDomainStrings.domainString055,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (DataInterface instance) => (instance as Account).fieldFlags.value,
    getValueForSerialization: (DataInterface instance) => (instance as Account).fieldFlags.value,
  );

  // Id
  // 0|Id|INT|0||1
  FieldId fieldId = FieldId(
    getValueForSerialization: (DataInterface instance) => (instance as Account).uniqueId,
  );

  Field<bool> fieldIsAccountOpen = Field<bool>(
    name: 'Account is open',
    defaultValue: false,
    useAsDetailPanels: defaultCallbackValueTrue,
    type: FieldType.toggle,
    getValueForDisplay: (DataInterface instance) => !(instance as Account).isClosed(),
    setValue: (DataInterface instance, dynamic value) {
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
    serializeName: SharedDomainStrings.domainString078,
    getValueForDisplay: (DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as Account).fieldLastBalance.value,
    ),
    getValueForSerialization: (DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as Account).fieldLastBalance.value,
    ),
  );

  /// LastSync Date & Time
  /// 11|LastSync|datetime|0||0
  FieldDate fieldLastSync = FieldDate(
    serializeName: SharedDomainStrings.domainString081,
    getValueForDisplay: (DataInterface instance) => (instance as Account).fieldLastSync.value,
    getValueForSerialization: (DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as Account).fieldLastSync.value,
    ),
  );

  // Name
  // 3|Name|nvarchar(80)|1||0
  FieldString fieldName = FieldString(
    name: SharedDomainStrings.domainString088,
    serializeName: SharedDomainStrings.domainString088,
    columnWidth: ColumnWidth.large,
    type: FieldType.widget,
    getValueForDisplay: (DataInterface instance) => TokenText((instance as Account).fieldName.value),
    getValueForSerialization: (DataInterface instance) => (instance as Account).fieldName.value,
    setValue: (DataInterface instance, dynamic value) => (instance as Account).fieldName.value = value as String,
    sort: (DataInterface a, DataInterface b, bool ascending) => sortByString(
      (a as Account).fieldName.value,
      (b as Account).fieldName.value,
      ascending,
    ),
  );

  // OFX Account Id
  // 2|OfxAccountId|nvarchar(50)|0||0
  FieldString fieldOfxAccountId = FieldString(
    name: SharedDomainStrings.domainString095,
    serializeName: SharedDomainStrings.domainString095,
    getValueForDisplay: (DataInterface instance) => (instance as Account).fieldOfxAccountId.value,
    getValueForSerialization: (DataInterface instance) => (instance as Account).fieldOfxAccountId.value,
    setValue: (DataInterface instance, dynamic value) =>
        (instance as Account).fieldOfxAccountId.value = value as String,
  );

  /// OnlineAccount
  /// 8|OnlineAccount|INT|0||0
  FieldInt fieldOnlineAccount = FieldInt(
    name: SharedDomainStrings.domainString098,
    serializeName: SharedDomainStrings.domainString098,
    getValueForSerialization: (DataInterface instance) => (instance as Account).fieldOnlineAccount.value,
  );

  // 6 Open Balance
  // 6|OpeningBalance|money|0||0
  FieldMoney fieldOpeningBalance = FieldMoney(
    name: 'Opening Balance',
    serializeName: SharedDomainStrings.domainString099,
    getValueForDisplay: (DataInterface instance) => (instance as Account).fieldOpeningBalance.value,
    getValueForSerialization: (DataInterface instance) => (instance as Account).fieldOpeningBalance.value.asDouble(),
  );

  /// ReconcileWarning
  /// 10|ReconcileWarning|INT|0||0
  FieldInt fieldReconcileWarning = FieldInt(
    serializeName: SharedDomainStrings.domainString115,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForSerialization: (DataInterface instance) => (instance as Account).fieldReconcileWarning.value,
  );

  FieldMoney fieldStockHoldingEstimation = FieldMoney(
    name: 'StockValue',
    getValueForDisplay: (DataInterface instance) => (instance as Account).fieldStockHoldingEstimation.value,
  );

  /// SyncGuid
  /// 12|SyncGuid|uniqueidentifier|0||0
  FieldString fieldSyncGuid = FieldString(
    serializeName: SharedDomainStrings.domainString132,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForSerialization: (DataInterface instance) =>
        // this field can not be blank, it needs to be a valid GUID or Null
        (instance as Account).fieldSyncGuid.value.isEmpty ? null : instance.fieldSyncGuid.value.isEmpty,
  );

  // Type of account
  // 5|Type|INT|1||0
  Field<AccountType> fieldType = Field<AccountType>(
    type: FieldType.text,
    align: TextAlign.center,
    columnWidth: ColumnWidth.small,
    name: SharedDomainStrings.domainString146,
    serializeName: SharedDomainStrings.domainString146,
    defaultValue: AccountType.checking,
    getValueForDisplay: (DataInterface instance) => getTypeAsText((instance as Account).fieldType.value),
    getValueForSerialization: (DataInterface instance) => (instance as Account).fieldType.value.index,
    getEditWidget:
        (
          DataInterface instance,
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
    setValue: (DataInterface instance, dynamic value) {
      (instance as Account).fieldType.value = AccountType.values[value as int];
    },
  );

  FieldDate fieldUpdatedOn = FieldDate(
    name: 'Updated',
    columnWidth: ColumnWidth.tiny,
    getValueForDisplay: (DataInterface instance) {
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
    name: SharedDomainStrings.domainString152,
    serializeName: SharedDomainStrings.domainString152,
    getValueForDisplay: (DataInterface instance) => (instance as Account).fieldWebSite.value,
    getValueForSerialization: (DataInterface instance) => (instance as Account).fieldWebSite.value,
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
            const SizedBox(width: SizeForPadding.small),
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
  set uniqueId(int value) => fieldId.value = value;

  static final Fields<Account> _fields = Fields<Account>();
  static final Fields<Account> _fieldsForColumns = Fields<Account>();
  static final List<FieldBlueprint<Account>> _fieldBlueprints = <FieldBlueprint<Account>>[
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldId),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldName, includeInColumnView: true),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldAccountId, includeInColumnView: true),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldDescription, includeInColumnView: true),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldType, includeInColumnView: true),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldOpeningBalance),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldOnlineAccount),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldWebSite),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldReconcileWarning),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldLastSync),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldSyncGuid),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldUpdatedOn, includeInColumnView: true),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldFlags),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldLastBalance),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldCategoryIdForPrincipal),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldCategoryIdForInterest),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldCount, includeInColumnView: true),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldStockHoldingEstimation),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldBalanceNative, includeInColumnView: true),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldCurrency, includeInColumnView: true),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldBalanceNormalized, includeInColumnView: true),
    FieldBlueprint<Account>(selector: (Account tmp) => tmp.fieldIsAccountOpen),
  ];

  /// Returns field definitions for Account entities.
  static Fields<Account> get fields => ensureCachedFieldDefinitionsFromBlueprints<Account>(
    cache: _fields,
    instanceFactory: () => Account.fromJson(<String, dynamic>{}),
    blueprints: _fieldBlueprints,
    forColumnView: false,
  );

  /// Returns field definitions for Account column view.
  static Fields<Account> get fieldsForColumnView => ensureCachedFieldDefinitionsFromBlueprints<Account>(
    cache: _fieldsForColumns,
    instanceFactory: () => Account.fromJson(<String, dynamic>{}),
    blueprints: _fieldBlueprints,
    forColumnView: true,
  );

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
  static String getName(Account? instance) {
    return instance == null ? '' : instance.fieldName.value;
  }

  /// True if the account is an asset account.
  bool get isAssetAccount {
    return fieldType.value == AccountType.asset;
  }

  /// Returns true if [bitIndex] is set in [value].
  bool isBitOn(int value, int bitIndex) {
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
  bool matchType(List<AccountType> types) {
    if (types.isEmpty) {
      // All accounts except the fake ones
      return !isFakeAccount();
    }
    return types.contains(fieldType.value);
  }
}
