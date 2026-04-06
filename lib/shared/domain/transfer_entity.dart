import 'package:flutter/material.dart';
import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/field_definition_cache_helper.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

const int _unsetId = -1;
const int _dateSpreadThresholdDays = 2;

/// Represents transfer.
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

  factory Transfer.fromJson(final MyJson _ /* json */) {
    return Transfer(id: _unsetId, source: null, isOrphan: true);
  }

  final num id; // used when the transfer is part of a split
  final bool isOrphan;
  final TransactionSplit? relatedSplit; // the related split, if it is a transfer in a split.
  final dynamic relatedTransaction; // the related transaction
  final dynamic source; // the source of the transfer.
  final TransactionSplit? sourceSplit; // the source split, if it is a transfer in a split.

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
    defaultValue: _unsetId,
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
    defaultValue: _unsetId,
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
    name: SharedDomainStrings.domainString017,
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

  static final Fields<Transfer> _fieldsForColumns = Fields<Transfer>();
  static final List<FieldBlueprint<Transfer>> _fieldBlueprints = <FieldBlueprint<Transfer>>[
    FieldBlueprint<Transfer>(
      selector: (Transfer tmp) => tmp.fieldSenderTransactionDate,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transfer>(
      selector: (Transfer tmp) => tmp.fieldSenderAccountId,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transfer>(
      selector: (Transfer tmp) => tmp.fieldSenderTransactionStatus,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transfer>(
      selector: (Transfer tmp) => tmp.fieldSenderTransactionMemo,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transfer>(
      selector: (Transfer tmp) => tmp.fieldReceiverTransactionDate,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transfer>(
      selector: (Transfer tmp) => tmp.fieldReceiverAccountId,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transfer>(
      selector: (Transfer tmp) => tmp.fieldAccountStatusDestination,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transfer>(
      selector: (Transfer tmp) => tmp.fieldMemoDestination,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transfer>(
      selector: (Transfer tmp) => tmp.fieldTroubleshoot,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transfer>(
      selector: (Transfer tmp) => tmp.fieldTransactionAmount,
      includeInColumnView: true,
    ),
  ];

  /// Returns the number of days between the sending and receiving transaction dates.
  int dateSpreadBetweenSendingAndReceiving() {
    final DateTime dateSent = geSenderTransactionDate() ?? DateTime.now();
    final DateTime dateReceived = getReceivedDateOrToday();
    return dateReceived.difference(dateSent).inDays;
  }

  /// Returns the field definitions for Transfer column view.
  static Fields<Transfer> get fieldsForColumnView => ensureCachedFieldDefinitionsFromBlueprints<Transfer>(
    cache: _fieldsForColumns,
    instanceFactory: () => Transfer.fromJson(<String, dynamic>{}),
    blueprints: _fieldBlueprints,
    forColumnView: true,
  );

  //---------------------------------------------
  /// Dates
  DateTime? geSenderTransactionDate() {
    return source!.fieldDateTime.value as DateTime?;
  }

  /// Returns a memo string for the destination side of the transfer.
  String getMemoDestination() {
    String memos = source!.fieldTransferSplit.value == _unsetId ? '' : '[Split:${source!.fieldTransferSplit.value}] ';
    if (relatedTransaction != null) {
      memos += relatedTransaction!.fieldMemo.value as String;
    }
    return memos;
  }

  /// Returns the memo from the source transaction.
  String getMemoSource() {
    return source!.fieldMemo.value as String;
  }

  /// Returns the receiver transaction date or today if missing.
  DateTime getReceivedDateOrToday() {
    return receiverTransactionDate ?? DateTime.now();
  }

  /// Returns a troubleshooting status string (orphan/date spread).
  String getTroubleshoot() {
    String status = '';
    if (isOrphan) {
      status += SharedDomainStrings.domainString101;
    }
    final int dateSpread = dateSpreadBetweenSendingAndReceiving().abs();

    if (dateSpread > _dateSpreadThresholdDays) {
      if (status.isNotEmpty) {
        status += ', ';
      }
      status += '$dateSpread${SharedDomainStrings.domainString003}';
    }
    return status;
  }

  /// Returns the receiver account, if available.
  Account? get receiverAccount => relatedTransaction?.instanceOfAccount as Account?;

  /// Returns the receiver account name or a placeholder if missing.
  String get receiverAccountName => receiverAccount?.fieldName.value ?? SharedDomainStrings.domainString009;

  /// Returns the receiver transaction, if available.
  dynamic get receiverTransaction => relatedTransaction;

  /// Returns the receiver transaction date, if available.
  DateTime? get receiverTransactionDate {
    if (relatedTransaction != null) {
      return relatedTransaction!.fieldDateTime.value as DateTime?;
    }
    return null;
  }

  //---------------------------------------------

  //---------------------------------------------
  // Sender Account
  /// Returns the sender account, if available.
  Account? get senderAccount {
    return senderTransaction?.instanceOfAccount as Account?;
  }

  //---------------------------------------------
  // Account Names
  /// Returns the sender account name or a placeholder if missing.
  String get senderAccountName {
    return senderAccount?.fieldName.value ?? SharedDomainStrings.domainString009;
  }

  //---------------------------------------------
  // Transactions
  /// Returns the sender (source) transaction.
  dynamic get senderTransaction {
    return source;
  }
}

// NOTE: we do not support a transfer from one split to another split, this is a pretty unlikely scenario,
// although it would be possible, if you withdraw 500 cash from one account, then combine $100 of that with
// a check for $200 in a single deposit, then the $100 is split on the source as a "transfer" to the
// deposited account, and the $300 deposit is split between the cash and the check.  Like I said, pretty unlikely.
