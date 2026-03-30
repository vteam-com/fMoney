// ignore_for_file: unnecessary_this
// ignore: fcheck_dead_code
import 'package:flutter/material.dart';
import 'package:money/data/models/field_type.dart';
import 'package:money/data/models/stock_cumulative.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/investment_types.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/data_abstract.dart';
import 'package:money/shared/domain/field_definition_cache.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';

const int _unsetId = -1;
const int _zeroInt = 0;
const int _oneInt = 1;
const double _zeroDouble = 0.0;
const double _oneDouble = 1.0;
const int _positiveMultiplier = 1;
const int _negativeMultiplier = -1;

/// Represents investment.
class Investment extends DataObject {
  Investment({
    required final int id, // 1
    required final int security, // 1
    required final double unitPrice, // 2
    required final double units, // 3
    required final int investmentType, // 9
    required final int tradeType, // 10
    final double commission = _zeroDouble, // 4
    final double markUpDown = _zeroDouble, // 5
    final double taxes = _zeroDouble, // 6
    final double fees = _zeroDouble, // 7
    final double load = _zeroDouble, // 8
    final int taxExempt = _zeroInt, // 11
    final double withholding = _zeroDouble, // 12
    this.data,
  }) {
    this.fieldId.value = id;
    this.fieldSecurity.value = security;
    this.fieldUnitPrice.value.setAmount(unitPrice);
    this.fieldUnits.value = units;
    this.fieldCommission.value.setAmount(commission);
    this.fieldMarkUpDown.value.setAmount(markUpDown);
    this.fieldTaxes.value.setAmount(taxes);
    this.fieldFees.value.setAmount(fees);
    this.fieldLoad.value.setAmount(load);
    this.fieldInvestmentType.value = investmentType;
    this.fieldTradeType.value = tradeType;
    this.fieldTaxExempt.value = taxExempt;
    this.fieldWithholding.value.setAmount(withholding);
  }

  /// Constructor from a SQLite row
  factory Investment.fromJson(final MyJson row, [DataAbstract? data]) {
    return Investment(
      // 1
      id: row.getInt('Id', _unsetId),
      // 1
      security: row.getInt('Security'),
      // 2
      unitPrice: row.getDouble('UnitPrice'),
      // 3
      units: row.getDouble('Units'),
      // 4
      commission: row.getDouble('Commission'),
      // 5
      markUpDown: row.getDouble('MarkUpDown'),
      // 6
      taxes: row.getDouble('Taxes'),
      // 7
      fees: row.getDouble('Fees'),
      // 8
      load: row.getDouble('Load'),
      // 9
      investmentType: row.getInt('InvestmentType'),
      // 10
      tradeType: row.getInt('TradeType'),
      // 11
      taxExempt: row.getInt('TaxExempt'),
      // 12
      withholding: row.getDouble('Withholding'),
      data: data,
    );
  }
  final DataAbstract? data;

  FieldMoney fieldActivityDividend = FieldMoney(
    name: 'ActivityDividend',
    getValueForDisplay: (final DataInterface instance) =>
        AmountModel(amount: (instance as Investment).activityDividend),
  );

  FieldMoney fieldActivityAmount = FieldMoney(
    name: 'ActivityAmount',
    getValueForDisplay: (final DataInterface instance) => AmountModel(amount: (instance as Investment).activityAmount),
  );

  /// 4    Commission      money   0                    0
  FieldMoney fieldCommission = FieldMoney(
    name: 'Commission',
    serializeName: 'Commission',
    getValueForDisplay: (final DataInterface instance) => (instance as Investment).fieldCommission.value,
    getValueForSerialization: (final DataInterface instance) =>
        (instance as Investment).fieldCommission.value.asDouble(),
  );

