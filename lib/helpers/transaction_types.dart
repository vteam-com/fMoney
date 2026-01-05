enum TransactionStatus { none, electronic, cleared, reconciled, voided }

String transactionStatusToLetter(final TransactionStatus status) {
  switch (status) {
    case TransactionStatus.none:
      return '_';
    case TransactionStatus.electronic:
      return 'E';
    case TransactionStatus.cleared:
      return 'C';
    case TransactionStatus.reconciled:
      return 'R';
    case TransactionStatus.voided:
      return 'V';
  }
}

enum TransactionFlags {
  none, // 0
  unaccepted, // 1
  // 2
  budgeted,
  // 3
  filler3,
  // 4
  hasAttachment,
  // 5
  filler5,
  // 6
  filler6,
  // 7
  filler7,
  // 8
  notDuplicate,
  filler9,
  filler10,
  filler11,
  filler12,
  filler13,
  filler14,
  filler15,
  // 16
  hasStatement,
}

const String columnIdAccount = 'Account';
const String columnIdDate = 'Date';
const String columnIdPayee = 'Payee/Transfer';
const String columnIdCategory = 'Category';
const String columnIdStatus = 'Status';
const String columnIdPaidOn = 'Paid On';
const String columnIdMemo = 'Memo';
const String columnIdAmount = 'Amount';
const String columnIdAmountNormalized = 'Amount(USD)';
const String columnIdBalance = 'Balance';
const String columnIdBalanceNormalized = 'Balance(USD)';
