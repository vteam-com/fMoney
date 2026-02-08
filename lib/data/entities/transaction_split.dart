// ignore_for_file: unrelated_type_equality_checks, unnecessary_this
import 'package:flutter/material.dart';
import 'package:money/data/entities/data_abstract.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/widgets/picker_category.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/field_type.dart';

const int _unsetId = -1;
const int _zeroInt = 0;
const double _zeroDouble = 0.0;

/*
  SQLite table definition

  0|Transaction|bigint|1||0
  1|Id|INT|1||0
  2|Category|INT|0||0
  3|Payee|INT|0||0
  4|Amount|money|1||0
  5|Transfer|bigint|0||0
  6|Memo|nvarchar(255)|0||0
  7|Flags|INT|0||0
  8|BudgetBalanceDate|datetime|0||0
 */

class TransactionSplit extends DataObject {
  /// Private constructor for static fields only
  TransactionSplit._static({
    required int id,
    required int transactionId,
    required int categoryId,
    required int payeeId,
    required double amount,
    required int transferId,
    required String memo,
    required int flags,
    required DateTime? budgetBalanceDate,
  }) {
    this.fieldId.value = id;
    this.fieldTransactionId.value = transactionId;
    this.fieldCategoryId.value = categoryId;
    this.fieldPayeeId.value = payeeId;
    this.fieldAmount.value.setAmount(amount);
    this.fieldTransferId.value = transferId;
    this.fieldMemo.value = memo;
    this.fieldFlags.value = flags;
    this.fieldBudgetBalanceDate.value = budgetBalanceDate;
  }
  factory TransactionSplit.fromJson(final MyJson row, final DataAbstract data) {
    return TransactionSplit(
      // 0
      transactionId: row.getInt('Transaction', _unsetId),
      // 1
      id: row.getInt('Id', _unsetId),
      // 2
      categoryId: row.getInt('Category', _unsetId),
      // 3
      payeeId: row.getInt('Payee', _unsetId),
      // 4
      amount: row.getDouble('Amount'),
      // 5
      transferId: row.getInt('Transfer', _unsetId),
      // 6
      memo: row.getString('Memo'),
      // 7
      flags: row.getInt('Flags'),
      // 8
      budgetBalanceDate: row.getDate('BudgetBalanceDate'),
      data: data,
    );
  }

  /// Constructor
  TransactionSplit({
    // 1
    required int id,
    // 0
    required int transactionId,
    // 2
    required int categoryId,
    // 3
    required int payeeId,
    // 4
    required double amount,
    // 5
    required int transferId,
    // 6
    required String memo,
    // 7
    required int flags,
    // 8
    required DateTime? budgetBalanceDate,
    required this.data,
  }) {
    this.fieldId.value = id;
    this.fieldTransactionId.value = transactionId;
    this.fieldCategoryId.value = categoryId;
    this.fieldPayeeId.value = payeeId;
    this.fieldAmount.value.setAmount(amount);
    this.fieldTransferId.value = transferId;
    this.fieldMemo.value = memo;
    this.fieldFlags.value = flags;
    this.fieldBudgetBalanceDate.value = budgetBalanceDate;
  }

  late DataAbstract data;

  // 4
  FieldMoney fieldAmount = FieldMoney(
    name: 'Amount',
    serializeName: 'Amount',
    getValueForDisplay: (final DataInterface instance) => (instance as TransactionSplit).fieldAmount.value,
    getValueForSerialization: (final DataInterface instance) =>
        (instance as TransactionSplit).fieldAmount.value.asDouble(),
    setValue: (DataInterface instance, dynamic newValue) =>
        (instance as TransactionSplit).fieldAmount.value.setAmount(newValue),
  );

