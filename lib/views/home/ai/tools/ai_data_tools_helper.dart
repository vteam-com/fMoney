// ignore: fcheck_hardcoded_strings
// Tool names, descriptions and results are written for the AI model, in English; the user never sees them.
import 'package:money/helpers/date_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/views/home/ai/tools/ai_tool_args_helper.dart';
import 'package:money/views/home/ai/tools/ai_tool_model.dart';
import 'package:money/views/home/ai/tools/ai_transaction_query_model.dart';

/// Rows returned when the model does not ask for a number.
const int _defaultRowLimit = 50;

/// Most rows a tool returns, so one result cannot flood the model's context.
const int _maxRowLimit = 200;

/// Most groups a summary returns.
const int _maxGroups = 100;

/// Most names a category or payee listing returns.
const int _maxNamedItems = 200;

/// Cents per currency unit, to round totals to cents.
const int _centsPerUnit = 100;

/// Characters of a YYYY-MM month key.
const int _monthKeyLength = 7;

/// Characters of a YYYY year key.
const int _yearKeyLength = 4;

/// Argument: how many rows to return.
const String _argLimit = 'limit';

/// Argument: row order.
const String _argSort = 'sort';

/// Argument: how to group a summary.
const String _argGroupBy = 'group_by';

/// Argument: part of a name to find.
const String _argSearch = 'search';

/// Argument: also list closed accounts.
const String _argIncludeClosed = 'include_closed';

/// Argument: one transaction id.
const String _argId = 'id';

/// Sort: newest first.
const String _sortDateDesc = 'date_desc';

/// Sort: oldest first.
const String _sortDateAsc = 'date_asc';

/// Sort: largest amount (without sign) first.
const String _sortAmountDesc = 'amount_desc';

/// Group by month.
const String _groupMonth = 'month';

/// Group by year.
const String _groupYear = 'year';

/// Group by category.
const String _groupCategory = 'category';

/// Group by payee or transfer account.
const String _groupPayee = 'payee';

/// Group by account.
const String _groupAccount = 'account';

/// Returns the read-only tools that look up accounts, transactions, categories and payees.
List<AiTool> aiDataTools() => <AiTool>[
  AiTool(
    name: 'list_accounts',
    description:
        'Lists accounts with id, name, type, balance, currency, number of transactions and date range. '
        'Call it first to turn account names into the ids other tools take.',
    parameters: <String, Map<String, Object>>{
      _argSearch: aiStringParam('Part of the account name to find; omit to list all.'),
      _argIncludeClosed: aiBoolParam('true to also list closed accounts.'),
    },
    run: (Map<String, dynamic> args) async => _listAccounts(args),
  ),
  AiTool(
    name: 'search_transactions',
    description:
        'Searches all transactions in every year (not only recent ones) and returns matching rows '
        'with the total number of matches. Combine filters to narrow the search.',
    parameters: <String, Map<String, Object>>{
      ...AiTransactionQuery.parameters,
      _argSort: aiStringParam(
        'Row order, newest first by default.',
        values: <String>[_sortDateDesc, _sortDateAsc, _sortAmountDesc],
      ),
      _argLimit: aiIntParam('Most rows to return, $_defaultRowLimit by default, at most $_maxRowLimit.'),
    },
    run: (Map<String, dynamic> args) async => _searchTransactions(args),
  ),
  AiTool(
    name: 'summarize_transactions',
    description:
        'Totals and counts the matching transactions per month, year, category, payee or account, without '
        'listing them. Use it for "how much" questions; split transactions count per split line.',
    parameters: <String, Map<String, Object>>{
      ...AiTransactionQuery.parameters,
      _argGroupBy: aiStringParam(
        'How to group the totals.',
        values: <String>[_groupMonth, _groupYear, _groupCategory, _groupPayee, _groupAccount],
      ),
    },
    required: <String>[_argGroupBy],
    run: (Map<String, dynamic> args) async => _summarizeTransactions(args),
  ),
  AiTool(
    name: 'get_transaction',
    description:
        'Returns every detail of one transaction: status, original bank text, number, split lines and transfer.',
    parameters: <String, Map<String, Object>>{_argId: aiIntParam('Transaction id.')},
    required: <String>[_argId],
    run: (Map<String, dynamic> args) async => _getTransaction(args),
  ),
  AiTool(
    name: 'list_categories',
    description: 'Lists categories with id, full name (Parent:Child), type and number of transactions.',
    parameters: <String, Map<String, Object>>{_argSearch: aiStringParam('Part of the category name to find.')},
    run: (Map<String, dynamic> args) async => _listCategories(args),
  ),
  AiTool(
    name: 'list_payees',
    description: 'Lists payees with id, name, number of transactions and total amount, most used first.',
    parameters: <String, Map<String, Object>>{_argSearch: aiStringParam('Part of the payee name to find.')},
    run: (Map<String, dynamic> args) async => _listPayees(args),
  ),
];

