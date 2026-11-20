// ignore: fcheck_hardcoded_strings
// Tool names, descriptions and results are written for the AI model, in English; the user never sees them.
import 'package:money/helpers/date_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/views/home/ai/tools/ai_tool_args_helper.dart';
import 'package:money/views/home/ai/tools/ai_tool_model.dart';

/// Argument: only these account ids.
const String aiArgAccountIds = 'account_ids';

/// Argument: free text to find.
const String aiArgText = 'text';

/// Argument: payee (or transfer account) name part.
const String aiArgPayee = 'payee';

/// Argument: category name part.
const String aiArgCategory = 'category';

/// Argument: first date included.
const String aiArgDateFrom = 'date_from';

/// Argument: last date included.
const String aiArgDateTo = 'date_to';

/// Argument: smallest absolute amount.
const String aiArgMinAmount = 'min_amount';

/// Argument: largest absolute amount.
const String aiArgMaxAmount = 'max_amount';

/// Argument: only transfers (true) or only non-transfers (false).
const String aiArgIsTransfer = 'is_transfer';

/// Argument: only transactions without a category.
const String aiArgUncategorized = 'uncategorized';

/// Category id of a transaction without a category.
const int _noCategoryId = -1;

/// Added to the last included date so the whole day is included.
const Duration _oneDay = Duration(days: 1);

/// Transaction filters shared by the AI tools that search, summarize or show transactions.
///
/// Text filters are case-insensitive and match any part of a name. The free [text] is looked for in
/// the payee, the bank's original text, the memo, the category, the split lines and the transfer
/// counterpart's account, but not in the transaction's own account name, which [accountIds] covers.
class AiTransactionQuery {
  /// Reads the filters from a tool call's [args]; missing arguments do not filter.
  AiTransactionQuery.fromArgs(Map<String, dynamic> args)
    : accountIds = args.intListArg(aiArgAccountIds).toSet(),
      text = args.stringArg(aiArgText).toLowerCase(),
      payee = args.stringArg(aiArgPayee).toLowerCase(),
      category = args.stringArg(aiArgCategory).toLowerCase(),
      dateFrom = args.dateArg(aiArgDateFrom),
      dateTo = args.dateArg(aiArgDateTo),
      minAmount = args.doubleArg(aiArgMinAmount),
      maxAmount = args.doubleArg(aiArgMaxAmount),
      isTransfer = args.boolArg(aiArgIsTransfer),
      uncategorizedOnly = args.boolArg(aiArgUncategorized) ?? false;

  /// Accounts to keep; empty keeps all.
  final Set<int> accountIds;

  /// Lowercase part of a category name to find, or empty.
  final String category;

  /// First date kept, or null.
  final DateTime? dateFrom;

  /// Last date kept (whole day), or null.
  final DateTime? dateTo;

  /// True keeps only transfers, false only non-transfers, null both.
  final bool? isTransfer;

  /// Largest absolute amount kept, or null.
  final double? maxAmount;

  /// Smallest absolute amount kept, or null.
  final double? minAmount;

  /// Lowercase part of a payee or transfer account name to find, or empty.
  final String payee;

  /// Lowercase free text to find, or empty.
  final String text;

  /// True keeps only transactions without a category.
  final bool uncategorizedOnly;

  /// JSON-schema description of the filter arguments, for the tools that take them.
  static Map<String, Map<String, Object>> get parameters => <String, Map<String, Object>>{
    aiArgAccountIds: aiIntListParam('Only these account ids (from list_accounts). Omit to search all accounts.'),
    aiArgText: aiStringParam(
      'One keyword to find (the exact text must appear) in the payee, original bank text, memo, category, '
      'split lines or transfer account name.',
    ),
    aiArgPayee: aiStringParam('Part of the payee name, or of the other account for transfers.'),
    aiArgCategory: aiStringParam('Part of the category name, e.g. "Condo" or "Housing:Insurance".'),
    aiArgDateFrom: aiStringParam('First date included, as YYYY-MM-DD.'),
    aiArgDateTo: aiStringParam('Last date included, as YYYY-MM-DD.'),
    aiArgMinAmount: aiNumberParam('Smallest amount kept, compared without its sign.'),
    aiArgMaxAmount: aiNumberParam('Largest amount kept, compared without its sign.'),
    aiArgIsTransfer: aiBoolParam('true for transfers between accounts only, false to exclude them.'),
    aiArgUncategorized: aiBoolParam('true for transactions without a category only.'),
  };