  // 8
  FieldDate fieldBudgetBalanceDate = FieldDate(
    name: 'Budgeted Date',
    serializeName: 'BudgetBalanceDate',
    columnWidth: ColumnWidth.hidden,
    getValueForDisplay: (final DataInterface instance) => (instance as TransactionSplit).fieldBudgetBalanceDate.value,
    getValueForSerialization: (final DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as TransactionSplit).fieldBudgetBalanceDate.value,
    ),
  );

  // 2
  FieldInt fieldCategoryId = FieldInt(
    name: 'Category',
    serializeName: 'Category',
    type: FieldType.text,
    align: TextAlign.left,
    getValueForDisplay: (final DataInterface instance) => (instance as TransactionSplit).categoryName,
    getValueForReading: (final DataInterface instance) => (instance as TransactionSplit).categoryName,
    getValueForSerialization: (final DataInterface instance) => (instance as TransactionSplit).fieldCategoryId.value,
    setValue: (final DataInterface instance, dynamic newValue) =>
        (instance as TransactionSplit).fieldCategoryId.value = newValue as int,
    getEditWidget:
        (
          final DataInterface instance,
          void Function(bool wasModified) onEdited,
        ) {
          (instance as TransactionSplit);
          return Row(
            children: <Widget>[
              Expanded(
                child: pickerCategory(
                  key: const Key('key_pick_category'),
                  categoryNames: instance.data.getCategoryNames(),
                  selectedName: instance.data.getCategoryNameFromId(instance.fieldCategoryId.value),
                  onSelected: (String? name) {
                    final int? id = name != null ? instance.data.getCategoryIdFromName(name) : null;
                    if (id != null) {
                      instance.fieldCategoryId.value = id;
                      // notify container
                      onEdited(true);
                    }
                  },
                ),
              ),
            ],
          );
        },
  );

  // 7
  FieldInt fieldFlags = FieldInt(
    name: 'Flags',
    serializeName: 'Flags',
    columnWidth: ColumnWidth.hidden,
    align: TextAlign.center,
    getValueForDisplay: (final DataInterface instance) => (instance as TransactionSplit).fieldFlags.value,
  );

  // 1
  FieldId fieldId = FieldId(
    getValueForSerialization: (final DataInterface instance) => (instance as TransactionSplit).uniqueId,
  );

  // 6
  FieldString fieldMemo = FieldString(
    name: 'Memo',
    serializeName: 'Memo',
    getValueForDisplay: (final DataInterface instance) => (instance as TransactionSplit).fieldMemo.value,
    getValueForSerialization: (final DataInterface instance) => (instance as TransactionSplit).fieldMemo.value,
    setValue: (DataInterface instance, dynamic newValue) =>
        (instance as TransactionSplit).fieldMemo.value = newValue as String,
  );

  // 3
  FieldInt fieldPayeeId = FieldInt(
    name: 'Payee',
    serializeName: 'Payee',
    type: FieldType.text,
    align: TextAlign.left,
    getValueForDisplay: (final DataInterface instance) =>
        (instance as TransactionSplit).data.getPayeeName(instance.fieldPayeeId.value),
    getValueForSerialization: (final DataInterface instance) => (instance as TransactionSplit).fieldPayeeId.value,
  );

  // 0
  FieldInt fieldTransactionId = FieldInt(
    name: 'Transaction',
    serializeName: 'Transaction',
    columnWidth: ColumnWidth.hidden,
    getValueForDisplay: (final DataInterface instance) => (instance as TransactionSplit).fieldTransactionId.value,
    getValueForSerialization: (final DataInterface instance) => (instance as TransactionSplit).fieldTransactionId.value,
  );

  // 5
  FieldInt fieldTransferId = FieldInt(
    name: 'Transfer',
    serializeName: 'Transfer',
    columnWidth: ColumnWidth.hidden,
    getValueForDisplay: (final DataInterface instance) => (instance as TransactionSplit).fieldTransferId.value,
    getValueForSerialization: (final DataInterface instance) => (instance as TransactionSplit).fieldTransferId.value,
  );

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  /// Splits are different from the other tables, the primary keys is Transaction+Id
  @override
  String getWhereClause() {
    return '"Transaction"=${fieldTransactionId.value} AND "Id"=$uniqueId';
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<TransactionSplit> _fields = Fields<TransactionSplit>();

  String get categoryName => data.getCategoryNameFromId(fieldCategoryId.value);

  static Fields<TransactionSplit> get fields {
    if (_fields.isEmpty) {
      // For static fields, we create a dummy instance without data
      // The fields are just for metadata and won't use data-dependent functionality
      final TransactionSplit tmp = TransactionSplit._static(
        id: _unsetId,
        transactionId: _unsetId,
        categoryId: _unsetId,
        payeeId: _unsetId,
        amount: _zeroDouble,
        transferId: _unsetId,
        memo: '',
        flags: _zeroInt,
        budgetBalanceDate: null,
      );
      _fields.setDefinitions(<Field<dynamic>>[
        tmp.fieldId,
        tmp.fieldTransactionId,
        tmp.fieldPayeeId,
        tmp.fieldCategoryId,
        tmp.fieldMemo,
        tmp.fieldAmount,
        tmp.fieldTransferId,
        tmp.fieldFlags,
        tmp.fieldBudgetBalanceDate,
      ]);
    }
    return _fields;
  }

  dynamic getTransferTransaction() {
    return data.getTransaction(this.fieldTransactionId.value);
  }
}