/// Returns [value] rounded to cents.
double aiRoundToCents(double value) => (value * _centsPerUnit).round() / _centsPerUnit;

/// Returns the transaction [args] names by its `id`, or throws a message the model can act on.
Transaction aiTransactionFromArgs(Map<String, dynamic> args, String key) {
  final int? id = args.intArg(key);
  final Transaction? transaction = id == null ? null : Data().transactions.get(id);
  if (transaction == null || transaction.isDeleted) {
    throw ArgumentError('No transaction with id ${args[key]}; use search_transactions to find ids.');
  }
  return transaction;
}

/// Returns [rows] capped at [limit] with the total, telling the model when rows were left out.
Map<String, Object> aiLimitedRows(List<Map<String, Object>> rows, int limit) {
  return <String, Object>{
    'total_matches': rows.length,
    'rows': rows.take(limit).toList(),
    if (rows.length > limit) 'note': 'Only the first $limit of ${rows.length} are listed; narrow the filters.',
  };
}

/// Returns the transaction detail asked for by [args].
Map<String, Object> _getTransaction(Map<String, dynamic> args) {
  final Transaction t = aiTransactionFromArgs(args, _argId);
  return <String, Object>{
    ...aiTransactionRow(t),
    'account_id': t.fieldAccountId.value,
    'status': t.fieldStatus.value.name,
    if (t.fieldOriginalPayee.value.isNotEmpty) 'original_bank_text': t.fieldOriginalPayee.value,
    if (t.fieldNumber.value.isNotEmpty) 'number': t.fieldNumber.value,
    if (t.isTransfer) 'transfer_transaction_id': t.fieldTransfer.value,
    if (t.isSplit)
      'splits': t.splits
          .map(
            (TransactionSplit split) => <String, Object>{
              'amount': split.fieldAmount.value.asDouble(),
              'category': Data().getCategoryNameFromId(split.fieldCategoryId.value),
              'payee': Data().getPayeeName(split.fieldPayeeId.value),
              'memo': split.fieldMemo.value,
            },
          )
          .toList(),
  };
}

/// Returns the group key of [t] for [groupBy].
String _groupKeyOf(Transaction t, String groupBy) {
  final String date = dateToString(t.fieldDateTime.value);
  switch (groupBy) {
    case _groupMonth:
      return date.substring(0, _monthKeyLength);
    case _groupYear:
      return date.substring(0, _yearKeyLength);
    case _groupPayee:
      return aiPayeeOrTransferName(t);
    case _groupAccount:
      return t.accountName;
    default:
      return t.categoryName;
  }
}

/// Returns the accounts asked for by [args], each with its transaction date range.
Map<String, Object> _listAccounts(Map<String, dynamic> args) {
  final String search = args.stringArg(_argSearch).toLowerCase();
  final bool includeClosed = args.boolArg(_argIncludeClosed) ?? false;
  final Map<int, List<DateTime>> datesByAccount = <int, List<DateTime>>{};
  for (final Transaction t in Data().transactions.iterableList()) {
    final DateTime? date = t.fieldDateTime.value;
    if (date != null) {
      datesByAccount.putIfAbsent(t.fieldAccountId.value, () => <DateTime>[]).add(date);
    }
  }
  final List<Map<String, Object>> rows = Data().accounts
      .iterableList()
      .where(
        (Account a) =>
            !a.isFakeAccount() && (includeClosed || a.isOpen) && a.fieldName.value.toLowerCase().contains(search),
      )
      .map((Account a) {
        final List<DateTime> dates = datesByAccount[a.uniqueId] ?? <DateTime>[];
        dates.sort();
        return <String, Object>{
          'id': a.uniqueId,
          'name': a.fieldName.value,
          'type': a.fieldType.value.name,
          'balance': aiRoundToCents(a.balance),
          'currency': a.getAccountCurrencyAsText(),
          'transactions': dates.length,
          if (dates.isNotEmpty) 'first_date': dateToString(dates.first),
          if (dates.isNotEmpty) 'last_date': dateToString(dates.last),
          if (!a.isOpen) 'closed': true,
        };
      })
      .toList();
  return aiLimitedRows(rows, _maxRowLimit);
}

