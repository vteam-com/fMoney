// ignore_for_file: unnecessary_this

import 'package:flutter/material.dart';
import 'package:money/data/data.dart';
import 'package:money/data/entities/stock_split.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/investment_types.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/picker_edit_box.dart';
import 'package:money/widgets/stock_cumulative.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/field_type.dart';

class Investment extends DataObject {
  Investment({
    required final int id, // 1
    required final int security, // 1
    required final double unitPrice, // 2
    required final double units, // 3
    required final int investmentType, // 9
    required final int tradeType, // 10
    final double commission = 0, // 4
    final double markUpDown = 0, // 5
    final double taxes = 0, // 6
    final double fees = 0, // 7
    final double load = 0, // 8
    final int taxExempt = 0, // 11
    final double withholding = 0, // 12
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
  factory Investment.fromJson(final MyJson row) {
    return Investment(
      // 1
      id: row.getInt('Id', -1),
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
    );
  }

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
          void Function(bool wasModified) onEdited,
        ) {
          return pickerInvestmentTypeWidget?.call(instance as Investment, onEdited) ?? const Text('no picker');
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
        (instance as Investment).fieldTaxExempt.value == 1 ? 'No' : 'Yes',
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
          void Function(bool wasModified) onEdited,
        ) {
          return pickerInvestmentTradeTypeWidget?.call(instance as Investment, onEdited) ?? const Text('no picker');
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
    sort: (final DataInterface a, final DataInterface b, final bool ascending) => sortByDateAndInvestmentType(
      a as Investment,
      b as Investment,
      ascending,
      false,
    ),
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

  double _splitRatio = 1;

  /// The actual transaction date.
  dynamic _transactionInstance;

  @override
  Widget buildFieldsAsWidgetForSmallScreen() {
    return buildSmallScreenWidget?.call(this) ?? const Text('no UI');
  }

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  String getRepresentation() {
    return fieldSecurity.value.toString();
  }

  @override
  String toString() {
    return '$uniqueId $date ${fieldInvestmentType.getValueForDisplay(this)} ${fieldSecuritySymbol.getValueForDisplay(this)} $effectiveUnits ${fieldUnitPrice.value} ${fieldHoldingShares.value} $activityAmount';
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<Investment> _fields = Fields<Investment>();

  InvestmentType get actionType => getInvestmentTypeFromValue(this.fieldInvestmentType.value);

  double get activityAmount {
    // if (investmentType.value != InvestmentType.dividend.index &&
    //     investmentType.value != InvestmentType.add.index &&
    //     investmentType.value != InvestmentType.remove.index) {
    final dynamic transaction = transactionInstance;
    if (transaction != null) {
      return transaction.fieldAmount.value.asDouble() as double;
    }
    return 0.00;
    // }
    // return 0.00;
  }

  void applySplits(List<StockSplit> splits) {
    _splitRatio = 1;
    for (final StockSplit split in splits) {
      this._applySplit(split);
    }
  }

  double get costForShares => this.effectiveUnitsAdjusted * this.unitPriceAdjusted;

  DateTime get date {
    final dynamic transaction = transactionInstance;
    if (transaction != null) {
      return (transaction.fieldDateTime.value ?? DateTime.now()) as DateTime;
    }
    return DateTime.now();
  }

  double get effectiveUnits {
    if (this.fieldUnits.value == 0) {
      return 0;
    }

    return this.fieldUnits.value * _signBasedOnActivity;
  }

  // Buy is a positive value
  // Sell is negative value
  double get effectiveUnitsAdjusted {
    if (this.fieldUnits.value == 0) {
      return 0;
    }

    return this.fieldUnits.value * this._splitRatio * _signBasedOnActivity;
  }

  static Fields<Investment> get fields {
    if (_fields.isEmpty) {
      final Investment tmp = Investment.fromJson(<String, dynamic>{});
      _fields.setDefinitions(<Field<dynamic>>[
        tmp.fieldId,
        tmp.fieldTransactionDate,
        tmp.fieldTransactionAccountName,
        tmp.fieldSecurity,
        tmp.fieldSecuritySymbol,
        tmp.fieldInvestmentType,
        tmp.fieldTradeType,
        tmp.fieldUnits,
        tmp.fieldSplitRatioAsText,
        tmp.fieldUnitsAdjusted,
        tmp.fieldHoldingShares,
        tmp.fieldUnitPrice,
        tmp.fieldUnitPriceAdjusted,
        tmp.fieldCommission,
        tmp.fieldMarkUpDown,
        tmp.fieldTaxes,
        tmp.fieldFees,
        tmp.fieldLoad,
        tmp.fieldTaxExempt,
        tmp.fieldWithholding,
        tmp.fieldActivityAmount,
        tmp.fieldHoldingSharesValue,
      ]);
    }

    return _fields;
  }

  static Fields<Investment> get fieldsForColumnView {
    final Investment tmp = Investment.fromJson(<String, dynamic>{});
    return Fields<Investment>()..setDefinitions(<Field<dynamic>>[
      tmp.fieldTransactionDate,
      tmp.fieldTransactionAccountName,
      tmp.fieldSecuritySymbol,
      tmp.fieldInvestmentType,
      tmp.fieldTradeType,
      tmp.fieldUnits,
      tmp.fieldSplitRatioAsText,
      tmp.fieldUnitsAdjusted,
      tmp.fieldHoldingShares,
      tmp.fieldUnitPrice,
      tmp.fieldUnitPriceAdjusted,
      tmp.fieldCommission,
      tmp.fieldFees,
      tmp.fieldLoad,
      tmp.fieldActivityAmount,
      tmp.fieldHoldingSharesValue,
      tmp.fieldNetValueOfEvent,
    ]);
  }

  StockCumulative get finalAmount {
    final StockCumulative cumulative = StockCumulative();
    cumulative.quantity = -1 * effectiveUnits * this.fieldUnitPrice.value.asDouble();
    cumulative.amount += this.fieldCommission.value.asDouble();
    return cumulative;
  }

  double get originalCostBasis {
    // looking for the original un-split cost basis at the date of this transaction.
    final double proceeds = this.fieldUnitPrice.value.asDouble() * this.fieldUnits.value;

    final dynamic transaction = transactionInstance;
    if (transaction != null && transaction.fieldAmount.value.asDouble() != 0) {
      // We may have paid more for the stock than "price" in a buy transaction because of brokerage fees and
      // this can be included in the cost basis.  We may have also received less than "price" in a sale
      // transaction, and that can also reduce our capital gain, so we use the transaction amount if we
      // have one.
      return (transaction.fieldAmount.value.asDouble().abs()) as double;
    }

    // But if the sale proceeds were not recorded for some reason, then we fall back on the proceeds.
    return proceeds;
  }

  static int sortByDateAndInvestmentType(
    final Investment a,
    final Investment b,
    final bool ascending,
    bool ta,
  ) {
    int result = sortByDate(a.date, b.date, ascending);

    if (result == 0) {
      // If on the same date sort so that "Buy" is before "Sell"
      result = sortByValue(
        a.fieldInvestmentType.value,
        b.fieldInvestmentType.value,
        ascending,
      );
    }

    // if (result == 0) {
    //   // then if needed sort by amount
    //   result = sortByValue(
    //     a.finalAmount.amount.abs(),
    //     b.finalAmount.amount.abs(),
    //     !ascending,
    //   );
    // }
    return result;
  }

  String get symbol => Data().securities.getSymbolFromId(fieldSecurity.value);

  double get transactionHoldingValue => this.fieldHoldingShares.value * this.unitPriceAdjusted;

  /// The actual transaction date.
  dynamic get transactionInstance {
    _transactionInstance ??= Data().transactions.get(this.uniqueId);
    return _transactionInstance;
  }

  /// The actual transaction date.
  set transactionInstance(dynamic value) {
    _transactionInstance = value;
  }

  double get transactionNetValue => transactionHoldingValue + this.activityAmount;

  double get activityDividend {
    if (fieldInvestmentType.value == InvestmentType.dividend.index) {
      final dynamic transaction = transactionInstance;
      if (transaction != null) {
        return (transaction.fieldAmount.value.asDouble()) as double;
      }
    }
    return 0.00;
  }

  void _applySplit(final StockSplit s) {
    if (this.date.isBefore(s.fieldDate.value!) && s.fieldDenominator.value != 0 && s.fieldNumerator.value != 0) {
      _splitRatio *= s.fieldNumerator.value / s.fieldDenominator.value;
    }
  }

  String get _investmentTypeAsString => getInvestmentTypeTextFromValue(this.fieldInvestmentType.value);

  int get _signBasedOnActivity =>
      <InvestmentType>[
        InvestmentType.buy,
        InvestmentType.add,
      ].contains(getInvestmentTypeFromValue(this.fieldInvestmentType.value))
      ? 1
      : -1;

  double get unitPriceAdjusted => this.fieldUnitPrice.value.asDouble() / this._splitRatio;

  static Widget Function(Investment instance)? buildSmallScreenWidget;
  static Widget Function(Investment instance, void Function(bool wasModified) onEdited)? pickerInvestmentTypeWidget;
  static Widget Function(Investment instance, void Function(bool wasModified) onEdited)?
  pickerInvestmentTradeTypeWidget;
}

Widget pickerInvestmentTradeType({
  required final InvestmentTradeType itemSelected,
  required final void Function(InvestmentTradeType) onSelected,
}) {
  final String selectedName = getInvestmentTradeTypeText(itemSelected);

  return PickerEditBox(
    title: 'Investment Trade Type',
    items: getInvestmentTradeTypeNames(),
    initialValue: selectedName,
    onChanged: (String newSelection) {
      onSelected(getInvestmentTradeTypeFromText(newSelection));
    },
  );
}
