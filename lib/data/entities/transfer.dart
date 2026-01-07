import 'package:flutter/material.dart';
import 'package:money/data/entities/money_split.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/transaction_types.dart';
import 'package:money/models/account.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/field_type.dart';

class Transfer extends DataObject {
  Transfer({
    required this.id,
    required this.source,
    required this.isOrphan,
    this.relatedTransaction,
    this.sourceSplit,
    this.relatedSplit,
  }) {
    // body of constructor
  }

  factory Transfer.fromJson(final MyJson row) {
    return Transfer(id: -1, source: null, isOrphan: true);
  }

  final num id; // used when the transfer is part of a split
  final bool isOrphan;
  final MoneySplit? relatedSplit; // the related split, if it is a transfer in a split.
  final dynamic relatedTransaction; // the related transaction
  final dynamic source; // the source of the transfer.
  final MoneySplit? sourceSplit; // the source split, if it is a transfer in a split.

  /// Status
  FieldString fieldAccountStatusDestination = FieldString(
    name: 'RS',
    align: TextAlign.center,
    columnWidth: ColumnWidth.nano,
    getValueForDisplay: (final DataInterface instance) => transactionStatusToLetter(
      (instance as Transfer).relatedTransaction!.fieldStatus.value as TransactionStatus,
    ),
  );

  /// memo
  FieldString fieldMemoDestination = FieldString(
    name: 'Recipient memo',
    columnWidth: ColumnWidth.largest,
    getValueForDisplay: (final DataInterface instance) => (instance as Transfer).getMemoDestination(),
  );

  /// Account
  Field<int> fieldReceiverAccountId = Field<int>(
    type: FieldType.text,
    name: 'Recipient account',
    defaultValue: -1,
    getValueForDisplay: (final DataInterface instance) => (instance as Transfer).receiverAccountName,
  );

  //
  // RECEIVED
  //

  /// Date received
  FieldDate fieldReceiverTransactionDate = FieldDate(
    name: 'Date Received',
    getValueForDisplay: (final DataInterface instance) => (instance as Transfer).receiverTransactionDate,
  );

  /// Account
  Field<int> fieldSenderAccountId = Field<int>(
    type: FieldType.text,
    name: 'Sender',
    defaultValue: -1,
    getValueForDisplay: (final DataInterface instance) => (instance as Transfer).senderAccountName,
  );

  //
  // SENDER
  //
  FieldDate fieldSenderTransactionDate = FieldDate(
    name: 'Sent on',
    getValueForDisplay: (final DataInterface instance) => (instance as Transfer).geSenderTransactionDate(),
  );

  /// memo
  FieldString fieldSenderTransactionMemo = FieldString(
    name: 'Sender memo',
    columnWidth: ColumnWidth.largest,
    getValueForDisplay: (final DataInterface instance) => (instance as Transfer).getMemoSource(),
  );

  /// Status
  FieldString fieldSenderTransactionStatus = FieldString(
    name: 'SS',
    align: TextAlign.center,
    columnWidth: ColumnWidth.nano,
    getValueForDisplay: (final DataInterface instance) => transactionStatusToLetter(
      (instance as Transfer).source!.fieldStatus.value as TransactionStatus,
    ),
  );

  /// Transfer amount
  FieldMoney fieldTransactionAmount = FieldMoney(
    name: 'Amount',
    columnWidth: ColumnWidth.small,
    getValueForDisplay: (final DataInterface instance) => (instance as Transfer).source!.fieldAmount.value,
  );

  ///
  /// Common
  ///

  /// Troubleshoot
  FieldString fieldTroubleshoot = FieldString(
    name: 'Troubleshoot',
    getValueForDisplay: (final DataInterface instance) => (instance as Transfer).getTroubleshoot(),
  );

  @override
  int get uniqueId => source!.uniqueId as int;

  int dateSpreadBetweenSendingAndReceiving() {
    final DateTime dateSent = geSenderTransactionDate() ?? DateTime.now();
    final DateTime dateReceived = getReceivedDateOrToday();
    return dateReceived.difference(dateSent).inDays;
  }

  static Fields<Transfer> get fieldsForColumnView {
    final Transfer tmp = Transfer.fromJson(<String, dynamic>{});

    return Fields<Transfer>()..setDefinitions(<Field<dynamic>>[
      tmp.fieldSenderTransactionDate,
      tmp.fieldSenderAccountId,
      tmp.fieldSenderTransactionStatus,
      tmp.fieldSenderTransactionMemo,
      tmp.fieldReceiverTransactionDate,
      tmp.fieldReceiverAccountId,
      tmp.fieldAccountStatusDestination,
      tmp.fieldMemoDestination,
      tmp.fieldTroubleshoot,
      tmp.fieldTransactionAmount,
    ]);
  }

  //---------------------------------------------
  /// Dates
  DateTime? geSenderTransactionDate() {
    return source!.fieldDateTime.value as DateTime?;
  }

  String getMemoDestination() {
    String memos = source!.fieldTransferSplit.value == -1 ? '' : '[Split:${source!.fieldTransferSplit.value}] ';
    if (relatedTransaction != null) {
      memos += relatedTransaction!.fieldMemo.value as String;
    }
    return memos;
  }

  String getMemoSource() {
    return source!.fieldMemo.value as String;
  }

  DateTime getReceivedDateOrToday() {
    return receiverTransactionDate ?? DateTime.now();
  }

  String getTroubleshoot() {
    String status = '';
    if (isOrphan) {
      status += 'Orphan';
    }
    final int dateSpread = dateSpreadBetweenSendingAndReceiving().abs();

    if (dateSpread > 2) {
      if (status.isNotEmpty) {
        status += ', ';
      }
      status += '$dateSpread days';
    }
    return status;
  }

  Account? get receiverAccount => relatedTransaction?.instanceOfAccount as Account?;

  String get receiverAccountName => receiverAccount?.fieldName.value ?? '<account not found>';

  dynamic get receiverTransaction => relatedTransaction;

  DateTime? get receiverTransactionDate {
    if (relatedTransaction != null) {
      return relatedTransaction!.fieldDateTime.value as DateTime?;
    }
    return null;
  }

  //---------------------------------------------

  //---------------------------------------------
  // Sender Account
  Account? get senderAccount {
    return senderTransaction?.instanceOfAccount as Account?;
  }

  //---------------------------------------------
  // Account Names
  String get senderAccountName {
    return senderAccount?.fieldName.value ?? '<account not found>';
  }

  //---------------------------------------------
  // Transactions
  dynamic get senderTransaction {
    return source;
  }
}

// NOTE: we do not support a transfer from one split to another split, this is a pretty unlikely scenario,
// although it would be possible, if you withdraw 500 cash from one account, then combine $100 of that with
// a check for $200 in a single deposit, then the $100 is split on the source as a "transfer" to the
// deposited account, and the $300 deposit is split between the cash and the check.  Like I said, pretty unlikely.
