import 'package:flutter/material.dart';
import 'package:money/data/splits.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/money_objects/accounts/account.dart';
import 'package:money/money_objects/transactions/transaction.dart';
import 'package:money/widgets_data/money_object.dart';

class Transfer extends MoneyObject {
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
  final Transaction? relatedTransaction; // the related transaction
  final Transaction? source; // the source of the transfer.
  final MoneySplit? sourceSplit; // the source split, if it is a transfer in a split.

  /// Status
  FieldString fieldAccountStatusDestination = FieldString(
    name: 'RS',
    align: TextAlign.center,
    columnWidth: ColumnWidth.nano,
    getValueForDisplay: (final MoneyObject instance) => transactionStatusToLetter(
      (instance as Transfer).relatedTransaction!.fieldStatus.value,
    ),
  );

  /// memo
  FieldString fieldMemoDestination = FieldString(
    name: 'Recipient memo',
    columnWidth: ColumnWidth.largest,
    getValueForDisplay: (final MoneyObject instance) => (instance as Transfer).getMemoDestination(),
  );

  /// Account
  Field<int> fieldReceiverAccountId = Field<int>(
    type: FieldType.text,
    name: 'Recipient account',
    defaultValue: -1,
    getValueForDisplay: (final MoneyObject instance) => (instance as Transfer).receiverAccountName,
  );

  //
  // RECEIVED
  //

  /// Date received
  FieldDate fieldReceiverTransactionDate = FieldDate(
    name: 'Date Received',
    getValueForDisplay: (final MoneyObject instance) => (instance as Transfer).receiverTransactionDate,
  );

  /// Account
  Field<int> fieldSenderAccountId = Field<int>(
    type: FieldType.text,
    name: 'Sender',
    defaultValue: -1,
    getValueForDisplay: (final MoneyObject instance) => (instance as Transfer).senderAccountName,
  );

  //
  // SENDER
  //
  FieldDate fieldSenderTransactionDate = FieldDate(
    name: 'Sent on',
    getValueForDisplay: (final MoneyObject instance) => (instance as Transfer).geSenderTransactionDate(),
  );

  /// memo
  FieldString fieldSenderTransactionMemo = FieldString(
    name: 'Sender memo',
    columnWidth: ColumnWidth.largest,
    getValueForDisplay: (final MoneyObject instance) => (instance as Transfer).getMemoSource(),
  );

  /// Status
  FieldString fieldSenderTransactionStatus = FieldString(
    name: 'SS',
    align: TextAlign.center,
    columnWidth: ColumnWidth.nano,
    getValueForDisplay: (final MoneyObject instance) => transactionStatusToLetter(
      (instance as Transfer).source!.fieldStatus.value,
    ),
  );

  /// Transfer amount
  FieldMoney fieldTransactionAmount = FieldMoney(
    name: 'Amount',
    columnWidth: ColumnWidth.small,
    getValueForDisplay: (final MoneyObject instance) => (instance as Transfer).source!.fieldAmount.value,
  );

  ///
  /// Common
  ///

  /// Troubleshoot
  FieldString fieldTroubleshoot = FieldString(
    name: 'Troubleshoot',
    getValueForDisplay: (final MoneyObject instance) => (instance as Transfer).getTroubleshoot(),
  );

  @override
  int get uniqueId => source!.uniqueId;

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
    return source!.fieldDateTime.value;
  }

  String getMemoDestination() {
    String memos = source!.fieldTransferSplit.value == -1 ? '' : '[Split:${source!.fieldTransferSplit.value}] ';
    if (relatedTransaction != null) {
      memos += relatedTransaction!.fieldMemo.value;
    }
    return memos;
  }

  String getMemoSource() {
    return source!.fieldMemo.value;
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

  Account? get receiverAccount => relatedTransaction?.instanceOfAccount;

  String get receiverAccountName => receiverAccount?.fieldName.value ?? '<account not found>';

  Transaction? get receiverTransaction => relatedTransaction;

  DateTime? get receiverTransactionDate {
    if (relatedTransaction != null) {
      return relatedTransaction!.fieldDateTime.value;
    }
    return null;
  }

  //---------------------------------------------

  //---------------------------------------------
  // Sender Account
  Account? get senderAccount {
    return senderTransaction?.instanceOfAccount;
  }

  //---------------------------------------------
  // Account Names
  String get senderAccountName {
    return senderAccount?.fieldName.value ?? '<account not found>';
  }

  //---------------------------------------------
  // Transactions
  Transaction? get senderTransaction {
    return source;
  }
}

// NOTE: we do not support a transfer from one split to another split, this is a pretty unlikely scenario,
// although it would be possible, if you withdraw 500 cash from one account, then combine $100 of that with
// a check for $200 in a single deposit, then the $100 is split on the source as a "transfer" to the
// deposited account, and the $300 deposit is split between the cash and the check.  Like I said, pretty unlikely.
void linkTransfer(
  Transaction transactionSource,
  Transaction transactionRelated,
) {
  transactionSource.instanceOfTransfer = Transfer(
    id: 0,
    source: transactionSource,
    relatedTransaction: transactionRelated,
    isOrphan: false,
  );

  transactionRelated.instanceOfTransfer = Transfer(
    id: 0,
    source: transactionRelated,
    relatedTransaction: transactionSource,
    isOrphan: false,
  );
}
