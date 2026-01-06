// ignore_for_file: unrelated_type_equality_checks, unnecessary_this
import 'package:flutter/material.dart';
import 'package:money/data/category.dart';
import 'package:money/data/data.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/widgets/picker_category.dart';
import 'package:money/widgets/widgets_domain/cd/field.dart';
import 'package:money/widgets/widgets_domain/cd/money_object.dart';
import 'package:money/widgets/widgets_domain/field_type.dart';

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

class MoneySplit extends MoneyObject {
  /// Constructor
  MoneySplit({
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

  factory MoneySplit.fromJson(final MyJson row) {
    return MoneySplit(
      // 0
      transactionId: row.getInt('Transaction', -1),
      // 1
      id: row.getInt('Id', -1),
      // 2
      categoryId: row.getInt('Category', -1),
      // 3
      payeeId: row.getInt('Payee', -1),
      // 4
      amount: row.getDouble('Amount'),
      // 5
      transferId: row.getInt('Transfer', -1),
      // 6
      memo: row.getString('Memo'),
      // 7
      flags: row.getInt('Flags'),
      // 8
      budgetBalanceDate: row.getDate('BudgetBalanceDate'),
    );
  }

  // 4
  FieldMoney fieldAmount = FieldMoney(
    name: 'Amount',
    serializeName: 'Amount',
    getValueForDisplay: (final MoneyObject instance) => (instance as MoneySplit).fieldAmount.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as MoneySplit).fieldAmount.value.asDouble(),
    setValue: (MoneyObject instance, dynamic newValue) =>
        (instance as MoneySplit).fieldAmount.value.setAmount(newValue),
  );

  // 8
  FieldDate fieldBudgetBalanceDate = FieldDate(
    name: 'Budgeted Date',
    serializeName: 'BudgetBalanceDate',
    columnWidth: ColumnWidth.hidden,
    getValueForDisplay: (final MoneyObject instance) => (instance as MoneySplit).fieldBudgetBalanceDate.value,
    getValueForSerialization: (final MoneyObject instance) => dateToIso8601OrDefaultString(
      (instance as MoneySplit).fieldBudgetBalanceDate.value,
    ),
  );

  // 2
  FieldInt fieldCategoryId = FieldInt(
    name: 'Category',
    serializeName: 'Category',
    type: FieldType.text,
    align: TextAlign.left,
    getValueForDisplay: (final MoneyObject instance) => (instance as MoneySplit).categoryName,
    getValueForReading: (final MoneyObject instance) => (instance as MoneySplit).categoryName,
    getValueForSerialization: (final MoneyObject instance) => (instance as MoneySplit).fieldCategoryId.value,
    setValue: (final MoneyObject instance, dynamic newValue) =>
        (instance as MoneySplit).fieldCategoryId.value = newValue as int,
    getEditWidget:
        (
          final MoneyObject instance,
          void Function(bool wasModified) onEdited,
        ) {
          (instance as MoneySplit);
          return Row(
            children: <Widget>[
              Expanded(
                child: pickerCategory(
                  key: const Key('key_pick_category'),
                  categoryNames: Data().categories.getCategoriesAsStrings(),
                  selectedName: Data().categories.getNameFromId(instance.fieldCategoryId.value),
                  onSelected: (String? name) {
                    final Category? newCategory = name != null ? Data().categories.getByName(name) : null;
                    if (newCategory != null) {
                      instance.fieldCategoryId.value = newCategory.uniqueId;
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
    getValueForDisplay: (final MoneyObject instance) => (instance as MoneySplit).fieldFlags.value,
  );

  // 1
  FieldId fieldId = FieldId(
    getValueForSerialization: (final MoneyObject instance) => (instance as MoneySplit).uniqueId,
  );

  // 6
  FieldString fieldMemo = FieldString(
    name: 'Memo',
    serializeName: 'Memo',
    getValueForDisplay: (final MoneyObject instance) => (instance as MoneySplit).fieldMemo.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as MoneySplit).fieldMemo.value,
    setValue: (MoneyObject instance, dynamic newValue) => (instance as MoneySplit).fieldMemo.value = newValue as String,
  );

  // 3
  FieldInt fieldPayeeId = FieldInt(
    name: 'Payee',
    serializeName: 'Payee',
    type: FieldType.text,
    align: TextAlign.left,
    getValueForDisplay: (final MoneyObject instance) => Data().payees.getNameFromId(
      (instance as MoneySplit).fieldPayeeId.value,
    ),
    getValueForSerialization: (final MoneyObject instance) => (instance as MoneySplit).fieldPayeeId.value,
  );

  // 0
  FieldInt fieldTransactionId = FieldInt(
    name: 'Transaction',
    serializeName: 'Transaction',
    columnWidth: ColumnWidth.hidden,
    getValueForDisplay: (final MoneyObject instance) => (instance as MoneySplit).fieldTransactionId.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as MoneySplit).fieldTransactionId.value,
  );

  // 5
  FieldInt fieldTransferId = FieldInt(
    name: 'Transfer',
    serializeName: 'Transfer',
    columnWidth: ColumnWidth.hidden,
    getValueForDisplay: (final MoneyObject instance) => (instance as MoneySplit).fieldTransferId.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as MoneySplit).fieldTransferId.value,
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

  static final Fields<MoneySplit> _fields = Fields<MoneySplit>();

  String get categoryName => Data().categories.getNameFromId(fieldCategoryId.value);

  static Fields<MoneySplit> get fields {
    if (_fields.isEmpty) {
      final MoneySplit tmp = MoneySplit.fromJson(<String, dynamic>{});
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
    return Data().transactions.get(this.fieldTransactionId.value);
  }
}