  /// Returns true when [t] passes every filter.
  bool matches(Transaction t) {
    if (accountIds.isNotEmpty && !accountIds.contains(t.fieldAccountId.value)) {
      return false;
    }
    if (!_isInDateRange(t.fieldDateTime.value) || !_isInAmountRange(t.fieldAmount.value.asDouble().abs())) {
      return false;
    }
    if ((isTransfer != null && t.isTransfer != isTransfer) ||
        (uncategorizedOnly && (t.isTransfer || t.fieldCategoryId.value != _noCategoryId))) {
      return false;
    }
    if (payee.isNotEmpty && !aiPayeeOrTransferName(t).toLowerCase().contains(payee)) {
      return false;
    }
    if (category.isNotEmpty && !_categoryNamesOf(t).any((String name) => name.toLowerCase().contains(category))) {
      return false;
    }
    return text.isEmpty || _searchableTextsOf(t).any((String value) => value.toLowerCase().contains(text));
  }

  /// Returns the live transactions passing every filter.
  List<Transaction> run() => Data().transactions.iterableList().where(matches).toList();

  /// Returns the category names of [t] and of its split lines.
  static Iterable<String> _categoryNamesOf(Transaction t) sync* {
    yield t.categoryName;
    for (final TransactionSplit split in t.splits) {
      yield Data().getCategoryNameFromId(split.fieldCategoryId.value);
    }
  }

  /// Returns true when [date] is within [dateFrom] and [dateTo].
  bool _isInDateRange(DateTime? date) {
    if (dateFrom == null && dateTo == null) {
      return true;
    }
    if (date == null) {
      return false;
    }
    return (dateFrom == null || !date.isBefore(dateFrom!)) && (dateTo == null || date.isBefore(dateTo!.add(_oneDay)));
  }

  /// Returns true when [absoluteAmount] is within [minAmount] and [maxAmount].
  bool _isInAmountRange(double absoluteAmount) =>
      (minAmount == null || absoluteAmount >= minAmount!) && (maxAmount == null || absoluteAmount <= maxAmount!);

  /// Returns the texts the free [text] filter looks in.
  static Iterable<String> _searchableTextsOf(Transaction t) sync* {
    yield aiPayeeOrTransferName(t);
    yield t.fieldOriginalPayee.value;
    yield t.fieldMemo.value;
    yield* _categoryNamesOf(t);
    for (final TransactionSplit split in t.splits) {
      yield split.fieldMemo.value;
      yield Data().getPayeeName(split.fieldPayeeId.value);
    }
  }
}

/// Returns the payee name of [t], or the name of the other account when [t] is a transfer.
String aiPayeeOrTransferName(Transaction t) {
  if (t.isTransfer) {
    return (t.relatedAccount as Account?)?.fieldName.value ?? '';
  }
  return t.payeeName;
}

/// Returns [t] as a compact row for a tool result, leaving out empty values to save tokens.
Map<String, Object> aiTransactionRow(Transaction t) {
  final String memo = t.fieldMemo.value;
  return <String, Object>{
    'id': t.uniqueId,
    'date': dateToString(t.fieldDateTime.value),
    'account': t.accountName,
    'amount': t.fieldAmount.value.asDouble(),
    if (t.isTransfer) 'transfer_account': aiPayeeOrTransferName(t) else 'payee': t.payeeName,
    'category': t.categoryName,
    if (memo.isNotEmpty) 'memo': memo,
    if (t.isSplit) 'split_lines': t.splits.length,
  };
}
