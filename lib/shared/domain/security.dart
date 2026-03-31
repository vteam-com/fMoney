import 'package:money/data/models/dividend.dart';
import 'package:money/data/models/field_type.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/shared/domain/field_definition_cache.dart';
import 'package:money/shared/domain/stock_split.dart';
import 'package:money/widgets/list/list_item_card.dart';
import 'package:money/widgets/pickers/picker_security_type.dart';
import 'package:money/widgets/pure/quantity_widget.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';

/*
  cid  name          type          notnull  dflt_value  pk
  ---  ------------  ------------  -------  ----------  --
  0    Id            INT           0                    1
  1    Name          nvarchar(80)  1                    0
  2    Symbol        nchar(20)     1                    0
  3    Price         money         0                    0
  4    LastPrice     money         0                    0
  5    CUSPID        nchar(20)     0                    0
  6    SECURITYTYPE  INT           0                    0
  7    TAXABLE       tinyint       0                    0
  8    PriceDate     datetime      0                    0
 */

/// Represents security.
class Security extends DataObject {
  Security({
    required int id,
    required String name,
    required String symbol,
    required double price,
    required double lastPrice,
    required String cuspid,
    required int securityType,
    required int taxable,
    required DateTime? priceDate,
  }) {
    this.fieldId.value = id;
    this.fieldName.value = name;
    this.fieldSymbol.value = symbol;
    this.fieldPrice.value.setAmount(price);
    this.fieldLastPrice.value.setAmount(lastPrice);
    this.fieldCuspid.value = cuspid;
    this.fieldSecurityType.value = securityType;
    this.taxable.value = taxable;
    this.fieldPriceDate.value = priceDate;
  }

  /// Constructor from a SQLite row
  factory Security.fromJson(final MyJson row) {
    return Security(
      // 0
      id: row.getInt(SharedDomainStrings.domainString057, -1),
      // 1
      name: row.getString(SharedDomainStrings.domainString088),
      // 2
      symbol: row.getString(SharedDomainStrings.domainString131),
      // 3
      price: row.getDouble(SharedDomainStrings.domainString108),
      // 4
      lastPrice: row.getDouble(SharedDomainStrings.domainString079),
      // 5
      cuspid: row.getString(SharedDomainStrings.domainString027),
      // 6
      securityType: row.getInt(SharedDomainStrings.domainString120),
      // 7
      taxable: row.getInt(SharedDomainStrings.domainString137),
      // 8
      priceDate: row.getDate(SharedDomainStrings.domainString109),
    );
  }

  final FieldMoney fieldHoldingValue = FieldMoney(
    name: 'HoldingsValue',
    getValueForDisplay: (final DataInterface instance) => AmountModel(amount: (instance as Security).holdingValue),
  );

  List<Dividend> dividends = <Dividend>[];
  FieldMoney fieldActivityDividend = FieldMoney(
    name: 'Dividend',
    getValueForDisplay: (final DataInterface instance) => (instance as Security).fieldActivityDividend.value,
  );

  FieldMoney fieldActivityProfit = FieldMoney(
    name: 'ActivityProfit',
    getValueForDisplay: (final DataInterface instance) => (instance as Security).fieldActivityProfit.value,
  );