  /// 7    Fees            money   0                    0
  FieldMoney fieldFees = FieldMoney(
    name: 'Fees',
    serializeName: 'Fees',
    getValueForDisplay: (final DataInterface instance) => (instance as Investment).fieldFees.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Investment).fieldFees.value.asDouble(),
  );

  FieldQuantity fieldHoldingShares = FieldQuantity(
    name: 'Holding',
    footer: FooterType.average,
    getValueForDisplay: (final DataInterface instance) => (instance as Investment).fieldHoldingShares.value,
  );

  FieldMoney fieldHoldingSharesValue = FieldMoney(
    name: 'HoldingValue',
    footer: FooterType.average,
    getValueForDisplay: (final DataInterface instance) {
      return AmountModel(
        amount: (instance as Investment).fieldHoldingShares.value * instance.unitPriceAdjusted,
      );
    },
  );

  /// Id
  //// 0    Id              bigint  0                    1
  FieldId fieldId = FieldId(
    getValueForSerialization: (final DataInterface instance) => (instance as Investment).uniqueId,
  );

  /// 9    InvestmentType  INT     1                    0
  FieldInt fieldInvestmentType = FieldInt(
    name: 'Activity',
    serializeName: 'InvestmentType',
    align: TextAlign.center,
    columnWidth: ColumnWidth.tiny,
    type: FieldType.text,
    footer: FooterType.count,
    getValueForDisplay: (final DataInterface instance) => (instance as Investment)._investmentTypeAsString,
    getValueForSerialization: (final DataInterface instance) => (instance as Investment).fieldInvestmentType.value,
    getEditWidget:
        (
          final DataInterface instance,
          void Function(bool /* wasModified */) onEdited,
        ) {
          return pickerInvestmentTypeWidget?.call(instance as Investment, onEdited) ??
              Text(AppL10n.tr(AppTranslationKeys.noPicker));
        },
    setValue: (final DataInterface instance, dynamic value) {
      (instance as Investment).stashValueBeforeEditing();
      instance.fieldInvestmentType.value = getInvestmentTypeFromValue(value as int).index;
    },
  );

  /// 8    Load            money   0                    0
  FieldMoney fieldLoad = FieldMoney(
    name: 'Load',
    serializeName: 'Load',
    getValueForDisplay: (final DataInterface instance) => (instance as Investment).fieldLoad.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Investment).fieldLoad.value.asDouble(),
  );

  /// 5    MarkUpDown      money   0                    0
  FieldMoney fieldMarkUpDown = FieldMoney(
    name: 'MarkUpDown',
    serializeName: 'MarkUpDown',
    getValueForDisplay: (final DataInterface instance) => (instance as Investment).fieldMarkUpDown.value.asDouble(),
    getValueForSerialization: (final DataInterface instance) =>
        (instance as Investment).fieldMarkUpDown.value.asDouble(),
  );

  FieldMoney fieldNetValueOfEvent = FieldMoney(
    name: 'NetValue',
    footer: FooterType.average,
    getValueForDisplay: (final DataInterface instance) {
      return AmountModel(amount: (instance as Investment).transactionNetValue);
    },
  );

  /// 1    Security        INT     1                    0
  FieldInt fieldSecurity = FieldInt(
    name: 'Security',
    serializeName: 'Security',
    getValueForDisplay: (final DataInterface instance) => (instance as Investment).fieldSecurity.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Investment).fieldSecurity.value,
  );

  FieldString fieldSecuritySymbol = FieldString(
    name: 'Symbol',
    columnWidth: ColumnWidth.tiny,
    getValueForDisplay: (final DataInterface instance) => (instance as Investment).symbol,
    getValueForSerialization: (final DataInterface instance) => (instance as Investment).fieldSecuritySymbol.value,
    setValue: (final DataInterface instance, dynamic value) {
      (instance as Investment).stashValueBeforeEditing();
      instance.fieldSecuritySymbol.value = value as String;
    },
  );

  FieldString fieldSplitRatioAsText = FieldString(
    name: 'Split',
    align: TextAlign.right,
    columnWidth: ColumnWidth.tiny,
    footer: FooterType.none,
    getValueForDisplay: (final DataInterface instance) =>
        'x ${formatDoubleTrimZeros((instance as Investment)._splitRatio)}',
  );

  /// 11   TaxExempt       bit     0                    0
  FieldInt fieldTaxExempt = FieldInt(
    name: 'Taxable',
    serializeName: 'TaxExempt',
    columnWidth: ColumnWidth.nano,
    align: TextAlign.center,
    type: FieldType.text,
    getValueForDisplay: (final DataInterface instance) =>
        (instance as Investment).fieldTaxExempt.value == _oneInt ? 'No' : 'Yes',
    getValueForSerialization: (final DataInterface instance) => (instance as Investment).fieldTaxExempt.value,
  );

  /// 6    Taxes           money   0                    0
  FieldMoney fieldTaxes = FieldMoney(
    name: 'Taxes',
    serializeName: 'Taxes',
    getValueForDisplay: (final DataInterface instance) => (instance as Investment).fieldTaxes.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Investment).fieldTaxes.value.asDouble(),
  );

  /// 10   TradeType       INT     0                    0
  FieldInt fieldTradeType = FieldInt(
    name: 'TradeType',
    serializeName: 'TradeType',
    type: FieldType.text,
    getValueForDisplay: (final DataInterface instance) =>
        InvestmentTradeType.values[(instance as Investment).fieldTradeType.value].name.toUpperCase(),
    getValueForSerialization: (final DataInterface instance) => (instance as Investment).fieldTradeType.value,
    getEditWidget:
        (
          final DataInterface instance,
          void Function(bool /* wasModified */) onEdited,
        ) {
          return pickerInvestmentTradeTypeWidget?.call(instance as Investment, onEdited) ??
              Text(AppL10n.tr(AppTranslationKeys.noPicker));
        },
    setValue: (final DataInterface instance, dynamic value) {
      // (instance as Investment).stashValueBeforeEditing();
      (instance as Investment).fieldTradeType.value = value as int;
    },
  );

  FieldString fieldTransactionAccountName = FieldString(
    name: 'Account',
    columnWidth: ColumnWidth.largest,
    getValueForDisplay: (final DataInterface instance) {
      final dynamic transaction = (instance as Investment).transactionInstance;
      if (transaction != null) {
        return transaction.accountName;
      }
      return '<Account?>';
    },
  );

  FieldDate fieldTransactionDate = FieldDate(
    name: 'Date',
    columnWidth: ColumnWidth.small,
    getValueForDisplay: (final DataInterface instance) => (instance as Investment).date,
    sort: (final DataInterface a, final DataInterface b, final bool ascending) =>
        sortByDateAndInvestmentType(a as Investment, b as Investment, ascending),
  );

  /// 2    UnitPrice       money   1
  FieldMoney fieldUnitPrice = FieldMoney(
    name: 'Price',
    serializeName: 'UnitPrice',
    footer: FooterType.average,
    getValueForDisplay: (final DataInterface instance) => (instance as Investment).fieldUnitPrice.value,
    getValueForSerialization: (final DataInterface instance) =>
        (instance as Investment).fieldUnitPrice.value.asDouble(),
    setValue: (final DataInterface instance, dynamic value) {
      // (instance as Investment).stashValueBeforeEditing();
      (instance as Investment).fieldUnitPrice.value.setAmount(value);
    },
  );

  FieldMoney fieldUnitPriceAdjusted = FieldMoney(
    name: 'Price A.S.',
    footer: FooterType.average,
    getValueForDisplay: (final DataInterface instance) =>
        AmountModel(amount: (instance as Investment).unitPriceAdjusted),
  );

  /// 3    Units           money   0                    0
  FieldQuantity fieldUnits = FieldQuantity(
    name: 'Units',
    serializeName: 'Units',
    getValueForDisplay: (final DataInterface instance) => (instance as Investment).effectiveUnits,
    getValueForSerialization: (final DataInterface instance) => (instance as Investment).fieldUnits.value,
    setValue: (final DataInterface instance, dynamic value) {
      // (instance as Investment).stashValueBeforeEditing();
      (instance as Investment).fieldUnits.value = getDoubleFromDynamic(value);
    },
  );

  FieldQuantity fieldUnitsAdjusted = FieldQuantity(
    name: 'Units A.S.',
    getValueForDisplay: (final DataInterface instance) => (instance as Investment).effectiveUnitsAdjusted,
  );

  /// 12   Withholding     money   0                    0
  FieldMoney fieldWithholding = FieldMoney(
    name: 'Withholding',
    serializeName: 'Withholding',
    getValueForDisplay: (final DataInterface instance) => (instance as Investment).fieldWithholding.value,
    getValueForSerialization: (final DataInterface instance) =>
        (instance as Investment).fieldWithholding.value.asDouble(),
  );

  double _splitRatio = _oneDouble;

  /// The actual transaction date.
  dynamic _transactionInstance;

  /// Builds a compact widget representation for small screens.
  @override
  Widget buildFieldsAsWidgetForSmallScreen() {
    return buildSmallScreenWidget?.call(this) ?? Text(AppL10n.tr(AppTranslationKeys.noUi));
  }

  // Fields for this instance
  /// Returns field definitions for this instance.
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  /// Returns a short string representation used by generic data views.
  @override
  String getRepresentation() {
    return fieldSecurity.value.toString();
  }

  /// Returns a debug-friendly string describing this investment.
  @override
  String toString() {
    return '$uniqueId $date ${fieldInvestmentType.getValueForDisplay(this)} ${fieldSecuritySymbol.getValueForDisplay(this)} $effectiveUnits ${fieldUnitPrice.value} ${fieldHoldingShares.value} $activityAmount';
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<Investment> _fields = Fields<Investment>();
  static final Fields<Investment> _fieldsForColumns = Fields<Investment>();
  static final List<FieldBlueprint<Investment>> _fieldBlueprints = <FieldBlueprint<Investment>>[
    FieldBlueprint<Investment>(selector: (Investment instance) => instance.fieldId),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldTransactionDate,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldTransactionAccountName,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(selector: (Investment instance) => instance.fieldSecurity),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldSecuritySymbol,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldInvestmentType,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldTradeType,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldUnits,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldSplitRatioAsText,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldUnitsAdjusted,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldHoldingShares,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldUnitPrice,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldUnitPriceAdjusted,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldCommission,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(selector: (Investment instance) => instance.fieldMarkUpDown),
    FieldBlueprint<Investment>(selector: (Investment instance) => instance.fieldTaxes),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldFees,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldLoad,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(selector: (Investment instance) => instance.fieldTaxExempt),
    FieldBlueprint<Investment>(selector: (Investment instance) => instance.fieldWithholding),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldActivityAmount,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldHoldingSharesValue,
      includeInColumnView: true,
    ),
    FieldBlueprint<Investment>(
      selector: (Investment instance) => instance.fieldNetValueOfEvent,
      includeInEntity: false,
      includeInColumnView: true,
    ),
  ];

  /// Returns the investment activity type.
  InvestmentType get actionType => getInvestmentTypeFromValue(this.fieldInvestmentType.value);

  /// Returns the transaction amount for this investment (0 if missing).
  double get activityAmount {
    // if (investmentType.value != InvestmentType.dividend.index &&
    //     investmentType.value != InvestmentType.add.index &&
    //     investmentType.value != InvestmentType.remove.index) {
    final dynamic transaction = transactionInstance;
    if (transaction != null) {
      return transaction.fieldAmount.value.asDouble() as double;
    }
    return _zeroDouble;
    // }
    // return 0.00;
  }

  /// Applies stock split ratio for this security up to this investment date.
  void applySplits() {
    _splitRatio = data?.getSplitRatioForSecurityBeforeDate(fieldSecurity.value, date) ?? _oneDouble;
  }

  /// Returns the cost basis for the shares at the adjusted unit price.
  double get costForShares => this.effectiveUnitsAdjusted * this.unitPriceAdjusted;

  /// Returns the transaction date for this investment (today if missing).
  DateTime get date {
    final dynamic transaction = transactionInstance;
    if (transaction != null) {
      return (transaction.fieldDateTime.value ?? DateTime.now()) as DateTime;
    }
    return DateTime.now();
  }

  /// Returns units adjusted for buy/sell sign.
  double get effectiveUnits {
    if (this.fieldUnits.value == _zeroDouble) {
      return _zeroDouble;
    }

    return this.fieldUnits.value * _signBasedOnActivity;
  }

  // Buy is a positive value
  // Sell is negative value
  /// Returns units adjusted for buy/sell sign and stock splits.
  double get effectiveUnitsAdjusted {
    if (this.fieldUnits.value == _zeroDouble) {
      return _zeroDouble;
    }

    return this.fieldUnits.value * this._splitRatio * _signBasedOnActivity;
  }

  /// Returns the field definitions for Investment entities.
  static Fields<Investment> get fields => ensureCachedFieldDefinitionsFromBlueprints<Investment>(
    cache: _fields,
    instanceFactory: () => Investment.fromJson(<String, dynamic>{}),
    blueprints: _fieldBlueprints,
    forColumnView: false,
  );

  /// Returns the field definitions for Investment column view.
  static Fields<Investment> get fieldsForColumnView => ensureCachedFieldDefinitionsFromBlueprints<Investment>(
    cache: _fieldsForColumns,
    instanceFactory: () => Investment.fromJson(<String, dynamic>{}),
    blueprints: _fieldBlueprints,
    forColumnView: true,
  );

  /// Returns the final cumulative amount for this investment.
  StockCumulative get finalAmount {
    final StockCumulative cumulative = StockCumulative();
    cumulative.quantity = _negativeMultiplier * effectiveUnits * this.fieldUnitPrice.value.asDouble();
    cumulative.amount += this.fieldCommission.value.asDouble();
    return cumulative;
  }

  /// Returns the original (pre-split) cost basis for this investment.
  double get originalCostBasis {
    // looking for the original un-split cost basis at the date of this transaction.
    final double proceeds = this.fieldUnitPrice.value.asDouble() * this.fieldUnits.value;

    final dynamic transaction = transactionInstance;
    if (transaction != null && transaction.fieldAmount.value.asDouble() != _zeroDouble) {
      // We may have paid more for the stock than "price" in a buy transaction because of brokerage fees and
      // this can be included in the cost basis.  We may have also received less than "price" in a sale
      // transaction, and that can also reduce our capital gain, so we use the transaction amount if we
      // have one.
      return (transaction.fieldAmount.value.asDouble().abs()) as double;
    }

    // But if the sale proceeds were not recorded for some reason, then we fall back on the proceeds.
    return proceeds;
  }

  /// Sorts investments by date, then by investment type.
  static int sortByDateAndInvestmentType(final Investment a, final Investment b, final bool ascending) {
    int result = sortByDate(a.date, b.date, ascending);

    if (result == _zeroInt) {
      // If on the same date sort so that "Buy" is before "Sell"
      result = sortByValue(
        a.fieldInvestmentType.value,
        b.fieldInvestmentType.value,
        ascending,
      );
    }

    // if (result == _zeroInt) {
    //   // then if needed sort by amount
    //   result = sortByValue(
    //     a.finalAmount.amount.abs(),
    //     b.finalAmount.amount.abs(),
    //     !ascending,
    //   );
    // }
    return result;
  }

  /// Returns the security symbol for this investment.
  String get symbol => data?.getSecuritySymbolFromId(fieldSecurity.value) ?? 'Unknown';

  /// Returns the holding value based on current holding shares and adjusted unit price.
  double get transactionHoldingValue => this.fieldHoldingShares.value * this.unitPriceAdjusted;

  /// The actual transaction date.
  dynamic get transactionInstance {
    _transactionInstance ??= data?.getTransaction(this.uniqueId);
    return _transactionInstance;
  }

  /// The actual transaction date.
  set transactionInstance(dynamic value) {
    _transactionInstance = value;
  }

  /// Returns holding value plus activity amount.
  double get transactionNetValue => transactionHoldingValue + this.activityAmount;

  /// Returns the dividend amount for dividend investments.
  double get activityDividend {
    if (fieldInvestmentType.value == InvestmentType.dividend.index) {
      final dynamic transaction = transactionInstance;
      if (transaction != null) {
        return (transaction.fieldAmount.value.asDouble()) as double;
      }
    }
    return _zeroDouble;
  }

  String get _investmentTypeAsString => getInvestmentTypeTextFromValue(this.fieldInvestmentType.value);

  int get _signBasedOnActivity =>
      <InvestmentType>[
        InvestmentType.buy,
        InvestmentType.add,
      ].contains(getInvestmentTypeFromValue(this.fieldInvestmentType.value))
      ? _positiveMultiplier
      : _negativeMultiplier;

  /// Returns the unit price adjusted for stock splits.
  double get unitPriceAdjusted => this.fieldUnitPrice.value.asDouble() / this._splitRatio;

  static Widget Function(Investment instance)? buildSmallScreenWidget;
  static Widget Function(Investment instance, void Function(bool /* wasModified */) onEdited)?
  pickerInvestmentTypeWidget;
  static Widget Function(Investment instance, void Function(bool /* wasModified */) onEdited)?
  pickerInvestmentTradeTypeWidget;
}