/// Returns the categories asked for by [args].
Map<String, Object> _listCategories(Map<String, dynamic> args) {
  final String search = args.stringArg(_argSearch).toLowerCase();
  final List<Category> categories =
      Data().categories.iterableList().where((Category c) => c.name.toLowerCase().contains(search)).toList()
        ..sort((Category a, Category b) => a.name.compareTo(b.name));
  return aiLimitedRows(
    categories
        .map(
          (Category c) => <String, Object>{
            'id': c.uniqueId,
            'name': c.name,
            'type': c.fieldType.value.name,
            'transactions': c.fieldTransactionCount.value,
          },
        )
        .toList(),
    _maxNamedItems,
  );
}

/// Returns the payees asked for by [args], most used first.
Map<String, Object> _listPayees(Map<String, dynamic> args) {
  final String search = args.stringArg(_argSearch).toLowerCase();
  final List<Payee> payees =
      Data().payees.iterableList().where((Payee p) => p.fieldName.value.toLowerCase().contains(search)).toList()
        ..sort((Payee a, Payee b) => b.fieldCount.value.compareTo(a.fieldCount.value));
  return aiLimitedRows(
    payees
        .map(
          (Payee p) => <String, Object>{
            'id': p.uniqueId,
            'name': p.fieldName.value,
            'transactions': p.fieldCount.value,
            'total': aiRoundToCents(p.fieldSum.value.asDouble()),
          },
        )
        .toList(),
    _maxNamedItems,
  );
}

/// Returns the transactions matching [args], sorted and capped as asked.
Map<String, Object> _searchTransactions(Map<String, dynamic> args) {
  final List<Transaction> matches = AiTransactionQuery.fromArgs(args).run();
  final String sort = args.stringArg(_argSort);
  matches.sort((Transaction a, Transaction b) {
    if (sort == _sortAmountDesc) {
      return b.fieldAmount.value.asDouble().abs().compareTo(a.fieldAmount.value.asDouble().abs());
    }
    final int byDate = Transaction.sortByDateTime(a, b, true);
    return sort == _sortDateAsc ? byDate : -byDate;
  });
  final int limit = (args.intArg(_argLimit) ?? _defaultRowLimit).clamp(1, _maxRowLimit);
  return aiLimitedRows(matches.map(aiTransactionRow).toList(), limit);
}

/// Returns the totals of the transactions matching [args], grouped as asked; split lines count separately.
Map<String, Object> _summarizeTransactions(Map<String, dynamic> args) {
  final AiTransactionQuery query = AiTransactionQuery.fromArgs(args);
  final String groupBy = args.stringArg(_argGroupBy);
  final Map<String, ({int count, double total})> groups = <String, ({int count, double total})>{};
  double grandTotal = 0;
  int count = 0;
  for (final Transaction t in Data().transactions.getListFlattenSplits(whereClause: query.matches)) {
    final double amount = t.fieldAmount.value.asDouble();
    final ({int count, double total}) group = groups[_groupKeyOf(t, groupBy)] ?? (count: 0, total: 0);
    groups[_groupKeyOf(t, groupBy)] = (count: group.count + 1, total: group.total + amount);
    grandTotal += amount;
    count++;
  }
  final List<MapEntry<String, ({int count, double total})>> sorted = groups.entries.toList()
    ..sort(
      (MapEntry<String, ({int count, double total})> a, MapEntry<String, ({int count, double total})> b) =>
          groupBy == _groupMonth || groupBy == _groupYear
          ? a.key.compareTo(b.key)
          : b.value.total.abs().compareTo(a.value.total.abs()),
    );
  return <String, Object>{
    'transactions': count,
    'total': aiRoundToCents(grandTotal),
    'groups': sorted
        .take(_maxGroups)
        .map(
          (MapEntry<String, ({int count, double total})> entry) => <String, Object>{
            'key': entry.key,
            'count': entry.value.count,
            'total': aiRoundToCents(entry.value.total),
          },
        )
        .toList(),
    if (sorted.length > _maxGroups) 'note': 'Only the $_maxGroups largest of ${sorted.length} groups are listed.',
  };
}