  // 5
  FieldString fieldCuspid = FieldString(
    name: SharedDomainStrings.domainString027,
    serializeName: SharedDomainStrings.domainString027,
    getValueForDisplay: (final DataInterface instance) => (instance as Security).fieldCuspid.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Security).fieldCuspid.value,
  );

  FieldQuantity fieldHoldingShares = FieldQuantity(
    name: 'Holding',
    columnWidth: ColumnWidth.small,
    getValueForDisplay: (final DataInterface instance) => (instance as Security).fieldHoldingShares.value,
  );

  // 0
  FieldId fieldId = FieldId(
    getValueForSerialization: (final DataInterface instance) => (instance as Security).uniqueId,
  );

  // 4
  FieldMoney fieldLastPrice = FieldMoney(
    name: 'Last Price',
    serializeName: SharedDomainStrings.domainString079,
    columnWidth: ColumnWidth.small,
    getValueForDisplay: (final DataInterface instance) => (instance as Security).fieldLastPrice.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Security).fieldLastPrice.value.asDouble(),
    setValue: (final DataInterface instance, dynamic value) {
      (instance as Security).fieldLastPrice.value.setAmount(value);
    },
  );

  // 1
  FieldString fieldName = FieldString(
    name: SharedDomainStrings.domainString088,
    serializeName: SharedDomainStrings.domainString088,
    columnWidth: ColumnWidth.largest,
    getValueForDisplay: (final DataInterface instance) => (instance as Security).fieldName.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Security).fieldName.value,
    setValue: (final DataInterface instance, dynamic value) {
      (instance as Security).fieldName.value = value as String;
    },
  );

  // Not persisted fields

  FieldInt fieldNumberOfTrades = FieldInt(
    name: 'Trades',
    columnWidth: ColumnWidth.nano,
    getValueForDisplay: (final DataInterface instance) => (instance as Security).fieldNumberOfTrades.value,
  );

  // 3
  FieldMoney fieldPrice = FieldMoney(
    name: SharedDomainStrings.domainString108,
    columnWidth: ColumnWidth.small,
    serializeName: SharedDomainStrings.domainString108,
    getValueForDisplay: (final DataInterface instance) => (instance as Security).fieldPrice.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Security).fieldPrice.value.asDouble(),
    setValue: (final DataInterface instance, dynamic value) => (instance as Security).fieldPrice.value.setAmount(value),
  );

  // 8
  FieldDate fieldPriceDate = FieldDate(
    name: 'LatestPrice',
    serializeName: SharedDomainStrings.domainString109,
    getValueForDisplay: (final DataInterface instance) => (instance as Security).fieldPriceDate.value,
    getValueForSerialization: (final DataInterface instance) =>
        dateToSqliteFormat((instance as Security).fieldPriceDate.value),
    setValue: (final DataInterface instance, dynamic value) {
      (instance as Security).fieldPriceDate.value = attemptToGetDateFromDynamic(
        value,
      );
    },
  );

  /// Returns total profit including activity profit, dividends, and holding value.
  double get profit =>
      this.fieldActivityProfit.value.asDouble() + this.fieldActivityDividend.value.asDouble() + this.holdingValue;
  FieldMoney fieldProfit = FieldMoney(
    name: 'Profit',
    getValueForDisplay: (final DataInterface instance) => AmountModel(amount: (instance as Security).profit),
  );

  /* 
    enum SecurityType {
      none,
      bond, // Bonds
      mutualFund,
      equity, // stocks
      moneyMarket, // cash
      etf, // electronically traded fund
      reit, // Real estate investment trust
      futures, // Futures (a type of commodity investment)
      private, // Investment in a private company.
    } 
  */
  // 6
  FieldInt fieldSecurityType = FieldInt(
    name: SharedDomainStrings.domainString146,
    serializeName: SharedDomainStrings.domainString120,
    columnWidth: ColumnWidth.tiny,
    type: FieldType.text,
    align: TextAlign.center,
    getValueForDisplay: (final DataInterface instance) => getSecurityTypeFromInt(
      (instance as Security).fieldSecurityType.value,
    ),
    getValueForSerialization: (final DataInterface instance) => (instance as Security).fieldSecurityType.value,
    getEditWidget:
        (
          DataInterface instance,
          void Function(bool /* wasModified */) onEdited,
        ) {
          instance = instance as Security;
          return pickerSecurityType(
            itemSelected: SecurityType.values[instance.fieldSecurityType.value],
            onSelected: (final SecurityType? newSecurityType) {
              if (newSecurityType != null) {
                (instance as Security).fieldSecurityType.value = newSecurityType.index;
                // notify container
                onEdited(true);
              }
            },
          );
        },
    setValue: (final DataInterface instance, dynamic value) {
      (instance as Security).fieldSecurityType.value = value as int;
    },
  );

  // 2
  FieldString fieldSymbol = FieldString(
    name: SharedDomainStrings.domainString131,
    serializeName: SharedDomainStrings.domainString131,
    getValueForDisplay: (final DataInterface instance) => (instance as Security).fieldSymbol.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Security).fieldSymbol.value,
    setValue: (final DataInterface instance, dynamic value) {
      (instance as Security).fieldSymbol.value = value as String;
    },
  );

  Field<DateRange> fieldTransactionDateRange = Field<DateRange>(
    name: 'Dates',
    defaultValue: DateRange(),
    type: FieldType.dateRange,
    footer: FooterType.range,
    getValue: (final DataInterface instance) => (instance as Security).fieldTransactionDateRange.value,
    getValueForDisplay: (final DataInterface instance) =>
        (instance as Security).fieldTransactionDateRange.value.toStringYears(),
  );

  List<StockSplit> splitsHistory = <StockSplit>[];
  // 7
  FieldInt taxable = FieldInt(
    name: SharedDomainStrings.domainString137,
    serializeName: SharedDomainStrings.domainString137,
    getValueForDisplay: (final DataInterface instance) => (instance as Security).taxable.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Security).taxable.value,
  );

  @override
  Widget buildFieldsAsWidgetForSmallScreen() {
    return MyListItemAsCard(
      leftTopAsString: fieldSymbol.value,
      leftBottomAsWidget: QuantityWidget(
        quantity: fieldHoldingShares.value.toDouble(),
        align: TextAlign.left,
      ),
      rightTopAsWidget: fieldProfit.getValueAsWidget(this),
      rightBottomAsWidget: fieldHoldingValue.getValueAsWidget(this),
    );
  }

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<Security> _fields = Fields<Security>();
  static final Fields<Security> _fieldsForColumns = Fields<Security>();
  static final List<FieldBlueprint<Security>> _fieldBlueprints = <FieldBlueprint<Security>>[
    FieldBlueprint<Security>(selector: (Security tmp) => tmp.fieldId),
    FieldBlueprint<Security>(selector: (Security tmp) => tmp.fieldName, includeInColumnView: true),
    FieldBlueprint<Security>(selector: (Security tmp) => tmp.fieldSymbol, includeInColumnView: true),
    FieldBlueprint<Security>(
      selector: (Security tmp) => tmp.fieldTransactionDateRange,
      includeInColumnView: true,
    ),
    FieldBlueprint<Security>(selector: (Security tmp) => tmp.fieldPrice, includeInColumnView: true),
    FieldBlueprint<Security>(selector: (Security tmp) => tmp.fieldLastPrice, includeInColumnView: true),
    FieldBlueprint<Security>(selector: (Security tmp) => tmp.fieldCuspid),
    FieldBlueprint<Security>(
      selector: (Security tmp) => tmp.fieldSecurityType,
      includeInColumnView: true,
    ),
    FieldBlueprint<Security>(
      selector: (Security tmp) => tmp.fieldNumberOfTrades,
      includeInColumnView: true,
    ),
    FieldBlueprint<Security>(
      selector: (Security tmp) => tmp.fieldHoldingShares,
      includeInColumnView: true,
    ),
    FieldBlueprint<Security>(
      selector: (Security tmp) => tmp.fieldHoldingValue,
      includeInColumnView: true,
    ),
    FieldBlueprint<Security>(
      selector: (Security tmp) => tmp.fieldActivityProfit,
      includeInColumnView: true,
    ),
    FieldBlueprint<Security>(
      selector: (Security tmp) => tmp.fieldActivityDividend,
      includeInColumnView: true,
    ),
    FieldBlueprint<Security>(selector: (Security tmp) => tmp.fieldProfit, includeInColumnView: true),
  ];

  /// Returns the field definitions for Security entities.
  static Fields<Security> get fields => ensureCachedFieldDefinitionsFromBlueprints<Security>(
    cache: _fields,
    instanceFactory: () => Security.fromJson(<String, dynamic>{}),
    blueprints: _fieldBlueprints,
    forColumnView: false,
  );

  /// Returns the field definitions for Security column view.
  static Fields<Security> get fieldsForColumnView => ensureCachedFieldDefinitionsFromBlueprints<Security>(
    cache: _fieldsForColumns,
    instanceFactory: () => Security.fromJson(<String, dynamic>{}),
    blueprints: _fieldBlueprints,
    forColumnView: true,
  );

  /// Returns a display string for the security type index.
  static String getSecurityTypeFromInt(final int index) {
    if (isIndexInRange(SecurityType.values, index)) {
      return SecurityType.values[index].name;
    }
    return '';
  }

  /// Returns the holding value based on shares and latest price.
  double get holdingValue => this.fieldHoldingShares.value * this.fieldPrice.value.asDouble();
}
