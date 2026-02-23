import 'package:money/data/models/dividend.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/views/providers/stock_split.dart';
import 'package:money/widgets/adaptive_list/list_item_card.dart';
import 'package:money/widgets/picker_security_type.dart';
import 'package:money/widgets/pure/quantity_widget.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/field_type.dart';

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
      id: row.getInt('Id', -1),
      // 1
      name: row.getString('Name'),
      // 2
      symbol: row.getString('Symbol'),
      // 3
      price: row.getDouble('Price'),
      // 4
      lastPrice: row.getDouble('LastPrice'),
      // 5
      cuspid: row.getString('CUSPID'),
      // 6
      securityType: row.getInt('SECURITYTYPE'),
      // 7
      taxable: row.getInt('Taxable'),
      // 8
      priceDate: row.getDate('PriceDate'),
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
    name: 'CUSPID',
    serializeName: 'CUSPID',
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
    serializeName: 'LastPrice',
    columnWidth: ColumnWidth.small,
    getValueForDisplay: (final DataInterface instance) => (instance as Security).fieldLastPrice.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Security).fieldLastPrice.value.asDouble(),
    setValue: (final DataInterface instance, dynamic value) {
      (instance as Security).fieldLastPrice.value.setAmount(value);
    },
  );

  // 1
  FieldString fieldName = FieldString(
    name: 'Name',
    serializeName: 'Name',
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
    name: 'Price',
    columnWidth: ColumnWidth.small,
    serializeName: 'Price',
    getValueForDisplay: (final DataInterface instance) => (instance as Security).fieldPrice.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Security).fieldPrice.value.asDouble(),
    setValue: (final DataInterface instance, dynamic value) => (instance as Security).fieldPrice.value.setAmount(value),
  );

  // 8
  FieldDate fieldPriceDate = FieldDate(
    name: 'LatestPrice',
    serializeName: 'PriceDate',
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
    name: 'Type',
    serializeName: 'SECURITYTYPE',
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
    name: 'Symbol',
    serializeName: 'Symbol',
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
    name: 'Taxable',
    serializeName: 'Taxable',
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

  /// Returns the field definitions for Security entities.
  static Fields<Security> get fields {
    if (_fields.isEmpty) {
      final Security tmp = Security.fromJson(<String, dynamic>{});
      _fields.setDefinitions(<Field<dynamic>>[
        tmp.fieldId,
        tmp.fieldName,
        tmp.fieldSymbol,
        tmp.fieldTransactionDateRange,
        tmp.fieldPrice,
        tmp.fieldLastPrice,
        tmp.fieldCuspid,
        tmp.fieldSecurityType,
        tmp.fieldNumberOfTrades,
        tmp.fieldHoldingShares,
        tmp.fieldHoldingValue,
        tmp.fieldActivityProfit,
        tmp.fieldActivityDividend,
        tmp.fieldProfit,
      ]);
    }
    return _fields;
  }

  /// Returns the field definitions for Security column view.
  static Fields<Security> get fieldsForColumnView {
    final Security tmp = Security.fromJson(<String, dynamic>{});
    return Fields<Security>()..setDefinitions(<Field<dynamic>>[
      tmp.fieldName,
      tmp.fieldSymbol,
      tmp.fieldTransactionDateRange,
      tmp.fieldPrice,
      tmp.fieldLastPrice,
      tmp.fieldSecurityType,
      tmp.fieldNumberOfTrades,
      tmp.fieldHoldingShares,
      tmp.fieldHoldingValue,
      tmp.fieldActivityProfit,
      tmp.fieldActivityDividend,
      tmp.fieldProfit,
    ]);
  }

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
